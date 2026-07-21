import 'package:uuid/uuid.dart';

import '../../../clients/domain/models/client.dart';

enum WorkoutStatus { inProgress, completed }

class Workout {
  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? templateId;
  final String? notes;
  final String clientId;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Workout({
    required this.id,
    required this.startedAt,
    this.completedAt,
    this.templateId,
    this.notes,
    required this.clientId,
    required this.updatedAt,
    this.deletedAt,
  });

  WorkoutStatus get status =>
      completedAt != null ? WorkoutStatus.completed : WorkoutStatus.inProgress;

  bool get isDeleted => deletedAt != null;

  Duration get elapsed {
    final end = completedAt ?? DateTime.now().toUtc();
    return end.difference(startedAt);
  }

  Workout copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? completedAt,
    String? templateId,
    String? notes,
    String? clientId,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      templateId: templateId ?? this.templateId,
      notes: notes ?? this.notes,
      clientId: clientId ?? this.clientId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static Workout create({
    String? templateId,
    String? notes,
    String clientId = kSelfClientId,
  }) {
    final now = DateTime.now().toUtc();
    return Workout(
      id: const Uuid().v4(),
      startedAt: now,
      templateId: templateId,
      notes: notes,
      clientId: clientId,
      updatedAt: now,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workout && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Workout(id: $id, startedAt: $startedAt, status: $status)';
}
