import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../domain/models/client_plan_assignment.dart';
import '../domain/repositories/client_plan_assignment_repository.dart';

class DriftClientPlanAssignmentRepository
    implements ClientPlanAssignmentRepository {
  DriftClientPlanAssignmentRepository(this._db);

  final db.AppDatabase _db;

  @override
  Stream<List<ClientPlanAssignment>> watchAssignments(String clientId) {
    final q = _db.select(_db.clientPlanAssignments)
      ..where((t) => t.clientId.equals(clientId));
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> assign(String clientId, PlanType planType, String planId) async {
    final assignment = ClientPlanAssignment.create(
      clientId: clientId,
      planType: planType,
      planId: planId,
    );
    await _db.into(_db.clientPlanAssignments).insert(
          db.ClientPlanAssignmentsCompanion.insert(
            id: assignment.id,
            clientId: assignment.clientId,
            planType: assignment.planType.name,
            planId: assignment.planId,
            startedAt: Value(nullableDateTimeToEpochMs(assignment.startedAt)),
            createdAt: dateTimeToEpochMs(assignment.createdAt),
            updatedAt: Value(dateTimeToEpochMs(assignment.updatedAt)),
          ),
          mode: InsertMode.insertOrIgnore, // idempotent on the unique index
        );
  }

  @override
  Future<void> unassign(String assignmentId) async {
    await (_db.delete(_db.clientPlanAssignments)
          ..where((t) => t.id.equals(assignmentId)))
        .go();
  }

  @override
  Future<List<String>> watchClientsForPlan(
    PlanType planType,
    String planId,
  ) async {
    final q = _db.select(_db.clientPlanAssignments)
      ..where(
          (t) => t.planType.equals(planType.name) & t.planId.equals(planId));
    final rows = await q.get();
    return rows.map((r) => r.clientId).toList();
  }

  ClientPlanAssignment _toDomain(db.ClientPlanAssignment row) =>
      ClientPlanAssignment(
        id: row.id,
        clientId: row.clientId,
        planType: enumFromString(PlanType.values, row.planType),
        planId: row.planId,
        startedAt: nullableDateTimeFromEpochMs(row.startedAt),
        createdAt: dateTimeFromEpochMs(row.createdAt),
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
      );
}
