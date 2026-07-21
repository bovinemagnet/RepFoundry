import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../domain/models/client.dart';
import '../domain/repositories/client_repository.dart';

class DriftClientRepository implements ClientRepository {
  DriftClientRepository(this._db);

  final db.AppDatabase _db;

  @override
  Stream<List<Client>> watchClients() {
    final q = _db.select(_db.clients)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Client?> getClient(String id) async {
    final row = await (_db.select(_db.clients)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Client> getSelfClient() async {
    final row = await (_db.select(_db.clients)
          ..where((t) => t.id.equals(kSelfClientId)))
        .getSingle();
    return _toDomain(row);
  }

  @override
  Future<Client> createClient(Client client) async {
    await _db.into(_db.clients).insert(_toCompanion(client));
    return client;
  }

  @override
  Future<Client> updateClient(Client client) async {
    await (_db.update(_db.clients)..where((t) => t.id.equals(client.id)))
        .write(_toCompanion(client));
    return client;
  }

  @override
  Future<void> softDeleteClient(String id) async {
    if (id == kSelfClientId) {
      throw StateError('The self client cannot be deleted.');
    }
    await (_db.update(_db.clients)..where((t) => t.id.equals(id))).write(
      db.ClientsCompanion(
        deletedAt: Value(dateTimeToEpochMs(DateTime.now().toUtc())),
        updatedAt: Value(dateTimeToEpochMs(DateTime.now().toUtc())),
      ),
    );
  }

  Client _toDomain(db.Client row) => Client(
        id: row.id,
        name: row.name,
        colour: row.colour,
        notes: row.notes,
        isSelf: row.isSelf,
        createdAt: dateTimeFromEpochMs(row.createdAt),
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
        deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
      );

  db.ClientsCompanion _toCompanion(Client c) => db.ClientsCompanion.insert(
        id: c.id,
        name: c.name,
        colour: c.colour,
        notes: Value(c.notes),
        isSelf: Value(c.isSelf),
        createdAt: dateTimeToEpochMs(c.createdAt),
        updatedAt: Value(dateTimeToEpochMs(c.updatedAt)),
        deletedAt: Value(nullableDateTimeToEpochMs(c.deletedAt)),
      );
}
