import 'package:drift/drift.dart';

class BodyMetrics extends Table {
  TextColumn get id => text()();
  IntColumn get date => integer()();
  RealColumn get weight => real()();
  RealColumn get bodyFatPercent => real().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
