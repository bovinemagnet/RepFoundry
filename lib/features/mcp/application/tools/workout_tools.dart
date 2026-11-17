import '../../../cardio/domain/repositories/cardio_session_repository.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../exercises/domain/repositories/exercise_repository.dart';
import '../../../stretching/domain/repositories/stretching_session_repository.dart';
import '../../../workout/domain/models/workout.dart';
import '../../../workout/domain/models/workout_set.dart';
import '../../../workout/domain/repositories/workout_repository.dart';
import '../mcp_args.dart';
import '../mcp_scope.dart';
import '../mcp_tool.dart';

/// Name used when a set's exercise has since been deleted.
const String kUnknownExerciseName = 'Unknown exercise';

/// One logged set as returned by the MCP tools.
Map<String, Object?> workoutSetJson(WorkoutSet s) => {
      'set_order': s.setOrder,
      'weight_kg': round2(s.weight),
      'reps': s.reps,
      'rpe': s.rpe,
      'is_warm_up': s.isWarmUp,
      'estimated_1rm_kg': round2(s.estimatedOneRepMax),
      'avg_hr_bpm': s.avgHeartRate,
      'peak_hr_bpm': s.peakHeartRate,
      'logged_at': isoLocal(s.timestamp),
    };

/// Every exercise, deleted ones aside, keyed by id.
Future<Map<String, Exercise>> exercisesById(ExerciseRepository repo) async =>
    {for (final e in await repo.getAllExercises()) e.id: e};

List<WorkoutSet> _liveSetsInOrder(Iterable<WorkoutSet> sets) =>
    sets.where((s) => !s.isDeleted).toList()
      ..sort((a, b) {
        final byOrder = a.setOrder.compareTo(b.setOrder);
        return byOrder != 0 ? byOrder : a.timestamp.compareTo(b.timestamp);
      });

int? _durationSeconds(Workout w) =>
    w.completedAt?.difference(w.startedAt).inSeconds;

/// Lists sessions, newest first, with a one-line summary each.
class ListWorkoutsTool implements McpTool {
  ListWorkoutsTool(this._workouts, this._exercises, this._scope);

  final WorkoutRepository _workouts;
  final ExerciseRepository _exercises;
  final McpScope _scope;

  @override
  String get name => 'list_workouts';

  @override
  String get description =>
      'Lists completed strength sessions, newest first, with the exercises '
      'done, working-set count and total volume (warm-ups excluded). The '
      'first page also returns any session still in progress as '
      '`in_progress`. Page with `next_cursor`.';

  @override
  Map<String, Object?> get inputSchema => objectSchema({
        'from': kFromSchema,
        'to': kToSchema,
        'limit': kLimitSchema,
        'cursor': kCursorSchema,
        'client_id': kClientIdSchema,
      });

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final clientId = await _scope.resolveClientId(args);
    final limit = parseLimit(args);
    final from = parseDate(args, 'from');
    final to = parseDate(args, 'to');
    final cursor = decodeCursor(args);
    final before = cursor ?? to;

    bool afterFrom(Workout w) => from == null || !w.startedAt.isBefore(from);

    final rows = await _workouts.getWorkoutHistory(
      clientId: clientId,
      limit: limit + 1,
      before: before,
    );
    final page = rows.take(limit).where(afterFrom).toList();
    final hasMore = rows.length > limit && afterFrom(rows[limit]);

    Workout? inProgress;
    if (cursor == null) {
      final active = await _workouts.getActiveWorkout();
      if (active != null &&
          !active.isDeleted &&
          active.clientId == clientId &&
          afterFrom(active) &&
          (to == null || active.startedAt.isBefore(to))) {
        inProgress = active;
      }
    }

    final all = [...page, if (inProgress != null) inProgress];
    final setsByWorkout =
        await _workouts.getSetsForWorkouts([for (final w in all) w.id]);
    final names = await exercisesById(_exercises);

