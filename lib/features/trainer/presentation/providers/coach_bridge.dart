import 'dart:async';

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

final speechServiceProvider = Provider<SpeechService>((ref) {
  final rate = ref.watch(trainerSettingsProvider).speechRate;
  final service = FlutterTtsSpeechService(speechRate: rate);
  ref.onDispose(service.dispose);
  return service;
});

/// Connects the event bus to the engine to the voice.
///
/// Watch this from a widget mounted for the life of the app shell, passing the
/// localisations instance in, so phrase keys can be resolved without a
/// BuildContext reaching the engine.
class CoachBridge {
  CoachBridge(this._ref, this._strings) {
    _engine = CoachingEngine(persona: steadyPersona);
    _subscription = _ref.read(trainerEventBusProvider).events.listen(_onEvent);
  }

  final Ref _ref;
  final S _strings;

  late final CoachingEngine _engine;
  late final StreamSubscription<TrainerEvent> _subscription;

  void _onEvent(TrainerEvent event) {
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
      final text = resolvePhrase(_strings, cue.phraseKey, cue.args);
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

/// Family keyed on the localisations instance so the bridge rebuilds if the
/// locale changes mid-session.
final coachBridgeProvider = Provider.family<CoachBridge, S>((ref, strings) {
  final bridge = CoachBridge(ref, strings);
  ref.onDispose(bridge.dispose);
  return bridge;
});
