import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/cardio/presentation/controllers/cardio_tracking_controller.dart';
import 'package:rep_foundry/features/cardio/presentation/controllers/cardio_tracking_state.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/max_hr_alert_provider.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/zone_configuration_provider.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/hr_event_source.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_settings_provider.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';

import '../../cardio/data/fake_heart_rate_service.dart';

class _Entitlements implements EntitlementService {
  _Entitlements(this.entitled);
  final bool entitled;

  @override
  bool has(Entitlement entitlement) => entitled;
}

class _Settings extends TrainerSettingsNotifier {
  _Settings(this._seed);
  final TrainerSettings _seed;

  @override
  TrainerSettings build() => _seed;
}

class _Workout extends ActiveWorkoutController {
  _Workout(this._inProgress);
  final bool _inProgress;

  @override
  ActiveWorkoutState build() => _inProgress
      ? ActiveWorkoutState(activeWorkout: Workout.create())
      : const ActiveWorkoutState();
}

class _QuietMaxHrAlert extends MaxHrAlertNotifier {
  @override
  MaxHrAlertSettings build() => const MaxHrAlertSettings();
}

class _Cardio extends CardioTrackingController {
  @override
  CardioTrackingState build() => const CardioTrackingState(isRunning: true);
}

/// Zone 2 starts at 108 bpm, zone 5 at 162.
ZoneConfiguration _config({int maxHr = 195}) => ZoneConfiguration(
      method: ZoneMethod.percentOfEstimatedMax,
      reliability: ZoneReliability.medium,
      maxHr: maxHr,
      reason: 'test config',
      zones: const [
        CalculatedZone(
          zoneNumber: 1,
          label: 'Zone 1',
          effortLabel: 'Easy',
          descriptiveLabel: 'Recovery',
          lowerBound: 90,
          upperBound: 108,
          color: 0xFF000000,
        ),
        CalculatedZone(
          zoneNumber: 2,
          label: 'Zone 2',
          effortLabel: 'Light',
          descriptiveLabel: 'Aerobic',
          lowerBound: 108,
          upperBound: 126,
          color: 0xFF000000,
        ),
        CalculatedZone(
          zoneNumber: 3,
          label: 'Zone 3',
          effortLabel: 'Moderate',
          descriptiveLabel: 'Aerobic',
          lowerBound: 126,
          upperBound: 144,
          color: 0xFF000000,
        ),
        CalculatedZone(
          zoneNumber: 4,
          label: 'Zone 4',
          effortLabel: 'Hard',
          descriptiveLabel: 'Threshold',
          lowerBound: 144,
          upperBound: 162,
          color: 0xFF000000,
        ),
        CalculatedZone(
          zoneNumber: 5,
          label: 'Zone 5',
          effortLabel: 'Maximum',
          descriptiveLabel: 'VO2 Max',
          lowerBound: 162,
          upperBound: 200,
          color: 0xFF000000,
        ),
      ],
    );

const _nudgesOn = TrainerSettings(
  enabled: true,
  disclaimerAccepted: true,
  activityNudgesEnabled: true,
);