    Map<String, Object?> summary(Workout w) {
      final sets = _liveSetsInOrder(setsByWorkout[w.id] ?? const []);
      final working = sets.where((s) => !s.isWarmUp);
      final exerciseNames = <String>[];
      for (final s in sets) {
        final n = names[s.exerciseId]?.name ?? kUnknownExerciseName;
        if (!exerciseNames.contains(n)) exerciseNames.add(n);
      }
      return {
        'id': w.id,
        'started_at': isoLocal(w.startedAt),
        'completed_at': isoLocalOrNull(w.completedAt),
        'duration_seconds': _durationSeconds(w),
        'notes': w.notes,
        'exercises': exerciseNames,
        'working_set_count': working.length,
        'total_volume_kg':
            round2(working.fold<double>(0, (sum, s) => sum + s.volume)),
      };
    }

    return {
      'workouts': [for (final w in page) summary(w)],
      'in_progress': inProgress == null ? null : summary(inProgress),
      'next_cursor': hasMore ? encodeCursor(page.last.startedAt) : null,
    };
  }
}

/// Everything recorded in one session.
class GetWorkoutTool implements McpTool {
  GetWorkoutTool(
    this._workouts,
    this._exercises,
    this._cardio,
    this._stretching,
    this._scope,
  );

  final WorkoutRepository _workouts;
  final ExerciseRepository _exercises;
  final CardioSessionRepository _cardio;
  final StretchingSessionRepository _stretching;
  final McpScope _scope;

  @override
  String get name => 'get_workout';

  @override
  String get description =>
      'Returns one session in full: every set grouped by exercise (weight, '
      'reps, RPE, estimated 1RM, heart rate), cardio summaries and '
      'stretches. Routes and GPS positions are never included.';

  @override
  Map<String, Object?> get inputSchema => objectSchema({
        'workout_id': {
          'type': 'string',
          'description': 'id from list_workouts.',
        },
      }, required: [
        'workout_id'
      ]);

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final id = requireString(args, 'workout_id');
    final w = await _workouts.getWorkout(id);
    // One message for missing, deleted and out-of-scope, so the existence
    // of another client's session is not revealed.
    if (w == null || w.isDeleted || !await _scope.canRead(w.clientId)) {
      throw const McpToolError('Workout not found');
    }

    final names = await exercisesById(_exercises);
    final sets = _liveSetsInOrder(await _workouts.getSetsForWorkout(id));
    final grouped = <String, List<WorkoutSet>>{};
    for (final s in sets) {
      grouped.putIfAbsent(s.exerciseId, () => []).add(s);
    }

    final cardio =
        (await _cardio.getSessionsForWorkout(id)).where((c) => !c.isDeleted);
    final stretches = (await _stretching.getSessionsForWorkout(id))
        .where((s) => !s.isDeleted);

    return {
      'id': w.id,
      'started_at': isoLocal(w.startedAt),
      'completed_at': isoLocalOrNull(w.completedAt),
      'duration_seconds': _durationSeconds(w),
      'notes': w.notes,
      'exercises': [
        for (final entry in grouped.entries)
          {
            'exercise_id': entry.key,
            'name': names[entry.key]?.name ?? kUnknownExerciseName,
            'sets': [for (final s in entry.value) workoutSetJson(s)],
          },
      ],
      'cardio': [
        for (final c in cardio)
          {
            'exercise_name': names[c.exerciseId]?.name ?? kUnknownExerciseName,
            'duration_seconds': c.durationSeconds,
            'distance_km': round2OrNull(
                c.distanceMeters == null ? null : c.distanceMeters! / 1000),
            'pace_min_per_km': round2OrNull(c.paceMinutesPerKm),
            'incline': c.incline,
            'avg_hr_bpm': c.avgHeartRate,
          },
      ],
      'stretching': [
        for (final s in stretches)
          {
            'name': s.customName ?? s.type,
            'body_area': s.bodyArea?.name,
            'side': s.side?.name,
            'duration_seconds': s.durationSeconds,
          },
      ],
    };
  }
}
