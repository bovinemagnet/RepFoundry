import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/data/drift_client_repository.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';

void main() {
  late db.AppDatabase database;
  late DriftClientRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftClientRepository(database);
  });
  tearDown(() => database.close());

  test('seeded Me client is returned and marked self', () async {
    final self = await repo.getSelfClient();
    expect(self.id, kSelfClientId);
    expect(self.isSelf, isTrue);
  });

  test('create then watch excludes soft-deleted', () async {
    final sarah = Client.create(name: 'Sarah', colour: 0xFF000000);
    await repo.createClient(sarah);
    expect((await repo.watchClients().first).map((c) => c.name),
        contains('Sarah'));

    await repo.softDeleteClient(sarah.id);
    expect((await repo.watchClients().first).map((c) => c.name),
        isNot(contains('Sarah')));
  });

  test('cannot soft-delete the self client', () async {
    expect(() => repo.softDeleteClient(kSelfClientId), throwsStateError);
  });
}
