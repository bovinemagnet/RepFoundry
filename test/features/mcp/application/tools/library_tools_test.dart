import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/features/body_metrics/domain/models/body_metric.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/mcp/application/mcp_tool.dart';
import 'package:rep_foundry/features/mcp/application/tools/client_tools.dart';
import 'package:rep_foundry/features/mcp/application/tools/library_tools.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';
import 'package:rep_foundry/features/templates/data/workout_template_repository_impl.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';

import '../../support/fake_client_repository.dart';
import '../../support/fake_health_profile_repository.dart';
import '../../support/fake_library_repositories.dart';
import '../../support/mcp_fixture.dart';

final _t = DateTime.utc(2026, 1, 1);

BodyMetric _metric(String id, DateTime date, double kg,
        {String clientId = kSelfClientId, DateTime? deletedAt}) =>
    BodyMetric(
      id: id,
      date: date,
      weight: kg,
      bodyFatPercent: id == 'b' ? 18.5 : null,
      clientId: clientId,
      updatedAt: _t,
      deletedAt: deletedAt,
    );

void main() {
  late McpFixture f;
  setUp(() => f = McpFixture());

  test('list_body_metrics lists my entries newest first, within dates',
      () async {
    final repo = FakeBodyMetricRepository([
      _metric('a', DateTime(2026, 3, 1), 80),
      _metric('b', DateTime(2026, 3, 8), 79.456),
      _metric('c', DateTime(2026, 3, 9), 70, deletedAt: _t),
      _metric('d', DateTime(2026, 3, 9), 60, clientId: otherClientId),
      _metric('e', DateTime(2026, 1, 1), 85),
    ]);
    final r =
        await ListBodyMetricsTool(repo, f.scope()).call({'from': '2026-02-01'});
    final rows = (r['entries']! as List).cast<Map<String, Object?>>();
    expect(rows.map((e) => e['weight_kg']), [79.46, 80]);
    expect(rows.first['body_fat_percent'], 18.5);
    expect(rows.first['date'], '2026-03-08');
  });

  test('list_templates lists live templates with exercises in order', () async {
    final repo = InMemoryWorkoutTemplateRepository();
    TemplateExercise ex(String id, String name, int order,
            {DateTime? deletedAt}) =>
        TemplateExercise(
          id: id,
          templateId: 't1',
          exerciseId: 'x-$id',
          exerciseName: name,
          targetSets: 3,
          targetReps: 8,
          orderIndex: order,
          updatedAt: _t,
          deletedAt: deletedAt,
        );
    await repo.createTemplate(WorkoutTemplate(
      id: 't1',
      name: 'Push',
      createdAt: _t,
      updatedAt: _t,
      exercises: [
        ex('2', 'Dips', 1),
        ex('1', 'Bench', 0),
        ex('3', 'Gone', 2, deletedAt: _t)
      ],
    ));
    await repo.createTemplate(WorkoutTemplate(
        id: 't2', name: 'Old', createdAt: _t, updatedAt: _t, deletedAt: _t));

    final r = await ListTemplatesTool(repo).call({});
    final templates = (r['templates']! as List).cast<Map<String, Object?>>();
    expect(templates.map((t) => t['name']), ['Push']);
    final exercises =
        (templates.single['exercises']! as List).cast<Map<String, Object?>>();
    expect(exercises.map((e) => e['name']), ['Bench', 'Dips']);
    expect(exercises.first['target_sets'], 3);
    expect(exercises.first['target_reps'], 8);
  });

  test('list_programmes includes days and progression rules', () async {
    final squat = await f.exercise('Squat', MuscleGroup.quadriceps);
    final repo = FakeProgrammeRepository(
      programmes: [
        Programme(
            id: 'p1',
            name: 'Base',
            durationWeeks: 4,
            createdAt: _t,
            updatedAt: _t),
        Programme(
            id: 'p2',
            name: 'Old',
            durationWeeks: 4,
            createdAt: _t,
            updatedAt: _t,
            deletedAt: _t),
      ],
      days: [
        ProgrammeDay(
            id: 'd2',
            programmeId: 'p1',
            weekNumber: 1,
            dayOfWeek: 3,
            templateId: 't',
            templateName: 'Pull',
            updatedAt: _t),
        ProgrammeDay(
            id: 'd1',
            programmeId: 'p1',
            weekNumber: 1,
            dayOfWeek: 1,
            templateId: 't',
            templateName: 'Push',
            updatedAt: _t),
        ProgrammeDay(
            id: 'd3',
            programmeId: 'p1',
            weekNumber: 2,
            dayOfWeek: 1,
            templateId: 't',
            templateName: 'Gone',
            updatedAt: _t,
            deletedAt: _t),
      ],
      rules: [
        ProgressionRule(
            id: 'r1',
            programmeId: 'p1',
            exerciseId: squat.id,
            type: ProgressionType.fixedIncrement,
            value: 2.5,
            updatedAt: _t),
      ],
    );
    final r = await ListProgrammesTool(repo, f.exercises).call({});
    final p = (r['programmes']! as List).single as Map<String, Object?>;
    expect(p['name'], 'Base');
    expect(p['duration_weeks'], 4);
    expect(p['started_at'], isNull);
    expect((p['days']! as List).map((d) => (d as Map)['template_name']),
        ['Push', 'Pull']);
    final rule =
        (p['progression_rules']! as List).single as Map<String, Object?>;
    expect(rule['exercise_name'], 'Squat');
    expect(rule['type'], 'fixedIncrement');
    expect(rule['value'], 2.5);
    expect(rule['frequency_weeks'], 1);
  });

  test('list_clients lists the live roster', () async {
    final repo = FakeClientRepository([
      testClient('alice', name: 'Alice'),
      testClient('gone', deletedAt: _t),
    ]);
    final r = await ListClientsTool(repo).call({});
    final rows = (r['clients']! as List).cast<Map<String, Object?>>();
    expect(rows.map((c) => c['name']), unorderedEquals(['Me', 'Alice']));
    expect(rows.firstWhere((c) => c['name'] == 'Me')['is_self'], isTrue);
  });

  group('get_health_profile', () {
    final profiles = FakeHealthProfileRepository({
      kSelfClientId: const HealthProfile(
          age: 52, restingHr: 58, clinicianMaxHr: 140, betaBlocker: true),
      otherClientId: const HealthProfile(age: 30),
    });

    test('returns my profile', () async {
      final r = await GetHealthProfileTool(profiles, f.scope()).call({});
      expect(r['client_id'], kSelfClientId);
      expect(r['age'], 52);
      expect(r['resting_hr_bpm'], 58);
      expect(r['clinician_max_hr_bpm'], 140);
      expect(r['measured_max_hr_bpm'], isNull);
      expect(r['beta_blocker'], isTrue);
      expect(r['heart_condition'], isFalse);
    });

    test("returns a client's profile only when client data is on", () async {
      await expectLater(
          GetHealthProfileTool(profiles, f.scope())
              .call({'client_id': otherClientId}),
          throwsA(isA<McpToolError>()));
      final r =
          await GetHealthProfileTool(profiles, f.scope(includeClients: true))
              .call({'client_id': otherClientId});
      expect(r['age'], 30);
    });
  });
}
