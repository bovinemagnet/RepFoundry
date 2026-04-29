import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';
import 'package:rep_foundry/features/programmes/domain/repositories/programme_repository.dart';
import 'package:rep_foundry/features/programmes/presentation/screens/programme_list_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

class _FakeProgrammeRepository implements ProgrammeRepository {
  _FakeProgrammeRepository(this._initial);

  final List<Programme> _initial;
  final List<String> deletedIds = [];
  final List<Programme> created = [];

  @override
  Stream<List<Programme>> watchAllProgrammes() {
    return Stream<List<Programme>>.value(_initial);
  }

  @override
  Future<Programme> createProgramme(Programme programme) async {
    created.add(programme);
    return programme;
  }

  @override
  Future<void> deleteProgramme(String id) async {
    deletedIds.add(id);
  }

  @override
  Future<Programme?> getProgramme(String id) async => null;

  @override
  Future<List<Programme>> getAllProgrammes() async => _initial;

  @override
  Future<Programme> updateProgramme(Programme programme) async => programme;

  @override
  Future<void> markProgrammeStarted(String id, {DateTime? startedAt}) async {}

  @override
  Future<void> addDay(ProgrammeDay day) async {}

  @override
  Future<void> removeDay(String dayId) async {}

  @override
  Future<List<ProgrammeDay>> getDaysForProgramme(String programmeId) async =>
      [];

  @override
  Future<void> addRule(ProgressionRule rule) async {}

  @override
  Future<void> removeRule(String ruleId) async {}

  @override
  Future<List<ProgressionRule>> getRulesForProgramme(
          String programmeId) async =>
      [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildScreen(_FakeProgrammeRepository repo) {
    final router = GoRouter(
      initialLocation: '/programmes',
      routes: [
        GoRoute(
          path: '/programmes',
          builder: (_, __) => const ProgrammeListScreen(),
        ),
        GoRoute(
          path: '/programmes/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Edit ${state.pathParameters['id']}')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        programmeRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('ProgrammeListScreen', () {
    testWidgets('shows the empty state when no programmes exist',
        (tester) async {
      await tester.pumpWidget(buildScreen(_FakeProgrammeRepository([])));
      await tester.pumpAndSettle();

      expect(find.text('No programmes yet'), findsOneWidget);
      expect(
          find.byIcon(Icons.calendar_month_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('renders one tile per programme with the name', (tester) async {
      final p1 = Programme.create(name: '5x5 StrongLifts', durationWeeks: 12);
      final p2 = Programme.create(name: 'PPL Split', durationWeeks: 8);
      await tester.pumpWidget(buildScreen(_FakeProgrammeRepository([p1, p2])));
      await tester.pumpAndSettle();

      expect(find.text('5x5 StrongLifts'), findsOneWidget);
      expect(find.text('PPL Split'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('shows the New Programme FAB', (tester) async {
      await tester.pumpWidget(buildScreen(_FakeProgrammeRepository([])));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('tapping FAB opens the new-programme dialog with two fields',
        (tester) async {
      await tester.pumpWidget(buildScreen(_FakeProgrammeRepository([])));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      // One for name, one for duration.
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Create is a no-op when name is empty', (tester) async {
      final repo = _FakeProgrammeRepository([]);
      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      // Tap Create with no input — dialog should remain open.
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(repo.created, isEmpty);
    });
  });
}
