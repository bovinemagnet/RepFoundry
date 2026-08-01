import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/coach_bridge.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_settings_provider.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../data/silent_speech_service.dart';

class _AlwaysEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

class _NeverEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => false;
}

/// Pushes a fixed [TrainerSettings] synchronously, bypassing
/// `SharedPreferences` entirely, and exposes [forceUpdate] so a test can
/// simulate a setting changing under the bridge's feet without going through
/// the notifier's own public API (which enforces invariants the bridge is
/// specifically meant to re-check independently of).
class _SeededTrainerSettingsNotifier extends TrainerSettingsNotifier {
  _SeededTrainerSettingsNotifier(this._seed);

  final TrainerSettings _seed;

  @override
  TrainerSettings build() => _seed;

  void forceUpdate(TrainerSettings next) => state = next;
}

/// A stand-in for [coachBridgeProvider] whose `create` callback each test
/// overrides, so the engine's [Random] source can be seeded — the real
/// provider only ever passes `null` (unseeded) in production.
final _bridgeUnderTest = Provider<CoachBridge>((ref) => CoachBridge(ref));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SilentSpeechService speechService;

  setUp(() {
    speechService = SilentSpeechService();
  });

  /// Builds a container wired for the happy path: entitled, enabled, and the
  /// disclaimer accepted, with a seeded (reproducible) engine. Individual
  /// tests override what they need to exercise a specific gate.
  ProviderContainer buildContainer({
    TrainerSettings settings = const TrainerSettings(
      enabled: true,
      disclaimerAccepted: true,
    ),
    EntitlementService? entitlementService,
    TrainerEventBus? bus,
    int seed = 1,
  }) {
    final overrides = [
      speechServiceProvider.overrideWithValue(speechService),
      trainerSettingsProvider.overrideWith(
        () => _SeededTrainerSettingsNotifier(settings),
      ),
      entitlementServiceProvider
          .overrideWithValue(entitlementService ?? _AlwaysEntitled()),
      _bridgeUnderTest.overrideWith((ref) {
        final bridge = CoachBridge(ref, random: Random(seed));
        ref.onDispose(bridge.dispose);
        return bridge;
      }),
    ];
    if (bus != null) {
      overrides.add(trainerEventBusProvider.overrideWithValue(bus));
    }
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    return container;
  }

  test('speaks a resolved phrase when enabled, accepted, and entitled',
      () async {
    final container = buildContainer();
    final bridge = container.read(_bridgeUnderTest);
    bridge.strings = lookupS(const Locale('en'));

    container.read(trainerEventBusProvider).emit(const WorkoutStarted());
    await Future<void>.delayed(Duration.zero);

    expect(speechService.spoken, hasLength(1));
  });

  test(
      'does not speak when the disclaimer has not been accepted, even if '
      'enabled — the bridge enforces this independently of the notifier',
      () async {
    final container = buildContainer(
      settings: const TrainerSettings(enabled: true, disclaimerAccepted: false),
    );
    final bridge = container.read(_bridgeUnderTest);
    bridge.strings = lookupS(const Locale('en'));

    container.read(trainerEventBusProvider).emit(const WorkoutStarted());
    await Future<void>.delayed(Duration.zero);

    expect(speechService.spoken, isEmpty);
  });

  test(
      'does not speak when not entitled, even if the bus itself would have '
      'let the event through — the bridge re-checks independently of the bus',
      () async {
    // The bus is given its own always-true entitlement callback, decoupled
    // from `entitlementServiceProvider`, so this specifically exercises the
    // bridge's own check rather than the bus's (already-tested) gate.
    final container = buildContainer(
      bus: TrainerEventBus(() => true),
      entitlementService: _NeverEntitled(),
    );
    final bridge = container.read(_bridgeUnderTest);
    bridge.strings = lookupS(const Locale('en'));

    container.read(trainerEventBusProvider).emit(const WorkoutStarted());
    await Future<void>.delayed(Duration.zero);

    expect(speechService.spoken, isEmpty);
  });

  test(
      'WorkoutStarted resets the engine so a nearly-exhausted phrase kind has '
      'its full pool back afterwards', () async {
    // Use up 2 of the 3 restFinished phrases, leaving exactly one unheard.
    // Without a reset, the engine's "prefer unheard" rule would then force
    // that one remaining phrase every single time, with no randomness left
    // to vary the outcome — so if WorkoutStarted did not reset the engine,
    // every trial below would produce the exact same closing line regardless
    // of seed. Observing more than one distinct outcome across seeds proves
    // the reset happened.
    final outcomes = <String>{};

    for (var seed = 1; seed <= 12; seed++) {
      final trialSpeech = SilentSpeechService();
      final container = ProviderContainer(overrides: [
        speechServiceProvider.overrideWithValue(trialSpeech),
        trainerSettingsProvider.overrideWith(
          () => _SeededTrainerSettingsNotifier(
            const TrainerSettings(enabled: true, disclaimerAccepted: true),
          ),
        ),
        entitlementServiceProvider.overrideWithValue(_AlwaysEntitled()),
        _bridgeUnderTest.overrideWith((ref) {
          final bridge = CoachBridge(ref, random: Random(seed));
          ref.onDispose(bridge.dispose);
          return bridge;
        }),
      ]);
      addTearDown(container.dispose);

      final bridge = container.read(_bridgeUnderTest);
      bridge.strings = lookupS(const Locale('en'));

      final bus = container.read(trainerEventBusProvider);
      bus.emit(const RestFinished());
      await Future<void>.delayed(Duration.zero);
      bus.emit(const RestFinished());
      await Future<void>.delayed(Duration.zero);

      bus.emit(const WorkoutStarted());
      await Future<void>.delayed(Duration.zero);

      bus.emit(const RestFinished());
      await Future<void>.delayed(Duration.zero);

      outcomes.add(trialSpeech.spoken.last);
    }

    expect(
      outcomes.length,
      greaterThan(1),
      reason: 'if WorkoutStarted did not reset the engine, the one phrase '
          'left unheard before it would be forced every time regardless of '
          'seed, and every trial would produce the same line',
    );
  });

  test(
      'countdown cues are suppressed by the countdowns toggle, but milestone '
      'cues are not', () async {
    final container = buildContainer(
      settings: const TrainerSettings(
        enabled: true,
        disclaimerAccepted: true,
        countdownsEnabled: false,
      ),
    );
    final bridge = container.read(_bridgeUnderTest);
    bridge.strings = lookupS(const Locale('en'));

    final bus = container.read(trainerEventBusProvider);
    bus.emit(const RestCountdown(secondsLeft: 3));
    await Future<void>.delayed(Duration.zero);
    expect(speechService.spoken, isEmpty);

    bus.emit(const WorkoutStarted());
    await Future<void>.delayed(Duration.zero);
    expect(speechService.spoken, hasLength(1));
  });

  test(
      'encouragement cues are suppressed by the encouragement toggle, but a '
      'personal record still speaks', () async {
    final container = buildContainer(
      settings: const TrainerSettings(
        enabled: true,
        disclaimerAccepted: true,
        encouragementEnabled: false,
      ),
    );
    final bridge = container.read(_bridgeUnderTest);
    bridge.strings = lookupS(const Locale('en'));

    final bus = container.read(trainerEventBusProvider);
    bus.emit(const SetLogged(setNumber: 1, isPersonalRecord: false));
    await Future<void>.delayed(Duration.zero);
    bus.emit(const SetLogged(setNumber: 2, isPersonalRecord: false));
    await Future<void>.delayed(Duration.zero);
    expect(speechService.spoken, isEmpty,
        reason: 'encouragement toggle is off, so the second-set cue must '
            'stay silent');

    bus.emit(const SetLogged(setNumber: 3, isPersonalRecord: true));
    await Future<void>.delayed(Duration.zero);
    expect(speechService.spoken, hasLength(1),
        reason: 'a personal record is a milestone cue and is never gated by '
            'the encouragement toggle');
  });

  test('turning the master switch off stops any in-flight speech immediately',
      () async {
    final container = buildContainer();
    final bridge = container.read(_bridgeUnderTest);
    bridge.strings = lookupS(const Locale('en'));

    expect(speechService.stopCount, 0);

    final notifier = container.read(trainerSettingsProvider.notifier)
        as _SeededTrainerSettingsNotifier;
    notifier.forceUpdate(
      container.read(trainerSettingsProvider).copyWith(enabled: false),
    );

    expect(speechService.stopCount, 1,
        reason: 'the master switch must cut off in-flight speech '
            'immediately, not just prevent the next cue');
  });

  test(
      'reading coachBridgeProvider again after a locale change reuses the '
      'same bridge instead of leaking a duplicate subscription', () async {
    final container = ProviderContainer(overrides: [
      speechServiceProvider.overrideWithValue(speechService),
      trainerSettingsProvider.overrideWith(
        () => _SeededTrainerSettingsNotifier(
          const TrainerSettings(enabled: true, disclaimerAccepted: true),
        ),
      ),
      entitlementServiceProvider.overrideWithValue(_AlwaysEntitled()),
    ]);
    addTearDown(container.dispose);

    final bridge = container.read(coachBridgeProvider);
    bridge.strings = lookupS(const Locale('en'));

    // Simulate the shell rebuilding after a locale change: it reads the
    // provider again and pushes in a new `S` instance.
    final bridgeAfterLocaleChange = container.read(coachBridgeProvider);
    bridgeAfterLocaleChange.strings = lookupS(const Locale('ja'));

    expect(
      identical(bridge, bridgeAfterLocaleChange),
      isTrue,
      reason: 'coachBridgeProvider must not be keyed on the localisations '
          'instance, or a locale change leaks a second, still-subscribed '
          'bridge',
    );

    container.read(trainerEventBusProvider).emit(const WorkoutStarted());
    await Future<void>.delayed(Duration.zero);

    expect(speechService.spoken, hasLength(1),
        reason: 'a leaked second bridge would speak every cue twice');
  });

  test(
      'speechServiceProvider is not rebuilt when an unrelated setting '
      'changes — only speechRate should recreate the TTS engine', () {
    final container = ProviderContainer(overrides: [
      trainerSettingsProvider.overrideWith(
        () => _SeededTrainerSettingsNotifier(const TrainerSettings()),
      ),
    ]);
    addTearDown(container.dispose);

    final first = container.read(speechServiceProvider);
    final notifier = container.read(trainerSettingsProvider.notifier)
        as _SeededTrainerSettingsNotifier;
    notifier.forceUpdate(
      container
          .read(trainerSettingsProvider)
          .copyWith(countdownsEnabled: false),
    );

    final second = container.read(speechServiceProvider);
    expect(
      identical(first, second),
      isTrue,
      reason: 'toggling an unrelated setting must not tear down and '
          'recreate the TTS engine mid-session',
    );
  });
}
