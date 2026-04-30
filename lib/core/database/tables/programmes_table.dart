import 'package:drift/drift.dart';

class Programmes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get durationWeeks => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  /// Epoch ms when the user activated the programme. Null = not yet started.
  /// Used to compute the current week for [Programme.currentWeek].
  IntColumn get startedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
