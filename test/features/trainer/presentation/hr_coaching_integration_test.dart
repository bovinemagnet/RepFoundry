import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/cardio/data/heart_rate_service.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/max_hr_alert_provider.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/zone_configuration_provider.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/coach_bridge.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/hr_event_source.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_settings_provider.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../cardio/data/fake_heart_rate_service.dart';
import '../data/silent_speech_service.dart';

/// End-to-end wiring test for Task 4: a fake HR service feeds
/// [HrEventSource], which emits onto the real [trainerEventBusProvider],
/// which [CoachBridge] turns into speech via [SilentSpeechService] — the
/// full path Tasks 1-3 built but nothing had connected yet.

class _AlwaysEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

/// Pushes a fixed [TrainerSettings] synchronously, bypassing
/// `SharedPreferences` — mirrors the identical helper in coach_bridge_test.
class _SeededTrainerSettingsNotifier extends TrainerSettingsNotifier {
  _SeededTrainerSettingsNotifier(this._seed);

  final TrainerSettings _seed;

  @override
  TrainerSettings build() => _seed;
}

/// Pushes a fixed [MaxHrAlertSettings] synchronously, bypassing
/// `SharedPreferences` — mirrors the identical helper in
/// hr_event_source_test. Needed because `_announceAboveCap` always reads
/// this provider, even when the panel isn't mounted and no delay applies.
class _SeededMaxHrAlertNotifier extends MaxHrAlertNotifier {
  _SeededMaxHrAlertNotifier(this._seed);

  final MaxHrAlertSettings _seed;

  @override
  MaxHrAlertSettings build() => _seed;
}

