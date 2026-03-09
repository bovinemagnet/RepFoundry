import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/application/save_cardio_session_use_case.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/data/heart_rate_service.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/cardio/presentation/controllers/cardio_tracking_controller.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/core/providers.dart';

import '../../data/fake_heart_rate_service.dart';
import '../../data/fake_location_service.dart';

/// A test notifier that returns a fixed [HealthSyncSettings].
class _FakeHealthSyncSettingsNotifier extends HealthSyncSettingsNotifier {
  @override
  HealthSyncSettings build() => const HealthSyncSettings();
}

void main() {
  late InMemoryCardioSessionRepository cardioRepo;
  late InMemoryWorkoutRepository workoutRepo;
  late SaveCardioSessionUseCase useCase;
  late FakeLocationService locationService;
  late FakeHeartRateService heartRateService;
  late ProviderContainer container;

  CardioTrackingController ctrl() =>
      container.read(cardioTrackingProvider.notifier);

  setUp(() {
    cardioRepo = InMemoryCardioSessionRepository();
    workoutRepo = InMemoryWorkoutRepository();
    useCase = SaveCardioSessionUseCase(
      cardioRepository: cardioRepo,
      workoutRepository: workoutRepo,
    );
    locationService = FakeLocationService();
    heartRateService = FakeHeartRateService();
    container = ProviderContainer(
      overrides: [
        cardioSessionRepositoryProvider.overrideWithValue(cardioRepo),
        saveCardioSessionUseCaseProvider.overrideWithValue(useCase),
        locationServiceProvider.overrideWithValue(locationService),
        heartRateServiceProvider.overrideWithValue(heartRateService),
        healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
        healthSyncSettingsProvider
            .overrideWith(() => _FakeHealthSyncSettingsNotifier()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    locationService.dispose();
    heartRateService.dispose();
  });

  group('CardioTrackingController', () {
    group('timer state transitions', () {
      test('initial state is not running with zero elapsed', () {
        expect(ctrl().state.isRunning, isFalse);
        expect(ctrl().state.elapsedSeconds, 0);
      });

      test('start() sets isRunning to true', () {
        ctrl().start();
        expect(ctrl().state.isRunning, isTrue);
      });

      test('pause() sets isRunning to false', () {
        ctrl().start();
        ctrl().pause();
        expect(ctrl().state.isRunning, isFalse);
      });

      test('reset() clears elapsed but preserves exercise selection',
          () async {
        await ctrl().selectExercise('e1', 'Treadmill');
        ctrl().start();
        ctrl().reset();

        expect(ctrl().state.isRunning, isFalse);
        expect(ctrl().state.elapsedSeconds, 0);
        expect(ctrl().state.selectedExerciseId, 'e1');
        expect(ctrl().state.selectedExerciseName, 'Treadmill');
      });

      test('start() is idempotent when already running', () {
        ctrl().start();
        ctrl().start();
        expect(ctrl().state.isRunning, isTrue);
      });
    });

    group('selectExercise', () {
      test('sets exercise id and name', () async {
        await ctrl().selectExercise('e1', 'Treadmill');
        expect(ctrl().state.selectedExerciseId, 'e1');
        expect(ctrl().state.selectedExerciseName, 'Treadmill');
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

        await ctrl().selectExercise('e1', 'Treadmill');

        expect(ctrl().state.lastSession, isNotNull);
        expect(ctrl().state.lastSession!.durationSeconds, 1800);
        expect(ctrl().state.lastSession!.distanceMeters, 5000);
      });

      test('sets lastSession to null when no previous session', () async {
        await ctrl().selectExercise('e2', 'Bike');
        expect(ctrl().state.lastSession, isNull);
      });
    });

    group('save()', () {
      test('does nothing when no exercise selected', () async {
        await ctrl().save();
        expect(ctrl().state.savedSuccessfully, isFalse);
      });

      test('does nothing when elapsed is zero', () async {
        await ctrl().selectExercise('e1', 'Treadmill');
        await ctrl().save();
        expect(ctrl().state.savedSuccessfully, isFalse);
      });

      test('saves session and resets state on success', () async {
        await ctrl().selectExercise('e1', 'Treadmill');
        ctrl().start();
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        ctrl().pause();

        expect(ctrl().state.elapsedSeconds, greaterThan(0));

        await ctrl().save(
          distanceMeters: 5000,
          avgHeartRate: 145,
          incline: 2.0,
        );

        expect(ctrl().state.savedSuccessfully, isTrue);
        expect(ctrl().state.elapsedSeconds, 0);
        expect(ctrl().state.isRunning, isFalse);
        expect(ctrl().state.selectedExerciseId, isNull);

        final sessions = await cardioRepo.getSessionsForExercise('e1');
        expect(sessions, hasLength(1));
      });

      test('sets error on validation failure', () async {
        await ctrl().selectExercise('e1', 'Treadmill');
        ctrl().start();
        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        ctrl().pause();

        await ctrl().save(avgHeartRate: 10);

        expect(ctrl().state.error, isNotNull);
        expect(ctrl().state.isSaving, isFalse);
        expect(ctrl().state.savedSuccessfully, isFalse);
      });
    });

    group('GPS tracking', () {
      test('toggleGps enables GPS when permission granted', () async {
        await ctrl().toggleGps();
        expect(ctrl().state.gpsEnabled, isTrue);
        expect(ctrl().state.gpsDistanceMeters, 0);
      });

      test('toggleGps sets error when permission denied', () async {
        locationService.permissionGranted = false;
        await ctrl().toggleGps();
        expect(ctrl().state.gpsEnabled, isFalse);
        expect(ctrl().state.error, isNotNull);
      });

      test('toggleGps disables GPS when already enabled', () async {
        await ctrl().toggleGps();
        expect(ctrl().state.gpsEnabled, isTrue);

        await ctrl().toggleGps();
        expect(ctrl().state.gpsEnabled, isFalse);
        expect(ctrl().state.gpsDistanceMeters, 0);
      });

      test('accumulates distance from position stream', () async {
        await ctrl().toggleGps();
        ctrl().start();

        // First position — sets baseline, no distance added.
        locationService.emitPosition(latitude: 51.5074, longitude: -0.1278);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(ctrl().state.gpsDistanceMeters, 0);
        expect(ctrl().state.gpsAcquiring, isFalse);

        // Second position — adds fixedDistance (10m).
        locationService.emitPosition(latitude: 51.5075, longitude: -0.1279);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(ctrl().state.gpsDistanceMeters, 10.0);

        // Third position — adds another 10m.
        locationService.emitPosition(latitude: 51.5076, longitude: -0.1280);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(ctrl().state.gpsDistanceMeters, 20.0);

        ctrl().pause();
      });

      test('gpsAcquiring is true until first position', () async {
        await ctrl().toggleGps();
        ctrl().start();

        expect(ctrl().state.gpsAcquiring, isTrue);

        locationService.emitPosition();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ctrl().state.gpsAcquiring, isFalse);
        ctrl().pause();
      });

      test('reset clears GPS distance but preserves gpsEnabled', () async {
        await ctrl().toggleGps();
        ctrl().start();

        locationService.emitPosition();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        locationService.emitPosition(latitude: 51.508);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        ctrl().reset();
        expect(ctrl().state.gpsEnabled, isTrue);
        expect(ctrl().state.gpsDistanceMeters, 0);
      });

      test('save uses GPS distance when GPS enabled', () async {
        await ctrl().selectExercise('e1', 'Treadmill');
        await ctrl().toggleGps();
        ctrl().start();

        locationService.emitPosition();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        locationService.fixedDistance = 500;
        locationService.emitPosition(latitude: 51.51);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        ctrl().pause();

        await ctrl().save();

        final sessions = await cardioRepo.getSessionsForExercise('e1');
        expect(sessions, hasLength(1));
        expect(sessions.first.distanceMeters, 500.0);
      });
    });

    group('Heart rate monitor', () {
      test('connectHeartRate sets hrConnected and hrDeviceName', () async {
        await ctrl().connectHeartRate('dev1', 'Polar H10');

        expect(ctrl().state.hrConnected, isTrue);
        expect(ctrl().state.hrConnecting, isFalse);
        expect(ctrl().state.hrDeviceName, 'Polar H10');
      });

      test('HR stream updates currentHeartRate and appends readings',
          () async {
        await ctrl().connectHeartRate('dev1', 'Polar H10');

        heartRateService.emitHeartRate(140);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ctrl().state.currentHeartRate, 140);
        expect(ctrl().state.heartRateReadings, [140]);

        heartRateService.emitHeartRate(145);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ctrl().state.currentHeartRate, 145);
        expect(ctrl().state.heartRateReadings, [140, 145]);
      });

      test('disconnectHeartRate clears HR state', () async {
        await ctrl().connectHeartRate('dev1', 'Polar H10');
        heartRateService.emitHeartRate(140);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await ctrl().disconnectHeartRate();

        expect(ctrl().state.hrConnected, isFalse);
        expect(ctrl().state.currentHeartRate, isNull);
        expect(ctrl().state.heartRateReadings, isEmpty);
        expect(ctrl().state.hrDeviceName, isNull);
      });

      test('save computes average from HR readings', () async {
        await ctrl().selectExercise('e1', 'Treadmill');
        await ctrl().connectHeartRate('dev1', 'Polar H10');
        ctrl().start();

        heartRateService.emitHeartRate(140);
        heartRateService.emitHeartRate(150);
        heartRateService.emitHeartRate(160);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        ctrl().pause();

        await ctrl().save();

        final sessions = await cardioRepo.getSessionsForExercise('e1');
        expect(sessions, hasLength(1));
        expect(sessions.first.avgHeartRate, 150); // (140+150+160)/3
      });

      test('save with HR readings overrides manual avgHeartRate', () async {
        await ctrl().selectExercise('e1', 'Treadmill');
        await ctrl().connectHeartRate('dev1', 'Polar H10');
        ctrl().start();

        heartRateService.emitHeartRate(140);
        heartRateService.emitHeartRate(160);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await Future<void>.delayed(
            const Duration(seconds: 1, milliseconds: 100));
        ctrl().pause();

        // Manual value 100 should be ignored in favour of HR readings.
        await ctrl().save(avgHeartRate: 100);

        final sessions = await cardioRepo.getSessionsForExercise('e1');
        expect(sessions, hasLength(1));
        expect(sessions.first.avgHeartRate, 150); // (140+160)/2, not 100
      });

      test('connectHeartRate sets error on connection failure', () async {
        heartRateService.shouldThrowOnConnect = true;

        await ctrl().connectHeartRate('dev1', 'Polar H10');

        expect(ctrl().state.hrConnected, isFalse);
        expect(ctrl().state.hrConnecting, isFalse);
        expect(ctrl().state.error, isNotNull);
      });

      test('reset preserves HR connection state', () async {
        await ctrl().connectHeartRate('dev1', 'Polar H10');
        ctrl().start();
        ctrl().reset();

        expect(ctrl().state.hrConnected, isTrue);
        expect(ctrl().state.hrDeviceName, 'Polar H10');
        expect(ctrl().state.heartRateReadings, isEmpty);
      });

      test('hrReconnecting is set when reconnecting event received', () async {
        await ctrl().connectHeartRate('dev1', 'Polar H10');
        expect(ctrl().state.hrReconnecting, isFalse);

        heartRateService.emitConnectionState(HrConnectionState.reconnecting);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ctrl().state.hrReconnecting, isTrue);
        expect(ctrl().state.hrConnected, isTrue);
      });

      test('hrReconnecting clears when connected event received', () async {
        await ctrl().connectHeartRate('dev1', 'Polar H10');

        heartRateService.emitConnectionState(HrConnectionState.reconnecting);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(ctrl().state.hrReconnecting, isTrue);

        heartRateService.emitConnectionState(HrConnectionState.connected);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ctrl().state.hrReconnecting, isFalse);
        expect(ctrl().state.hrConnected, isTrue);
      });

      test('disconnected event clears HR state and sets error', () async {
        await ctrl().connectHeartRate('dev1', 'Polar H10');

        heartRateService.emitConnectionState(HrConnectionState.disconnected);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ctrl().state.hrConnected, isFalse);
        expect(ctrl().state.hrReconnecting, isFalse);
        expect(ctrl().state.currentHeartRate, isNull);
        expect(ctrl().state.error, isNotNull);
      });
    });
  });
}
