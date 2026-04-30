import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../domain/models/workout_template.dart';
import '../domain/repositories/workout_template_repository.dart';

class DriftWorkoutTemplateRepository implements WorkoutTemplateRepository {
  final db.AppDatabase _db;

  DriftWorkoutTemplateRepository(this._db);

  @override
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    await _db.transaction(() async {
      await _db.into(_db.workoutTemplates).insert(
            db.WorkoutTemplatesCompanion.insert(
              id: template.id,
              name: template.name,
              createdAt: dateTimeToEpochMs(template.createdAt),
              updatedAt: dateTimeToEpochMs(template.updatedAt),
            ),
          );
      for (final ex in template.exercises) {
        await _db.into(_db.templateExercises).insert(
              db.TemplateExercisesCompanion.insert(
                id: ex.id,
                templateId: template.id,
                exerciseId: ex.exerciseId,
                exerciseName: ex.exerciseName,
                targetSets: ex.targetSets,
                targetReps: ex.targetReps,
                orderIndex: ex.orderIndex,
                updatedAt: Value(dateTimeToEpochMs(ex.updatedAt)),
              ),
            );
      }
    });
    return template;
  }

  @override
  Future<WorkoutTemplate?> getTemplate(String id) async {
    final q = _db.select(_db.workoutTemplates)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    final row = await q.getSingleOrNull();
    if (row == null) return null;

    final exercises = await _getExercisesForTemplate(id);
    return _toDomain(row, exercises);
  }

  @override
  Future<List<WorkoutTemplate>> getAllTemplates() async {
    final q = _db.select(_db.workoutTemplates)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await q.get();
    return Future.wait(rows.map((row) async {
      final exercises = await _getExercisesForTemplate(row.id);
      return _toDomain(row, exercises);
    }));
  }

  @override
  Future<WorkoutTemplate> updateTemplate(WorkoutTemplate template) async {
    final nowMs = dateTimeToEpochMs(DateTime.now().toUtc());
    await _db.transaction(() async {
      await (_db.update(_db.workoutTemplates)
            ..where((t) => t.id.equals(template.id)))
          .write(
        db.WorkoutTemplatesCompanion(
          name: Value(template.name),
          updatedAt: Value(dateTimeToEpochMs(template.updatedAt)),
        ),
      );
      // Soft-delete previous children (preserves tombstones for sync) and
      // insert the new set. New rows with the same id will upsert via
      // primary-key conflict; new ids appear as new rows.
      await (_db.update(_db.templateExercises)
            ..where(
              (t) => t.templateId.equals(template.id) & t.deletedAt.isNull(),
            ))
          .write(
        db.TemplateExercisesCompanion(
          deletedAt: Value(nowMs),
          updatedAt: Value(nowMs),
        ),
      );
      for (final ex in template.exercises) {
        await _db.into(_db.templateExercises).insertOnConflictUpdate(
              db.TemplateExercisesCompanion.insert(
                id: ex.id,
                templateId: template.id,
                exerciseId: ex.exerciseId,
                exerciseName: ex.exerciseName,
                targetSets: ex.targetSets,
                targetReps: ex.targetReps,
                orderIndex: ex.orderIndex,
                updatedAt: Value(dateTimeToEpochMs(ex.updatedAt)),
                // Resurrect: explicit null clears any prior tombstone.
                deletedAt: const Value(null),
              ),
            );
      }
    });
    return template;
  }

  @override
  Future<void> deleteTemplate(String id) async {
    final nowMs = dateTimeToEpochMs(DateTime.now().toUtc());
    await _db.transaction(() async {
      await (_db.update(_db.templateExercises)
            ..where((t) => t.templateId.equals(id) & t.deletedAt.isNull()))
          .write(
        db.TemplateExercisesCompanion(
          deletedAt: Value(nowMs),
          updatedAt: Value(nowMs),
        ),
      );
      await (_db.update(_db.workoutTemplates)..where((t) => t.id.equals(id)))
          .write(
        db.WorkoutTemplatesCompanion(
          deletedAt: Value(nowMs),
          updatedAt: Value(nowMs),
        ),
      );
    });
  }

  @override
  Stream<List<WorkoutTemplate>> watchAllTemplates() {
    final q = _db.select(_db.workoutTemplates)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch().asyncMap((rows) async {
      return Future.wait(rows.map((row) async {
        final exercises = await _getExercisesForTemplate(row.id);
        return _toDomain(row, exercises);
      }));
    });
  }

  Future<List<TemplateExercise>> _getExercisesForTemplate(
    String templateId,
  ) async {
    final q = _db.select(_db.templateExercises)
      ..where((t) => t.templateId.equals(templateId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]);
    final rows = await q.get();
    return rows.map(_exerciseToDomain).toList();
  }

  WorkoutTemplate _toDomain(
    db.WorkoutTemplate row,
    List<TemplateExercise> exercises,
  ) {
    return WorkoutTemplate(
      id: row.id,
      name: row.name,
      createdAt: dateTimeFromEpochMs(row.createdAt),
      updatedAt: dateTimeFromEpochMs(row.updatedAt),
      deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
      exercises: exercises,
    );
  }

  TemplateExercise _exerciseToDomain(db.TemplateExercise row) {
    return TemplateExercise(
      id: row.id,
      templateId: row.templateId,
      exerciseId: row.exerciseId,
      exerciseName: row.exerciseName,
      targetSets: row.targetSets,
      targetReps: row.targetReps,
      orderIndex: row.orderIndex,
      updatedAt: dateTimeFromEpochMs(row.updatedAt),
      deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
    );
  }
}
