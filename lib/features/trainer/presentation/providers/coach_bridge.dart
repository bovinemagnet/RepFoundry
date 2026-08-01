import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/entitlements/entitlement.dart';
import '../../../../core/entitlements/entitlement_provider.dart';
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
    _engine = CoachingEngine(persona: steadyPersona, random: random);
    _subscription = _ref.read(trainerEventBusProvider).events.listen(_onEvent);
    // The master switch must cut off in-flight speech immediately, rather
    // than only preventing the next cue — `_onEvent`'s early return alone
    // cannot do that.
    _ref.listen<TrainerSettings>(trainerSettingsProvider, (previous, next) {
      if ((previous?.enabled ?? false) && !next.enabled) {
        unawaited(_ref.read(speechServiceProvider).stop());
      }
    });
  }

  final Ref _ref;

  /// Set by the widget that mounts this bridge, every time it (re)builds.
  /// `null` only until the first build; events arriving before then are
  /// dropped rather than crashing.
  S? strings;

  late final CoachingEngine _engine;
  late final StreamSubscription<TrainerEvent> _subscription;

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

    final cue = _engine.onEvent(event, now: DateTime.now());
    if (cue != null && _allowedBySettings(cue, settings)) {
      final text = resolvePhrase(strings, cue.phraseKey, cue.args);
      if (text != null) {
        unawaited(
          _ref.read(speechServiceProvider).speak(text, priority: cue.priority),
        );
      }
    }

    // Reset for the next session, but never cut off the sign-off line we just
    // started speaking.
    if (event is WorkoutFinished) {
      _engine.reset();
      if (cue == null) unawaited(_ref.read(speechServiceProvider).stop());
    }
  }

  bool _allowedBySettings(CoachingCue cue, TrainerSettings settings) {
    return switch (cue.priority) {
      SpeechPriority.countdown => settings.countdownsEnabled,
      SpeechPriority.encouragement => settings.encouragementEnabled,
      SpeechPriority.milestone || SpeechPriority.safety => true,
    };
  }

  void dispose() {
    unawaited(_subscription.cancel());
  }
}

final coachBridgeProvider = Provider<CoachBridge>((ref) {
  final bridge = CoachBridge(ref);
  ref.onDispose(bridge.dispose);
  return bridge;
});
