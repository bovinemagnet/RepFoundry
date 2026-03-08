import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../../core/providers.dart';

class MuscleGroupVolume {
  final MuscleGroup group;
  final double volume;

  const MuscleGroupVolume({required this.group, required this.volume});
}

final muscleGroupDistributionProvider =
    FutureProvider.autoDispose<List<MuscleGroupVolume>>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);

  final workouts = await workoutRepo.getWorkoutHistory(limit: 100);
  if (workouts.isEmpty) return [];

  final exercises = await exerciseRepo.getAllExercises();
  final exerciseMap = {for (final e in exercises) e.id: e.muscleGroup};

  final volumeByGroup = <MuscleGroup, double>{};

  for (final workout in workouts) {
    final sets = await workoutRepo.getSetsForWorkout(workout.id);
    for (final set in sets) {
      final group = exerciseMap[set.exerciseId];
      if (group != null) {
        volumeByGroup[group] = (volumeByGroup[group] ?? 0) + set.volume;
      }
    }
  }

  final result = volumeByGroup.entries
      .map((e) => MuscleGroupVolume(group: e.key, volume: e.value))
      .toList()
    ..sort((a, b) => b.volume.compareTo(a.volume));

  return result;
});
