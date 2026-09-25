import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/foreground/foreground_keep_alive.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/coach_keep_alive.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_settings_provider.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';

import '../../cardio/data/fake_foreground_session_service.dart';

class _SeededTrainerSettings extends TrainerSettingsNotifier {
  _SeededTrainerSettings(this._seed);
  final TrainerSettings _seed;

  @override
  TrainerSettings build() => _seed;

  void forceUpdate(TrainerSettings next) => state = next;
}

class _SeededEntitlements extends UnlockedEntitlementsNotifier {
  _SeededEntitlements(this._seed);
  final Set<Entitlement> _seed;

  @override
  Set<Entitlement> build() => _seed;

  void forceUpdate(Set<Entitlement> next) => state = next;
}

class _SeededWorkout extends ActiveWorkoutController {
  _SeededWorkout(this._inProgress);
  final bool _inProgress;

  static ActiveWorkoutState stateFor(bool inProgress) => inProgress
      ? ActiveWorkoutState(activeWorkout: Workout.create())
      : const ActiveWorkoutState();

  @override
  ActiveWorkoutState build() => stateFor(_inProgress);

  void forceUpdate(bool inProgress) => state = stateFor(inProgress);
}

void main() {
  const coachOn = TrainerSettings(enabled: true, disclaimerAccepted: true);

  late FakeForegroundSessionService service;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer start({
    TrainerSettings settings = coachOn,
    Set<Entitlement> entitlements = const {Entitlement.virtualTrainer},
    bool workoutInProgress = true,
  }) {
    service = FakeForegroundSessionService();
    final container = ProviderContainer(overrides: [
      foregroundKeepAliveProvider
          .overrideWithValue(ForegroundKeepAlive(service)),
      trainerSettingsProvider
          .overrideWith(() => _SeededTrainerSettings(settings)),
      unlockedEntitlementsProvider
          .overrideWith(() => _SeededEntitlements(entitlements)),
      activeWorkoutControllerProvider
          .overrideWith(() => _SeededWorkout(workoutInProgress)),
    ]);
    addTearDown(container.dispose);
    container.read(coachKeepAliveProvider);
    return container;
  }

  bool? coachKeptAlive() => service.last?.coachActive;

  test('an enabled coach keeps the app alive through a workout', () {
    start();

    expect(coachKeptAlive(), isTrue);
    expect(service.last?.sessionRunning, isTrue);
  });

  test('asks for nothing outside a workout', () {
    start(workoutInProgress: false);

    expect(coachKeptAlive(), isNot(isTrue));
  });

  test('asks for nothing when speaking in the background is switched off', () {
    start(
      settings: const TrainerSettings(
        enabled: true,
        disclaimerAccepted: true,
        speakInBackground: false,
      ),
    );

    expect(coachKeptAlive(), isNot(isTrue));
  });

  test('asks for nothing before the disclaimer is accepted', () {
    start(settings: const TrainerSettings(enabled: true));

    expect(coachKeptAlive(), isNot(isTrue));
  });

  test('asks for nothing without the trainer entitlement', () {
    start(entitlements: const {});

    expect(coachKeptAlive(), isNot(isTrue));
  });

  test('releases the keep-alive when the workout finishes', () async {
    final container = start();

    (container.read(activeWorkoutControllerProvider.notifier) as _SeededWorkout)
        .forceUpdate(false);
    await container.pump();

    expect(coachKeptAlive(), isFalse);
  });

  test('picks the keep-alive up when a workout starts', () async {
    final container = start(workoutInProgress: false);

    (container.read(activeWorkoutControllerProvider.notifier) as _SeededWorkout)
        .forceUpdate(true);
    await container.pump();

    expect(coachKeptAlive(), isTrue);
  });

  test('releases the keep-alive when the coach is switched off mid-workout',
      () async {
    final container = start();

    (container.read(trainerSettingsProvider.notifier) as _SeededTrainerSettings)
        .forceUpdate(const TrainerSettings(disclaimerAccepted: true));
    await container.pump();

    expect(coachKeptAlive(), isFalse);
  });

  test('releases the keep-alive when the entitlement is revoked mid-workout',
      () async {
    final container = start();

    (container.read(unlockedEntitlementsProvider.notifier)
            as _SeededEntitlements)
        .forceUpdate(const {});
    await container.pump();

    expect(coachKeptAlive(), isFalse);
  });

  test('the notification button switches the coach off and releases it',
      () async {
    final container = start();
    expect(coachKeptAlive(), isTrue);

    service.pressStopCoach();
    await pumpEventQueue();
    await container.pump();

    expect(container.read(trainerSettingsProvider).enabled, isFalse);
    expect(coachKeptAlive(), isFalse);
  });
}
