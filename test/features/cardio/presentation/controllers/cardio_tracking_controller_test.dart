import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/application/save_cardio_session_use_case.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/cardio/presentation/controllers/cardio_tracking_controller.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';

import '../../data/fake_heart_rate_service.dart';
import '../../data/fake_location_service.dart';

void main() {
  late InMemoryCardioSessionRepository cardioRepo;
  late InMemoryWorkoutRepository workoutRepo;
  late SaveCardioSessionUseCase useCase;
  late FakeLocationService locationService;
  late FakeHeartRateService heartRateService;
  late CardioTrackingController controller;

  setUp(() {
    cardioRepo = InMemoryCardioSessionRepository();
    workoutRepo = InMemoryWorkoutRepository();
    useCase = SaveCardioSessionUseCase(
      cardioRepository: cardioRepo,
      workoutRepository: workoutRepo,
    );
    locationService = FakeLocationService();
    heartRateService = FakeHeartRateService();
    controller = CardioTrackingController(
      cardioRepository: cardioRepo,
      saveUseCase: useCase,
      locationService: locationService,
      heartRateService: heartRateService,
    );
  });

  tearDown(() {
    controller.dispose();
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

    group('save()', () {
      test('does nothing when no exercise selected', () async {
        await controller.save();
        expect(controller.state.savedSuccessfully, isFalse);
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

        final sessions = await cardioRepo.getSessionsForExercise('e1');
        expect(sessions, hasLength(1));
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

        final sessions = await cardioRepo.getSessionsForExercise('e1');
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

      test('HR stream updates currentHeartRate and appends readings', () async {
        await controller.connectHeartRate('dev1', 'Polar H10');

        heartRateService.emitHeartRate(140);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.state.currentHeartRate, 140);
        expect(controller.state.heartRateReadings, [140]);

        heartRateService.emitHeartRate(145);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(controller.state.currentHeartRate, 145);
        expect(controller.state.heartRateReadings, [140, 145]);
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

        final sessions = await cardioRepo.getSessionsForExercise('e1');
        expect(sessions, hasLength(1));
        expect(sessions.first.avgHeartRate, 150); // (140+150+160)/3
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

        final sessions = await cardioRepo.getSessionsForExercise('e1');
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
    });
  });
}
