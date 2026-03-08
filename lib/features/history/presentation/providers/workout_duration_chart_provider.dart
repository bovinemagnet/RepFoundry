import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/progress_chart_widget.dart';

/// Provides per-workout duration (in minutes) as [ProgressDataPoint] for the
/// last 20 completed workouts.
final workoutDurationChartProvider =
    FutureProvider.autoDispose<List<ProgressDataPoint>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(limit: 20);

  final points = <ProgressDataPoint>[];
  for (final w in workouts) {
    if (w.completedAt == null) continue;
    final durationMinutes =
        w.completedAt!.difference(w.startedAt).inMinutes.toDouble();
    if (durationMinutes > 0) {
      points.add(ProgressDataPoint(date: w.startedAt, value: durationMinutes));
    }
  }

  // getWorkoutHistory returns newest first — reverse for chronological order.
  return points.reversed.toList();
});
