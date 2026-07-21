import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/clients/domain/models/client_plan_assignment.dart';

void main() {
  test('create builds a template assignment with an id', () {
    final a = ClientPlanAssignment.create(
      clientId: 'c1',
      planType: PlanType.template,
      planId: 't1',
    );
    expect(a.id, isNotEmpty);
    expect(a.clientId, 'c1');
    expect(a.planType, PlanType.template);
    expect(a.planId, 't1');
    expect(a.startedAt, isNull);
  });
}
