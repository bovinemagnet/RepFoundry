import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';

/// Provides total volume per workout for the last 20 workouts (oldest → newest).
final volumeSparklineProvider =
    FutureProvider.autoDispose<List<double>>((ref) async {
  final clientId = (await ref.watch(activeClientProvider.future)).id;
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(
    clientId: clientId,
    limit: 20,
  );
  if (workouts.isEmpty) return const [];

  final setsByWorkout =
      await repo.getSetsForWorkouts([for (final w in workouts) w.id]);
  final volumes = <double>[
    for (final w in workouts)
      (setsByWorkout[w.id] ?? const [])
          .fold<double>(0, (sum, s) => sum + s.volume),
  ];

  // getWorkoutHistory returns newest first — reverse for chronological order.
  return volumes.reversed.toList();
});
