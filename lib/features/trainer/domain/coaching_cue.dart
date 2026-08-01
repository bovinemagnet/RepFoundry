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
  });

  final String phraseKey;
  final SpeechPriority priority;
  final Map<String, Object> args;
}
