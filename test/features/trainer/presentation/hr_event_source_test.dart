import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/cardio/data/heart_rate_service.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/zone_configuration_provider.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/hr_event_source.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';

import '../../cardio/data/fake_heart_rate_service.dart';

class _AlwaysEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

/// A minimal [HeartRateService] whose stream can be made to emit an error,
/// which [FakeHeartRateService] has no hook for.
class _ErroringHeartRateService implements HeartRateService {
  final _controller = StreamController<int>.broadcast();

  @override
  Stream<int> get heartRateStream => _controller.stream;

  void addReading(int bpm) => _controller.add(bpm);
  void addError() => _controller.addError(Exception('BLE read failed'));

  @override
  Future<bool> checkAndRequestPermission() async => true;

  @override
  Future<bool> turnOnBluetooth() async => true;

  @override
  Future<List<DiscoveredHrDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async =>
      const [];

  @override
  Future<void> connectToDevice(String deviceId) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Stream<HrConnectionState> get connectionStateStream => const Stream.empty();

  @override
  bool get isConnected => true;
}

/// Zone boundaries chosen so cap-boundary tests (cap = maxHr = 180, default
/// hysteresis margin 5 bpm) never cross a zone boundary, and zone tests never
/// approach the cap.
ZoneConfiguration _config({int maxHr = 180}) => ZoneConfiguration(
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
          descriptiveLabel: 'Anaerobic',
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
          color: 0xFF000000,
        ),
      ],
    );

/// A stand-in for [hrEventSourceProvider] whose `create` callback each test
/// overrides, so constructor parameters can be varied — the real provider
/// only ever passes the defaults in production.
final _sourceUnderTest = Provider<HrEventSource>((ref) => HrEventSource(ref));

