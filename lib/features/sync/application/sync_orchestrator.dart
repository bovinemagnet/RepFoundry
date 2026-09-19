import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/database/app_database.dart';
import '../data/sync_snapshot_serialiser.dart';
import '../domain/models/sync_result.dart';
import '../domain/models/sync_snapshot.dart';
import '../domain/sync_merge_engine.dart';
import '../domain/sync_schema_version_exception.dart';
import '../domain/sync_service.dart';

class SyncOrchestrator {
  final AppDatabase _database;
  final CloudSyncService _cloudService;
  final SyncSnapshotSerialiser _serialiser;
  final SyncMergeEngine _mergeEngine;
  final Connectivity _connectivity;
  final String _deviceId;

  // Static so the guard survives provider rebuilds (the orchestrator is
  // recreated whenever sync settings change). Holds the in-flight run so
  // deleteCloudData can wait for it rather than race its upload.
  static Future<SyncResult>? _inFlight;

  SyncOrchestrator({
    required AppDatabase database,
    required CloudSyncService cloudService,
    required String deviceId,
    SyncSnapshotSerialiser? serialiser,
    SyncMergeEngine? mergeEngine,
    Connectivity? connectivity,
  })  : _database = database,
        _cloudService = cloudService,
        _deviceId = deviceId,
        _serialiser = serialiser ?? SyncSnapshotSerialiser(),
        _mergeEngine = mergeEngine ?? SyncMergeEngine(),
        _connectivity = connectivity ?? Connectivity();

  bool get isSyncing => _inFlight != null;

  /// Whether this host has a real cloud backend. See
  /// [CloudSyncService.isSupported].
  bool get isSupported => _cloudService.isSupported;

  Future<SyncResult> sync({bool interactive = false}) async {
    if (!isSupported) {
      return SyncResult.error('Cloud sync is not available on this platform');
    }
    if (_inFlight != null) {
      return SyncResult.error('Sync already in progress');
    }

    final run = _run(interactive: interactive);
    _inFlight = run;
    return run;
  }

  Future<SyncResult> _run({required bool interactive}) async {
    try {
      // 1. Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.every((r) => r == ConnectivityResult.none)) {
        return SyncResult.error('No network connection');
      }

      // 2. Create local snapshot (including soft-deleted)
      final localSnapshot = await _serialiser.createFromDatabase(
        _database,
        deviceId: _deviceId,
      );

      // 3. Download remote snapshot (null on first sync)
      final remoteJson = await _cloudService.downloadSnapshot(
        interactive: interactive,
      );

      // 4. Merge local + remote.
      //
      // fromJson can throw SyncSchemaVersionException when the remote
      // snapshot was created by a newer client; surface that as a typed
      // failure so the UI can display upgrade copy.
      final SyncSnapshot merged;
      try {
        merged = remoteJson != null
            ? _mergeEngine.merge(
                local: localSnapshot,
                remote: _serialiser.fromJson(remoteJson),
              )
            : localSnapshot;
      } on SyncSchemaVersionException catch (e) {
        return SyncResult.error(e.message);
      }

      // 5. Upload merged snapshot to cloud FIRST.
      //
      // Upload-first makes cloud the source of truth: if the upload
      // throws (network blip), the local DB stays untouched and a retry
      // can compose a fresh merge. The previous order — apply-then-upload
      // — left local ahead of cloud after a failed upload, which let the
      // next syncing device overwrite the unrelayed work.
      final mergedJson = _serialiser.toJson(merged);
      await _cloudService.uploadSnapshot(
        mergedJson,
        interactive: interactive,
      );

      // 6. Apply merged result to local DB (only after upload succeeds).
      await _serialiser.applyToDatabase(_database, merged);

      final totalEntities = merged.exercises.length +
          merged.workouts.length +
          merged.workoutSets.length +
          merged.cardioSessions.length +
          merged.personalRecords.length +
          merged.workoutTemplates.length +
          merged.templateExercises.length +
          merged.bodyMetrics.length +
          merged.programmes.length +
          merged.programmeDays.length +
          merged.progressionRules.length +
          merged.stretchingSessions.length;

      return SyncResult.success(entitiesMerged: totalEntities);
      // Catch Errors too (e.g. StateError from parsing a snapshot written by
      // a newer app version) — sync must fail cleanly, never crash the app.
    } catch (e) {
      return SyncResult.error(e.toString());
    } finally {
      _inFlight = null;
    }
  }

  /// Delete all cloud data and reset sync state.
  ///
  /// Waits for any in-flight sync first: its upload would otherwise land
  /// after the delete and silently recreate the data the user just removed.
  Future<void> deleteCloudData({bool interactive = false}) async {
    // sync() never throws — _run catches everything — so awaiting is safe.
    await _inFlight;
    await _cloudService.deleteCloudData(interactive: interactive);
  }
}
