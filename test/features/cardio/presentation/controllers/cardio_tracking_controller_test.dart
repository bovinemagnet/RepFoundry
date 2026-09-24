import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rep_foundry/features/cardio/application/save_cardio_session_use_case.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/data/heart_rate_service.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/cardio/presentation/controllers/cardio_tracking_controller.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';

import '../../data/fake_foreground_session_service.dart';
import '../../data/fake_heart_rate_service.dart';
import '../../data/fake_location_service.dart';

/// Simulates a database/platform failure that is not a validation error.
class _ThrowingSaveUseCase extends SaveCardioSessionUseCase {
  _ThrowingSaveUseCase()
      : super(
          cardioRepository: InMemoryCardioSessionRepository(),
          workoutRepository: InMemoryWorkoutRepository(),
        );

  @override
  Future<SaveCardioSessionResult> execute(SaveCardioSessionInput input) async {
    throw StateError('disk full');
  }
}

/// Records outbound health-store writes instead of touching the platform.
class _RecordingHealthSyncService extends HealthSyncService {
  final List<({DateTime start, DateTime end})> workouts = [];
  final List<({int bpm, DateTime at})> heartRates = [];

  @override
  Future<bool> writeWorkout({
    required DateTime startTime,
    required DateTime endTime,
    required int totalCalories,
    bool isCardio = false,
    double? distanceMeters,
  }) async {
    workouts.add((start: startTime, end: endTime));
    return true;
  }

  @override
  Future<bool> writeHeartRate({
    required int bpm,
    required DateTime dateTime,
  }) async {
    heartRates.add((bpm: bpm, at: dateTime));
    return true;
  }
}

class _FixedActiveClientNotifier extends ActiveClientNotifier {
  _FixedActiveClientNotifier(this._client);

  final Client _client;

  @override
  Future<Client> build() async => _client;

  @override
  Future<void> setActive(Client client) async {
    state = AsyncData(client);
  }
}

