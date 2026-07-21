import 'package:drift/drift.dart';

import 'clients_table.dart';

class HealthProfiles extends Table {
  TextColumn get clientId => text().references(Clients, #id)();
  IntColumn get age => integer().nullable()();
  IntColumn get restingHr => integer().nullable()();
  IntColumn get measuredMaxHr => integer().nullable()();
  IntColumn get clinicianMaxHr => integer().nullable()();
  BoolColumn get betaBlocker => boolean().withDefault(const Constant(false))();
  BoolColumn get heartCondition =>
      boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {clientId};
}
