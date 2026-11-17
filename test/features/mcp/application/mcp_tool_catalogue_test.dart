import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/application/build_cardio_history_use_case.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/heart_rate/application/build_weekly_heart_report_use_case.dart';
import 'package:rep_foundry/features/history/application/calculate_progress_use_case.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/mcp/application/mcp_tool.dart';
import 'package:rep_foundry/features/mcp/application/mcp_tool_catalogue.dart';
import 'package:rep_foundry/features/mcp/domain/mcp_settings.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

import 'support_paths.dart';

const _baseTools = {
  'list_workouts',
  'get_workout',
  'list_exercises',
  'get_exercise_history',
  'list_personal_records',
  'get_training_summary',
  'list_cardio_sessions',
  'get_cardio_progress',
  'get_weekly_heart_report',
  'list_body_metrics',
  'list_templates',
  'list_programmes',
};

class _Repos {
  _Repos() {
    workouts = GuardedWorkoutRepository(guard);
    exercises = GuardedExerciseRepository(guard);
    cardio = GuardedCardioSessionRepository(guard);
    stretching = GuardedStretchingSessionRepository(guard);
    records = GuardedPersonalRecordRepository(guard);
    templates = GuardedWorkoutTemplateRepository(guard);
  }

  final guard = WriteGuard();
  late final GuardedWorkoutRepository workouts;
  late final GuardedExerciseRepository exercises;
  late final GuardedCardioSessionRepository cardio;
  late final GuardedStretchingSessionRepository stretching;
  late final GuardedPersonalRecordRepository records;
  late final GuardedWorkoutTemplateRepository templates;
  final clients = FakeClientRepository([testClient('alice', name: 'Alice')]);

  McpToolDeps deps() => McpToolDeps(
        workouts: workouts,
        exercises: exercises,
        cardio: cardio,
        stretching: stretching,
        records: records,
        bodyMetrics: FakeBodyMetricRepository(),
        templates: templates,
        programmes: FakeProgrammeRepository(),
        clients: clients,
        healthProfiles: FakeHealthProfileRepository(),
        calculateProgress:
            CalculateProgressUseCase(workoutRepository: workouts),
        cardioHistory: BuildCardioHistoryUseCase(
          workoutRepository: workouts,
          cardioSessionRepository: cardio,
          exerciseRepository: exercises,
        ),
        weeklyHeartReport: BuildWeeklyHeartReportUseCase(
          workoutRepository: workouts,
          cardioSessionRepository: cardio,
          exerciseRepository: exercises,
        ),
        now: () => DateTime(2026, 11, 11, 12),
      );
}

/// Valid arguments for the tools that need an id.
Map<String, Object?> _argsFor(String tool, Map<String, String> ids) =>
    switch (tool) {
      'get_workout' => {'workout_id': ids['workout']!},
      'get_exercise_history' => {'exercise_id': ids['exercise']!},
      _ => {},
    };

