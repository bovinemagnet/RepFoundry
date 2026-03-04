import 'package:drift/drift.dart';

class Workouts extends Table {
  TextColumn get id => text()();
  IntColumn get startedAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  TextColumn get templateId => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
