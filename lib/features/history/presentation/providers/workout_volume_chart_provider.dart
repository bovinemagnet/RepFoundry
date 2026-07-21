import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';
import '../../../../core/widgets/progress_chart_widget.dart';

/// Provides per-workout volume as [ProgressDataPoint] for the last 20 workouts.
final workoutVolumeChartProvider =
    FutureProvider.autoDispose<List<ProgressDataPoint>>((ref) async {
  final clientId = (await ref.watch(activeClientProvider.future)).id;
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(
    clientId: clientId,
    limit: 20,
  );
  if (workouts.isEmpty) return const [];

  final points = <ProgressDataPoint>[];
  for (final w in workouts) {
    final sets = await repo.getSetsForWorkout(w.id);
    final volume = sets.fold<double>(0, (sum, s) => sum + s.volume);
    points.add(ProgressDataPoint(date: w.startedAt, value: volume));
  }

  // getWorkoutHistory returns newest first — reverse for chronological order.
  return points.reversed.toList();
});
