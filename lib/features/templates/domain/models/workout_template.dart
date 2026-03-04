import 'package:uuid/uuid.dart';

class TemplateExercise {
  final String id;
  final String templateId;
  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final int orderIndex;

  const TemplateExercise({
    required this.id,
    required this.templateId,
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.orderIndex,
  });
}

class WorkoutTemplate {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TemplateExercise> exercises;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.exercises = const [],
  });

  static WorkoutTemplate create({
    required String name,
    List<TemplateExercise> exercises = const [],
  }) {
    final now = DateTime.now().toUtc();
    return WorkoutTemplate(
      id: const Uuid().v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
      exercises: exercises,
    );
  }

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TemplateExercise>? exercises,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exercises: exercises ?? this.exercises,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
