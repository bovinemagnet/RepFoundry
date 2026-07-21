import 'package:drift/drift.dart';

import 'clients_table.dart';

@TableIndex(
  name: 'idx_client_plan_assignments_unique',
  columns: {#clientId, #planType, #planId},
  unique: true,
)
class ClientPlanAssignments extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text().references(Clients, #id)();
  TextColumn get planType => text()();
  TextColumn get planId => text()();
  IntColumn get startedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
