import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/entitlements/entitlement.dart';
import '../../../../core/entitlements/entitlement_provider.dart';
import '../../../../core/entitlements/entitlement_service.dart';
import '../../../heart_rate/presentation/providers/zone_configuration_provider.dart';
import '../../application/coaching_engine.dart';
import '../../data/flutter_tts_speech_service.dart';
import '../../data/persona_packs.dart';
import '../../domain/coaching_cue.dart';
import '../../domain/speech_service.dart';
import '../../domain/trainer_event.dart';
import 'phrase_resolver.dart';
import 'trainer_event_bus.dart';
import 'trainer_settings_provider.dart';

/// Only the speech rate should ever recreate the TTS engine: every other
/// settings write (toggles, disclaimer, master switch) must not tear it down
/// mid-utterance. `select` narrows the rebuild trigger to that one field.
final speechServiceProvider = Provider<SpeechService>((ref) {
  final rate = ref.watch(trainerSettingsProvider.select((s) => s.speechRate));
  final service = FlutterTtsSpeechService(speechRate: rate);
  ref.onDispose(service.dispose);
  return service;
});

/// Connects the event bus to the engine to the voice.
///
/// A single instance lives for the container's lifetime (see
/// [coachBridgeProvider], a plain non-family [Provider] so it is never
/// recreated). The widget that mounts it pushes the current localisations
/// instance in via [strings] on every build, so a locale change updates the
/// existing subscription in place instead of leaking a second one.
class CoachBridge {
  CoachBridge(this._ref, {Random? random}) {
    _engine = CoachingEngine(
      persona: personaForId(_ref.read(trainerSettingsProvider).personaId),
      random: random,
    );
    _subscription = _ref.read(trainerEventBusProvider).events.listen(_onEvent);
    // The master switch must cut off in-flight speech immediately, rather
    // than only preventing the next cue — `_onEvent`'s early return alone
    // cannot do that.
    _ref.listen<TrainerSettings>(trainerSettingsProvider, (previous, next) {
      if ((previous?.enabled ?? false) && !next.enabled) {
        unawaited(_ref.read(speechServiceProvider).stop());
      }
      // A persona switch takes effect from the next cue onward. Fix round 1:
      // this used to discard the whole engine and build a fresh one, which
      // silently threw away live heart-rate safety state (`_aboveCap`,
      // `_currentZone`, the cap-warning cooldown) along with it — see
      // `CoachingEngine.persona`'s doc comment for why that mattered. Setting
      // the persona in place instead keeps that state intact; only the
      // phrase bank changes. Without reacting to the change at all,
      // `TrainerSettings.personaId` would persist but the bridge would keep
      // speaking Steady's bank regardless of what the user picked.
      if (previous != null && previous.personaId != next.personaId) {
        _engine.persona = personaForId(next.personaId);
      }
    });
    // Losing the entitlement mid-utterance must silence the coach for the
    // same reason: revoking access has to take effect now, not after the
    // sentence in flight finishes.
    //
    // Subscribed through the container rather than with `_ref.listen`:
    // `entitlementServiceProvider` is derived, and a provider-internal
    // listener on a derived provider is lazy — nothing recomputes it, so the
    // callback would never fire until some unrelated reader happened to
    // touch it. A container subscription keeps it eagerly recomputed. It is
    // closed in [dispose] alongside the event subscription.
    _entitlementSubscription = _ref.container.listen<EntitlementService>(
      entitlementServiceProvider,
      (previous, next) {
        final had = previous?.has(Entitlement.virtualTrainer) ?? false;
        if (had && !next.has(Entitlement.virtualTrainer)) {
          unawaited(_ref.read(speechServiceProvider).stop());
        }
      },
    );
  }

  final Ref _ref;

  /// Set by the widget that mounts this bridge, every time it (re)builds.
  /// `null` only until the first build; events arriving before then are
  /// dropped rather than crashing.
  S? strings;

  late final CoachingEngine _engine;
  late final StreamSubscription<TrainerEvent> _subscription;
  late final ProviderSubscription<EntitlementService> _entitlementSubscription;

  void _onEvent(TrainerEvent event) {
    final strings = this.strings;
    if (strings == null) return;

    final settings = _ref.read(trainerSettingsProvider);
    if (!settings.enabled || !settings.disclaimerAccepted) return;
    if (!_ref
        .read(entitlementServiceProvider)
        .has(Entitlement.virtualTrainer)) {
      return;
    }

    if (event is WorkoutStarted) _engine.reset();

    // The toggles go *into* the engine rather than filtering its result: a
    // cue the user has switched off must not consume a phrase from the
    // variety bank nor restart the encouragement cooldown.
    final cue = _engine.onEvent(
      event,
      now: clock.now(),
      countdownsEnabled: settings.countdownsEnabled,
      encouragementEnabled: settings.encouragementEnabled,
      hrCalloutsEnabled: settings.hrCalloutsEnabled,
      hrSafetyWarningsEnabled: settings.hrSafetyWarningsEnabled,
      cautionMode: _ref.read(cautionModeProvider),
      quotesEnabled: settings.quotesEnabled,
    );
    if (cue != null) {
      final text = _resolveCue(strings, cue);
      if (text != null) {
        unawaited(
          _ref.read(speechServiceProvider).speak(text, priority: cue.priority),
        );
      }
    }

    // Reset for the next session, but never cut off the sign-off line we just
    // started speaking. A null cue here can now mean two different things:
    // no phrase was available (safe to stop), or the finish cue was
    // suppressed because the reading is still above the safety cap — in
    // which case a SpeechPriority.safety warning is the most likely thing
    // still playing, and cutting it off mid-sentence is the one truncation
    // this feature must never produce. Read isAboveCap before reset() clears
    // it.
    if (event is WorkoutFinished) {
      final aboveCapAtFinish = _engine.isAboveCap;
      _engine.reset();
      if (cue == null && !aboveCapAtFinish) {
        unawaited(_ref.read(speechServiceProvider).stop());
      }
    }
  }

  /// Resolves a cue, folding in its attached quote as one utterance.
  ///
  /// Joined through the ARB rather than with a hardcoded space: `app_en.arb`
  /// has ja/ko/zh siblings where a bare inter-sentence space is wrong.
  ///
  /// If exactly one of the two keys fails to resolve, whatever did resolve is
  /// still spoken. `resolvePhrase` returns null for an unknown key, and
  /// speech time is the wrong place to lose a cue over a missing quote.
  String? _resolveCue(S strings, CoachingCue cue) {
    final text = resolvePhrase(strings, cue.phraseKey, cue.args);
    final quoteKey = cue.quotePhraseKey;
    if (quoteKey == null) return text;

    final quote = resolvePhrase(strings, quoteKey, const {});
    if (quote == null) return text;
    if (text == null) return quote;
    return strings.coachCueWithQuote(text, quote);
  }

  void dispose() {
    unawaited(_subscription.cancel());
    _entitlementSubscription.close();
  }
}

final coachBridgeProvider = Provider<CoachBridge>((ref) {
  final bridge = CoachBridge(ref);
  ref.onDispose(bridge.dispose);
  return bridge;
});
