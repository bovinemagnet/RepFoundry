import 'models/sync_snapshot.dart';

/// Merges two [SyncSnapshot]s using last-write-wins per entity, with
/// tombstone awareness so deletes do not resurrect across devices.
///
/// For each entity type, entities are matched by UUID. When the same
/// UUID exists in both snapshots, the comparator runs in this order:
///
/// 1. If both sides have a `deletedAt` set, the larger one wins.
/// 2. If exactly one side has a `deletedAt` set, that side wins —
///    a tombstone always beats a live row.
/// 3. Otherwise, the side with the larger `updatedAt` wins.
///    Ties are broken in favour of the local snapshot.
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
        getDeletedAt: (e) => e.deletedAt,
      ),
      workouts: _mergeById(
        local.workouts,
        remote.workouts,
        getId: (w) => w.id,
        getUpdatedAt: (w) => w.updatedAt,
        getDeletedAt: (w) => w.deletedAt,
      ),
      workoutSets: _mergeById(
        local.workoutSets,
        remote.workoutSets,
        getId: (s) => s.id,
        getUpdatedAt: (s) => s.updatedAt,
        getDeletedAt: (s) => s.deletedAt,
      ),
      cardioSessions: _mergeById(
        local.cardioSessions,
        remote.cardioSessions,
        getId: (c) => c.id,
        getUpdatedAt: (c) => c.updatedAt,
        getDeletedAt: (c) => c.deletedAt,
      ),
      personalRecords: _mergeById(
        local.personalRecords,
        remote.personalRecords,
        getId: (p) => p.id,
        getUpdatedAt: (p) => p.updatedAt,
        getDeletedAt: (p) => p.deletedAt,
      ),
      workoutTemplates: _mergeById(
        local.workoutTemplates,
        remote.workoutTemplates,
        getId: (t) => t.id,
        getUpdatedAt: (t) => t.updatedAt,
        getDeletedAt: (t) => t.deletedAt,
      ),
      templateExercises: _mergeById(
        local.templateExercises,
        remote.templateExercises,
        getId: (te) => te.id,
        getUpdatedAt: (te) => te.updatedAt,
        getDeletedAt: (te) => te.deletedAt,
      ),
      bodyMetrics: _mergeById(
        local.bodyMetrics,
        remote.bodyMetrics,
        getId: (b) => b.id,
        getUpdatedAt: (b) => b.updatedAt,
        getDeletedAt: (b) => b.deletedAt,
      ),
      programmes: _mergeById(
        local.programmes,
        remote.programmes,
        getId: (p) => p.id,
        getUpdatedAt: (p) => p.updatedAt,
        getDeletedAt: (p) => p.deletedAt,
      ),
      programmeDays: _mergeById(
        local.programmeDays,
        remote.programmeDays,
        getId: (d) => d.id,
        getUpdatedAt: (d) => d.updatedAt,
        getDeletedAt: (d) => d.deletedAt,
      ),
      progressionRules: _mergeById(
        local.progressionRules,
        remote.progressionRules,
        getId: (r) => r.id,
        getUpdatedAt: (r) => r.updatedAt,
        getDeletedAt: (r) => r.deletedAt,
      ),
      stretchingSessions: _mergeById(
        local.stretchingSessions,
        remote.stretchingSessions,
        getId: (s) => s.id,
        getUpdatedAt: (s) => s.updatedAt,
        getDeletedAt: (s) => s.deletedAt,
      ),
    );
  }

  /// Generic last-write-wins merge by UUID, with tombstone precedence.
  List<T> _mergeById<T>(
    List<T> localItems,
    List<T> remoteItems, {
    required String Function(T) getId,
    required DateTime Function(T) getUpdatedAt,
    DateTime? Function(T)? getDeletedAt,
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
        continue;
      }
      if (_remoteWins(existing, item, getUpdatedAt, getDeletedAt)) {
        merged[id] = item;
      }
      // Otherwise the local entry stays (already in map).
    }

    return merged.values.toList();
  }

  bool _remoteWins<T>(
    T local,
    T remote,
    DateTime Function(T) getUpdatedAt,
    DateTime? Function(T)? getDeletedAt,
  ) {
    final localDeleted = getDeletedAt?.call(local);
    final remoteDeleted = getDeletedAt?.call(remote);

    if (localDeleted != null && remoteDeleted != null) {
      // Both tombstones: larger wins. Ties favour local.
      return remoteDeleted.isAfter(localDeleted);
    }
    if (remoteDeleted != null && localDeleted == null) {
      return true;
    }
    if (localDeleted != null && remoteDeleted == null) {
      return false;
    }
    // Neither tombstoned: compare updatedAt. Ties favour local.
    return getUpdatedAt(remote).isAfter(getUpdatedAt(local));
  }
}
