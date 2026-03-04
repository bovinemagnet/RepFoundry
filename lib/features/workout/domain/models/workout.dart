import 'package:uuid/uuid.dart';

enum WorkoutStatus { inProgress, completed }

class Workout {
  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? templateId;
  final String? notes;
  final DateTime? deletedAt;

  const Workout({
    required this.id,
    required this.startedAt,
    this.completedAt,
    this.templateId,
    this.notes,
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
    DateTime? deletedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      templateId: templateId ?? this.templateId,
      notes: notes ?? this.notes,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static Workout create({String? templateId, String? notes}) {
    return Workout(
      id: const Uuid().v4(),
      startedAt: DateTime.now().toUtc(),
      templateId: templateId,
      notes: notes,
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