void main() {
  late List<TrainerEvent> received;

  /// Builds a container wired for the happy path (entitled, a usable zone
  /// config) with the given heart rate service and, optionally, a
  /// non-default [HrEventSource]. Subscribes to the bus immediately so
  /// `received` captures everything emitted from the moment the container is
  /// built.
  ProviderContainer buildContainer({
    required HeartRateService heartRateService,
    // A separate flag rather than a nullable `zoneConfig` parameter: the
    // caller needs to be able to say "override with null" explicitly,
    // distinct from "use the default test config", and a bare `T?` parameter
    // can't distinguish "not passed" from "passed as null".
    bool nullZoneConfig = false,
    // Lets a test change the resolved config mid-session (paired with
    // `container.invalidate(zoneConfigurationProvider)`), for scenarios
    // where the profile goes from usable to unusable partway through.
    // Takes precedence over `nullZoneConfig` when supplied.
    ZoneConfiguration? Function()? zoneConfigResolver,
    HrEventSource Function(Ref ref)? create,
  }) {
    final container = ProviderContainer(overrides: [
      heartRateServiceProvider.overrideWithValue(heartRateService),
      entitlementServiceProvider.overrideWithValue(_AlwaysEntitled()),
      zoneConfigurationProvider.overrideWith(
        (ref) => zoneConfigResolver != null
            ? zoneConfigResolver()
            : (nullZoneConfig ? null : _config()),
      ),
      _sourceUnderTest.overrideWith(create ?? (ref) => HrEventSource(ref)),
    ]);
    addTearDown(container.dispose);

    final sub = container.read(trainerEventBusProvider).events.listen(
          received.add,
        );
    addTearDown(sub.cancel);

    return container;
  }

  setUp(() {
    received = [];
  });

  group('zone dwell', () {
    test('no emission before the dwell elapses', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(130); // zone 3
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 9));
        hr.emitHeartRate(130);
        async.flushMicrotasks();

        expect(received, isEmpty);
      });
    });

    test('exactly one emission once the dwell has elapsed', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(130); // zone 3
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        hr.emitHeartRate(130);
        async.flushMicrotasks();

        expect(received, hasLength(1));
        final event = received.single as HeartRateZoneChanged;
        expect(event.zoneNumber, 3);
        expect(event.effortLabel, 'Moderate');
        expect(event.descriptiveLabel, 'Aerobic');
      });
    });

    test('no repeat while the zone holds', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(130);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        hr.emitHeartRate(130);
        async.flushMicrotasks();
        expect(received, hasLength(1));

        for (var i = 0; i < 5; i++) {
          async.elapse(const Duration(seconds: 3));
          hr.emitHeartRate(131);
          async.flushMicrotasks();
        }

        expect(received, hasLength(1),
            reason: 'the zone never changed, so no further zone events '
                'should be emitted');
      });
    });

    test(
        'alternating between two zones never settles long enough to be '
        'announced — the anti-flicker path the dwell exists for', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        // 130 (zone 3) and 150 (zone 4), once a second, for 30s — every
        // reading replaces the previous candidate before it can ever
        // accumulate the 10s dwell, so this specifically exercises the
        // candidate-replacement branch with two genuinely different zones,
        // not just the "same zone repeated" path the other tests cover.
        for (var i = 0; i < 30; i++) {
          hr.emitHeartRate(i.isEven ? 130 : 150);
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 1));
        }

        expect(received, isEmpty,
            reason: 'boundary flicker between two zones must never be '
                'announced — this is the single most likely way the '
                'feature becomes intolerable');
      });
    });
  });

  group('above cap', () {
    test('emits immediately on the first reading above the cap', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(190);
        async.flushMicrotasks();

        expect(received, hasLength(1));
        final event = received.single as HeartRateAboveCap;
        expect(event.bpm, 190);
        expect(event.cap, 180);
      });
    });

    test('does not repeat before capRepeat elapses', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(190);
        async.flushMicrotasks();
        expect(received.whereType<HeartRateAboveCap>(), hasLength(1));

        // A real strap reports roughly once a second; readings every second
        // for 29s keep the signal-loss timer from firing (it would
        // otherwise fire on a single 29s gap with nothing in between and
        // wrongly clear _aboveCap, which is not what this test is about —
        // see the dedicated 'signal loss' group for that).
        for (var i = 0; i < 29; i++) {
          async.elapse(const Duration(seconds: 1));
          hr.emitHeartRate(190);
          async.flushMicrotasks();
        }

        expect(received.whereType<HeartRateAboveCap>(), hasLength(1),
            reason: 'the 30 second repeat window has not elapsed yet');
      });
    });

    test('repeats every capRepeat (30s) while it stays above', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(190);
        async.flushMicrotasks();
        expect(received.whereType<HeartRateAboveCap>(), hasLength(1));

        for (var i = 0; i < 31; i++) {
          async.elapse(const Duration(seconds: 1));
          hr.emitHeartRate(190);
          async.flushMicrotasks();
        }

        expect(received.whereType<HeartRateAboveCap>(), hasLength(2));
      });
    });
  });

  group('back below cap hysteresis', () {
    test('stays above while only marginally below the cap (within margin)', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(190); // above cap of 180
        async.flushMicrotasks();
        expect(received, hasLength(1));

        // 178 is below 180 but within the 5 bpm hysteresis margin (i.e. not
        // <= 175), so it must not count as "meaningfully below".
        for (var i = 0; i < 8; i++) {
          async.elapse(const Duration(seconds: 1));
          hr.emitHeartRate(178);
          async.flushMicrotasks();
        }

        expect(received, hasLength(1),
            reason: 'a reading within the hysteresis margin of the cap must '
                'never trigger back-below-cap');
      });
    });

    test(
        'emits back-below once the reading has been meaningfully below the '
        'cap for the hysteresis dwell', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(190);
        async.flushMicrotasks();
        expect(received, hasLength(1));

        // 170 <= 180 - 5 = 175, so this is "meaningfully below".
        async.elapse(const Duration(seconds: 1));
        hr.emitHeartRate(170);
        async.flushMicrotasks();
        expect(received, hasLength(1),
            reason: 'the hysteresis dwell has not elapsed yet');

        async.elapse(const Duration(seconds: 3));
        hr.emitHeartRate(170);
        async.flushMicrotasks();
        expect(received, hasLength(1),
            reason: 'still short of the 5 second hysteresis dwell');

        async.elapse(const Duration(seconds: 2));
        hr.emitHeartRate(170);
        async.flushMicrotasks();

        expect(received, hasLength(2));
        expect(received.last, isA<HeartRateBackBelowCap>());
      });
    });

    test(
        'a partial recovery that returns near the cap resets the hysteresis '
        'dwell rather than resuming it', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        // Filtered to the cap events specifically: the readings below stay
        // in zone 5 throughout, and the dwell/reset arithmetic this test
        // exercises pushes total elapsed time past the (unrelated) zone
        // dwell, which would otherwise contaminate a raw `received` count.
        List<TrainerEvent> capEvents() => received
            .where((e) => e is HeartRateAboveCap || e is HeartRateBackBelowCap)
            .toList();

        hr.emitHeartRate(190);
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 1));
        hr.emitHeartRate(170); // meaningfully below; dwell candidate starts
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 3));
        hr.emitHeartRate(170); // 3s into the dwell, not yet 5s
        async.flushMicrotasks();
        expect(capEvents(), hasLength(1));

        async.elapse(const Duration(seconds: 1));
        hr.emitHeartRate(178); // pops back within the margin band
        async.flushMicrotasks();
        expect(capEvents(), hasLength(1));

        // If the dwell had merely paused rather than reset, 5s after the
        // very first below-cap reading (i.e. now) would already satisfy it.
        async.elapse(const Duration(seconds: 1));
        hr.emitHeartRate(170);
        async.flushMicrotasks();
        expect(capEvents(), hasLength(1),
            reason: 'the dwell must restart from this reading, not resume '
                'from the interrupted attempt');

        async.elapse(const Duration(seconds: 5));
        hr.emitHeartRate(170);
        async.flushMicrotasks();

        expect(capEvents(), hasLength(2));
        expect(capEvents().last, isA<HeartRateBackBelowCap>());
      });
    });

    test(
        'rapid oscillation around the cap does not produce alternating '
        'events', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        const oscillation = [182, 178, 183, 177, 181, 179, 184, 176];
        for (final bpm in oscillation) {
          hr.emitHeartRate(bpm);
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 1));
        }

        expect(received, hasLength(1),
            reason: 'noise of a few beats either side of the cap must '
                'produce exactly the one initial warning, never an '
                'alternating above/below chatter');
        expect(received.single, isA<HeartRateAboveCap>());
      });
    });

    test('a genuine second crossing after back-below warns immediately', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(190);
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 1));
        hr.emitHeartRate(170);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));
        hr.emitHeartRate(170);
        async.flushMicrotasks();
        expect(received, hasLength(2));
        expect(received.last, isA<HeartRateBackBelowCap>());

        async.elapse(const Duration(seconds: 1));
        hr.emitHeartRate(190);
        async.flushMicrotasks();

        expect(received, hasLength(3),
            reason: 'a genuine new crossing is new information and must not '
                'be swallowed by a stale 30 second repeat window');
        expect(received.last, isA<HeartRateAboveCap>());
      });
    });
  });

  group('signal loss', () {
    test('a quiet stream while above cap emits back-below after the timeout',
        () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(190);
        async.flushMicrotasks();
        expect(received, hasLength(1));

        async.elapse(const Duration(seconds: 24));
        expect(received, hasLength(1),
            reason: 'the signal-loss timeout has not elapsed yet');

        async.elapse(const Duration(seconds: 1));
        expect(received, hasLength(2));
        expect(received.last, isA<HeartRateBackBelowCap>());
      });
    });

    test('a quiet stream while not above cap stays silent', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(130); // ordinary reading, well under the cap
        async.flushMicrotasks();

        // Past the 25s default signal-loss timeout, so this genuinely
        // exercises the quiet-timer firing, not just a gap too short to
        // matter.
        async.elapse(const Duration(seconds: 30));

        expect(received.whereType<HeartRateBackBelowCap>(), isEmpty);
      });
    });

    test('the stream closing while above cap emits back-below', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(190);
        async.flushMicrotasks();
        expect(received, hasLength(1));

        hr.dispose(); // closes the heart rate stream controller
        async.flushMicrotasks();

        expect(received, hasLength(2));
        expect(received.last, isA<HeartRateBackBelowCap>());
      });
    });

    test('the stream erroring while above cap emits back-below', () {
      fakeAsync((async) {
        final hr = _ErroringHeartRateService();
        final container = buildContainer(heartRateService: hr);
        container.read(_sourceUnderTest);

        hr.addReading(190);
        async.flushMicrotasks();
        expect(received, hasLength(1));

        hr.addError();
        async.flushMicrotasks();

        expect(received, hasLength(2));
        expect(received.last, isA<HeartRateBackBelowCap>());
      });
    });
  });

  group('zone configuration', () {
    test('null zone config emits nothing at all', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container =
            buildContainer(heartRateService: hr, nullZoneConfig: true);
        container.read(_sourceUnderTest);

        hr.emitHeartRate(130);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 15));
        hr.emitHeartRate(190); // would be above a 180 cap, if there were one
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 40));

        expect(received, isEmpty);
      });
    });

    test(
        'the config going null mid-session while above cap immediately '
        'clears the stuck suppression, not just on the next signal-loss '
        'timeout', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        ZoneConfiguration? config = _config();
        final container = buildContainer(
          heartRateService: hr,
          zoneConfigResolver: () => config,
        );
        container.read(_sourceUnderTest);

        hr.emitHeartRate(190); // above the 180 cap while config is usable
        async.flushMicrotasks();
        expect(received, hasLength(1));
        expect(received.single, isA<HeartRateAboveCap>());

        // The user clears their health profile — calculateZones can no
        // longer resolve a method, so zoneConfigurationProvider goes null.
        config = null;
        container.invalidate(zoneConfigurationProvider);

        hr.emitHeartRate(190); // would still be above a cap, if one existed
        async.flushMicrotasks();

        expect(received, hasLength(2),
            reason: 'a null config must not leave _aboveCap stuck; without '
                'this fix, encouragement would stay suppressed for the rest '
                'of the session with no event able to lift it, and nothing '
                'short of the (much longer) signal-loss timeout would ever '
                'clear it');
        expect(received.last, isA<HeartRateBackBelowCap>());

        // And it must not then repeat on every further null-config reading —
        // _aboveCap is already false, so there is nothing left to clear.
        hr.emitHeartRate(190);
        async.flushMicrotasks();
        expect(received, hasLength(2));
      });
    });
  });

  group('lifecycle', () {
    test('dispose cancels the subscription and the signal-loss timer', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(heartRateService: hr);
        final source = container.read(_sourceUnderTest);

        hr.emitHeartRate(190);
        async.flushMicrotasks();
        expect(received, hasLength(1));

        source.dispose();

        // If dispose failed to cancel the signal-loss timer, this elapse
        // would fire it and wrongly emit HeartRateBackBelowCap even though
        // the source has been torn down.
        async.elapse(const Duration(seconds: 25));
        expect(received, hasLength(1),
            reason: 'dispose must cancel the signal-loss timer');

        // A leaked subscription would still forward further readings. The
        // probe has to be one that would actually emit from a *live* source
        // — a bare disconnected-looking value like 30 resolves to no zone
        // and, since bpm <= cap, only ever touches `_belowCapSince` inside
        // `_handleCap`, so it would pass this assertion even with a leaked
        // subscription. 130 twice, 5s apart, is exactly the sequence that
        // would produce HeartRateBackBelowCap from a live source (still
        // above cap from the very first reading above).
        hr.emitHeartRate(130);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));
        hr.emitHeartRate(130);
        async.flushMicrotasks();
        expect(received, hasLength(1),
            reason: 'dispose must cancel the stream subscription');
      });
    });

    test(
        'the real hrEventSourceProvider constructs with its default '
        'parameters and disposes when the container does', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = ProviderContainer(overrides: [
          heartRateServiceProvider.overrideWithValue(hr),
          entitlementServiceProvider.overrideWithValue(_AlwaysEntitled()),
          zoneConfigurationProvider.overrideWithValue(_config()),
        ]);
        final sub = container.read(trainerEventBusProvider).events.listen(
              received.add,
            );

        container.read(hrEventSourceProvider);
        hr.emitHeartRate(190);
        async.flushMicrotasks();
        expect(received, hasLength(1));
        expect(received.single, isA<HeartRateAboveCap>());

        container.dispose();

        // A leaked subscription from a source the container failed to
        // dispose would still forward this reading.
        hr.emitHeartRate(190);
        async.flushMicrotasks();
        expect(received, hasLength(1));

        unawaited(sub.cancel());
      });
    });
  });

  group('constructor parameters', () {
    test('custom durations and margin are honoured, not just the defaults', () {
      fakeAsync((async) {
        final hr = FakeHeartRateService();
        final container = buildContainer(
          heartRateService: hr,
          create: (ref) => HrEventSource(
            ref,
            zoneDwell: const Duration(seconds: 2),
            capRepeat: const Duration(seconds: 5),
            capHysteresisMargin: 2,
            capHysteresisDwell: const Duration(seconds: 1),
            signalLossTimeout: const Duration(seconds: 3),
          ),
        );
        container.read(_sourceUnderTest);

        // Cap events specifically: every bpm value used from here on sits in
        // zone 5, and with a 2s custom zoneDwell a second (unrelated) zone
        // callout is expected somewhere in here too — filtering keeps this
        // test's assertions about only the parameters it's actually probing.
        List<TrainerEvent> capEvents() => received
            .where((e) => e is HeartRateAboveCap || e is HeartRateBackBelowCap)
            .toList();

        // Zone dwell: 2s instead of the 10s default.
        hr.emitHeartRate(130);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        hr.emitHeartRate(130);
        async.flushMicrotasks();
        expect(received, hasLength(1));
        expect(received.single, isA<HeartRateZoneChanged>());

        // Cap repeat: 5s instead of the 30s default. Readings every 2s (well
        // under the custom 3s signal-loss timeout) keep the strap "alive"
        // while the 5s repeat window is crossed.
        hr.emitHeartRate(190);
        async.flushMicrotasks();
        expect(capEvents(), hasLength(1));
        for (var i = 0; i < 3; i++) {
          async.elapse(const Duration(seconds: 2));
          hr.emitHeartRate(190);
          async.flushMicrotasks();
        }
        expect(capEvents().whereType<HeartRateAboveCap>(), hasLength(2),
            reason: 'the 5 second custom repeat window was crossed');

        // Hysteresis margin/dwell: 2 bpm / 1s instead of 5 bpm / 5s. 177 is
        // more than 2 bpm below the 180 cap.
        async.elapse(const Duration(seconds: 1));
        hr.emitHeartRate(177);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        hr.emitHeartRate(177);
        async.flushMicrotasks();
        expect(capEvents(), hasLength(3));
        expect(capEvents().last, isA<HeartRateBackBelowCap>());

        // Signal-loss timeout: 3s instead of the 25s default.
        hr.emitHeartRate(190);
        async.flushMicrotasks();
        expect(capEvents(), hasLength(4));
        async.elapse(const Duration(seconds: 3));
        expect(capEvents(), hasLength(5));
        expect(capEvents().last, isA<HeartRateBackBelowCap>());
      });
    });
  });
}
