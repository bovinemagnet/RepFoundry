import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';

class SetData {
  final DateTime date;
  final double volume;
  final double? rpe;

  const SetData({required this.date, required this.volume, this.rpe});
}

class WeeklyVolume {
  final DateTime weekStart;
  final double totalVolume;
  final double? percentChange;

  const WeeklyVolume(
      {required this.weekStart, required this.totalVolume, this.percentChange});
}

List<WeeklyVolume> computeWeeklyVolume(List<SetData> sets) {
  final byWeek = <DateTime, double>{};
  for (final s in sets) {
    final weekStart = s.date.subtract(Duration(days: s.date.weekday - 1));
    final key = DateTime(weekStart.year, weekStart.month, weekStart.day);
    byWeek[key] = (byWeek[key] ?? 0) + s.volume;
  }

  final sorted = byWeek.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  final result = <WeeklyVolume>[];
  for (var i = 0; i < sorted.length; i++) {
    final prev = i > 0 ? sorted[i - 1].value : null;
    final change = prev != null && prev > 0
        ? ((sorted[i].value - prev) / prev) * 100
        : null;
    result.add(WeeklyVolume(
        weekStart: sorted[i].key,
        totalVolume: sorted[i].value,
        percentChange: change));
  }
  return result;
}

final weeklyVolumeProvider =
    FutureProvider.autoDispose<List<WeeklyVolume>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(limit: 200);
  final allSets = <SetData>[];

  for (final w in workouts) {
    if (w.completedAt == null) continue;
    final sets = await repo.getSetsForWorkout(w.id);
    for (final s in sets) {
      if (!s.isWarmUp) {
        allSets.add(SetData(date: s.timestamp, volume: s.volume, rpe: s.rpe));
      }
    }
  }

  return computeWeeklyVolume(allSets);
});
