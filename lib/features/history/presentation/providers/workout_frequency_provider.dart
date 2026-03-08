import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';

/// A single week's workout count for the frequency chart.
class WeeklyFrequency {
  final DateTime weekStart;
  final int count;

  const WeeklyFrequency({required this.weekStart, required this.count});
}

/// Provides workout counts grouped by week for the last 12 weeks.
final workoutFrequencyProvider =
    FutureProvider.autoDispose<List<WeeklyFrequency>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(limit: 200);

  final now = DateTime.now();
  // Start of the current week (Monday).
  final currentWeekStart =
      DateTime(now.year, now.month, now.day - (now.weekday - 1));

  final weeks = <WeeklyFrequency>[];
  for (var i = 11; i >= 0; i--) {
    final weekStart = currentWeekStart.subtract(Duration(days: 7 * i));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final count = workouts.where((w) {
      final date = w.startedAt.toLocal();
      return !date.isBefore(weekStart) && date.isBefore(weekEnd);
    }).length;

    weeks.add(WeeklyFrequency(weekStart: weekStart, count: count));
  }

  return weeks;
});
