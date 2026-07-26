import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/cardio/application/save_cardio_session_use_case.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/presentation/screens/cardio_tracking_screen.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/fake_heart_rate_service.dart';
import '../../data/fake_location_service.dart';

class _FakeExerciseRepository implements ExerciseRepository {
  _FakeExerciseRepository(this._all);

  final List<Exercise> _all;

  @override
  Future<List<Exercise>> getAllExercises() async => _all;

  @override
  Future<List<Exercise>> getExercisesByMuscleGroup(MuscleGroup group) async =>
      _all.where((e) => e.muscleGroup == group).toList();

  @override
  Future<Exercise?> getExercise(String id) async {
    for (final e in _all) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<List<Exercise>> searchExercises(String query) async => [];

  @override
  Future<Exercise> createExercise(Exercise exercise) async => exercise;

  @override
  Future<Exercise> updateExercise(Exercise exercise) async => exercise;

  @override
  Future<void> deleteExercise(String id) async {}

  @override
  Stream<List<Exercise>> watchAllExercises() => Stream.value(_all);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocationService locationService;
  late FakeHeartRateService heartRateService;
  late InMemoryCardioSessionRepository cardioRepo;
  late InMemoryWorkoutRepository workoutRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    locationService = FakeLocationService();
    heartRateService = FakeHeartRateService();
    cardioRepo = InMemoryCardioSessionRepository();
    workoutRepo = InMemoryWorkoutRepository();

    // Make the test surface tall so the lazy ListView builds the rows we
    // assert on without needing to scroll.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    locationService.dispose();
    heartRateService.dispose();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Widget buildScreen({List<Exercise> cardioExercises = const []}) {
    return ProviderScope(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(
          _FakeExerciseRepository(cardioExercises),
        ),
        cardioSessionRepositoryProvider.overrideWithValue(cardioRepo),
        saveCardioSessionUseCaseProvider.overrideWithValue(
          SaveCardioSessionUseCase(
            cardioRepository: cardioRepo,
            workoutRepository: workoutRepo,
          ),
        ),
        locationServiceProvider.overrideWithValue(locationService),
        heartRateServiceProvider.overrideWithValue(heartRateService),
        healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
        healthSyncSettingsProvider
            .overrideWith(() => HealthSyncSettingsNotifier()),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: CardioTrackingScreen(),
      ),
    );
  }

  Exercise cardioExercise(String name) => Exercise.create(
        name: name,
        category: ExerciseCategory.cardio,
        muscleGroup: MuscleGroup.cardio,
        equipmentType: EquipmentType.bodyweight,
      );

  group('CardioTrackingScreen', () {
    testWidgets('renders the cardio app bar and the Save Session button',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Cardio'), findsOneWidget);
      // The save button is hidden until elapsedSeconds > 0, so the initial
      // surface shows only the start action.
      expect(find.text('Save Session'), findsNothing);
    });

    testWidgets(
        'heart rate tile stacks the Connect action below the label on a '
        'narrow phone', (tester) async {
      // On a ~411dp phone the icon, help button and Connect button squeezed
      // the text column to ~140dp, wrapping "Heart Rate Monitor" onto two
      // lines and the subtitle onto three. Same family as issue #79: the
      // action moves below the label rather than beside it.
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize =
          const Size(720, 1480);
      binding.platformDispatcher.views.first.devicePixelRatio = 1.75;

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final title = find.text('Heart Rate Monitor');
      final connect = find.widgetWithText(FilledButton, 'Connect');
      expect(title, findsOneWidget);
      expect(connect, findsOneWidget);

      // Stacked: the Connect button starts below the title, not beside it.
      expect(
        tester.getTopLeft(connect).dy,
        greaterThan(tester.getBottomLeft(title).dy),
        reason: 'Connect must sit below the label on a narrow phone',
      );

      // With the full width available the title no longer wraps.
      expect(tester.getSize(title).height, lessThan(30));
    });

    testWidgets('heart rate tile keeps Connect beside the label when wide',
        (tester) async {
      // Default harness surface is 800dp wide — the side-by-side layout must
      // be preserved there so tablets/desktop are unchanged.
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final title = find.text('Heart Rate Monitor');
      final connect = find.widgetWithText(FilledButton, 'Connect');

      expect(
        tester.getTopLeft(connect).dx,
        greaterThan(tester.getBottomRight(title).dx),
        reason: 'Connect stays beside the label on a wide surface',
      );
    });

    testWidgets('Connect offers to enable Bluetooth before giving up',
        (tester) async {
      heartRateService.permissionGranted = false;
      heartRateService.turnOnBluetoothResult = true;

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Connect'));
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(heartRateService.turnOnBluetoothCalled, isTrue);
      expect(find.text('Heart Rate Monitors'), findsOneWidget);
    });

    testWidgets('lists cardio exercises returned by the repository',
        (tester) async {
      await tester.pumpWidget(buildScreen(cardioExercises: [
        cardioExercise('Treadmill'),
        cardioExercise('Rowing'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Treadmill'), findsOneWidget);
      expect(find.text('Rowing'), findsOneWidget);
    });

    testWidgets('initial timer reads 00:00 with no elapsed time',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // The hero timer renders zero-padded seconds at the start.
      expect(find.textContaining('00'), findsAtLeastNWidgets(1));
    });

    testWidgets('start action appears when no time has elapsed',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // `_ActionButton` for start uses the play_arrow icon when not running.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });
}
