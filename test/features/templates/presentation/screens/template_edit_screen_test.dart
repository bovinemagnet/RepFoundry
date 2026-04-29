import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/features/templates/domain/repositories/workout_template_repository.dart';
import 'package:rep_foundry/features/templates/presentation/screens/template_edit_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

class _FakeWorkoutTemplateRepository implements WorkoutTemplateRepository {
  _FakeWorkoutTemplateRepository(this._templates);

  final Map<String, WorkoutTemplate> _templates;
  final List<WorkoutTemplate> updated = [];

  @override
  Future<WorkoutTemplate?> getTemplate(String id) async => _templates[id];

  @override
  Future<WorkoutTemplate> updateTemplate(WorkoutTemplate template) async {
    updated.add(template);
    _templates[template.id] = template;
    return template;
  }

  @override
  Stream<List<WorkoutTemplate>> watchAllTemplates() =>
      Stream.value(_templates.values.toList());

  @override
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async =>
      template;

  @override
  Future<void> deleteTemplate(String id) async {}

  @override
  Future<List<WorkoutTemplate>> getAllTemplates() async =>
      _templates.values.toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ({Widget app, GoRouter router}) buildScreen({
    required _FakeWorkoutTemplateRepository repo,
  }) {
    // Start on a placeholder root so context.pop() at save time has somewhere
    // to go.  The test then navigates to the edit page via router.push().
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/templates/:id',
          builder: (_, state) =>
              TemplateEditScreen(templateId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/exercises',
          builder: (_, __) => const Scaffold(body: Text('Exercises picker')),
        ),
      ],
    );

    return (
      app: ProviderScope(
        overrides: [
          workoutTemplateRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          routerConfig: router,
        ),
      ),
      router: router,
    );
  }

  Future<({_FakeWorkoutTemplateRepository repo, GoRouter router})>
      pumpEditScreen(
    WidgetTester tester, {
    required _FakeWorkoutTemplateRepository repo,
    required String templateId,
  }) async {
    final scaffolding = buildScreen(repo: repo);
    await tester.pumpWidget(scaffolding.app);
    scaffolding.router.push('/templates/$templateId');
    await tester.pumpAndSettle();
    return (repo: repo, router: scaffolding.router);
  }

  group('TemplateEditScreen', () {
    testWidgets('shows the error state when the template is missing',
        (tester) async {
      final repo = _FakeWorkoutTemplateRepository({});
      await pumpEditScreen(tester, repo: repo, templateId: 'unknown');

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'renders the empty exercises hint and Save action when template loads',
        (tester) async {
      final template = WorkoutTemplate.create(name: 'Push Day');
      final repo = _FakeWorkoutTemplateRepository({template.id: template});
      await pumpEditScreen(tester, repo: repo, templateId: template.id);

      // Empty state copy is "Add Exercise" — same string as the FAB label and
      // the empty hint, so we expect at least 2 occurrences.
      expect(find.text('Add Exercise'), findsAtLeastNWidgets(2));
      // The Save action sits in the AppBar.
      expect(find.text('Save'), findsOneWidget);
      // Template name field is pre-filled.
      final nameField = tester.widget<TextField>(find.byType(TextField).first);
      expect(nameField.controller?.text, 'Push Day');
    });

    testWidgets('renders one tile per exercise when the template has them',
        (tester) async {
      const templateId = 'tpl-1';
      final template = WorkoutTemplate(
        id: templateId,
        name: 'Pull Day',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        exercises: [
          TemplateExercise(
            id: 'e1',
            templateId: templateId,
            exerciseId: 'ex-pull-up',
            exerciseName: 'Pull-up',
            targetSets: 4,
            targetReps: 8,
            orderIndex: 0,
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
          TemplateExercise(
            id: 'e2',
            templateId: templateId,
            exerciseId: 'ex-row',
            exerciseName: 'Bent-over Row',
            targetSets: 3,
            targetReps: 10,
            orderIndex: 1,
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );
      final repo = _FakeWorkoutTemplateRepository({templateId: template});
      await pumpEditScreen(tester, repo: repo, templateId: templateId);

      expect(find.text('Pull-up'), findsOneWidget);
      expect(find.text('Bent-over Row'), findsOneWidget);
      expect(find.text('Drag to reorder exercises'), findsOneWidget);
      // One drag handle per exercise.
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));
      // One delete button per exercise.
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('tapping Save calls updateTemplate with the edited name',
        (tester) async {
      final template = WorkoutTemplate.create(name: 'Old Name');
      final repo = _FakeWorkoutTemplateRepository({template.id: template});
      await pumpEditScreen(tester, repo: repo, templateId: template.id);

      // Replace the name.
      await tester.enterText(find.byType(TextField).first, 'New Name');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.updated, hasLength(1));
      expect(repo.updated.single.name, 'New Name');
    });

    testWidgets('removing an exercise rebuilds the list without it',
        (tester) async {
      const templateId = 'tpl-2';
      final template = WorkoutTemplate(
        id: templateId,
        name: 'Legs',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        exercises: [
          TemplateExercise(
            id: 'e1',
            templateId: templateId,
            exerciseId: 'ex-squat',
            exerciseName: 'Back Squat',
            targetSets: 5,
            targetReps: 5,
            orderIndex: 0,
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
          TemplateExercise(
            id: 'e2',
            templateId: templateId,
            exerciseId: 'ex-rdl',
            exerciseName: 'Romanian Deadlift',
            targetSets: 3,
            targetReps: 10,
            orderIndex: 1,
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );
      final repo = _FakeWorkoutTemplateRepository({templateId: template});
      await pumpEditScreen(tester, repo: repo, templateId: templateId);

      expect(find.text('Back Squat'), findsOneWidget);
      expect(find.text('Romanian Deadlift'), findsOneWidget);

      // Tap the first delete button — removes "Back Squat".
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Back Squat'), findsNothing);
      expect(find.text('Romanian Deadlift'), findsOneWidget);
    });
  });
}
