import 'models/sync_snapshot.dart';

/// Merges two [SyncSnapshot]s using last-write-wins per entity.
///
/// For each entity type, entities are matched by UUID. When the same
/// UUID exists in both snapshots, the entity with the newer [updatedAt]
/// wins. Ties are broken in favour of the local snapshot.
class SyncMergeEngine {
  SyncSnapshot merge({
    required SyncSnapshot local,
    required SyncSnapshot remote,
  }) {
    return SyncSnapshot(
      snapshotAt: DateTime.now().toUtc(),
      deviceId: local.deviceId,
      schemaVersion: local.schemaVersion,
      exercises: _mergeById(
        local.exercises,
        remote.exercises,
        getId: (e) => e.id,
        getUpdatedAt: (e) => e.updatedAt,
      ),
      workouts: _mergeById(
        local.workouts,
        remote.workouts,
        getId: (w) => w.id,
        getUpdatedAt: (w) => w.updatedAt,
      ),
      workoutSets: _mergeById(
        local.workoutSets,
        remote.workoutSets,
        getId: (s) => s.id,
        getUpdatedAt: (s) => s.updatedAt,
      ),
      cardioSessions: _mergeById(
        local.cardioSessions,
        remote.cardioSessions,
        getId: (c) => c.id,
        getUpdatedAt: (c) => c.updatedAt,
      ),
      personalRecords: _mergeById(
        local.personalRecords,
        remote.personalRecords,
        getId: (p) => p.id,
        getUpdatedAt: (p) => p.updatedAt,
      ),
      workoutTemplates: _mergeById(
        local.workoutTemplates,
        remote.workoutTemplates,
        getId: (t) => t.id,
        getUpdatedAt: (t) => t.updatedAt,
      ),
      templateExercises: _mergeById(
        local.templateExercises,
        remote.templateExercises,
        getId: (te) => te.id,
        getUpdatedAt: (te) => te.updatedAt,
      ),
      bodyMetrics: _mergeById(
        local.bodyMetrics,
        remote.bodyMetrics,
        getId: (b) => b.id,
        getUpdatedAt: (b) => b.updatedAt,
      ),
      programmes: _mergeById(
        local.programmes,
        remote.programmes,
        getId: (p) => p.id,
        getUpdatedAt: (p) => p.updatedAt,
      ),
      programmeDays: _mergeById(
        local.programmeDays,
        remote.programmeDays,
        getId: (d) => d.id,
        getUpdatedAt: (d) => d.updatedAt,
      ),
      progressionRules: _mergeById(
        local.progressionRules,
        remote.progressionRules,
        getId: (r) => r.id,
        getUpdatedAt: (r) => r.updatedAt,
      ),
    );
  }

  /// Generic last-write-wins merge by UUID.
  ///
  /// When timestamps are equal, local wins (deterministic tie-breaking).
  List<T> _mergeById<T>(
    List<T> localItems,
    List<T> remoteItems, {
    required String Function(T) getId,
    required DateTime Function(T) getUpdatedAt,
  }) {
    final merged = <String, T>{};

    for (final item in localItems) {
      merged[getId(item)] = item;
    }

    for (final item in remoteItems) {
      final id = getId(item);
      final existing = merged[id];
      if (existing == null) {
        merged[id] = item;
      } else {
        final existingTime = getUpdatedAt(existing);
        final remoteTime = getUpdatedAt(item);
        if (remoteTime.isAfter(existingTime)) {
          merged[id] = item;
        }
        // Equal timestamps: local wins (already in map).
      }
    }

    return merged.values.toList();
  }
}