void main() {
  late InMemoryCardioSessionRepository cardioRepo;
  late InMemoryWorkoutRepository workoutRepo;
  late SaveCardioSessionUseCase useCase;
  late FakeLocationService locationService;
  late FakeHeartRateService heartRateService;
  late FakeForegroundSessionService foregroundService;
  late ProviderContainer container;
  late CardioTrackingController controller;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    cardioRepo = InMemoryCardioSessionRepository();
    workoutRepo = InMemoryWorkoutRepository();
    useCase = SaveCardioSessionUseCase(
      cardioRepository: cardioRepo,
      workoutRepository: workoutRepo,
    );
    locationService = FakeLocationService();
    heartRateService = FakeHeartRateService();
    foregroundService = FakeForegroundSessionService();
    container = ProviderContainer(
      overrides: [
        cardioSessionRepositoryProvider.overrideWithValue(cardioRepo),
        saveCardioSessionUseCaseProvider.overrideWithValue(useCase),
        locationServiceProvider.overrideWithValue(locationService),
        heartRateServiceProvider.overrideWithValue(heartRateService),
        foregroundSessionServiceProvider.overrideWithValue(foregroundService),
        healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
        healthSyncSettingsProvider
            .overrideWith(() => HealthSyncSettingsNotifier()),
      ],
    );
    controller = container.read(cardioTrackingProvider.notifier);
  });

  tearDown(() {
    container.dispose();
    locationService.dispose();
    heartRateService.dispose();
  });

  group('CardioTrackingController', () {
    group('timer state transitions', () {
      test('initial state is not running with zero elapsed', () {
        expect(controller.state.isRunning, isFalse);
        expect(controller.state.elapsedSeconds, 0);
      });

      test('start() sets isRunning to true', () {
        controller.start();
        expect(controller.state.isRunning, isTrue);
      });

      test('pause() sets isRunning to false', () {
        controller.start();
        controller.pause();
        expect(controller.state.isRunning, isFalse);
      });

      test('reset() clears elapsed but preserves exercise selection', () async {
        await controller.selectExercise('e1', 'Treadmill');
        controller.start();
        controller.reset();

        expect(controller.state.isRunning, isFalse);
        expect(controller.state.elapsedSeconds, 0);
        expect(controller.state.selectedExerciseId, 'e1');
        expect(controller.state.selectedExerciseName, 'Treadmill');
      });

      test('start() is idempotent when already running', () {
        controller.start();
        controller.start();
        expect(controller.state.isRunning, isTrue);
      });

      test('elapsed time follows the wall clock, not tick count', () {
        fakeAsync((async) {
          controller.start();
          async.elapse(const Duration(seconds: 5));
          expect(controller.state.elapsedSeconds, 5);

          // Simulate OS suspension: wall time passes but no ticks fire.
          async.elapseBlocking(const Duration(minutes: 10));
          // The next tick after resume corrects the display.
          async.elapse(const Duration(seconds: 1));
          expect(controller.state.elapsedSeconds, 5 + 600 + 1);
          controller.reset();
        });
      });

      test('pause() freezes elapsed and resume accumulates correctly', () {
        fakeAsync((async) {
          controller.start();
          async.elapse(const Duration(seconds: 10));
          controller.pause();
          // Time passing while paused must not count.
          async.elapse(const Duration(minutes: 5));
          expect(controller.state.elapsedSeconds, 10);

          controller.start();
          async.elapse(const Duration(seconds: 20));
          expect(controller.state.elapsedSeconds, 30);
          controller.reset();
        });
      });

      test('reset() zeroes the wall-clock accumulator', () {
        fakeAsync((async) {
          controller.start();
          async.elapse(const Duration(seconds: 30));
          controller.reset();
          controller.start();
          async.elapse(const Duration(seconds: 3));
          expect(controller.state.elapsedSeconds, 3);
          controller.reset();
        });
      });

      test('save() persists wall-clock duration even without a recent tick',
          () {
        fakeAsync((async) {
          controller.selectExercise('e1', 'Treadmill');
          async.flushMicrotasks();

          controller.start();
          async.elapse(const Duration(seconds: 5));
          // Suspension right before save: no tick fires for 10 minutes.
          async.elapseBlocking(const Duration(minutes: 10));
          controller.save(distanceMeters: 1000);
          async.flushMicrotasks();

          late List<CardioSession> sessions;
          cardioRepo
              .getSessionsForExercise('e1', kSelfClientId)
              .then((s) => sessions = s);
          async.flushMicrotasks();
          expect(sessions.single.durationSeconds, 605);
        });
      });
    });

    group('selectExercise', () {
      test('sets exercise id and name', () async {
        await controller.selectExercise('e1', 'Treadmill');
        expect(controller.state.selectedExerciseId, 'e1');
        expect(controller.state.selectedExerciseName, 'Treadmill');
      });

      test('loads ghost session when previous session exists', () async {
        final session = CardioSession.create(
          workoutId: 'w1',
          exerciseId: 'e1',
          durationSeconds: 1800,
          distanceMeters: 5000,
          avgHeartRate: 145,
        );
        await cardioRepo.createSession(session);

        await controller.selectExercise('e1', 'Treadmill');

        expect(controller.state.lastSession, isNotNull);
        expect(controller.state.lastSession!.durationSeconds, 1800);
        expect(controller.state.lastSession!.distanceMeters, 5000);
      });

      test('sets lastSession to null when no previous session', () async {
        await controller.selectExercise('e2', 'Bike');
        expect(controller.state.lastSession, isNull);
      });
    });

    group('sharing the monitor with the heart-rate panel', () {
      // The HR service is a singleton shared with the Heart Rate tab. A
      // strap connected there must show as connected here too, otherwise
      // cardio offers "Connect" for a device that is already streaming.
      test('adopts a connection that already exists when built', () async {
        await heartRateService.connectToDevice('strap');
        heartRateService.emitConnectionState(HrConnectionState.connected);
        container.dispose();
        container = ProviderContainer(
          overrides: [
            cardioSessionRepositoryProvider.overrideWithValue(cardioRepo),
            saveCardioSessionUseCaseProvider.overrideWithValue(useCase),
            locationServiceProvider.overrideWithValue(locationService),
            heartRateServiceProvider.overrideWithValue(heartRateService),
            foregroundSessionServiceProvider
                .overrideWithValue(foregroundService),
            healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
            healthSyncSettingsProvider
                .overrideWith(() => HealthSyncSettingsNotifier()),
          ],
        );
        controller = container.read(cardioTrackingProvider.notifier);

        expect(controller.state.hrConnected, isTrue);

        heartRateService.emitHeartRate(128);
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.currentHeartRate, 128);
      });

      test('picks up a connection made later from the panel', () async {
        expect(controller.state.hrConnected, isFalse);

        // What the real service does when the panel connects the strap.
        await heartRateService.connectToDevice('strap');
        heartRateService.emitConnectionState(HrConnectionState.connected);
        await Future<void>.delayed(Duration.zero);

        expect(controller.state.hrConnected, isTrue);
        heartRateService.emitHeartRate(131);
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.currentHeartRate, 131);
      });

      test('the monitor stays connected after a session is saved', () async {
        await controller.selectExercise('e1', 'Treadmill');
        await controller.connectHeartRate('dev', 'Strap');
        controller.start();
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();

        await controller.save();

        expect(controller.state.savedSuccessfully, isTrue);
        expect(controller.state.hrConnected, isTrue);
        heartRateService.emitHeartRate(120);
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.currentHeartRate, 120);
      });

      test('a disconnect made elsewhere clears the connection here', () async {
        await heartRateService.connectToDevice('strap');
        heartRateService.emitConnectionState(HrConnectionState.connected);
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.hrConnected, isTrue);

        heartRateService.simulateDisconnection();
        heartRateService.emitConnectionState(HrConnectionState.disconnected);
        await Future<void>.delayed(Duration.zero);

        expect(controller.state.hrConnected, isFalse);
        expect(controller.state.currentHeartRate, isNull);
      });
    });

    group('review after save', () {
      test('the saved workout id is exposed so the UI can link to it',
          () async {
        await controller.selectExercise('e1', 'Run');
        controller.start();
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();

        await controller.save();

        final history = await workoutRepo.getWorkoutHistory(
          clientId: kSelfClientId,
        );
        expect(controller.state.savedWorkoutId, history.single.id);
      });
    });

    group('recordings', () {
      test('the saved session carries the GPS track that was received',
          () async {
        await controller.selectExercise('e1', 'Run');
        await controller.toggleGps();
        controller.start();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        locationService.emitPosition(latitude: 51.5074, longitude: -0.1278);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        locationService.emitPosition(latitude: 51.5080, longitude: -0.1290);
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();

        await controller.save();
        expect(controller.state.error, isNull);

        final session = (await cardioRepo.getAllSessions(kSelfClientId)).single;
        final points = await cardioRepo.getTrackPoints(session.id);
        expect(points.map((p) => p.latitude), [51.5074, 51.5080]);
        expect(points.map((p) => p.longitude), [-0.1278, -0.1290]);
        expect(points.first.timestamp.isBefore(points.last.timestamp), isTrue);
      });

      test('the saved session carries the heart-rate readings received',
          () async {
        await controller.selectExercise('e1', 'Run');
        await controller.connectHeartRate('dev', 'Strap');
        controller.start();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        heartRateService.emitHeartRate(131);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        heartRateService.emitHeartRate(142);
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();

        await controller.save();
        expect(controller.state.error, isNull);

        final session = (await cardioRepo.getAllSessions(kSelfClientId)).single;
        final samples = await cardioRepo.getHeartRateSamples(session.id);
        expect(samples.map((s) => s.bpm), [131, 142]);
      });

      test('recordings from a previous session do not leak into the next',
          () async {
        await controller.selectExercise('e1', 'Run');
        await controller.toggleGps();
        controller.start();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        locationService.emitPosition(latitude: 51.5, longitude: -0.1);
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();
        await controller.save();

        await controller.selectExercise('e1', 'Run');
        controller.start();
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();
        await controller.save();

        final sessions = await cardioRepo.getAllSessions(kSelfClientId);
        expect(sessions, hasLength(2));
        final second = sessions.last;
        expect(await cardioRepo.getTrackPoints(second.id), isEmpty);
      });
    });

    group('session ownership', () {
      test('a session belongs to the client active when it started', () async {
        final alice = Client.create(name: 'Alice', colour: 0);
        final bob = Client.create(name: 'Bob', colour: 1);
        final c = ProviderContainer(
          overrides: [
            cardioSessionRepositoryProvider.overrideWithValue(cardioRepo),
            saveCardioSessionUseCaseProvider.overrideWithValue(useCase),
            locationServiceProvider.overrideWithValue(locationService),
            heartRateServiceProvider.overrideWithValue(heartRateService),
            foregroundSessionServiceProvider
                .overrideWithValue(foregroundService),
            healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
            healthSyncSettingsProvider
                .overrideWith(() => HealthSyncSettingsNotifier()),
            activeClientProvider
                .overrideWith(() => _FixedActiveClientNotifier(alice)),
          ],
        );
        addTearDown(c.dispose);
        c.listen(activeClientProvider, (_, __) {});
        await c.read(activeClientProvider.future);
        final controller = c.read(cardioTrackingProvider.notifier);

        await controller.selectExercise('e1', 'Treadmill');
        controller.start();
        expect(controller.state.sessionClientId, alice.id);
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        // The coach switches the roster to Bob while Alice is still running.
        await c.read(activeClientProvider.notifier).setActive(bob);
        controller.pause();
        await controller.save();

        final sessions =
            await cardioRepo.getSessionsForExercise('e1', alice.id);
        expect(sessions, hasLength(1));
        expect(await workoutRepo.getWorkoutHistory(clientId: bob.id), isEmpty);
      });
    });

    group('health store writes on save', () {
      late _RecordingHealthSyncService health;

      ProviderContainer healthContainer({Client? activeClient}) {
        health = _RecordingHealthSyncService();
        final c = ProviderContainer(
          overrides: [
            cardioSessionRepositoryProvider.overrideWithValue(cardioRepo),
            saveCardioSessionUseCaseProvider.overrideWithValue(useCase),
            locationServiceProvider.overrideWithValue(locationService),
            heartRateServiceProvider.overrideWithValue(heartRateService),
            foregroundSessionServiceProvider
                .overrideWithValue(foregroundService),
            healthSyncServiceProvider.overrideWithValue(health),
            healthSyncSettingsProvider
                .overrideWith(() => HealthSyncSettingsNotifier()),
            if (activeClient != null)
              activeClientProvider
                  .overrideWith(() => _FixedActiveClientNotifier(activeClient)),
          ],
        );
        addTearDown(c.dispose);
        return c;
      }

      /// The settings notifier reads SharedPreferences asynchronously on
      /// first access, so touch it and let that load land.
      Future<CardioTrackingController> controllerOf(ProviderContainer c) async {
        c.read(healthSyncSettingsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return c.read(cardioTrackingProvider.notifier);
      }

      Future<void> runSession(CardioTrackingController c) async {
        await c.selectExercise('e1', 'Treadmill');
        await c.connectHeartRate('dev', 'Strap');
        c.start();
        await Future<void>.delayed(const Duration(milliseconds: 600));
        heartRateService.emitHeartRate(140);
        await Future<void>.delayed(const Duration(milliseconds: 600));
        heartRateService.emitHeartRate(150);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        c.pause();
        await c.save();
        expect(c.state.error, isNull);
      }

      test('writes the session heart-rate samples when the toggle is on',
          () async {
        SharedPreferences.setMockInitialValues({
          'health_sync_enabled': true,
          'health_sync_write_heart_rate': true,
        });
        final c = healthContainer();
        final controller = await controllerOf(c);

        await runSession(controller);

        // The two readings are well under the 10 s export spacing, so only
        // the first is written; selectSamplesForExport covers the spacing.
        expect(health.heartRates.map((s) => s.bpm), [140]);
        expect(health.workouts, hasLength(1));
      });

      test('writes no heart-rate samples when the toggle is off', () async {
        SharedPreferences.setMockInitialValues({
          'health_sync_enabled': true,
          'health_sync_write_heart_rate': false,
        });
        final c = healthContainer();
        final controller = await controllerOf(c);

        await runSession(controller);

        expect(health.heartRates, isEmpty);
        expect(health.workouts, hasLength(1));
      });

      test('writes nothing to the health store for another client\'s session',
          () async {
        SharedPreferences.setMockInitialValues({
          'health_sync_enabled': true,
          'health_sync_write_heart_rate': true,
        });
        final alice = Client.create(name: 'Alice', colour: 0);
        final c = healthContainer(activeClient: alice);
        final controller = await controllerOf(c);

        await runSession(controller);

        expect(health.workouts, isEmpty,
            reason: 'the coach\'s health account must not receive a '
                'client\'s workout');
        expect(health.heartRates, isEmpty);
      });
    });

    group('save()', () {
      test('reports why it did not save when no exercise is selected',
          () async {
        controller.start();
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();

        await controller.save();

        expect(controller.state.savedSuccessfully, isFalse);
        expect(controller.state.error, isNotNull,
            reason: 'a silent no-op looks like a lost session');
        expect(controller.state.elapsedSeconds, greaterThan(0),
            reason: 'the session must survive so the user can fix it');
      });

      test('does nothing when elapsed is zero', () async {
        await controller.selectExercise('e1', 'Treadmill');
        await controller.save();
        expect(controller.state.savedSuccessfully, isFalse);
      });

      test('saves session and resets state on success', () async {
        await controller.selectExercise('e1', 'Treadmill');
        controller.start();
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();

        expect(controller.state.elapsedSeconds, greaterThan(0));

        await controller.save(
          distanceMeters: 5000,
          avgHeartRate: 145,
          incline: 2.0,
        );

        expect(controller.state.savedSuccessfully, isTrue);
        expect(controller.state.elapsedSeconds, 0);
        expect(controller.state.isRunning, isFalse);
        expect(controller.state.selectedExerciseId, isNull);

        final sessions =
            await cardioRepo.getSessionsForExercise('e1', kSelfClientId);
        expect(sessions, hasLength(1));
      });

      test('a storage failure clears isSaving and reports the error', () async {
        final failing = ProviderContainer(
          overrides: [
            cardioSessionRepositoryProvider.overrideWithValue(cardioRepo),
            saveCardioSessionUseCaseProvider
                .overrideWithValue(_ThrowingSaveUseCase()),
            locationServiceProvider.overrideWithValue(locationService),
            heartRateServiceProvider.overrideWithValue(heartRateService),
            foregroundSessionServiceProvider
                .overrideWithValue(foregroundService),
            healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
            healthSyncSettingsProvider
                .overrideWith(() => HealthSyncSettingsNotifier()),
          ],
        );
        addTearDown(failing.dispose);
        final failingController = failing.read(cardioTrackingProvider.notifier);

        await failingController.selectExercise('e1', 'Treadmill');
        failingController.start();
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        failingController.pause();

        await failingController.save();

        expect(failingController.state.isSaving, isFalse);
        expect(failingController.state.error, isNotNull);
        expect(failingController.state.savedSuccessfully, isFalse);
      });

      test('sets error on validation failure', () async {
        await controller.selectExercise('e1', 'Treadmill');
        controller.start();
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();

        await controller.save(avgHeartRate: 10);

        expect(controller.state.error, isNotNull);
        expect(controller.state.isSaving, isFalse);
        expect(controller.state.savedSuccessfully, isFalse);
      });
    });

    group('GPS tracking', () {
      test('toggleGps enables GPS when permission granted', () async {
        await controller.toggleGps();
        expect(controller.state.gpsEnabled, isTrue);
        expect(controller.state.gpsDistanceMeters, 0);
      });

      test('toggleGps sets error when permission denied', () async {
        locationService.permissionGranted = false;
        await controller.toggleGps();
        expect(controller.state.gpsEnabled, isFalse);
        expect(controller.state.error, isNotNull);
      });

      test('toggleGps disables GPS when already enabled', () async {
        await controller.toggleGps();
        expect(controller.state.gpsEnabled, isTrue);

        await controller.toggleGps();
        expect(controller.state.gpsEnabled, isFalse);
        expect(controller.state.gpsDistanceMeters, 0);
      });

      test('accumulates distance from position stream', () async {
        await controller.toggleGps();
        controller.start();

        // First position — sets baseline, no distance added.
        locationService.emitPosition(latitude: 51.5074, longitude: -0.1278);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(controller.state.gpsDistanceMeters, 0);
        expect(controller.state.gpsAcquiring, isFalse);

        // Second position — adds fixedDistance (10m).
        locationService.emitPosition(latitude: 51.5075, longitude: -0.1279);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(controller.state.gpsDistanceMeters, 10.0);

        // Third position — adds another 10m.
        locationService.emitPosition(latitude: 51.5076, longitude: -0.1280);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(controller.state.gpsDistanceMeters, 20.0);

        controller.pause();
      });

      test('gpsAcquiring is true until first position', () async {
        await controller.toggleGps();
        controller.start();

        expect(controller.state.gpsAcquiring, isTrue);

        locationService.emitPosition();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.state.gpsAcquiring, isFalse);
        controller.pause();
      });

      test('reset clears GPS distance but preserves gpsEnabled', () async {
        await controller.toggleGps();
        controller.start();

        locationService.emitPosition();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        locationService.emitPosition(latitude: 51.508);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        controller.reset();
        expect(controller.state.gpsEnabled, isTrue);
        expect(controller.state.gpsDistanceMeters, 0);
      });

      test('save uses GPS distance when GPS enabled', () async {
        await controller.selectExercise('e1', 'Treadmill');
        await controller.toggleGps();
        controller.start();

        locationService.emitPosition();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        locationService.fixedDistance = 500;
        locationService.emitPosition(latitude: 51.51);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();

        await controller.save();

        final sessions =
            await cardioRepo.getSessionsForExercise('e1', kSelfClientId);
        expect(sessions, hasLength(1));
        expect(sessions.first.distanceMeters, 500.0);
      });
    });

    group('Heart rate monitor', () {
      test('connectHeartRate sets hrConnected and hrDeviceName', () async {
        await controller.connectHeartRate('dev1', 'Polar H10');

        expect(controller.state.hrConnected, isTrue);
        expect(controller.state.hrConnecting, isFalse);
        expect(controller.state.hrDeviceName, 'Polar H10');
      });

      test(
          'HR stream updates currentHeartRate but does not append readings before start',
          () async {
        await controller.connectHeartRate('dev1', 'Polar H10');

        heartRateService.emitHeartRate(140);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // currentHeartRate still displays so the user sees the live BPM during
        // setup, but readings do not accumulate into the session average.
        expect(controller.state.currentHeartRate, 140);
        expect(controller.state.heartRateReadings, isEmpty);
      });

      test('HR stream appends readings only while session is running',
          () async {
        await controller.connectHeartRate('dev1', 'Polar H10');
        controller.start();

        heartRateService.emitHeartRate(140);
        heartRateService.emitHeartRate(145);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.state.heartRateReadings, [140, 145]);

        // Pause stops accumulation but still updates currentHeartRate.
        controller.pause();
        heartRateService.emitHeartRate(150);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.state.currentHeartRate, 150);
        expect(controller.state.heartRateReadings, [140, 145]);
      });

      test('ignores zero BPM readings from sensors without skin contact',
          () async {
        await controller.connectHeartRate('dev1', 'Polar H10');
        controller.start();

        heartRateService.emitHeartRate(0);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.state.currentHeartRate, isNull);
        expect(controller.state.heartRateReadings, isEmpty);

        heartRateService.emitHeartRate(120);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.state.currentHeartRate, 120);
        expect(controller.state.heartRateReadings, [120]);
      });

      test('start() clears stale heart rate readings from a previous session',
          () async {
        await controller.connectHeartRate('dev1', 'Polar H10');
        controller.start();
        heartRateService.emitHeartRate(140);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        controller.pause();
        controller.reset();

        // Defence in depth: even if readings somehow leaked, start clears them.
        controller.start();
        heartRateService.emitHeartRate(160);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.state.heartRateReadings, [160]);
      });

      test('disconnectHeartRate clears HR state', () async {
        await controller.connectHeartRate('dev1', 'Polar H10');
        heartRateService.emitHeartRate(140);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await controller.disconnectHeartRate();

        expect(controller.state.hrConnected, isFalse);
        expect(controller.state.currentHeartRate, isNull);
        expect(controller.state.heartRateReadings, isEmpty);
        expect(controller.state.hrDeviceName, isNull);
      });

      test('save computes average from HR readings', () async {
        await controller.selectExercise('e1', 'Treadmill');
        await controller.connectHeartRate('dev1', 'Polar H10');
        controller.start();

        heartRateService.emitHeartRate(140);
        heartRateService.emitHeartRate(150);
        heartRateService.emitHeartRate(160);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();

        await controller.save();

        final sessions =
            await cardioRepo.getSessionsForExercise('e1', kSelfClientId);
        expect(sessions, hasLength(1));
        expect(sessions.first.avgHeartRate, 150); // (140+150+160)/3
      });

      test('save tears down HR subscription so post-save samples do not leak',
          () async {
        await controller.selectExercise('e1', 'Treadmill');
        await controller.connectHeartRate('dev1', 'Polar H10');
        controller.start();
        heartRateService.emitHeartRate(140);
        heartRateService.emitHeartRate(160);
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();
        await controller.save();

        // Late-arriving samples after save must not pollute the next
        // session's readings. The live BPM still shows, since the strap is
        // still connected and cardio keeps following it (#119).
        heartRateService.emitHeartRate(220);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.state.heartRateReadings, isEmpty);
        expect(controller.state.currentHeartRate, 220);
        expect(controller.state.hrConnected, isTrue);
        // The HR service is a singleton shared with the dedicated HR panel —
        // saving cardio must not disconnect the underlying BLE device.
        expect(heartRateService.isConnected, isTrue);
      });

      test('resume after pause preserves pre-pause heart rate readings',
          () async {
        await controller.selectExercise('e1', 'Treadmill');
        await controller.connectHeartRate('dev1', 'Polar H10');
        controller.start();

        heartRateService.emitHeartRate(140);
        heartRateService.emitHeartRate(150);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(controller.state.heartRateReadings, [140, 150]);

        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();

        // Resume — start() is also wired to the resume button, so it must
        // NOT clear the buffer mid-session.
        controller.start();
        heartRateService.emitHeartRate(160);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(controller.state.heartRateReadings, [140, 150, 160]);

        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();
        await controller.save();

        final sessions =
            await cardioRepo.getSessionsForExercise('e1', kSelfClientId);
        expect(sessions, hasLength(1));
        // Average across the full session, not just the post-resume segment.
        expect(sessions.first.avgHeartRate, 150);
      });

      test('save with HR readings overrides manual avgHeartRate', () async {
        await controller.selectExercise('e1', 'Treadmill');
        await controller.connectHeartRate('dev1', 'Polar H10');
        controller.start();

        heartRateService.emitHeartRate(140);
        heartRateService.emitHeartRate(160);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        controller.pause();

        // Manual value 100 should be ignored in favour of HR readings.
        await controller.save(avgHeartRate: 100);

        final sessions =
            await cardioRepo.getSessionsForExercise('e1', kSelfClientId);
        expect(sessions, hasLength(1));
        expect(sessions.first.avgHeartRate, 150); // (140+160)/2, not 100
      });

      test('connectHeartRate sets error on connection failure', () async {
        heartRateService.shouldThrowOnConnect = true;

        await controller.connectHeartRate('dev1', 'Polar H10');

        expect(controller.state.hrConnected, isFalse);
        expect(controller.state.hrConnecting, isFalse);
        expect(controller.state.error, isNotNull);
      });

      test('reset preserves HR connection state', () async {
        await controller.connectHeartRate('dev1', 'Polar H10');
        controller.start();
        controller.reset();

        expect(controller.state.hrConnected, isTrue);
        expect(controller.state.hrDeviceName, 'Polar H10');
        expect(controller.state.heartRateReadings, isEmpty);
      });

      test('hrReconnecting is set when reconnecting event received', () async {
        await controller.connectHeartRate('dev1', 'Polar H10');
        expect(controller.state.hrReconnecting, isFalse);

        heartRateService.emitConnectionState(HrConnectionState.reconnecting);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.state.hrReconnecting, isTrue);
        expect(controller.state.hrConnected, isTrue);
      });

      test('hrReconnecting clears when connected event received', () async {
        await controller.connectHeartRate('dev1', 'Polar H10');

        heartRateService.emitConnectionState(HrConnectionState.reconnecting);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(controller.state.hrReconnecting, isTrue);

        heartRateService.emitConnectionState(HrConnectionState.connected);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.state.hrReconnecting, isFalse);
        expect(controller.state.hrConnected, isTrue);
      });

      test('disconnected event clears HR state and sets error', () async {
        await controller.connectHeartRate('dev1', 'Polar H10');

        heartRateService.emitConnectionState(HrConnectionState.disconnected);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.state.hrConnected, isFalse);
        expect(controller.state.hrReconnecting, isFalse);
        expect(controller.state.currentHeartRate, isNull);
        expect(controller.state.error, isNotNull);
      });
    });

    group('foreground session service', () {
      test('start() activates the service with current capabilities', () {
        controller.start();
        expect(
          foregroundService.last,
          (
            sessionRunning: true,
            gpsEnabled: false,
            hrConnected: false,
            coachActive: false
          ),
        );
        controller.reset();
      });

      test('pause() deactivates the service', () {
        controller.start();
        controller.pause();
        expect(foregroundService.last?.sessionRunning, isFalse);
      });

      test('reset() deactivates the service', () {
        controller.start();
        controller.reset();
        expect(foregroundService.last?.sessionRunning, isFalse);
      });

      test('toggleGps() while running updates the service capabilities',
          () async {
        controller.start();
        await controller.toggleGps();
        expect(
          foregroundService.last,
          (
            sessionRunning: true,
            gpsEnabled: true,
            hrConnected: false,
            coachActive: false
          ),
        );
        controller.reset();
      });

      test('connectHeartRate() while running updates the capabilities',
          () async {
        controller.start();
        await controller.connectHeartRate('dev1', 'Polar H10');
        expect(
          foregroundService.last,
          (
            sessionRunning: true,
            gpsEnabled: false,
            hrConnected: true,
            coachActive: false
          ),
        );
        controller.reset();
      });

      test('save() deactivates the service', () async {
        await controller.selectExercise('e1', 'Treadmill');
        controller.start();
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        await controller.save(distanceMeters: 500);
        expect(controller.state.savedSuccessfully, isTrue);
        expect(foregroundService.last?.sessionRunning, isFalse);
        // Let the lazily mounted health-sync settings finish loading
        // before tearDown disposes the container.
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
    });
  });
}
