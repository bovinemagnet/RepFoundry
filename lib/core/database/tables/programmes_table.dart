import 'package:drift/drift.dart';

class Programmes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get durationWeeks => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