void main() {
  late List<TrainerEvent> received;
  late FakeHeartRateService hr;

  List<ActivityDetected> nudges() =>
      received.whereType<ActivityDetected>().toList();

  ProviderContainer start({
    TrainerSettings settings = _nudgesOn,
    bool entitled = true,
    bool workoutInProgress = false,
    bool cardioRunning = false,
    bool cautionMode = false,
    int maxHr = 195,
  }) {
    received = [];
    hr = FakeHeartRateService();
    final container = ProviderContainer(overrides: [
      heartRateServiceProvider.overrideWithValue(hr),
      entitlementServiceProvider.overrideWithValue(_Entitlements(entitled)),
      zoneConfigurationProvider.overrideWith((ref) => _config(maxHr: maxHr)),
      cautionModeProvider.overrideWithValue(cautionMode),
      maxHrAlertProvider.overrideWith(_QuietMaxHrAlert.new),
      trainerSettingsProvider.overrideWith(() => _Settings(settings)),
      activeWorkoutControllerProvider
          .overrideWith(() => _Workout(workoutInProgress)),
      cardioTrackingProvider.overrideWith(_Cardio.new),
    ]);
    addTearDown(container.dispose);
    container.read(trainerEventBusProvider).events.listen(received.add);
    container.read(activeWorkoutControllerProvider);
    if (cardioRunning) container.read(cardioTrackingProvider);
    container.read(hrEventSourceProvider);
    return container;
  }

  /// One reading a second at [bpm] for [seconds].
  void beat(FakeAsync async, int bpm, int seconds) {
    for (var i = 0; i < seconds; i++) {
      hr.emitHeartRate(bpm);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
    }
  }

  test('sustained effort with nothing running offers company once', () {
    fakeAsync((async) {
      start();

      beat(async, 130, 300);

      expect(nudges(), hasLength(1));
    });
  });

  test('zone 2 counts as effort', () {
    fakeAsync((async) {
      start();

      beat(async, 110, 120);

      expect(nudges(), hasLength(1));
    });
  });

  test('resting readings never prompt', () {
    fakeAsync((async) {
      start();

      beat(async, 95, 300);

      expect(nudges(), isEmpty);
    });
  });

  test('stays quiet during a workout', () {
    fakeAsync((async) {
      start(workoutInProgress: true);

      beat(async, 130, 300);

      expect(nudges(), isEmpty);
    });
  });

  test('stays quiet during a cardio session', () {
    fakeAsync((async) {
      start(cardioRunning: true);

      beat(async, 130, 300);

      expect(nudges(), isEmpty);
    });
  });

  test('stays quiet unless the user opted in', () {
    fakeAsync((async) {
      start(
        settings:
            const TrainerSettings(enabled: true, disclaimerAccepted: true),
      );

      beat(async, 130, 300);

      expect(nudges(), isEmpty);
    });
  });

  test('stays quiet with the coach switched off', () {
    fakeAsync((async) {
      start(
        settings: const TrainerSettings(
          disclaimerAccepted: true,
          activityNudgesEnabled: true,
        ),
      );

      beat(async, 130, 300);

      expect(nudges(), isEmpty);
    });
  });

  test('stays quiet before the safety notice is accepted', () {
    fakeAsync((async) {
      start(
        settings: const TrainerSettings(
          enabled: true,
          activityNudgesEnabled: true,
        ),
      );

      beat(async, 130, 300);

      expect(nudges(), isEmpty);
    });
  });

  test('stays quiet without the trainer entitlement', () {
    fakeAsync((async) {
      start(entitled: false);

      beat(async, 130, 300);

      expect(nudges(), isEmpty);
    });
  });

  test('a strap dropout restarts the count', () {
    fakeAsync((async) {
      start();

      beat(async, 130, 80);
      // Longer than the 25 s signal-loss timeout.
      async.elapse(const Duration(seconds: 30));
      beat(async, 130, 80);

      expect(nudges(), isEmpty);
    });
  });

  group('safety rules apply to the offer, spoken or shown', () {
    test('zone 4 still earns the offer', () {
      fakeAsync((async) {
        start();

        beat(async, 150, 120);

        expect(nudges(), hasLength(1));
      });
    });

    test('never offered above the safe maximum', () {
      fakeAsync((async) {
        start(maxHr: 145);

        beat(async, 150, 300);

        expect(nudges(), isEmpty);
        expect(received.whereType<HeartRateAboveCap>(), isNotEmpty);
      });
    });

    test('never offered in zone 5', () {
      fakeAsync((async) {
        start();

        beat(async, 170, 300);

        expect(nudges(), isEmpty);
      });
    });

    test('never offered in caution mode', () {
      fakeAsync((async) {
        start(cautionMode: true);

        beat(async, 130, 300);

        expect(nudges(), isEmpty);
      });
    });
  });
}
