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
    this.encouragementMinSets = 2,
    this.encouragementMaxSets = 3,
  })  : _persona = persona,
        _random = random ?? Random() {
    _encouragementQuota = _pickEncouragementQuota();
  }

  final Persona _persona;
  final Random _random;

  /// Minimum quiet period between encouragement cues. Countdown, milestone,
  /// and safety cues are exempt — constant chatter is the commonest complaint
  /// about audio coaching, but a missed countdown makes the feature useless.
  final Duration encouragementCooldown;

  /// Encourage on roughly every 2nd–3rd logged set: the gap is redrawn after
  /// each encouragement so the coach does not fall into an audible rhythm.
  /// Set both to the same value for a fixed cadence.
  final int encouragementMinSets;
  final int encouragementMaxSets;

  /// Minimum gap between repeats of the above-cap warning while it holds.
  static const Duration _capWarningRepeat = Duration(seconds: 30);

  final Set<String> _spokenPhrases = {};
  DateTime? _lastSpokenAt;
  int _setsSinceEncouragement = 0;
  late int _encouragementQuota;
  bool _aboveCap = false;
  DateTime? _lastCapWarningAt;
  int? _currentZone;

  /// Whether the last `HeartRateAboveCap`/`HeartRateBackBelowCap` event left
  /// the reading above the user's safe maximum.
  bool get isAboveCap => _aboveCap;

  /// Clears per-session state. Call when a workout starts or finishes.
  void reset() {
    _spokenPhrases.clear();
    _lastSpokenAt = null;
    _setsSinceEncouragement = 0;
    _encouragementQuota = _pickEncouragementQuota();
    _aboveCap = false;
    _lastCapWarningAt = null;
    _currentZone = null;
  }

  /// Decides whether and what to say.
  ///
  /// The user's cue toggles are passed in rather than applied to the result,
  /// so a suppressed cue never consumes a phrase from the variety bank nor
  /// restarts the encouragement cooldown. The engine stays the single owner
  /// of "whether to speak".
  CoachingCue? onEvent(
    TrainerEvent event, {
    required DateTime now,
    bool countdownsEnabled = true,
    bool encouragementEnabled = true,
    bool hrCalloutsEnabled = true,
    bool cautionMode = false,
  }) {
    return switch (event) {
      WorkoutStarted() => _speak(event.kind, SpeechPriority.milestone, now),
      WorkoutFinished(:final totalSets) => _speak(
          event.kind,
          SpeechPriority.milestone,
          now,
          args: {'totalSets': totalSets},
        ),
      SetLogged(isPersonalRecord: true) => _encouragementBlocked(cautionMode)
          ? null
          : _speak(event.kind, SpeechPriority.milestone, now),
      SetLogged(isPersonalRecord: false) =>
        (encouragementEnabled && !_encouragementBlocked(cautionMode))
            ? _onSetLogged(now)
            : null,
      RestCountdown(:final secondsLeft) => countdownsEnabled
          ? _speak(
              event.kind,
              SpeechPriority.countdown,
              now,
              args: {'secondsLeft': secondsLeft},
            )
          : null,
      RestFinished() => countdownsEnabled
          ? _speak(event.kind, SpeechPriority.countdown, now)
          : null,
      RestStarted() => null,
      HeartRateZoneChanged(:final zoneNumber, :final effortLabel) =>
        _onZoneChanged(zoneNumber, effortLabel, hrCalloutsEnabled, now),
      HeartRateAboveCap(:final bpm, :final cap) => _onAboveCap(bpm, cap, now),
      HeartRateBackBelowCap() => _onBackBelowCap(now),
    };
  }

  /// True while no encouragement-type cue — motivational chatter or a
  /// personal record — may be spoken: above the safety cap, in caution mode,
  /// or once the user has reached zone 5.
  ///
  /// Every encouragement-producing branch in [onEvent] routes through this
  /// single check so a future event kind cannot quietly bypass the rule.
  bool _encouragementBlocked(bool cautionMode) =>
      _aboveCap || cautionMode || _currentZone == 5;

  /// Records the new zone unconditionally — zone 5 must be tracked even when
  /// callouts are switched off — and speaks it unless callouts are disabled
  /// or the reading is above cap (rule: encouragement, including zone
  /// callouts, is suppressed while above cap).
  CoachingCue? _onZoneChanged(
    int zoneNumber,
    String effortLabel,
    bool hrCalloutsEnabled,
    DateTime now,
  ) {
    _currentZone = zoneNumber;
    if (!hrCalloutsEnabled || _aboveCap) return null;
    return _speak(
      TrainerEventKind.hrZoneChanged,
      SpeechPriority.milestone,
      now,
      args: {'zoneNumber': zoneNumber, 'effortLabel': effortLabel},
    );
  }

  /// Safety path: never gated by [hrCalloutsEnabled] or caution mode, and
  /// repeats no more often than [_capWarningRepeat] while the reading stays
  /// above the cap.
  CoachingCue? _onAboveCap(int bpm, int cap, DateTime now) {
    _aboveCap = true;
    final lastWarning = _lastCapWarningAt;
    if (lastWarning != null &&
        now.difference(lastWarning) < _capWarningRepeat) {
      return null;
    }

    final cue = _speak(
      TrainerEventKind.hrAboveCap,
      SpeechPriority.safety,
      now,
      args: {'bpm': bpm, 'cap': cap},
    );
    if (cue != null) _lastCapWarningAt = now;
    return cue;
  }

  /// Lifts the above-cap suppression and resets the repeat timer, so a later
  /// cap crossing warns immediately rather than inheriting a stale cooldown.
  CoachingCue? _onBackBelowCap(DateTime now) {
    _aboveCap = false;
    _lastCapWarningAt = null;
    return _speak(
        TrainerEventKind.hrBackBelowCap, SpeechPriority.milestone, now);
  }

  CoachingCue? _onSetLogged(DateTime now) {
    _setsSinceEncouragement++;
    if (_setsSinceEncouragement < _encouragementQuota) return null;

    final last = _lastSpokenAt;
    if (last != null && now.difference(last) < encouragementCooldown) {
      return null;
    }

    final cue = _speak(
      TrainerEventKind.setLogged,
      SpeechPriority.encouragement,
      now,
    );
    if (cue != null) {
      _setsSinceEncouragement = 0;
      _encouragementQuota = _pickEncouragementQuota();
    }
    return cue;
  }

  /// Draws the next encouragement gap. A fixed cadence (min == max) draws
  /// nothing, so seeding the engine for a phrase-variety test is unaffected.
  int _pickEncouragementQuota() {
    final span = encouragementMaxSets - encouragementMinSets;
    if (span <= 0) return encouragementMinSets;
    return encouragementMinSets + _random.nextInt(span + 1);
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
