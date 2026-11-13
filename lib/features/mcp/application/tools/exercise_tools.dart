import '../../../exercises/domain/models/exercise.dart';
import '../../../exercises/domain/repositories/exercise_repository.dart';
import '../../../history/application/calculate_progress_use_case.dart';
import '../../../history/domain/models/personal_record.dart';
import '../../../history/domain/repositories/personal_record_repository.dart';
import '../../../workout/domain/models/workout_set.dart';
import '../../../workout/domain/repositories/workout_repository.dart';
import '../mcp_args.dart';
import '../mcp_scope.dart';
import '../mcp_tool.dart';
import 'workout_tools.dart';

/// The exercise library, with how often each has been used.
class ListExercisesTool implements McpTool {
  ListExercisesTool(this._exercises, this._workouts, this._scope);

  final ExerciseRepository _exercises;
  final WorkoutRepository _workouts;
  final McpScope _scope;

  @override
  String get name => 'list_exercises';

  @override
  String get description =>
      'Lists the exercise library sorted by name, with category, muscle '
      'group, equipment and the number of sessions each was used in. Use the '
      'ids with get_exercise_history and list_personal_records.';

  @override
  Map<String, Object?> get inputSchema => objectSchema({
        'query': {'type': 'string', 'description': 'Name contains this text.'},
        'muscle_group': {
          'type': 'string',
          'enum': [for (final g in MuscleGroup.values) g.name],
        },
        'client_id': kClientIdSchema,
      });

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final clientId = await _scope.resolveClientId(args);
    final query = optionalString(args, 'query');
    final groupName = optionalString(args, 'muscle_group');
    MuscleGroup? group;
    if (groupName != null) {
      group = MuscleGroup.values.where((g) => g.name == groupName).firstOrNull;
      if (group == null) {
        throw McpToolError('Unknown muscle_group "$groupName"');
      }
    }

    final found = query == null || query.isEmpty
        ? await _exercises.getAllExercises()
        : await _exercises.searchExercises(query);
    final usage = await _workouts.getExerciseUsageCounts(clientId);
    final rows = found
        .where((e) => !e.isDeleted && (group == null || e.muscleGroup == group))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return {
      'exercises': [
        for (final e in rows)
          {
            'id': e.id,
            'name': e.name,
            'category': e.category.name,
            'muscle_group': e.muscleGroup.name,
            'equipment': e.equipmentType.name,
            'is_custom': e.isCustom,
            'times_used': usage[e.id] ?? 0,
          },
      ],
    };
  }
}

/// Every set of one exercise, grouped by session.
class GetExerciseHistoryTool implements McpTool {
  GetExerciseHistoryTool(this._exercises, this._progress, this._scope);

  final ExerciseRepository _exercises;
  final CalculateProgressUseCase _progress;
  final McpScope _scope;

  @override
  String get name => 'get_exercise_history';

  @override
  String get description =>
      'Returns the sets of one exercise grouped by session, newest first, '
      'with the best estimated one-rep max and total working-set volume '
      'across the sessions returned. `limit` counts sessions; page with '
      '`next_cursor`. Covers the '
      'most recent 200 sets.';

  @override
  Map<String, Object?> get inputSchema => objectSchema({
        'exercise_id': {
          'type': 'string',
          'description': 'id from list_exercises.',
        },
        'from': kFromSchema,
        'to': kToSchema,
        'limit': kLimitSchema,
        'cursor': kCursorSchema,
        'client_id': kClientIdSchema,
      }, required: [
        'exercise_id'
      ]);

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final exerciseId = requireString(args, 'exercise_id');
    final clientId = await _scope.resolveClientId(args);
    final limit = parseLimit(args);
    final from = parseDate(args, 'from');
    final before = decodeCursor(args) ?? parseDate(args, 'to');
    final exercise = await _exercises.getExercise(exerciseId);
    if (exercise == null || exercise.isDeleted) {
      throw const McpToolError('Exercise not found');
    }

