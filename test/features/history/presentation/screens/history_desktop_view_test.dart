import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/core/responsive/layout_mode.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/history/presentation/screens/history_list_screen.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// At desktop widths the History screen swaps the mobile tabbed layout for the
/// master–detail power layout (session list + detail pane), with no bottom
/// tabs.
/// An [AsyncNotifier] override that resolves the active client to the fixed
/// "Me" client, without touching the database.
class _FixedActiveClientNotifier extends ActiveClientNotifier {
  _FixedActiveClientNotifier(this._client);

  final Client _client;

  @override
  Future<Client> build() async => _client;
}

final _meClient = Client(
  id: kSelfClientId,
  name: 'Me',
  colour: 0xFF4CAF50,
  notes: null,
  isSelf: true,
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
  deletedAt: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> useDesktopViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildScreen(
    InMemoryWorkoutRepository workoutRepo,
    InMemoryExerciseRepository exerciseRepo, {
    LayoutMode mode = LayoutMode.auto,
  }) {
    return ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(workoutRepo),
        exerciseRepositoryProvider.overrideWithValue(exerciseRepo),
        activeClientProvider.overrideWith(
          () => _FixedActiveClientNotifier(_meClient),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        builder: (context, child) => LayoutModeScope(mode: mode, child: child!),
        home: const HistoryListScreen(),
      ),
    );
  }

  Future<void> seed(InMemoryWorkoutRepository repo) async {
    final now = DateTime.utc(2026, 6, 1, 9);
    await repo.createWorkout(
      Workout(
        id: 'w1',
        startedAt: now,
        completedAt: now.add(const Duration(minutes: 45)),
        clientId: kSelfClientId,
        updatedAt: now,
      ),
    );
    await repo.addSet(
      WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 1,
        weight: 40,
        reps: 10,
      ),
    );
  }

  testWidgets('renders the master-detail layout at desktop width',
      (tester) async {
    await useDesktopViewport(tester);

    final workoutRepo = InMemoryWorkoutRepository();
    final exerciseRepo = InMemoryExerciseRepository();
    await seed(workoutRepo);

    await tester.pumpWidget(buildScreen(workoutRepo, exerciseRepo));
    await tester.pumpAndSettle();

    // Desktop layout: no mobile tab shell, a desktop top bar, and the detail
    // pane KPI strip (KineticStatTile uppercases its label).
    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Training History'), findsOneWidget);
    expect(find.text('VOLUME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forced desktop on a narrow tablet width does not overflow',
      (tester) async {
    // A 640px-wide forced-desktop view is the tight end of the range; the
    // master list and KPI strip must reflow rather than overflow.
    tester.view.physicalSize = const Size(640, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workoutRepo = InMemoryWorkoutRepository();
    final exerciseRepo = InMemoryExerciseRepository();
    await seed(workoutRepo);

    await tester.pumpWidget(
      buildScreen(workoutRepo, exerciseRepo, mode: LayoutMode.desktop),
    );
    await tester.pumpAndSettle();

    expect(find.text('Training History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
