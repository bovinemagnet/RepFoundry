import 'package:drift/drift.dart';

class ProgrammeDays extends Table {
  TextColumn get id => text()();
  TextColumn get programmeId => text()();
  IntColumn get weekNumber => integer()();
  IntColumn get dayOfWeek => integer()();
  TextColumn get templateId => text()();
  TextColumn get templateName => text()();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
