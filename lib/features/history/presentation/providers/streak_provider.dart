import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';

/// Holds the current and longest workout streaks.
class StreakData {
  final int currentStreak;
  final int longestStreak;

  const StreakData({required this.currentStreak, required this.longestStreak});
}

/// Calculates the current streak (consecutive days with workouts ending today
/// or yesterday) and the longest streak ever recorded.
final streakProvider = FutureProvider.autoDispose<StreakData>((ref) async {
  final clientId = (await ref.watch(activeClientProvider.future)).id;
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(
    clientId: clientId,
    limit: 500,
  );

  if (workouts.isEmpty) {
    return const StreakData(currentStreak: 0, longestStreak: 0);
  }

  // Collect unique local calendar days. Each is held as a UTC DateTime
  // built from the local year/month/day, so days are always exactly 24h
  // apart: a local midnight converted with toUtc() is 23 or 25 hours from
  // its neighbour across a DST change and breaks the streak.
  final uniqueDays = <DateTime>{};
  for (final w in workouts) {
    uniqueDays.add(_calendarDay(w.startedAt.toLocal()));
  }

  final sortedDays = uniqueDays.toList()..sort((a, b) => b.compareTo(a));

  // Current streak: start from today (or yesterday) and count backwards.
  final today = _calendarDay(DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));

  int currentStreak = 0;
  DateTime? checkDate;

  if (sortedDays.contains(today)) {
    checkDate = today;
  } else if (sortedDays.contains(yesterday)) {
    checkDate = yesterday;
  }

  if (checkDate != null) {
    var current = checkDate;
    while (sortedDays.contains(current)) {
      currentStreak++;
      current = current.subtract(const Duration(days: 1));
    }
  }

  // Longest streak: scan all sorted days.
  int longestStreak = 0;
  int runningStreak = 1;

  for (int i = 1; i < sortedDays.length; i++) {
    final dayDiff = sortedDays[i - 1].difference(sortedDays[i]).inDays;
    if (dayDiff == 1) {
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

/// The local calendar day of [local] as a UTC midnight, so day arithmetic
/// is immune to the local zone's DST transitions.
DateTime _calendarDay(DateTime local) =>
    DateTime.utc(local.year, local.month, local.day);
