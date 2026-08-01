import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// Turns a persona's phrase key into speakable text.
///
/// Kept as an explicit map rather than reflection so a missing entry is a
/// compile-time-adjacent failure caught by [phraseResolvers] in tests.
typedef PhraseBuilder = String Function(S s, Map<String, Object> args);

final Map<String, PhraseBuilder> phraseResolvers = {
  'coachSteadyStart1': (s, _) => s.coachSteadyStart1,
  'coachSteadyStart2': (s, _) => s.coachSteadyStart2,
  'coachSteadyStart3': (s, _) => s.coachSteadyStart3,
  'coachSteadySet1': (s, _) => s.coachSteadySet1,
  'coachSteadySet2': (s, _) => s.coachSteadySet2,
  'coachSteadySet3': (s, _) => s.coachSteadySet3,
  'coachSteadySet4': (s, _) => s.coachSteadySet4,
  'coachSteadyPr1': (s, _) => s.coachSteadyPr1,
  'coachSteadyPr2': (s, _) => s.coachSteadyPr2,
  'coachSteadyPr3': (s, _) => s.coachSteadyPr3,
  // `as int?` rather than `! as int`: a missing/mistyped arg falls back to 0
  // instead of throwing inside a stream listener. Unreachable with the
  // current pack (CoachingEngine always supplies the matching arg for these
  // keys), but speech-time is the wrong place to discover a mismatch.
  'coachSteadyCountdown1': (s, a) =>
      s.coachSteadyCountdown1(a['secondsLeft'] as int? ?? 0),
  'coachSteadyCountdown2': (s, a) =>
      s.coachSteadyCountdown2(a['secondsLeft'] as int? ?? 0),
  'coachSteadyCountdown3': (s, a) =>
      s.coachSteadyCountdown3(a['secondsLeft'] as int? ?? 0),
  'coachSteadyRestDone1': (s, _) => s.coachSteadyRestDone1,
  'coachSteadyRestDone2': (s, _) => s.coachSteadyRestDone2,
  'coachSteadyRestDone3': (s, _) => s.coachSteadyRestDone3,
  'coachSteadyFinish1': (s, a) =>
      s.coachSteadyFinish1(a['totalSets'] as int? ?? 0),
  'coachSteadyFinish2': (s, a) =>
      s.coachSteadyFinish2(a['totalSets'] as int? ?? 0),
  'coachSteadyFinish3': (s, a) =>
      s.coachSteadyFinish3(a['totalSets'] as int? ?? 0),
};

String? resolvePhrase(S s, String key, Map<String, Object> args) {
  final builder = phraseResolvers[key];
  if (builder == null) return null;
  return builder(s, args);
}
