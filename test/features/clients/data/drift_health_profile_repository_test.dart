import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/data/drift_health_profile_repository.dart';

void main() {
  late db.AppDatabase database;
  late DriftHealthProfileRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftHealthProfileRepository(database);
  });
  tearDown(() => database.close());

  test('missing profile returns a default HealthProfile', () async {
    final p = await repo.getForClient('nobody');
    expect(p.age, isNull);
  });

  test('save then read round-trips per client', () async {
    // health_profiles.client_id is a foreign key into clients, so the
    // referenced rows must exist first.
    await database.into(database.clients).insert(
          db.ClientsCompanion.insert(
            id: 'c1',
            name: 'Client One',
            colour: 0xFF000000,
            createdAt: 0,
          ),
        );
    await database.into(database.clients).insert(
          db.ClientsCompanion.insert(
            id: 'c2',
            name: 'Client Two',
            colour: 0xFF000000,
            createdAt: 0,
          ),
        );

    await repo.saveForClient('c1', const HealthProfile(age: 40, restingHr: 55));
    await repo.saveForClient('c2', const HealthProfile(age: 25));
    expect((await repo.getForClient('c1')).age, 40);
    expect((await repo.getForClient('c1')).restingHr, 55);
    expect((await repo.getForClient('c2')).age, 25);
  });
}
