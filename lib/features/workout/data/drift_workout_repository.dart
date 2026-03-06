import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../domain/models/workout.dart';
import '../domain/models/workout_set.dart';
import '../domain/repositories/workout_repository.dart';

class DriftWorkoutRepository implements WorkoutRepository {
  final db.AppDatabase _db;

  DriftWorkoutRepository(this._db);

  // ── Workouts ──────────────────────────────────────────────────────────

  @override
  Future<Workout> createWorkout(Workout workout) async {
    await _db.into(_db.workouts).insert(
          db.WorkoutsCompanion.insert(
            id: workout.id,
            startedAt: dateTimeToEpochMs(workout.startedAt),
            completedAt: Value(nullableDateTimeToEpochMs(workout.completedAt)),
            templateId: Value(workout.templateId),
            notes: Value(workout.notes),
          ),
        );
    return workout;
  }

  @override
  Future<Workout?> getWorkout(String id) async {
    final q = _db.select(_db.workouts)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await q.getSingleOrNull();
    return row == null ? null : _workoutToDomain(row);
  }

  @override
  Future<Workout?> getActiveWorkout() async {
    final q = _db.select(_db.workouts)
      ..where(
        (t) => t.completedAt.isNull() & t.deletedAt.isNull(),
      );
    final row = await q.getSingleOrNull();
    return row == null ? null : _workoutToDomain(row);
  }

  @override
  Future<List<Workout>> getWorkoutHistory({
    int limit = 20,
    DateTime? before,
  }) async {
    final q = _db.select(_db.workouts)
      ..where((t) {
        var cond = t.completedAt.isNotNull() & t.deletedAt.isNull();
        if (before != null) {
          cond =
              cond & t.startedAt.isSmallerThanValue(dateTimeToEpochMs(before));
        }
        return cond;
      })
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(limit);
    final rows = await q.get();
    return rows.map(_workoutToDomain).toList();
  }

  @override
  Future<Workout> updateWorkout(Workout workout) async {
    await (_db.update(_db.workouts)..where((t) => t.id.equals(workout.id)))
        .write(
      db.WorkoutsCompanion(
        startedAt: Value(dateTimeToEpochMs(workout.startedAt)),
        completedAt: Value(nullableDateTimeToEpochMs(workout.completedAt)),
        templateId: Value(workout.templateId),
        notes: Value(workout.notes),
        deletedAt: Value(nullableDateTimeToEpochMs(workout.deletedAt)),
      ),
    );
    return workout;
  }

  @override
  Future<void> deleteWorkout(String id) async {
    final now = dateTimeToEpochMs(DateTime.now().toUtc());
    await (_db.update(_db.workouts)..where((t) => t.id.equals(id)))
        .write(db.WorkoutsCompanion(deletedAt: Value(now)));
  }

  // ── Sets ──────────────────────────────────────────────────────────────

  @override
  Future<WorkoutSet> addSet(WorkoutSet set) async {
    await _db.into(_db.workoutSets).insert(
          db.WorkoutSetsCompanion.insert(
            id: set.id,
            workoutId: set.workoutId,
            exerciseId: set.exerciseId,
            setOrder: set.setOrder,
            weight: set.weight,
            reps: set.reps,
            rpe: Value(set.rpe),
            timestamp: dateTimeToEpochMs(set.timestamp),
          ),
        );
    return set;
  }

  @override
  Future<List<WorkoutSet>> getSetsForWorkout(String workoutId) async {
    final q = _db.select(_db.workoutSets)
      ..where((t) => t.workoutId.equals(workoutId))
      ..orderBy([(t) => OrderingTerm.asc(t.setOrder)]);
    final rows = await q.get();
    return rows.map(_setToDomain).toList();
  }

  @override
  Future<List<WorkoutSet>> getSetsForExercise(
    String exerciseId, {
    int limit = 50,
  }) async {
    final q = _db.select(_db.workoutSets)
      ..where((t) => t.exerciseId.equals(exerciseId))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(limit);
    final rows = await q.get();
    return rows.map(_setToDomain).toList();
  }

  @override
  Future<WorkoutSet?> getLastSetForExercise(String exerciseId) async {
    final q = _db.select(_db.workoutSets)
      ..where((t) => t.exerciseId.equals(exerciseId))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(1);
    final row = await q.getSingleOrNull();
    return row == null ? null : _setToDomain(row);
  }

  @override
  Future<void> deleteSet(String setId) async {
    await (_db.delete(_db.workoutSets)..where((t) => t.id.equals(setId))).go();
  }

  @override
  Future<List<WorkoutSet>> getSetsFromLastSession(String exerciseId) async {
    // Find the most recent completed, non-deleted workout containing this exercise.
    final workoutIdResult = await _db.customSelect(
      'SELECT w.id FROM workouts w '
      'INNER JOIN workout_sets ws ON ws.workout_id = w.id '
      'WHERE ws.exercise_id = ? '
      'AND w.completed_at IS NOT NULL '
      'AND w.deleted_at IS NULL '
      'ORDER BY w.started_at DESC '
      'LIMIT 1',
      variables: [Variable.withString(exerciseId)],
    ).getSingleOrNull();

    if (workoutIdResult == null) return [];

    final workoutId = workoutIdResult.read<String>('id');

    // Fetch all sets for that exercise in that workout, ordered by setOrder.
    final q = _db.select(_db.workoutSets)
      ..where(
        (t) =>
            t.workoutId.equals(workoutId) & t.exerciseId.equals(exerciseId),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.setOrder)]);
    final rows = await q.get();
    return rows.map(_setToDomain).toList();
  }

  // ── Streams ───────────────────────────────────────────────────────────

  @override
  Stream<List<Workout>> watchWorkoutHistory() {
    final q = _db.select(_db.workouts)
      ..where(
        (t) => t.completedAt.isNotNull() & t.deletedAt.isNull(),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
    return q.watch().map((rows) => rows.map(_workoutToDomain).toList());
  }

  @override
  Stream<List<WorkoutSet>> watchSetsForWorkout(String workoutId) {
    final q = _db.select(_db.workoutSets)
      ..where((t) => t.workoutId.equals(workoutId))
      ..orderBy([(t) => OrderingTerm.asc(t.setOrder)]);
    return q.watch().map((rows) => rows.map(_setToDomain).toList());
  }

  // ── Mappers ───────────────────────────────────────────────────────────

  Workout _workoutToDomain(db.Workout row) {
    return Workout(
      id: row.id,
      startedAt: dateTimeFromEpochMs(row.startedAt),
      completedAt: nullableDateTimeFromEpochMs(row.completedAt),
      templateId: row.templateId,
      notes: row.notes,
      deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
    );
  }

  WorkoutSet _setToDomain(db.WorkoutSet row) {
    return WorkoutSet(
      id: row.id,
      workoutId: row.workoutId,
      exerciseId: row.exerciseId,
      setOrder: row.setOrder,
      weight: row.weight,
      reps: row.reps,
      rpe: row.rpe,
      timestamp: dateTimeFromEpochMs(row.timestamp),
    );
  }
}
