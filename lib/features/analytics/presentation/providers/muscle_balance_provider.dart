import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';
import '../../application/training_aggregates.dart';

export '../../application/training_aggregates.dart' show MuscleBalance;

final muscleBalanceProvider =
    FutureProvider.autoDispose<List<MuscleBalance>>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);

  final exercises = await exerciseRepo.getAllExercises();
  final exerciseMap = {for (final e in exercises) e.id: e};

  final clientId = (await ref.watch(activeClientProvider.future)).id;
  final workouts = await workoutRepo.getWorkoutHistory(
    clientId: clientId,
    limit: 100,
  );

  final completedIds = [
    for (final w in workouts)
      if (w.completedAt != null) w.id,
  ];
  final setsByWorkout = await workoutRepo.getSetsForWorkouts(completedIds);
  return computeMuscleBalance(
    setsByWorkout.values.expand((sets) => sets),
    exerciseMap,
  );
});
