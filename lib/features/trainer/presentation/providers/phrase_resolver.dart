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
  // descriptiveLabel is deliberately not threaded through here — see
  // HeartRateZoneChanged's doc comment for the decision. The spoken cue
  // stays to zone number + effortLabel only.
  'coachSteadyZone': (s, a) => s.coachSteadyZone(
        a['zoneNumber'] as int? ?? 0,
        a['effortLabel'] as String? ?? '',
      ),
  'coachSteadyAboveCap1': (s, _) => s.coachSteadyAboveCap1,
  'coachSteadyAboveCap2': (s, _) => s.coachSteadyAboveCap2,
  'coachSteadyBackBelowCap': (s, _) => s.coachSteadyBackBelowCap,

  'coachHypeStart1': (s, _) => s.coachHypeStart1,
  'coachHypeStart2': (s, _) => s.coachHypeStart2,
  'coachHypeStart3': (s, _) => s.coachHypeStart3,
  'coachHypeSet1': (s, _) => s.coachHypeSet1,
  'coachHypeSet2': (s, _) => s.coachHypeSet2,
  'coachHypeSet3': (s, _) => s.coachHypeSet3,
  'coachHypePr1': (s, _) => s.coachHypePr1,
  'coachHypePr2': (s, _) => s.coachHypePr2,
  'coachHypePr3': (s, _) => s.coachHypePr3,
  'coachHypeCountdown1': (s, a) =>
      s.coachHypeCountdown1(a['secondsLeft'] as int? ?? 0),
  'coachHypeCountdown2': (s, a) =>
      s.coachHypeCountdown2(a['secondsLeft'] as int? ?? 0),
  'coachHypeCountdown3': (s, a) =>
      s.coachHypeCountdown3(a['secondsLeft'] as int? ?? 0),
  'coachHypeRestDone1': (s, _) => s.coachHypeRestDone1,
  'coachHypeRestDone2': (s, _) => s.coachHypeRestDone2,
  'coachHypeRestDone3': (s, _) => s.coachHypeRestDone3,
  'coachHypeFinish1': (s, a) => s.coachHypeFinish1(a['totalSets'] as int? ?? 0),
  'coachHypeFinish2': (s, a) => s.coachHypeFinish2(a['totalSets'] as int? ?? 0),
  'coachHypeFinish3': (s, a) => s.coachHypeFinish3(a['totalSets'] as int? ?? 0),
  'coachHypeZone': (s, a) => s.coachHypeZone(
        a['zoneNumber'] as int? ?? 0,
        a['effortLabel'] as String? ?? '',
      ),
  'coachHypeAboveCap1': (s, _) => s.coachHypeAboveCap1,
  'coachHypeAboveCap2': (s, _) => s.coachHypeAboveCap2,
  'coachHypeBackBelowCap': (s, _) => s.coachHypeBackBelowCap,

  'coachSergeantStart1': (s, _) => s.coachSergeantStart1,
  'coachSergeantStart2': (s, _) => s.coachSergeantStart2,
  'coachSergeantStart3': (s, _) => s.coachSergeantStart3,
  'coachSergeantSet1': (s, _) => s.coachSergeantSet1,
  'coachSergeantSet2': (s, _) => s.coachSergeantSet2,
  'coachSergeantSet3': (s, _) => s.coachSergeantSet3,
  'coachSergeantPr1': (s, _) => s.coachSergeantPr1,
  'coachSergeantPr2': (s, _) => s.coachSergeantPr2,
  'coachSergeantPr3': (s, _) => s.coachSergeantPr3,
  'coachSergeantCountdown1': (s, a) =>
      s.coachSergeantCountdown1(a['secondsLeft'] as int? ?? 0),
  'coachSergeantCountdown2': (s, a) =>
      s.coachSergeantCountdown2(a['secondsLeft'] as int? ?? 0),
  'coachSergeantCountdown3': (s, a) =>
      s.coachSergeantCountdown3(a['secondsLeft'] as int? ?? 0),
  'coachSergeantRestDone1': (s, _) => s.coachSergeantRestDone1,
  'coachSergeantRestDone2': (s, _) => s.coachSergeantRestDone2,
  'coachSergeantRestDone3': (s, _) => s.coachSergeantRestDone3,
  'coachSergeantFinish1': (s, a) =>
      s.coachSergeantFinish1(a['totalSets'] as int? ?? 0),
  'coachSergeantFinish2': (s, a) =>
      s.coachSergeantFinish2(a['totalSets'] as int? ?? 0),
  'coachSergeantFinish3': (s, a) =>
      s.coachSergeantFinish3(a['totalSets'] as int? ?? 0),
  'coachSergeantZone': (s, a) => s.coachSergeantZone(
        a['zoneNumber'] as int? ?? 0,
        a['effortLabel'] as String? ?? '',
      ),
  'coachSergeantAboveCap1': (s, _) => s.coachSergeantAboveCap1,
  'coachSergeantAboveCap2': (s, _) => s.coachSergeantAboveCap2,
  'coachSergeantBackBelowCap': (s, _) => s.coachSergeantBackBelowCap,

  // Shared quote bank (phase 2, spec §5): identical across every persona, so
  // one set of resolver entries covers steady, hype, and sergeant alike.
  'coachQuote1': (s, _) => s.coachQuote1,
  'coachQuote2': (s, _) => s.coachQuote2,
  'coachQuote3': (s, _) => s.coachQuote3,
  'coachQuote5': (s, _) => s.coachQuote5,
  'coachQuote6': (s, _) => s.coachQuote6,
  'coachQuote7': (s, _) => s.coachQuote7,
  'coachQuote8': (s, _) => s.coachQuote8,
  'coachQuote9': (s, _) => s.coachQuote9,
  'coachQuote12': (s, _) => s.coachQuote12,
  'coachQuote14': (s, _) => s.coachQuote14,
  'coachQuote15': (s, _) => s.coachQuote15,
  'coachQuote17': (s, _) => s.coachQuote17,
  'coachQuote18': (s, _) => s.coachQuote18,
  'coachQuote19': (s, _) => s.coachQuote19,
  'coachQuote21': (s, _) => s.coachQuote21,
  'coachQuote22': (s, _) => s.coachQuote22,
  'coachQuote23': (s, _) => s.coachQuote23,
};

String? resolvePhrase(S s, String key, Map<String, Object> args) {
  final builder = phraseResolvers[key];
  if (builder == null) return null;
  return builder(s, args);
}