    final progress = await _progress.execute(exerciseId, clientId: clientId);
    final byWorkout = <String, List<WorkoutSet>>{};
    for (final s in progress.sets.where((s) => !s.isDeleted)) {
      byWorkout.putIfAbsent(s.workoutId, () => []).add(s);
    }

    DateTime sessionDate(List<WorkoutSet> sets) =>
        sets.map((s) => s.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);

    final sessions = byWorkout.entries
        .map((e) => (id: e.key, date: sessionDate(e.value), sets: e.value))
        .where((s) =>
            (from == null || !s.date.isBefore(from)) &&
            (before == null || s.date.isBefore(before)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final page = sessions.take(limit).toList();

    final working = page.expand((s) => s.sets).where((s) => !s.isWarmUp);
    double? best;
    for (final s in working) {
      if (best == null || s.estimatedOneRepMax > best) {
        best = s.estimatedOneRepMax;
      }
    }

    return {
      'exercise_id': exercise.id,
      'name': exercise.name,
      'max_estimated_1rm_kg': round2OrNull(best),
      'total_volume_kg':
          round2(working.fold<double>(0, (sum, s) => sum + s.volume)),
      'next_cursor':
          sessions.length > limit ? encodeCursor(page.last.date) : null,
      'sessions': [
        for (final s in page)
          {
            'workout_id': s.id,
            'date': isoLocal(s.date),
            'sets': [
              for (final set
                  in s.sets..sort((a, b) => a.setOrder.compareTo(b.setOrder)))
                workoutSetJson(set),
            ],
          },
      ],
    };
  }
}

/// The unit a personal record's value is measured in.
String recordUnit(RecordType type) => switch (type) {
      RecordType.estimatedOneRepMax || RecordType.maxWeight => 'kg',
      RecordType.maxReps => 'reps',
      RecordType.maxVolume => 'kg_x_reps',
    };

/// Personal records, newest first.
class ListPersonalRecordsTool implements McpTool {
  ListPersonalRecordsTool(this._records, this._exercises, this._scope);

  final PersonalRecordRepository _records;
  final ExerciseRepository _exercises;
  final McpScope _scope;

  @override
  String get name => 'list_personal_records';

  @override
  String get description =>
      'Lists personal records newest first: estimated one-rep max, heaviest '
      'weight, most reps and biggest single-set volume, each with its unit. '
      'Page with `next_cursor`.';

  @override
  Map<String, Object?> get inputSchema => objectSchema({
        'exercise_id': {'type': 'string'},
        'from': kFromSchema,
        'limit': kLimitSchema,
        'cursor': kCursorSchema,
        'client_id': kClientIdSchema,
      });

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final clientId = await _scope.resolveClientId(args);
    final exerciseId = optionalString(args, 'exercise_id');
    final from = parseDate(args, 'from');
    final limit = parseLimit(args);
    final before = decodeCursor(args);

    final found = exerciseId == null
        ? await _records.getAllRecords(clientId: clientId, limit: 1000)
        : await _records.getRecordsForExercise(exerciseId, clientId);
    final names = await exercisesById(_exercises);
    final rows = found
        .where((r) =>
            !r.isDeleted &&
            (from == null || !r.achievedAt.isBefore(from)) &&
            (before == null || r.achievedAt.isBefore(before)))
        .toList()
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

    final page = rows.take(limit).toList();
    return {
      'next_cursor':
          rows.length > limit ? encodeCursor(page.last.achievedAt) : null,
      'records': [
        for (final r in page)
          {
            'exercise_id': r.exerciseId,
            'exercise_name': names[r.exerciseId]?.name ?? kUnknownExerciseName,
            'record_type': r.recordType.name,
            'value': round2(r.value),
            'unit': recordUnit(r.recordType),
            'achieved_at': isoLocal(r.achievedAt),
          },
      ],
    };
  }
}
