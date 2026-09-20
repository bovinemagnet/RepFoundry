import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/core/widgets/kinetic.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/presentation/widgets/cardio_history_view.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

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

  late InMemoryWorkoutRepository workouts;
  late InMemoryCardioSessionRepository cardio;
  late InMemoryExerciseRepository exercises;
  late Exercise run;
  late Exercise bike;
  final visited = <String>[];

  setUp(() async {
    visited.clear();
    workouts = InMemoryWorkoutRepository();
    cardio = InMemoryCardioSessionRepository();
    exercises = InMemoryExerciseRepository();
    run = await exercises.createExercise(Exercise.create(
      name: 'Outdoor Run',
      category: ExerciseCategory.cardio,
      muscleGroup: MuscleGroup.cardio,
      equipmentType: EquipmentType.bodyweight,
    ));
    bike = await exercises.createExercise(Exercise.create(
      name: 'Stationary Bike',
      category: ExerciseCategory.cardio,
      muscleGroup: MuscleGroup.cardio,
      equipmentType: EquipmentType.machine,
    ));
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2600);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Future<void> seed(String id, DateTime at, Exercise sport,
      {double? distance = 5000, int duration = 1800, int? hr = 150}) async {
    await workouts.createWorkout(Workout(
      id: 'w-$id',
      startedAt: at,
      completedAt: at.add(Duration(seconds: duration)),
      clientId: kSelfClientId,
      updatedAt: at,
    ));
    await cardio.createSession(CardioSession(
      id: id,
      workoutId: 'w-$id',
      exerciseId: sport.id,
      durationSeconds: duration,
      distanceMeters: distance,
      avgHeartRate: hr,
      clientId: kSelfClientId,
      updatedAt: at,
    ));
  }

  Finder inCard(String text) =>
      find.descendant(of: find.byType(Card), matching: find.text(text));

  Widget buildView() {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: CardioHistoryView()),
      ),
      GoRoute(
        path: '/history/:id',
        builder: (_, state) {
          visited.add(state.pathParameters['id']!);
          return const Scaffold(body: Text('detail'));
        },
      ),
    ]);
    return ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(workouts),
        cardioSessionRepositoryProvider.overrideWithValue(cardio),
        exerciseRepositoryProvider.overrideWithValue(exercises),
        activeClientProvider
            .overrideWith(() => _FixedActiveClientNotifier(_meClient)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
      ),
    );
  }

  testWidgets('shows the empty state when nothing is saved', (tester) async {
    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    expect(find.text('No cardio sessions yet'), findsOneWidget);
  });

  testWidgets('lists sessions newest first with sport and stats',
      (tester) async {
    final now = DateTime.now();
    await seed('old', now.subtract(const Duration(days: 9)), bike,
        distance: null, hr: null, duration: 2400);
    await seed('new', now.subtract(const Duration(days: 1)), run,
        distance: 5210, duration: 1864, hr: 152);

    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();

    expect(inCard('Outdoor Run'), findsOneWidget);
    expect(inCard('Stationary Bike'), findsOneWidget);
    expect(find.text('31:04'), findsOneWidget);
    expect(find.text('5.21'), findsOneWidget);
    expect(find.text('5:58'), findsOneWidget); // pace min/km
    expect(find.text('152'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('LAST WEEK'), findsOneWidget);
    final runY = tester.getTopLeft(inCard('Outdoor Run')).dy;
    final bikeY = tester.getTopLeft(inCard('Stationary Bike')).dy;
    expect(runY, lessThan(bikeY));
  });

  testWidgets('tapping a session opens its workout in History', (tester) async {
    await seed('a', DateTime.now().subtract(const Duration(days: 1)), run);

    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();
    await tester.tap(inCard('Outdoor Run'));
    await tester.pumpAndSettle();

    expect(visited, ['w-a']);
  });

  testWidgets('sport chips filter the list', (tester) async {
    final now = DateTime.now();
    await seed('r', now.subtract(const Duration(days: 1)), run);
    await seed('b', now.subtract(const Duration(days: 2)), bike,
        distance: null);

    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();
    // The chip row carries one chip per sport plus "All sports"; the list
    // shows the sport names too, so the chip is the first match.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Stationary Bike'));
    await tester.pumpAndSettle();

    expect(inCard('Outdoor Run'), findsNothing);
    expect(inCard('Stationary Bike'), findsOneWidget);
  });

  testWidgets('Progress shows the weekly distance and pace charts',
      (tester) async {
    final now = DateTime.now();
    await seed('a', now.subtract(const Duration(days: 1)), run,
        distance: 5000, duration: 1500);
    await seed('b', now.subtract(const Duration(days: 8)), run,
        distance: 8000, duration: 2880);

    await tester.pumpWidget(buildView());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();

    expect(find.text('WEEKLY DISTANCE'), findsOneWidget);
    expect(find.text('AVERAGE PACE'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('13.0'), findsOneWidget); // km over the period
    expect(
      find.descendant(
        of: find.byType(KineticStatTile),
        matching: find.text('5:00'),
      ),
      findsOneWidget,
      reason: 'best pace',
    );
  });
}
