import 'package:drift/drift.dart';
import 'workouts_table.dart';
import 'exercises_table.dart';

@TableIndex(
    name: 'idx_workout_sets_exercise_timestamp',
    columns: {#exerciseId, #timestamp})
@TableIndex(
    name: 'idx_workout_sets_workout_order', columns: {#workoutId, #setOrder})
class WorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text().references(Workouts, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get setOrder => integer()();
  RealColumn get weight => real()();
  IntColumn get reps => integer()();
  RealColumn get rpe => real().nullable()();
  IntColumn get timestamp => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
