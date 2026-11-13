import '../../exercises/domain/models/exercise.dart';
import '../../workout/domain/models/workout_set.dart';

// Pure training aggregates shared by the analytics providers and the MCP
// training summary tool. Weeks are the user's local week, starting Monday.

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
    // Bucket by the user's local week, not the UTC week stored in the DB.
    final local = s.date.toLocal();
    final weekStart = local.subtract(Duration(days: local.weekday - 1));
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

class MuscleBalance {
  final MuscleGroup group;
  final double volumePercent;

  const MuscleBalance({required this.group, required this.volumePercent});
}

/// Share of working-set volume per muscle group, as percentages of the total.
///
/// Warm-ups and sets whose exercise is not in [exercisesById] are skipped.
/// Cardio volume counts towards the total but is omitted from the result.
/// Sorted by [MuscleGroup.index]; empty when there is no volume.
List<MuscleBalance> computeMuscleBalance(
  Iterable<WorkoutSet> sets,
  Map<String, Exercise> exercisesById,
) {
  final volumeByGroup = <MuscleGroup, double>{};
  for (final s in sets) {
    if (s.isWarmUp) continue;
    final exercise = exercisesById[s.exerciseId];
    if (exercise == null) continue;
    volumeByGroup[exercise.muscleGroup] =
        (volumeByGroup[exercise.muscleGroup] ?? 0) + s.volume;
  }

  final total = volumeByGroup.values.fold(0.0, (a, b) => a + b);
  if (total == 0) return [];

  return volumeByGroup.entries
      .where((e) => e.key != MuscleGroup.cardio)
      .map((e) =>
          MuscleBalance(group: e.key, volumePercent: (e.value / total) * 100))
      .toList()
    ..sort((a, b) => a.group.index.compareTo(b.group.index));
}
