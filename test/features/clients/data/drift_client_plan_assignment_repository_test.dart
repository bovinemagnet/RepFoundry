import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/data/drift_client_plan_assignment_repository.dart';
import 'package:rep_foundry/features/clients/domain/models/client_plan_assignment.dart';

void main() {
  late db.AppDatabase database;
  late DriftClientPlanAssignmentRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftClientPlanAssignmentRepository(database);
  });
  tearDown(() => database.close());

  Future<void> createClient(String clientId) async {
    await database.into(database.clients).insert(
          db.ClientsCompanion.insert(
            id: clientId,
            name: 'Test Client $clientId',
            colour: 0xFF000000,
            createdAt: 0,
          ),
        );
  }

  test('assign then watch by client', () async {
    await createClient('c1');
    await repo.assign('c1', PlanType.template, 't1');
    final list = await repo.watchAssignments('c1').first;
    expect(list, hasLength(1));
    expect(list.single.planId, 't1');
  });

  test('assign is idempotent', () async {
    await createClient('c1');
    await repo.assign('c1', PlanType.programme, 'p1');
    await repo.assign('c1', PlanType.programme, 'p1');
    expect(await repo.watchAssignments('c1').first, hasLength(1));
  });

  test('watchClientsForPlan is the reverse lookup', () async {
    await createClient('c1');
    await createClient('c2');
    await repo.assign('c1', PlanType.template, 't1');
    await repo.assign('c2', PlanType.template, 't1');
    expect(await repo.watchClientsForPlan(PlanType.template, 't1'),
        containsAll(['c1', 'c2']));
  });
}
