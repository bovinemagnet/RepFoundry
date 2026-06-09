import 'package:drift/drift.dart';
import 'workouts_table.dart';
import 'exercises_table.dart';

@TableIndex(name: 'idx_cardio_sessions_workout', columns: {#workoutId})
@TableIndex(name: 'idx_cardio_sessions_exercise', columns: {#exerciseId})
class CardioSessions extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text().references(Workouts, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get durationSeconds => integer()();
  RealColumn get distanceMeters => real().nullable()();
  RealColumn get incline => real().nullable()();
  IntColumn get avgHeartRate => integer().nullable()();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
