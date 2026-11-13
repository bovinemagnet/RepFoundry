import '../../../body_metrics/domain/repositories/body_metric_repository.dart';
import '../../../exercises/domain/repositories/exercise_repository.dart';
import '../../../programmes/domain/repositories/programme_repository.dart';
import '../../../templates/domain/repositories/workout_template_repository.dart';
import '../mcp_args.dart';
import '../mcp_scope.dart';
import '../mcp_tool.dart';
import 'workout_tools.dart';

/// Weight and body-fat entries, newest first.
class ListBodyMetricsTool implements McpTool {
  ListBodyMetricsTool(this._metrics, this._scope);

  final BodyMetricRepository _metrics;
  final McpScope _scope;

  @override
  String get name => 'list_body_metrics';

  @override
  String get description =>
      'Lists body weight and optional body-fat entries, newest first.';

  @override
  Map<String, Object?> get inputSchema => objectSchema({
        'from': kFromSchema,
        'to': kToSchema,
        'limit': kLimitSchema,
        'client_id': kClientIdSchema,
      });

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final clientId = await _scope.resolveClientId(args);
    final from = parseDate(args, 'from');
    final to = parseDate(args, 'to');
    final limit = parseLimit(args);
    final rows = (await _metrics.getAll(clientId: clientId, limit: 1000))
        .where((m) =>
            !m.isDeleted &&
            (from == null || !m.date.isBefore(from)) &&
            (to == null || m.date.isBefore(to)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return {
      'entries': [
        for (final m in rows.take(limit))
          {
            'date': isoDate(m.date),
            'weight_kg': round2(m.weight),
            'body_fat_percent': round2OrNull(m.bodyFatPercent),
            'notes': m.notes,
          },
      ],
    };
  }
}

/// Saved workout templates.
class ListTemplatesTool implements McpTool {
  ListTemplatesTool(this._templates);

  final WorkoutTemplateRepository _templates;

  @override
  String get name => 'list_templates';

  @override
  String get description =>
      'Lists saved workout templates with their exercises in order and the '
      'target sets and reps for each.';

  @override
  Map<String, Object?> get inputSchema => objectSchema({});

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final templates = (await _templates.getAllTemplates())
        .where((t) => !t.isDeleted)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return {
      'templates': [
        for (final t in templates)
          {
            'id': t.id,
            'name': t.name,
            'exercises': [
              for (final e
                  in t.exercises.where((e) => !e.isDeleted).toList()
                    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)))
                {
                  'exercise_id': e.exerciseId,
                  'name': e.exerciseName,
                  'target_sets': e.targetSets,
                  'target_reps': e.targetReps,
                },
            ],
          },
      ],
    };
  }
}

/// Multi-week programmes with their schedule and progression rules.
class ListProgrammesTool implements McpTool {
  ListProgrammesTool(this._programmes, this._exercises);

  final ProgrammeRepository _programmes;
  final ExerciseRepository _exercises;

  @override
  String get name => 'list_programmes';

  @override
  String get description =>
      'Lists training programmes: length in weeks, start date, which '
      'template runs on which day (day_of_week 1 = Monday), and the '
      'progression rule for each exercise.';

  @override
  Map<String, Object?> get inputSchema => objectSchema({});

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final names = await exercisesById(_exercises);
    final programmes = (await _programmes.getAllProgrammes())
        .where((p) => !p.isDeleted)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final result = <Map<String, Object?>>[];
    for (final p in programmes) {
      final days = (await _programmes.getDaysForProgramme(p.id))
          .where((d) => !d.isDeleted)
          .toList()
        ..sort((a, b) {
          final byWeek = a.weekNumber.compareTo(b.weekNumber);
          return byWeek != 0 ? byWeek : a.dayOfWeek.compareTo(b.dayOfWeek);
        });
      final rules = (await _programmes.getRulesForProgramme(p.id))
          .where((r) => !r.isDeleted);
      result.add({
        'id': p.id,
        'name': p.name,
        'duration_weeks': p.durationWeeks,
        'started_at': isoLocalOrNull(p.startedAt),
        'days': [
          for (final d in days)
            {
              'week': d.weekNumber,
              'day_of_week': d.dayOfWeek,
              'template_id': d.templateId,
              'template_name': d.templateName,
            },
        ],
        'progression_rules': [
          for (final r in rules)
            {
              'exercise_id': r.exerciseId,
              'exercise_name':
                  names[r.exerciseId]?.name ?? kUnknownExerciseName,
              'type': r.type.name,
              'value': r.value,
              'frequency_weeks': r.frequencyWeeks,
            },
        ],
      });
    }
    return {'programmes': result};
  }
}
