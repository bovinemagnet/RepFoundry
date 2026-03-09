import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/features/sync/application/sync_orchestrator.dart';
import 'package:rep_foundry/features/sync/data/sync_snapshot_serialiser.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_snapshot.dart';
import 'package:rep_foundry/features/sync/domain/sync_service.dart';

// ── Fakes ──────────────────────────────────────────────────────────────

class FakeCloudSyncService implements CloudSyncService {
  String? storedJson;
  bool available = true;
  bool throwOnUpload = false;
  String uploadError = 'Cloud upload failed';

  /// Completer to delay downloadSnapshot until we release it.
  Completer<String?>? downloadCompleter;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> uploadSnapshot(String jsonData) async {
    if (throwOnUpload) {
      throw Exception(uploadError);
    }
    storedJson = jsonData;
  }

  @override
  Future<String?> downloadSnapshot() async {
    if (downloadCompleter != null) {
      return downloadCompleter!.future;
    }
    return storedJson;
  }

  @override
  Future<void> deleteCloudData() async {
    storedJson = null;
  }
}

class FakeConnectivity implements Connectivity {
  List<ConnectivityResult> result = [ConnectivityResult.wifi];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => result;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value(result);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class FakeSyncSnapshotSerialiser extends SyncSnapshotSerialiser {
  late SyncSnapshot snapshotToReturn;
  SyncSnapshot? appliedSnapshot;

  @override
  Future<SyncSnapshot> createFromDatabase(
    AppDatabase database, {
    required String deviceId,
  }) async {
    return snapshotToReturn;
  }

  @override
  Future<void> applyToDatabase(
    AppDatabase database,
    SyncSnapshot snapshot,
  ) async {
    appliedSnapshot = snapshot;
  }
}

// ── Tests ──────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late FakeCloudSyncService cloudService;
  late FakeConnectivity connectivity;
  late FakeSyncSnapshotSerialiser serialiser;
  late SyncOrchestrator orchestrator;

  final fixedTime = DateTime.utc(2026, 3, 9, 12, 0, 0);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cloudService = FakeCloudSyncService();
    connectivity = FakeConnectivity();
    serialiser = FakeSyncSnapshotSerialiser();
    serialiser.snapshotToReturn = SyncSnapshot(
      snapshotAt: fixedTime,
      deviceId: 'test-device',
      schemaVersion: 6,
    );
    orchestrator = SyncOrchestrator(
      database: db,
      cloudService: cloudService,
      deviceId: 'test-device',
      connectivity: connectivity,
      serialiser: serialiser,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncOrchestrator', () {
    test('no connectivity returns error', () async {
      connectivity.result = [ConnectivityResult.none];

      final result = await orchestrator.sync();

      expect(result.success, isFalse);
      expect(result.errorMessage, 'No network connection');
    });

    test('concurrent sync blocked returns error', () async {
      // Use a completer to hold the first sync mid-flight.
      final downloadCompleter = Completer<String?>();
      cloudService.downloadCompleter = downloadCompleter;

      // Start first sync — it will block on downloadSnapshot.
      final future1 = orchestrator.sync();

      // While first is in progress, start a second sync.
      final result2 = await orchestrator.sync();

      expect(result2.success, isFalse);
      expect(result2.errorMessage, 'Sync already in progress');

      // Release the first sync so it can complete.
      downloadCompleter.complete(null);
      final result1 = await future1;
      expect(result1.success, isTrue);
    });

    test('first sync with no remote uploads local snapshot as-is', () async {
      // downloadSnapshot returns null (no remote data).
      cloudService.storedJson = null;

      final result = await orchestrator.sync();

      expect(result.success, isTrue);
      expect(result.entitiesMerged, 0); // empty snapshot
      expect(cloudService.storedJson, isNotNull);
      // applyToDatabase was called with the local snapshot (no merge).
      expect(serialiser.appliedSnapshot, isNotNull);
      expect(serialiser.appliedSnapshot!.deviceId, 'test-device');
    });

    test('normal sync with remote data merges and uploads', () async {
      // Set up a remote snapshot via JSON in the cloud service.
      final remoteSnapshot = SyncSnapshot(
        snapshotAt: fixedTime,
        deviceId: 'other-device',
        schemaVersion: 6,
      );
      // Serialise the remote snapshot to JSON using the real toJson.
      final realSerialiser = SyncSnapshotSerialiser();
      cloudService.storedJson = realSerialiser.toJson(remoteSnapshot);

      final result = await orchestrator.sync();

      expect(result.success, isTrue);
      // The merge engine was invoked; applyToDatabase was called.
      expect(serialiser.appliedSnapshot, isNotNull);
      // Uploaded JSON should exist.
      expect(cloudService.storedJson, isNotNull);
    });

    test('cloud service error on upload returns error and resets isSyncing',
        () async {
      cloudService.throwOnUpload = true;
      cloudService.uploadError = 'Service unavailable';

      final result = await orchestrator.sync();

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Service unavailable'));
      // isSyncing should be reset so another sync is possible.
      expect(orchestrator.isSyncing, isFalse);

      // Verify a subsequent sync is not blocked.
      cloudService.throwOnUpload = false;
      final result2 = await orchestrator.sync();
      expect(result2.success, isTrue);
    });

    test('deleteCloudData delegates to cloud service', () async {
      // Pre-populate cloud data.
      cloudService.storedJson = '{"some": "data"}';
      expect(cloudService.storedJson, isNotNull);

      await orchestrator.deleteCloudData();

      expect(cloudService.storedJson, isNull);
    });
  });
}
