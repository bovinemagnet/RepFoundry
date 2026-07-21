import '../models/client_plan_assignment.dart';

abstract class ClientPlanAssignmentRepository {
  Stream<List<ClientPlanAssignment>> watchAssignments(String clientId);
  Future<void> assign(String clientId, PlanType planType, String planId);
  Future<void> unassign(String assignmentId);
  Future<List<String>> watchClientsForPlan(PlanType planType, String planId);
}