void main() {
  test('offers the twelve base tools by default', () {
    final names = buildMcpTools(_Repos().deps(), const McpSettings())
        .map((t) => t.name)
        .toSet();
    expect(names, _baseTools);
  });

  test('adds list_clients and get_health_profile only with their toggles', () {
    final deps = _Repos().deps();
    Set<String> names(McpSettings s) =>
        buildMcpTools(deps, s).map((t) => t.name).toSet();
    expect(names(const McpSettings(includeClients: true)),
        {..._baseTools, 'list_clients'});
    expect(names(const McpSettings(includeHealthProfile: true)),
        {..._baseTools, 'get_health_profile'});
    expect(
        names(const McpSettings(
            includeClients: true, includeHealthProfile: true)),
        hasLength(14));
  });

  group('client data toggle', () {
    bool takesClientId(McpTool t) =>
        (t.inputSchema['properties']! as Map).containsKey('client_id');

    const all = McpSettings(includeClients: true, includeHealthProfile: true);
    const ids = {'workout': 'none', 'exercise': 'none'};

    test('every tool that takes client_id refuses it while off', () async {
      final repos = _Repos();
      final exercise = await repos.exercises.getAllExercises();
      final args = {...ids, 'exercise': exercise.first.id};
      final scoped = buildMcpTools(
              repos.deps(), const McpSettings(includeHealthProfile: true))
          .where(takesClientId)
          .toList();
      expect(scoped.map((t) => t.name), hasLength(greaterThanOrEqualTo(10)));
      for (final t in scoped) {
        await expectLater(
          t.call({..._argsFor(t.name, args), 'client_id': 'alice'}),
          throwsA(isA<McpToolError>()),
          reason: t.name,
        );
      }
    });

    test('control: every such tool accepts client_id while on', () async {
      final repos = _Repos();
      final exercise = await repos.exercises.getAllExercises();
      final args = {...ids, 'exercise': exercise.first.id};
      for (final t in buildMcpTools(repos.deps(), all).where(takesClientId)) {
        await t.call({..._argsFor(t.name, args), 'client_id': 'alice'});
      }
    });
  });

  test('every tool has an object input schema, a description and unique name',
      () {
    final tools = buildMcpTools(_Repos().deps(),
        const McpSettings(includeClients: true, includeHealthProfile: true));
    for (final t in tools) {
      expect(t.inputSchema['type'], 'object', reason: t.name);
      expect(t.description, isNotEmpty, reason: t.name);
      expect(t.name, matches(RegExp(r'^[a-z_]+$')));
    }
    expect(tools.map((t) => t.name).toSet(), hasLength(tools.length));
  });

  test('instructions state units, time zone and read-only access', () {
    for (final phrase in [
      'kg',
      'km',
      'seconds',
      'ISO 8601',
      'Monday',
      'read-only'
    ]) {
      expect(kMcpServerInstructions, contains(phrase));
    }
  });

  group('read-only', () {
    test('no tool writes, on a seeded database', () async {
      final r = _Repos();
      final bench = await r.exercises.createExercise(Exercise.create(
        name: 'Bench',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
      ));
      final w = await r.workouts.createWorkout(Workout(
        id: 'w1',
        startedAt: DateTime.utc(2026, 11, 10, 9),
        completedAt: DateTime.utc(2026, 11, 10, 10),
        clientId: kSelfClientId,
        updatedAt: DateTime.utc(2026, 11, 10),
      ));
      await r.workouts.addSet(WorkoutSet(
        id: 's1',
        workoutId: w.id,
        exerciseId: bench.id,
        setOrder: 1,
        weight: 100,
        reps: 5,
        avgHeartRate: 120,
        peakHeartRate: 140,
        timestamp: DateTime.utc(2026, 11, 10, 9, 5),
        updatedAt: DateTime.utc(2026, 11, 10),
      ));
      await r.records.createRecord(PersonalRecord(
        id: 'pr1',
        exerciseId: bench.id,
        recordType: RecordType.maxWeight,
        value: 100,
        achievedAt: DateTime.utc(2026, 11, 10),
        clientId: kSelfClientId,
        updatedAt: DateTime.utc(2026, 11, 10),
      ));
      await r.stretching.createSession(StretchingSession(
        id: 'st1',
        workoutId: w.id,
        type: 'calf',
        durationSeconds: 30,
        entryMethod: StretchingEntryMethod.manual,
        updatedAt: DateTime.utc(2026, 11, 10),
      ));
      r.guard.seal();

      final tools = buildMcpTools(r.deps(),
          const McpSettings(includeClients: true, includeHealthProfile: true));
      final ids = {'workout': w.id, 'exercise': bench.id};
      for (final t in tools) {
        await t.call(_argsFor(t.name, ids));
      }
    });

    test('control: a sealed guard does reject a write', () {
      final r = _Repos()..guard.seal();
      expect(() => r.workouts.deleteWorkout('w1'), throwsStateError);
    });
  });

  test('every tool without required arguments copes with an empty database',
      () async {
    final tools = buildMcpTools(_Repos().deps(),
        const McpSettings(includeClients: true, includeHealthProfile: true));
    for (final t in tools) {
      if ((t.inputSchema['required'] as List?)?.isNotEmpty ?? false) continue;
      final result = await t.call({});
      for (final key in [
        'workouts',
        'exercises',
        'records',
        'weeks',
        'sessions',
        'entries',
        'templates',
        'programmes',
        'muscle_balance'
      ]) {
        final v = result[key];
        if (v is List && key != 'exercises') {
          expect(v, isEmpty, reason: '${t.name}.$key');
        }
      }
    }
  });
}
