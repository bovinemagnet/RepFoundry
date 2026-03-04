import '../../workout/domain/models/workout_set.dart';
import '../../workout/domain/repositories/workout_repository.dart';

class ExerciseProgress {
  final String exerciseId;
  final List<WorkoutSet> sets;
  final double? maxEstimated1RM;
  final double? totalVolume;

  const ExerciseProgress({
    required this.exerciseId,
    required this.sets,
    this.maxEstimated1RM,
    this.totalVolume,
  });
}

class CalculateProgressUseCase {
  final WorkoutRepository _workoutRepository;

  const CalculateProgressUseCase({
    required WorkoutRepository workoutRepository,
  }) : _workoutRepository = workoutRepository;

  Future<ExerciseProgress> execute(String exerciseId) async {
    final sets = await _workoutRepository.getSetsForExercise(
      exerciseId,
      limit: 200,
    );

    if (sets.isEmpty) {
      return ExerciseProgress(exerciseId: exerciseId, sets: const []);
    }

    final maxE1RM = sets.fold<double>(
      0,
      (max, s) => s.estimatedOneRepMax > max ? s.estimatedOneRepMax : max,
    );

    final totalVolume = sets.fold<double>(0, (sum, s) => sum + s.volume);

    return ExerciseProgress(
      exerciseId: exerciseId,
      sets: sets,
      maxEstimated1RM: maxE1RM,
      totalVolume: totalVolume,
    );
  }
}
