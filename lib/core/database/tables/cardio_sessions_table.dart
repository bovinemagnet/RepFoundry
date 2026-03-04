import 'package:drift/drift.dart';
import 'workouts_table.dart';
import 'exercises_table.dart';

class CardioSessions extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text().references(Workouts, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get durationSeconds => integer()();
  RealColumn get distanceMeters => real().nullable()();
  RealColumn get incline => real().nullable()();
  IntColumn get avgHeartRate => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
