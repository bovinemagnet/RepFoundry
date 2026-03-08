import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';

/// Holds the current and longest workout streaks.
class StreakData {
  final int currentStreak;
  final int longestStreak;

  const StreakData({required this.currentStreak, required this.longestStreak});
}

/// Calculates the current streak (consecutive days with workouts ending today
/// or yesterday) and the longest streak ever recorded.
final streakProvider = FutureProvider.autoDispose<StreakData>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(limit: 500);

  if (workouts.isEmpty) {
    return const StreakData(currentStreak: 0, longestStreak: 0);
  }

  // Collect unique workout days (local time, normalised to midnight).
  final uniqueDays = <DateTime>{};
  for (final w in workouts) {
    final local = w.startedAt.toLocal();
    uniqueDays.add(DateTime(local.year, local.month, local.day));
  }

  final sortedDays = uniqueDays.toList()..sort((a, b) => b.compareTo(a));

  // Current streak: start from today (or yesterday) and count backwards.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  int currentStreak = 0;
  DateTime? checkDate;

  if (sortedDays.contains(today)) {
    checkDate = today;
  } else if (sortedDays.contains(yesterday)) {
    checkDate = yesterday;
  }

  if (checkDate != null) {
    while (sortedDays.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate!.subtract(const Duration(days: 1));
    }
  }

  // Longest streak: scan all sorted days.
  int longestStreak = 0;
  int runningStreak = 1;

  for (int i = 1; i < sortedDays.length; i++) {
    final diff = sortedDays[i - 1].difference(sortedDays[i]).inDays;
    if (diff == 1) {
      runningStreak++;
    } else {
      if (runningStreak > longestStreak) longestStreak = runningStreak;
      runningStreak = 1;
    }
  }
  if (runningStreak > longestStreak) longestStreak = runningStreak;

  return StreakData(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
  );
});
