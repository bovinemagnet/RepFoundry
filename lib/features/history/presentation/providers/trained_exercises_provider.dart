import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../../core/providers.dart';

class TrainedExercise {
  final Exercise exercise;
  final int setCount;

  const TrainedExercise({required this.exercise, required this.setCount});
}

final trainedExercisesProvider =
    FutureProvider.autoDispose<List<TrainedExercise>>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);

  final workouts = await workoutRepo.getWorkoutHistory(limit: 100);
  if (workouts.isEmpty) return [];

  final setCountByExercise = <String, int>{};

  for (final workout in workouts) {
    final sets = await workoutRepo.getSetsForWorkout(workout.id);
    for (final set in sets) {
      setCountByExercise[set.exerciseId] =
          (setCountByExercise[set.exerciseId] ?? 0) + 1;
    }
  }

  final exercises = await exerciseRepo.getAllExercises();
  final exerciseMap = {for (final e in exercises) e.id: e};

  final result = <TrainedExercise>[];
  for (final entry in setCountByExercise.entries) {
    final exercise = exerciseMap[entry.key];
    if (exercise != null) {
      result.add(TrainedExercise(exercise: exercise, setCount: entry.value));
    }
  }

  result.sort((a, b) => b.setCount.compareTo(a.setCount));
  return result;
});
