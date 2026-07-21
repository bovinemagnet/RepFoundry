import 'package:drift/drift.dart';
import 'exercises_table.dart';
import 'workout_sets_table.dart';
import 'clients_table.dart';

@TableIndex(
    name: 'idx_personal_records_exercise_achieved',
    columns: {#exerciseId, #achievedAt})
class PersonalRecords extends Table {
  TextColumn get id => text()();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  TextColumn get recordType => text()();
  RealColumn get value => real()();
  IntColumn get achievedAt => integer()();
  TextColumn get workoutSetId =>
      text().nullable().references(WorkoutSets, #id)();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get clientId => text()
      .references(Clients, #id)
      .withDefault(const Constant(kSelfClientIdConst))();

  @override
  Set<Column> get primaryKey => {id};
}
