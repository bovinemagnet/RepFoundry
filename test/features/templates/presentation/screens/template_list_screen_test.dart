import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/features/templates/domain/repositories/workout_template_repository.dart';
import 'package:rep_foundry/features/templates/presentation/screens/template_list_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

class _FakeWorkoutTemplateRepository implements WorkoutTemplateRepository {
  _FakeWorkoutTemplateRepository(this._initial);

  final List<WorkoutTemplate> _initial;
  final List<String> deletedIds = [];
  final List<WorkoutTemplate> created = [];

  @override
  Stream<List<WorkoutTemplate>> watchAllTemplates() {
    return Stream<List<WorkoutTemplate>>.value(_initial);
  }

  @override
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    created.add(template);
    return template;
  }

  @override
  Future<void> deleteTemplate(String id) async {
    deletedIds.add(id);
  }

  @override
  Future<WorkoutTemplate?> getTemplate(String id) async => null;

  @override
  Future<List<WorkoutTemplate>> getAllTemplates() async => _initial;

  @override
  Future<WorkoutTemplate> updateTemplate(WorkoutTemplate template) async =>
      template;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildScreen(_FakeWorkoutTemplateRepository repo) {
    final router = GoRouter(
      initialLocation: '/templates',
      routes: [
        GoRoute(
          path: '/templates',
          builder: (_, __) => const TemplateListScreen(),
        ),
        GoRoute(
          path: '/templates/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Edit ${state.pathParameters['id']}')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        workoutTemplateRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('TemplateListScreen', () {
    testWidgets('shows the empty state when no templates exist',
        (tester) async {
      await tester.pumpWidget(buildScreen(_FakeWorkoutTemplateRepository([])));
      await tester.pumpAndSettle();

      expect(find.text('No templates yet'), findsOneWidget);
      expect(find.byIcon(Icons.view_list), findsAtLeastNWidgets(1));
    });

    testWidgets('renders one tile per template with the name', (tester) async {
      final t1 = WorkoutTemplate.create(name: 'Push Day');
      final t2 = WorkoutTemplate.create(name: 'Pull Day');
      await tester.pumpWidget(
        buildScreen(_FakeWorkoutTemplateRepository([t1, t2])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Push Day'), findsOneWidget);
      expect(find.text('Pull Day'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('shows the New Template FAB', (tester) async {
      await tester.pumpWidget(buildScreen(_FakeWorkoutTemplateRepository([])));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('tapping FAB opens the new-template dialog', (tester) async {
      await tester.pumpWidget(buildScreen(_FakeWorkoutTemplateRepository([])));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('cancelling the new-template dialog dismisses it',
        (tester) async {
      final repo = _FakeWorkoutTemplateRepository([]);
      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.created, isEmpty);
    });
  });
}
