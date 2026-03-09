import 'package:uuid/uuid.dart';

enum WorkoutStatus { inProgress, completed }

class Workout {
  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? templateId;
  final String? notes;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Workout({
    required this.id,
    required this.startedAt,
    this.completedAt,
    this.templateId,
    this.notes,
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
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      templateId: templateId ?? this.templateId,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static Workout create({String? templateId, String? notes}) {
    final now = DateTime.now().toUtc();
    return Workout(
      id: const Uuid().v4(),
      startedAt: now,
      templateId: templateId,
      notes: notes,
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
