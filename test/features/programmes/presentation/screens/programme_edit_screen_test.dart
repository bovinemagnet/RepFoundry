import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';
import 'package:rep_foundry/features/programmes/domain/repositories/programme_repository.dart';
import 'package:rep_foundry/features/programmes/presentation/screens/programme_edit_screen.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/features/templates/domain/repositories/workout_template_repository.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

class _FakeProgrammeRepository implements ProgrammeRepository {
  _FakeProgrammeRepository({
    Map<String, Programme>? programmes,
    Map<String, List<ProgrammeDay>>? days,
    Map<String, List<ProgressionRule>>? rules,
  })  : _programmes = programmes ?? {},
        _days = days ?? {},
        _rules = rules ?? {};

  final Map<String, Programme> _programmes;
  final Map<String, List<ProgrammeDay>> _days;
  final Map<String, List<ProgressionRule>> _rules;
  final List<Programme> updated = [];

  @override
  Future<Programme?> getProgramme(String id) async => _programmes[id];

  @override
  Future<List<ProgrammeDay>> getDaysForProgramme(String programmeId) async =>
      _days[programmeId] ?? [];

  @override
  Future<List<ProgressionRule>> getRulesForProgramme(
          String programmeId) async =>
      _rules[programmeId] ?? [];

  @override
  Future<Programme> updateProgramme(Programme programme) async {
    updated.add(programme);
    _programmes[programme.id] = programme;
    return programme;
  }

  @override
  Future<Programme> createProgramme(Programme programme) async => programme;

  @override
  Future<List<Programme>> getAllProgrammes() async =>
      _programmes.values.toList();

  @override
  Stream<List<Programme>> watchAllProgrammes() =>
      Stream.value(_programmes.values.toList());

  @override
  Future<void> deleteProgramme(String id) async {}

  @override
  Future<void> markProgrammeStarted(String id, {DateTime? startedAt}) async {}

  @override
  Future<void> addDay(ProgrammeDay day) async {
    _days.putIfAbsent(day.programmeId, () => []).add(day);
  }

  @override
  Future<void> removeDay(String dayId) async {}

  @override
  Future<void> addRule(ProgressionRule rule) async {
    _rules.putIfAbsent(rule.programmeId, () => []).add(rule);
  }

  @override
  Future<void> removeRule(String ruleId) async {}
}

class _FakeExerciseRepository implements ExerciseRepository {
  _FakeExerciseRepository(this._exercises);

  final Map<String, Exercise> _exercises;

  @override
  Future<Exercise?> getExercise(String id) async => _exercises[id];

  @override
  Future<List<Exercise>> getAllExercises() async => _exercises.values.toList();

  @override
  Future<List<Exercise>> searchExercises(String query) async => [];

  @override
  Future<List<Exercise>> getExercisesByMuscleGroup(MuscleGroup group) async =>
      _exercises.values.where((e) => e.muscleGroup == group).toList();

  @override
  Future<Exercise> createExercise(Exercise exercise) async => exercise;

  @override
  Future<Exercise> updateExercise(Exercise exercise) async => exercise;

  @override
  Future<void> deleteExercise(String id) async {}

  @override
  Stream<List<Exercise>> watchAllExercises() =>
      Stream.value(_exercises.values.toList());
}

class _FakeWorkoutTemplateRepository implements WorkoutTemplateRepository {
  _FakeWorkoutTemplateRepository(this._templates);

  final List<WorkoutTemplate> _templates;

  @override
  Stream<List<WorkoutTemplate>> watchAllTemplates() => Stream.value(_templates);

  @override
  Future<List<WorkoutTemplate>> getAllTemplates() async => _templates;

  @override
  Future<WorkoutTemplate?> getTemplate(String id) async =>
      _templates.firstWhere((t) => t.id == id);

  @override
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async =>
      template;

  @override
  Future<WorkoutTemplate> updateTemplate(WorkoutTemplate template) async =>
      template;

