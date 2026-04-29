import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../exercises/domain/models/exercise.dart';

class MuscleBalance {
  final MuscleGroup group;
  final double volumePercent;

  const MuscleBalance({required this.group, required this.volumePercent});
}

final muscleBalanceProvider =
    FutureProvider.autoDispose<List<MuscleBalance>>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);

  final exercises = await exerciseRepo.getAllExercises();
  final exerciseMap = {for (final e in exercises) e.id: e};

  final workouts = await workoutRepo.getWorkoutHistory(limit: 100);
  final volumeByGroup = <MuscleGroup, double>{};

  for (final w in workouts) {
    if (w.completedAt == null) continue;
    final sets = await workoutRepo.getSetsForWorkout(w.id);
    for (final s in sets) {
      if (s.isWarmUp) continue;
      final exercise = exerciseMap[s.exerciseId];
      if (exercise == null) continue;
      volumeByGroup[exercise.muscleGroup] =
          (volumeByGroup[exercise.muscleGroup] ?? 0) + s.volume;
    }
  }

  final total = volumeByGroup.values.fold(0.0, (a, b) => a + b);
  if (total == 0) return [];

  return volumeByGroup.entries
      .where((e) => e.key != MuscleGroup.cardio)
      .map((e) =>
          MuscleBalance(group: e.key, volumePercent: (e.value / total) * 100))
      .toList()
    ..sort((a, b) => a.group.index.compareTo(b.group.index));
});
