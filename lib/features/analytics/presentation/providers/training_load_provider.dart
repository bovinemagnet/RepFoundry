import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import 'weekly_volume_provider.dart';

class WeeklyLoad {
  final DateTime weekStart;
  final int setCount;
  final double avgRpe;
  final double load;

  const WeeklyLoad(
      {required this.weekStart,
      required this.setCount,
      required this.avgRpe,
      required this.load});
}

List<WeeklyLoad> computeTrainingLoad(List<SetData> sets) {
  final byWeek = <DateTime, List<SetData>>{};
  for (final s in sets) {
    final weekStart = s.date.subtract(Duration(days: s.date.weekday - 1));
    final key = DateTime(weekStart.year, weekStart.month, weekStart.day);
    byWeek.putIfAbsent(key, () => []).add(s);
  }

  final sorted = byWeek.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return sorted.map((entry) {
    final setsWithRpe = entry.value.where((s) => s.rpe != null).toList();
    final avgRpe = setsWithRpe.isEmpty
        ? 0.0
        : setsWithRpe.fold(0.0, (sum, s) => sum + s.rpe!) / setsWithRpe.length;
    return WeeklyLoad(
        weekStart: entry.key,
        setCount: entry.value.length,
        avgRpe: avgRpe,
        load: entry.value.length * avgRpe);
  }).toList();
}

final trainingLoadProvider =
    FutureProvider.autoDispose<List<WeeklyLoad>>((ref) async {
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

  return computeTrainingLoad(allSets);
});
