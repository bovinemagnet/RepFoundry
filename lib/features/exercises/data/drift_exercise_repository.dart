import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../domain/models/exercise.dart';
import '../domain/repositories/exercise_repository.dart';

class DriftExerciseRepository implements ExerciseRepository {
  final db.AppDatabase _db;

  DriftExerciseRepository(this._db);

  @override
  Future<List<Exercise>> getAllExercises() async {
    final query = _db.select(_db.exercises)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<Exercise>> searchExercises(String query) async {
    final pattern = '%${query.toLowerCase()}%';
    final q = _db.select(_db.exercises)
      ..where(
        (t) => t.deletedAt.isNull() & t.name.lower().like(pattern),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<Exercise>> getExercisesByMuscleGroup(
    MuscleGroup muscleGroup,
  ) async {
    final q = _db.select(_db.exercises)
      ..where(
        (t) => t.deletedAt.isNull() & t.muscleGroup.equals(muscleGroup.name),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Exercise?> getExercise(String id) async {
    final q = _db.select(_db.exercises)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await q.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Exercise> createExercise(Exercise exercise) async {
    await _db.into(_db.exercises).insert(
          db.ExercisesCompanion.insert(
            id: exercise.id,
            name: exercise.name,
            category: exercise.category.name,
            muscleGroup: exercise.muscleGroup.name,
            equipmentType: exercise.equipmentType.name,
            isCustom: Value(exercise.isCustom),
          ),
        );
    return exercise;
  }

  @override
  Future<Exercise> updateExercise(Exercise exercise) async {
    await (_db.update(_db.exercises)..where((t) => t.id.equals(exercise.id)))
        .write(
      db.ExercisesCompanion(
        name: Value(exercise.name),
        category: Value(exercise.category.name),
        muscleGroup: Value(exercise.muscleGroup.name),
        equipmentType: Value(exercise.equipmentType.name),
        isCustom: Value(exercise.isCustom),
        deletedAt: Value(nullableDateTimeToEpochMs(exercise.deletedAt)),
      ),
    );
    return exercise;
  }

  @override
  Future<void> deleteExercise(String id) async {
    final now = dateTimeToEpochMs(DateTime.now().toUtc());
    await (_db.update(_db.exercises)..where((t) => t.id.equals(id)))
        .write(db.ExercisesCompanion(deletedAt: Value(now)));
  }

  @override
  Stream<List<Exercise>> watchAllExercises() {
    final q = _db.select(_db.exercises)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Exercise _toDomain(db.Exercise row) {
    return Exercise(
      id: row.id,
      name: row.name,
      category: enumFromString(ExerciseCategory.values, row.category),
      muscleGroup: enumFromString(MuscleGroup.values, row.muscleGroup),
      equipmentType: enumFromString(EquipmentType.values, row.equipmentType),
      isCustom: row.isCustom,
      deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
    );
  }
}
