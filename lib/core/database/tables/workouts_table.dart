import 'package:drift/drift.dart';

import 'clients_table.dart';

class Workouts extends Table {
  TextColumn get id => text()();
  IntColumn get startedAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  TextColumn get templateId => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get clientId => text()
      .references(Clients, #id)
      .withDefault(const Constant(kSelfClientIdConst))();

  @override
  Set<Column> get primaryKey => {id};
}