  @override
  Future<void> deleteTemplate(String id) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({_FakeProgrammeRepository repo, GoRouter router})> pumpEditScreen(
    WidgetTester tester, {
    required _FakeProgrammeRepository programmeRepo,
    _FakeExerciseRepository? exerciseRepo,
    _FakeWorkoutTemplateRepository? templateRepo,
    required String programmeId,
    Size surfaceSize = const Size(800, 2000),
  }) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = surfaceSize;
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(() {
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/programmes/:id',
          builder: (_, state) =>
              ProgrammeEditScreen(programmeId: state.pathParameters['id']!),
        ),
      ],
    );

    final app = ProviderScope(
      overrides: [
        programmeRepositoryProvider.overrideWithValue(programmeRepo),
        if (exerciseRepo != null)
          exerciseRepositoryProvider.overrideWithValue(exerciseRepo),
        if (templateRepo != null)
          workoutTemplateRepositoryProvider.overrideWithValue(templateRepo),
      ],
      child: MaterialApp.router(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        routerConfig: router,
      ),
    );

    await tester.pumpWidget(app);
    router.push('/programmes/$programmeId');
    await tester.pumpAndSettle();
    return (repo: programmeRepo, router: router);
  }

  group('ProgrammeEditScreen', () {
    testWidgets('shows the error state when the programme is missing',
        (tester) async {
      await pumpEditScreen(
        tester,
        programmeRepo: _FakeProgrammeRepository(),
        programmeId: 'unknown',
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets(
        'renders name + duration fields pre-filled and the schedule grid',
        (tester) async {
      const programmeId = 'p-1';
      final programme = Programme(
        id: programmeId,
        name: '5x5',
        durationWeeks: 2,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final repo = _FakeProgrammeRepository(
        programmes: {programmeId: programme},
      );
      await pumpEditScreen(
        tester,
        programmeRepo: repo,
        programmeId: programmeId,
      );

      // App bar title.
      expect(find.text('Edit Programme'), findsOneWidget);
      // Name pre-filled.
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, hasLength(2));
      expect(fields.first.controller?.text, '5x5');
      expect(fields.last.controller?.text, '2');
      // Schedule heading.
      expect(find.text('Schedule'), findsOneWidget);
      // 2 weeks × 7 days = 14 day tiles.
      final dayTiles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .where((t) => t.dense == true);
      expect(dayTiles.length, 14);
    });

    testWidgets('renders programme days with template names assigned',
        (tester) async {
      const programmeId = 'p-2';
      final programme = Programme(
        id: programmeId,
        name: 'PPL',
        durationWeeks: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final mondayDay = ProgrammeDay.create(
        programmeId: programmeId,
        weekNumber: 1,
        dayOfWeek: DateTime.monday,
        templateId: 'tpl-push',
        templateName: 'Push Day',
      );
      final repo = _FakeProgrammeRepository(
        programmes: {programmeId: programme},
        days: {
          programmeId: [mondayDay],
        },
      );
      await pumpEditScreen(
        tester,
        programmeRepo: repo,
        programmeId: programmeId,
      );

      expect(find.text('Push Day'), findsOneWidget);
    });

    testWidgets('renders progression rules when present', (tester) async {
      const programmeId = 'p-3';
      const exerciseId = 'ex-bench';
      final programme = Programme(
        id: programmeId,
        name: 'Linear progression',
        durationWeeks: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final rule = ProgressionRule.create(
        programmeId: programmeId,
        exerciseId: exerciseId,
        type: ProgressionType.fixedIncrement,
        value: 2.5,
        frequencyWeeks: 1,
      );
      final exercise = Exercise.create(
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        category: ExerciseCategory.strength,
        equipmentType: EquipmentType.barbell,
      ).copyWith(id: exerciseId);
      final repo = _FakeProgrammeRepository(
        programmes: {programmeId: programme},
        rules: {
          programmeId: [rule],
        },
      );
      await pumpEditScreen(
        tester,
        programmeRepo: repo,
        exerciseRepo: _FakeExerciseRepository({exerciseId: exercise}),
        programmeId: programmeId,
      );

      // The rule tile uses the exercise name, not the id.
      expect(find.text('Bench Press'), findsOneWidget);
      // Rule subtitle includes the type label.
      expect(find.textContaining('Fixed increment'), findsOneWidget);
    });

    testWidgets('save action persists name and duration changes',
        (tester) async {
      const programmeId = 'p-4';
      final programme = Programme(
        id: programmeId,
        name: 'Old Name',
        durationWeeks: 4,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final repo = _FakeProgrammeRepository(
        programmes: {programmeId: programme},
      );
      await pumpEditScreen(
        tester,
        programmeRepo: repo,
        programmeId: programmeId,
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'New Name');
      await tester.enterText(fields.last, '6');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.updated, hasLength(1));
      expect(repo.updated.single.name, 'New Name');
      expect(repo.updated.single.durationWeeks, 6);
    });
  });
}
