import '../../../analytics/application/training_aggregates.dart';
import '../../../exercises/domain/repositories/exercise_repository.dart';
import '../../../workout/domain/repositories/workout_repository.dart';
import '../mcp_args.dart';
import '../mcp_scope.dart';
import '../mcp_tool.dart';
import 'workout_tools.dart';

/// Weekly volume, training load and muscle balance, as on the analytics
/// screen, over a window of recent weeks.
class GetTrainingSummaryTool implements McpTool {
  GetTrainingSummaryTool(
      this._workouts, this._exercises, this._scope, this._now);

  final WorkoutRepository _workouts;
  final ExerciseRepository _exercises;
  final McpScope _scope;
  final DateTime Function() _now;

  /// Completed sessions read, matching the analytics screen.
  static const int sessionsRead = 200;

  @override
  String get name => 'get_training_summary';

  @override
  String get description =>
      'Summarises completed training over the last `weeks` local weeks '
      '(Monday start, current week included): working-set volume with change '
      'from the previous trained week, set count, average RPE, load (sets × '
      'average RPE), and the share of volume per muscle group. Warm-ups '
      'excluded; weeks with no training are omitted.';

  @override
  Map<String, Object?> get inputSchema => objectSchema({
        'weeks': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 52,
          'description': 'Weeks to cover, default 8.',
        },
        'client_id': kClientIdSchema,
      });

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final clientId = await _scope.resolveClientId(args);
    final weeks = parseLimit(args, key: 'weeks', defaultValue: 8, max: 52);

    final today = _now().toLocal();
    final thisWeek = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final windowStart =
        DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7 * (weeks - 1));

    final history = await _workouts.getWorkoutHistory(
        clientId: clientId, limit: sessionsRead);
    final completed = [
      for (final w in history)
        if (w.completedAt != null && !w.isDeleted) w.id,
    ];
    final setsByWorkout = await _workouts.getSetsForWorkouts(completed);
    final sets = setsByWorkout.values
        .expand((s) => s)
        .where((s) =>
            !s.isDeleted &&
            !s.isWarmUp &&
            !s.timestamp.toLocal().isBefore(windowStart))
        .toList();

    final data = [
      for (final s in sets)
        SetData(date: s.timestamp, volume: s.volume, rpe: s.rpe),
    ];
    final load = {for (final l in computeTrainingLoad(data)) l.weekStart: l};
    final balance = computeMuscleBalance(sets, await exercisesById(_exercises));

    return {
      'weeks': [
        for (final v in computeWeeklyVolume(data))
          {
            'week_start': isoDate(v.weekStart),
            'total_volume_kg': round2(v.totalVolume),
            'percent_change': round2OrNull(v.percentChange),
            'working_set_count': load[v.weekStart]?.setCount ?? 0,
            // The aggregate reports 0 when no set in the week had an RPE.
            'avg_rpe': switch (load[v.weekStart]?.avgRpe) {
              final r? when r > 0 => round2(r),
              _ => null,
            },
            'load': round2(load[v.weekStart]?.load ?? 0),
          },
      ],
      'muscle_balance': [
        for (final m in balance)
          {
            'muscle_group': m.group.name,
            'volume_percent': round2(m.volumePercent),
          },
      ],
    };
  }
}
