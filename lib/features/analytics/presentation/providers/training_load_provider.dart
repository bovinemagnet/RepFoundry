import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';
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
    // Bucket by the user's local week, not the UTC week stored in the DB.
    final local = s.date.toLocal();
    final weekStart = local.subtract(Duration(days: local.weekday - 1));
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
