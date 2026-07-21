import 'package:uuid/uuid.dart';

/// Which library entity an assignment points at.
enum PlanType { template, programme }

/// A live-reference link from a client to a shared library template or
/// programme. Editing the library plan changes it for every assigned client.
class ClientPlanAssignment {
  const ClientPlanAssignment({
    required this.id,
    required this.clientId,
    required this.planType,
    required this.planId,
    required this.startedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clientId;
  final PlanType planType;
  final String planId;

  /// Anchors this client's programme week for a shared programme; null for
  /// templates or an unstarted programme.
  final DateTime? startedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ClientPlanAssignment.create({
    required String clientId,
    required PlanType planType,
    required String planId,
    DateTime? startedAt,
  }) {
    final now = DateTime.now().toUtc();
    return ClientPlanAssignment(
      id: const Uuid().v4(),
      clientId: clientId,
      planType: planType,
      planId: planId,
      startedAt: startedAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClientPlanAssignment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
