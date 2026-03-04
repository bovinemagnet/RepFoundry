import 'package:drift/drift.dart';
import 'exercises_table.dart';
import 'workout_sets_table.dart';

class PersonalRecords extends Table {
  TextColumn get id => text()();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  TextColumn get recordType => text()();
  RealColumn get value => real()();
  IntColumn get achievedAt => integer()();
  TextColumn get workoutSetId =>
      text().nullable().references(WorkoutSets, #id)();

  @override
  Set<Column> get primaryKey => {id};
}
