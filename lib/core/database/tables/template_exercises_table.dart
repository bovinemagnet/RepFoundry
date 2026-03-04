import 'package:drift/drift.dart';
import 'workout_templates_table.dart';
import 'exercises_table.dart';

class TemplateExercises extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text().references(WorkoutTemplates, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  TextColumn get exerciseName => text().withLength(min: 1, max: 200)();
  IntColumn get targetSets => integer()();
  IntColumn get targetReps => integer()();
  IntColumn get orderIndex => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
