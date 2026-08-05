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

  Persona _persona;
  final Random _random;

  /// Swaps the persona in place, rather than requiring the caller to
  /// construct a new engine.
  ///
  /// Fix round 1: `CoachBridge` used to react to a persona change by
  /// throwing away the whole engine and building a fresh one. That silently
  /// discarded live heart-rate safety state — `_aboveCap`, `_currentZone`,
  /// `_lastCapWarningAt`, the cap-warning repeat cooldown — along with it.
  /// Losing `_currentZone` is the sharpest edge: [HeartRateZoneChanged] only
  /// fires on a zone *change*, so a user sitting in Zone 5 who then switches
  /// voice would get the Zone-5 encouragement ceiling lifted for the rest of
  /// the session, with no later event able to restore it. Losing `_aboveCap`
  /// lifts above-cap suppression for up to [_capWarningRepeat], long enough
  /// for a milestone cue to slip through in exactly the window it exists to
  /// block. Setting `_persona` in place keeps all of that session state
  /// intact; only which phrase bank [_pickPhrase] draws from changes. A
  /// persona key already spoken this session but absent from the new
  /// persona's bank simply never matches anything in [_spokenPhrases] again
  /// — harmless, since [_pickPhrase] only ever reads keys out of the
  /// *current* persona's own bank.
  set persona(Persona value) => _persona = value;

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

  /// Rests at or beyond this length earn an inspirational quote (spec §4).
  ///
  /// Public and `static` because the rest-timer chime suppression
  /// (`coachAnnouncesRestEndProvider`) has to apply the same rule to decide
  /// whether the coach will speak, and a second copy of "two minutes" in the
  /// presentation layer would be free to drift out of step with this one.
  static const Duration longRestThreshold = Duration(minutes: 2);

  final Set<String> _spokenPhrases = {};
  DateTime? _lastSpokenAt;
  int _setsSinceEncouragement = 0;
  late int _encouragementQuota;
  bool _aboveCap = false;
  DateTime? _lastCapWarningAt;
  int? _currentZone;

  /// The current call's caution-mode flag, set as the first statement of
  /// [onEvent] and read by [_encouragementBlocked]. A field rather than a
  /// parameter threaded through every private helper and into [_speak]: a
  /// forgotten parameter at a new call site is exactly how milestone cues
  /// escaped the above-cap/zone-5 gate before (see fix round 1) — a field
  /// cannot be forgotten the same way. Not session state, so [reset] leaves
  /// it alone; it is overwritten on every [onEvent] call before it is read.
  bool _cautionMode = false;

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
    bool hrSafetyWarningsEnabled = true,
    bool cautionMode = false,
    bool quotesEnabled = true,
  }) {
    _cautionMode = cautionMode;
    return switch (event) {
      WorkoutStarted() => _withQuote(
          _speak(event.kind, SpeechPriority.milestone, now),
          quotesEnabled,
        ),
      WorkoutFinished(:final totalSets) => _speak(
          event.kind,
          SpeechPriority.milestone,
          now,
          args: {'totalSets': totalSets},
        ),
      SetLogged(isPersonalRecord: true) =>
        _speak(event.kind, SpeechPriority.milestone, now),
      SetLogged(isPersonalRecord: false) =>
        encouragementEnabled ? _onSetLogged(now) : null,
      RestCountdown(:final secondsLeft) => countdownsEnabled
          ? _speak(
              event.kind,
              SpeechPriority.countdown,
              now,
              args: {'secondsLeft': secondsLeft},
              encouragement: false,
            )
          : null,
      RestFinished(:final restDuration) =>
        _onRestFinished(restDuration, countdownsEnabled, quotesEnabled, now),
      RestStarted() => null,
      HeartRateZoneChanged(:final zoneNumber, :final effortLabel) =>
        _onZoneChanged(zoneNumber, effortLabel, hrCalloutsEnabled, now),
      HeartRateAboveCap(:final bpm, :final cap) =>
        _onAboveCap(bpm, cap, now, hrSafetyWarningsEnabled),
      HeartRateBackBelowCap() => _onBackBelowCap(now, hrSafetyWarningsEnabled),
    };
  }

  /// True while no encouragement-type cue — motivational chatter, a
  /// personal record, or another milestone announcement — may be spoken:
  /// above the safety cap, in caution mode, or once the user has reached
  /// zone 5.
  ///
  /// Checked from exactly one place, [_speak] itself, so every cue the
  /// engine can produce passes through it by default; a path that must
  /// bypass the rule (countdowns, zone callouts, the safety cues
  /// themselves) opts out explicitly with `encouragement: false` rather
  /// than the rule having to be remembered at each call site.
  bool get _encouragementBlocked =>
      _aboveCap || _cautionMode || _currentZone == 5;

  /// Records the new zone unconditionally — zone 5 must be tracked even when
  /// callouts are switched off — and speaks it unless callouts are disabled
  /// or the reading is above cap (rule: encouragement, including zone
  /// callouts, is suppressed while above cap). Exempted from the shared
  /// encouragement gate because, unlike encouragement, a zone callout must
  /// still fire in caution mode and in zone 5 (that event is what sets the
  /// zone to 5 in the first place).
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
      encouragement: false,
    );
  }

  /// Safety path: never gated by [hrCalloutsEnabled], caution mode, or zone —
  /// only by [hrSafetyWarningsEnabled], the setting the user must
  /// deliberately switch off. The above-cap flag is recorded before that
  /// check so encouragement suppression still applies even when the audible
  /// warning itself is silenced. Repeats no more often than
  /// [_capWarningRepeat] while the reading stays above the cap.
  CoachingCue? _onAboveCap(
    int bpm,
    int cap,
    DateTime now,
    bool hrSafetyWarningsEnabled,
  ) {
    _aboveCap = true;
    if (!hrSafetyWarningsEnabled) return null;

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
      encouragement: false,
    );
    if (cue != null) _lastCapWarningAt = now;
    return cue;
  }

  /// The reassurance cue only makes sense as the bookend to a warning the
  /// user actually heard, so it stays silent unless the engine was actually
  /// tracking an above-cap episode. Lifts the suppression and resets the
  /// repeat timer, so a later cap crossing warns immediately rather than
  /// inheriting a stale cooldown.
  ///
  /// `hrSafetyWarningsEnabled` is checked only *after* the state above is
  /// cleared, the same order `_onAboveCap` follows: an early return before
  /// clearing state would leave encouragement suppressed for the rest of the
  /// session with no event able to lift it. A muted user still gets the
  /// suppression lifted; they just never hear the "back under" line.
  CoachingCue? _onBackBelowCap(DateTime now, bool hrSafetyWarningsEnabled) {
    if (!_aboveCap) return null;

    _aboveCap = false;
    _lastCapWarningAt = null;
    if (!hrSafetyWarningsEnabled) return null;

    return _speak(
      TrainerEventKind.hrBackBelowCap,
      SpeechPriority.milestone,
      now,
      encouragement: false,
    );
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

  /// The countdown line, the quote, both merged, or neither.
  ///
  /// Merged rather than returned as a second cue: `FlutterTtsSpeechService`
  /// drops any cue at equal or lower priority than the one already playing,
  /// so a quote emitted straight after the countdown line would never be
  /// heard. See the spec's §2 for the full derivation.
  ///
  /// When countdowns are off the quote is spoken alone, at milestone
  /// priority. Letting it vanish with the countdown line would make the
  /// countdown toggle a hidden second mute for quotes.
  CoachingCue? _onRestFinished(
    Duration? restDuration,
    bool countdownsEnabled,
    bool quotesEnabled,
    DateTime now,
  ) {
    final earnsQuote = quotesEnabled &&
        restDuration != null &&
        restDuration >= longRestThreshold;

    if (!countdownsEnabled) {
      if (!earnsQuote) return null;
      return _speak(TrainerEventKind.quote, SpeechPriority.milestone, now);
    }

    final cue = _speak(
      TrainerEventKind.restFinished,
      SpeechPriority.countdown,
      now,
      encouragement: false,
    );
    return _withQuote(cue, earnsQuote);
  }

  /// Attaches a quote to [cue], or returns it untouched.
  ///
  /// Gated on [_encouragementBlocked] independently of whatever [cue] itself
  /// was allowed through on. The countdown line is exempt from that gate
  /// (`encouragement: false`) because a missed countdown makes the feature
  /// useless — but a motivational quote riding along on that exemption would
  /// put inspirational chatter in the user's ear at the moment their heart
  /// rate is over their clinician cap.
  /// [earnsQuote] is the caller's decision that this moment qualifies —
  /// "quotes are on" at workout start, "quotes are on *and* the rest was long
  /// enough" at rest end.
  CoachingCue? _withQuote(CoachingCue? cue, bool earnsQuote) {
    if (cue == null || !earnsQuote || _encouragementBlocked) return cue;

    final quote = _pickPhrase(TrainerEventKind.quote);
    if (quote == null) return cue;

    _spokenPhrases.add(quote);
    return CoachingCue(
      phraseKey: cue.phraseKey,
      priority: cue.priority,
      args: cue.args,
      quotePhraseKey: quote,
    );
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
    bool encouragement = true,
  }) {
    if (encouragement && _encouragementBlocked) return null;

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
