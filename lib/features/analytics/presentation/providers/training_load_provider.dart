import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';
import '../../application/training_aggregates.dart';

export '../../application/training_aggregates.dart'
    show WeeklyLoad, computeTrainingLoad;

final trainingLoadProvider =
    FutureProvider.autoDispose<List<WeeklyLoad>>((ref) async {
  final clientId = (await ref.watch(activeClientProvider.future)).id;
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(
    clientId: clientId,
    limit: 200,
  );
  final completedIds = [
    for (final w in workouts)
      if (w.completedAt != null) w.id,
  ];
  final setsByWorkout = await repo.getSetsForWorkouts(completedIds);
  final allSets = <SetData>[
    for (final sets in setsByWorkout.values)
      for (final s in sets)
        if (!s.isWarmUp)
          SetData(date: s.timestamp, volume: s.volume, rpe: s.rpe),
  ];

  return computeTrainingLoad(allSets);
});
