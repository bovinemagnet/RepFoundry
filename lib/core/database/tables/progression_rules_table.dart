import 'package:drift/drift.dart';

class ProgressionRules extends Table {
  TextColumn get id => text()();
  TextColumn get programmeId => text()();
  TextColumn get exerciseId => text()();
  TextColumn get type => text()();
  RealColumn get value => real()();
  IntColumn get frequencyWeeks => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
