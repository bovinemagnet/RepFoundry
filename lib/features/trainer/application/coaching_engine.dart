import 'dart:math';

import '../domain/coaching_cue.dart';
import '../domain/persona.dart';
import '../domain/trainer_event.dart';

/// Decides whether and what the coach says in response to workout events.
///
/// Pure Dart and deterministic: the caller supplies the clock and the random
/// source, so every rule below is directly testable without audio or timers.
class CoachingEngine {
  CoachingEngine({
    required Persona persona,
    Random? random,
    this.encouragementCooldown = const Duration(seconds: 20),
    this.encouragementEverySets = 2,
  })  : _persona = persona,
        _random = random ?? Random();

  final Persona _persona;
  final Random _random;

  /// Minimum quiet period between encouragement cues. Countdown, milestone,
  /// and safety cues are exempt — constant chatter is the commonest complaint
  /// about audio coaching, but a missed countdown makes the feature useless.
  final Duration encouragementCooldown;

  /// Encourage on every Nth logged set rather than every one.
  final int encouragementEverySets;

  final Set<String> _spokenPhrases = {};
  DateTime? _lastSpokenAt;
  int _setsSinceEncouragement = 0;

  /// Clears per-session state. Call when a workout starts or finishes.
  void reset() {
    _spokenPhrases.clear();
    _lastSpokenAt = null;
    _setsSinceEncouragement = 0;
  }

  CoachingCue? onEvent(TrainerEvent event, {required DateTime now}) {
    return switch (event) {
      WorkoutStarted() => _speak(event.kind, SpeechPriority.milestone, now),
      WorkoutFinished(:final totalSets) => _speak(
          event.kind,
          SpeechPriority.milestone,
          now,
          args: {'totalSets': totalSets},
        ),
      SetLogged(isPersonalRecord: true) =>
        _speak(event.kind, SpeechPriority.milestone, now),
      SetLogged(isPersonalRecord: false) => _onSetLogged(now),
      RestCountdown(:final secondsLeft) => _speak(
          event.kind,
          SpeechPriority.countdown,
          now,
          args: {'secondsLeft': secondsLeft},
        ),
      RestFinished() => _speak(event.kind, SpeechPriority.countdown, now),
      RestStarted() => null,
    };
  }

  CoachingCue? _onSetLogged(DateTime now) {
    _setsSinceEncouragement++;
    if (_setsSinceEncouragement < encouragementEverySets) return null;

    final last = _lastSpokenAt;
    if (last != null && now.difference(last) < encouragementCooldown) {
      return null;
    }

    final cue = _speak(
      TrainerEventKind.setLogged,
      SpeechPriority.encouragement,
      now,
    );
    if (cue != null) _setsSinceEncouragement = 0;
    return cue;
  }

  CoachingCue? _speak(
    TrainerEventKind kind,
    SpeechPriority priority,
    DateTime now, {
    Map<String, Object> args = const {},
  }) {
    final phrase = _pickPhrase(kind);
    if (phrase == null) return null;

    _spokenPhrases.add(phrase);
    _lastSpokenAt = now;
    return CoachingCue(phraseKey: phrase, priority: priority, args: args);
  }

  /// Prefers phrases not yet heard this session; once the bank is exhausted it
  /// starts again rather than falling silent.
  String? _pickPhrase(TrainerEventKind kind) {
    final bank = _persona.phrasesFor(kind);
    if (bank.isEmpty) return null;

    final unheard = bank.where((p) => !_spokenPhrases.contains(p)).toList();
    if (unheard.isEmpty) {
      _spokenPhrases.removeAll(bank);
      return bank[_random.nextInt(bank.length)];
    }
    return unheard[_random.nextInt(unheard.length)];
  }
}