/// Zone boundaries matching hr_event_source_test's fixture: cap = maxHr =
/// 180, so 190 is above cap and 130/170 sit in zones 3/5 respectively
/// without crossing the cap.
ZoneConfiguration _config() => const ZoneConfiguration(
      method: ZoneMethod.percentOfEstimatedMax,
      reliability: ZoneReliability.medium,
      maxHr: 180,
      reason: 'test config',
      zones: [
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Builds a real container (not a stand-in) wired for the happy path:
  /// entitled, enabled, disclaimer accepted, both HR toggles on, and a
  /// usable zone config. The panel-visibility flag is deliberately left at
  /// its default (false / not mounted) throughout this file — that default
  /// is exactly what step 5 of the brief needs to prove.
  ProviderContainer buildContainer({
    required HeartRateService heartRateService,
    required SilentSpeechService speechService,
    TrainerSettings settings = const TrainerSettings(
      enabled: true,
      disclaimerAccepted: true,
    ),
    bool cautionMode = false,
  }) {
    final container = ProviderContainer(overrides: [
      heartRateServiceProvider.overrideWithValue(heartRateService),
      entitlementServiceProvider.overrideWithValue(_AlwaysEntitled()),
      speechServiceProvider.overrideWithValue(speechService),
      trainerSettingsProvider.overrideWith(
        () => _SeededTrainerSettingsNotifier(settings),
      ),
      zoneConfigurationProvider.overrideWithValue(_config()),
      // Overridden directly rather than left to resolve through
      // healthProfileProvider, which needs a real client/database this test
      // file doesn't set up.
      cautionModeProvider.overrideWithValue(cautionMode),
      // Overridden directly rather than left to resolve through
      // SharedPreferences, which the real notifier can't load without a
      // mocked plugin channel this test file doesn't set up.
      maxHrAlertProvider.overrideWith(
        () => _SeededMaxHrAlertNotifier(const MaxHrAlertSettings()),
      ),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  /// Mounts both real providers the way `router.dart`'s shell does, and
  /// pushes in the localisations the bridge needs before it can speak.
  void mountCoach(ProviderContainer container) {
    final bridge = container.read(coachBridgeProvider);
    bridge.strings = lookupS(const Locale('en'));
    container.read(hrEventSourceProvider);
  }

  test(
      'zone change after dwell speaks, cap crossing speaks a safety line, '
      'and encouragement goes silent above cap and returns below it', () {
    fakeAsync((async) {
      final hr = FakeHeartRateService();
      final speech = SilentSpeechService();
      final container =
          buildContainer(heartRateService: hr, speechService: speech);
      mountCoach(container);

      // Zone change after dwell speaks.
      hr.emitHeartRate(130); // zone 3
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 10));
      hr.emitHeartRate(130);
      async.flushMicrotasks();

      expect(speech.spoken, hasLength(1),
          reason: 'the zone callout must speak once the dwell has elapsed');
      expect(speech.spoken.single, contains('Zone 3'));

      // Cap crossing speaks a safety line.
      hr.emitHeartRate(190);
      async.flushMicrotasks();

      expect(speech.spoken, hasLength(2));
      expect(speech.spoken.last, contains('maximum'));

      // Clears the engine's 20s encouragement cooldown, which the cap
      // crossing's speak just started (via clock.now(), driven by this same
      // fake clock). Without this, the loop below is blocked by the
      // cooldown before it ever reaches the above-cap suppression check —
      // it would pass even with that suppression deleted entirely.
      async.elapse(const Duration(seconds: 21));

      // Encouragement goes silent above cap: push comfortably more than the
      // engine's max encouragement quota (3 sets) — if suppression were
      // broken, at least one of these would speak regardless of the exact
      // (randomised, unseeded in the real bridge) quota drawn.
      for (var setNumber = 1; setNumber <= 5; setNumber++) {
        container.read(trainerEventBusProvider).emit(
              SetLogged(setNumber: setNumber, isPersonalRecord: false),
            );
        async.flushMicrotasks();
      }
      expect(speech.spoken, hasLength(2),
          reason: 'encouragement must stay completely silent while above '
              'the safety cap');

      // Back below cap (hysteresis: meaningfully below for the dwell).
      // 140, not 170: by now the 21s elapse above has left the zone-5
      // candidate (started by the 190 reading) sitting well past its own
      // 10s dwell, so a reading that still sits in zone 5 (>=162) would
      // silently promote it — engine correctly never speaks that (still
      // above cap), but it would leave `_currentZone == 5` afterwards, and
      // encouragement never fires in zone 5 by design, permanently
      // confounding the "resumes below cap" assertion below with an
      // unrelated suppression rule. 140 matches the zone (3) already
      // promoted at the top of this test, so no candidate is even pending.
      async.elapse(const Duration(seconds: 1));
      hr.emitHeartRate(140);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 5));
      hr.emitHeartRate(140);
      async.flushMicrotasks();

      expect(speech.spoken, hasLength(3));
      expect(speech.spoken.last, contains('under your maximum'));

      // Encouragement returns below cap — same over-provisioned push as
      // above so the assertion doesn't depend on the exact random quota.
      // Also clears the engine's 20s encouragement cooldown (now driven by
      // the same fake clock as everything else in this test, via
      // package:clock), which the back-below-cap line above just started.
      async.elapse(const Duration(seconds: 21));
      final spokenBeforeReturn = speech.spoken.length;
      for (var setNumber = 6; setNumber <= 10; setNumber++) {
        container.read(trainerEventBusProvider).emit(
              SetLogged(setNumber: setNumber, isPersonalRecord: false),
            );
        async.flushMicrotasks();
      }
      expect(speech.spoken.length, greaterThan(spokenBeforeReturn),
          reason: 'encouragement must resume once genuinely back below cap');
    });
  });

  // Step 5 of the brief: the gap-closure benefit this whole feature exists
  // for. Before this task, a safety warning was only ever heard while the
  // HR panel screen happened to be on screen; mounting HrEventSource at the
  // app-shell level (router.dart), independent of any one screen, is what
  // fixes that. heartRatePanelVisibleProvider is left at its default
  // (false) throughout this test — the panel is never mounted.
  test(
      'a cap crossing still produces a spoken warning when the HR panel '
      'screen is not mounted', () {
    fakeAsync((async) {
      final hr = FakeHeartRateService();
      final speech = SilentSpeechService();
      final container =
          buildContainer(heartRateService: hr, speechService: speech);
      mountCoach(container);

      hr.emitHeartRate(190);
      async.flushMicrotasks();

      expect(speech.spoken, hasLength(1),
          reason: 'the coach must not be gated behind the HR panel screen '
              'being on screen');
      expect(speech.spoken.single, contains('maximum'));
    });
  });

  test(
      'cap warnings pass through when hrSafetyWarningsEnabled is true, '
      'and stay silent when the user has switched it off', () {
    fakeAsync((async) {
      final hr = FakeHeartRateService();
      final speech = SilentSpeechService();
      final container = buildContainer(
        heartRateService: hr,
        speechService: speech,
        settings: const TrainerSettings(
          enabled: true,
          disclaimerAccepted: true,
          hrSafetyWarningsEnabled: false,
        ),
      );
      mountCoach(container);

      hr.emitHeartRate(190);
      async.flushMicrotasks();

      expect(speech.spoken, isEmpty,
          reason: 'the user switched safety warnings off — that choice '
              'must be honoured end to end');
    });
  });

  // Fix round 1: cautionMode and hrCalloutsEnabled were only exercised at
  // the engine layer — every bridge/integration test pinned
  // cautionModeProvider to false and none drove hrCalloutsEnabled: false
  // through real TrainerSettings, so the suite stayed green even with both
  // hardcoded in coach_bridge.dart. These two prove the bridge itself
  // actually reads them, not just that the engine honours them once told.
  test(
      'cautionMode true silences encouragement but still speaks a cap '
      'warning', () {
    fakeAsync((async) {
      final hr = FakeHeartRateService();
      final speech = SilentSpeechService();
      final container = buildContainer(
        heartRateService: hr,
        speechService: speech,
        cautionMode: true,
      );
      mountCoach(container);

      // Over-provisioned past the engine's max encouragement quota (3
      // sets), same reasoning as the main test above: `_lastSpokenAt` is
      // null at the start of this test, so nothing here is blocked by the
      // cooldown gate — a hardcoded `cautionMode: false` in the bridge
      // would let at least one of these through.
      for (var setNumber = 1; setNumber <= 5; setNumber++) {
        container.read(trainerEventBusProvider).emit(
              SetLogged(setNumber: setNumber, isPersonalRecord: false),
            );
        async.flushMicrotasks();
      }
      expect(speech.spoken, isEmpty,
          reason: 'caution mode must suppress encouragement — this has to '
              'come from the bridge actually reading cautionModeProvider, '
              'not a hardcoded false');

      hr.emitHeartRate(190);
      async.flushMicrotasks();
      expect(speech.spoken, hasLength(1),
          reason: 'the safety cue is never gated by caution mode');
      expect(speech.spoken.single, contains('maximum'));
    });
  });

  test(
      'hrCalloutsEnabled false silences the zone callout but still speaks '
      'a cap warning', () {
    fakeAsync((async) {
      final hr = FakeHeartRateService();
      final speech = SilentSpeechService();
      final container = buildContainer(
        heartRateService: hr,
        speechService: speech,
        settings: const TrainerSettings(
          enabled: true,
          disclaimerAccepted: true,
          hrCalloutsEnabled: false,
        ),
      );
      mountCoach(container);

      hr.emitHeartRate(130); // zone 3
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 10));
      hr.emitHeartRate(130);
      async.flushMicrotasks();
      expect(speech.spoken, isEmpty,
          reason: 'hrCalloutsEnabled is off — the zone callout must not '
              'speak, and this has to come from the bridge actually '
              'reading the setting, not a hardcoded true');

      hr.emitHeartRate(190);
      async.flushMicrotasks();
      expect(speech.spoken, hasLength(1),
          reason: 'the safety cue is never gated by hrCalloutsEnabled');
      expect(speech.spoken.single, contains('maximum'));
    });
  });
}
