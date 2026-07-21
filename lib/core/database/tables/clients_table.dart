import 'package:drift/drift.dart';

/// Fixed id of the always-present "Me" client, matching
/// `kSelfClientId` in `lib/features/clients/domain/models/client.dart`.
/// Duplicated here as a top-level const because the Drift table DSL
/// requires a compile-time constant local to this file.
const String kSelfClientIdConst = '00000000-0000-4000-8000-000000000001';

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colour => integer()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSelf => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
