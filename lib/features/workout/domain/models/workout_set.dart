import 'package:uuid/uuid.dart';

class WorkoutSet {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int setOrder;
  final double weight;
  final int reps;
  final double? rpe;
  final DateTime timestamp;

  const WorkoutSet({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.setOrder,
    required this.weight,
    required this.reps,
    this.rpe,
    required this.timestamp,
  });

  double get volume => weight * reps;

  /// Epley formula: 1RM = weight × (1 + reps / 30)
  double get estimatedOneRepMax {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  WorkoutSet copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    int? setOrder,
    double? weight,
    int? reps,
    double? rpe,
    DateTime? timestamp,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      setOrder: setOrder ?? this.setOrder,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: rpe ?? this.rpe,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static WorkoutSet create({
    required String workoutId,
    required String exerciseId,
    required int setOrder,
    required double weight,
    required int reps,
    double? rpe,
  }) {
    return WorkoutSet(
      id: const Uuid().v4(),
      workoutId: workoutId,
      exerciseId: exerciseId,
      setOrder: setOrder,
      weight: weight,
      reps: reps,
      rpe: rpe,
      timestamp: DateTime.now().toUtc(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSet &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WorkoutSet(id: $id, exerciseId: $exerciseId, weight: $weight, reps: $reps)';
}
