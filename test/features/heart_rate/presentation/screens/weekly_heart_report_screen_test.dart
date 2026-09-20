import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_heart_rate_sample.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/zone_configuration_provider.dart';
import 'package:rep_foundry/features/heart_rate/presentation/screens/weekly_heart_report_screen.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

class _FixedActiveClientNotifier extends ActiveClientNotifier {
  _FixedActiveClientNotifier(this._client);

  final Client _client;

  @override
  Future<Client> build() async => _client;
}

final _me = Client(
  id: kSelfClientId,
  name: 'Me',
  colour: 0xFF4CAF50,
  notes: null,
  isSelf: true,
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
  deletedAt: null,
);

const _zones = ZoneConfiguration(
  method: ZoneMethod.percentOfEstimatedMax,
  reliability: ZoneReliability.medium,
  maxHr: 200,
  reason: 'test',
  zones: [
    CalculatedZone(
        zoneNumber: 2,
        label: 'Z2',
        effortLabel: 'Light',
        descriptiveLabel: 'Fat burn',
        lowerBound: 0,
        upperBound: 140,
        color: 0xFF10B981),
    CalculatedZone(
        zoneNumber: 4,
        label: 'Z4',
        effortLabel: 'Hard',
        descriptiveLabel: 'Threshold',
        lowerBound: 140,
        color: 0xFFC6FF3D),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryWorkoutRepository workouts;
  late InMemoryCardioSessionRepository cardio;

  setUp(() {
    workouts = InMemoryWorkoutRepository();
    cardio = InMemoryCardioSessionRepository();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(workouts),
        cardioSessionRepositoryProvider.overrideWithValue(cardio),
        exerciseRepositoryProvider
            .overrideWithValue(InMemoryExerciseRepository()),
        zoneConfigurationProvider.overrideWithValue(_zones),
        activeClientProvider
            .overrideWith(() => _FixedActiveClientNotifier(_me)),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: WeeklyHeartReportScreen(),
      ),
    );
  }

  testWidgets('shows an empty state when no heart-rate data was recorded',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Weekly Heart Report'), findsOneWidget);
    expect(find.text('No heart rate data this week'), findsOneWidget);
  });

  testWidgets('summarises the week with sessions, peaks and time in zone',
      (tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await workouts.createWorkout(Workout(
      id: 'w-run',
      startedAt: yesterday,
      completedAt: yesterday.add(const Duration(minutes: 30)),
      clientId: kSelfClientId,
      updatedAt: yesterday,
    ));
    await cardio.createSession(CardioSession(
      id: 'run',
      workoutId: 'w-run',
      exerciseId: '16',
      durationSeconds: 1800,
      clientId: kSelfClientId,
      updatedAt: yesterday,
    ));
    await cardio.saveHeartRateSamples('run', [
      for (var i = 0; i < 120; i++)
        CardioHeartRateSample(
            timestamp: yesterday.add(Duration(seconds: i)),
            bpm: i < 60 ? 130 : 160),
    ]);
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    await workouts.createWorkout(Workout(
      id: 'w-lift',
      startedAt: threeDaysAgo,
      completedAt: threeDaysAgo.add(const Duration(minutes: 45)),
      clientId: kSelfClientId,
      updatedAt: threeDaysAgo,
    ));
    await workouts.addSet(WorkoutSet.create(
      workoutId: 'w-lift',
      exerciseId: '1',
      setOrder: 1,
      weight: 60,
      reps: 8,
      avgHeartRate: 118,
      peakHeartRate: 142,
    ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget); // sessions
    expect(find.text('160'), findsWidgets); // peak
    expect(find.text('Treadmill'), findsOneWidget);
    expect(find.text('Strength workout'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('TIME IN ZONE'), findsOneWidget);
    expect(find.textContaining('Z2'), findsWidgets);
    expect(find.text('1m'), findsNWidgets(2)); // 60 s in each zone
  });
}
