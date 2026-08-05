/// How urgently a cue must be heard.
///
/// Declaration order matters: a cue pre-empts any cue with a lower index, so
/// safety warnings interrupt countdowns, which interrupt encouragement.
enum SpeechPriority {
  encouragement,
  milestone,
  countdown,
  safety,
}

/// A decision to say something.
///
/// Carries an ARB phrase key rather than literal text so the coaching engine
/// stays pure Dart and the presentation layer localises at the last moment.
class CoachingCue {
  const CoachingCue({
    required this.phraseKey,
    required this.priority,
    this.args = const {},
    this.quotePhraseKey,
  });

  final String phraseKey;
  final SpeechPriority priority;
  final Map<String, Object> args;

  /// An inspirational quote to speak as part of the same utterance, or null.
  ///
  /// Merged into one `speak()` call rather than emitted as a second cue
  /// because `FlutterTtsSpeechService` drops any cue at equal or lower
  /// priority than what is already playing, and every moment a quote is
  /// wanted is a moment the coach is already speaking. A separate quote cue
  /// would be silently dropped at both.
  ///
  /// [phraseKey] stays non-null: a standalone quote is expressed by putting
  /// the quote key in [phraseKey] and leaving this null, so no consumer has
  /// to cope with an empty lead-in.
  final String? quotePhraseKey;
}
