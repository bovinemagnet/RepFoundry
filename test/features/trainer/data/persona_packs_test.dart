import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/data/persona_packs.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/phrase_resolver.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// Phrases the coach must never speak, one rule per group.
///
/// Spec §5 "Content language rules": never urge load increases, "push through
/// pain", or ego-lifting; praise completion and consistency, never intensity
/// escalation; no body-shaming, no guilt framing.
///
/// Deliberately a blunt denylist rather than anything clever — its job is to
/// catch a phrase that drifts across the line, not to judge tone. Matching is
/// case-insensitive over the resolved English text with typographic
/// apostrophes normalised, so "don't" and "don’t" both match, and is done on
/// whole-word/whole-phrase boundaries (see [_matchesBanned]) rather than bare
/// substrings, so an entry like "fat" does not false-positive on "fatigue".
const Map<String, List<String>> _bannedLanguage = {
  'urging a load increase': [
    'add weight',
    'more weight',
    'heavier',
    'load up',
    'go heavy',
    'add a plate',
    'bump it up',
    'more reps than',
    'one more rep',
    'squeeze out',
  ],
  'pushing through pain': [
    'push through',
    'no pain',
    'pain is',
    'through the pain',
    'ignore the pain',
    'fight through',
    'suck it up',
    'don\'t stop',
    'never stop',
    'to failure',
  ],
  'ego lifting': [
    'beat everyone',
    'stronger than',
    'out-lift',
    'outlift',
    'show them',
    'prove them wrong',
    'real lifters',
    'nobody cares',
  ],
  'body shaming': [
    'fat',
    'skinny',
    'weak',
    'lazy',
    'pathetic',
    'excuses',
    'soft',
  ],
  'guilt framing': [
    'you skipped',
    'you missed',
    'finally',
    'about time',
    'where have you been',
    'let yourself',
    'disappointed',
    'you should have',
  ],
};

/// Normalises typographic punctuation so the denylist can be written plainly.
String _normalise(String text) =>
    text.toLowerCase().replaceAll('’', "'").replaceAll('‘', "'");

/// Whole-word/whole-phrase match: `\b` on each side of the (escaped) banned
/// text. Plain `String.contains` previously flagged "fatigue" for containing
/// "fat", "auto failure" for containing "to failure", and so on — this stays
/// exact for multi-word entries (the boundary only has to hold at the two
/// outer edges) while no longer matching a banned word as a mere substring of
/// a longer, innocuous one.
bool _matchesBanned(String text, String banned) {
  final pattern = RegExp('\\b${RegExp.escape(banned)}\\b');
  return pattern.hasMatch(text);
}

const _spokenKinds = [
  TrainerEventKind.workoutStarted,
  TrainerEventKind.setLogged,
  TrainerEventKind.personalRecord,
  TrainerEventKind.restCountdown,
  TrainerEventKind.restFinished,
  TrainerEventKind.workoutFinished,
];

/// Heart-rate cues (phase 2a). Kept separate from [_spokenKinds] because
/// their variety-count expectations differ (see the brief's exact phrase
/// lists — one or two phrases per kind, not the three required elsewhere),
/// but they still need to pass through the uniqueness, resolver, and
/// denylist loops below.
const _hrKinds = [
  TrainerEventKind.hrZoneChanged,
  TrainerEventKind.hrAboveCap,
  TrainerEventKind.hrBackBelowCap,
];

/// The shared quote bank (phase 2, spec §5). Kept separate from
/// [_spokenKinds] for the same reason as [_hrKinds] — its size (~40) is not
/// the "at least three" rule that applies to the six coaching-moment kinds —
/// but it still needs uniqueness, resolver, and denylist coverage.
const _quoteKinds = [TrainerEventKind.quote];

/// Every kind whose phrases must resolve to text and obey the denylist.
const _allSpokenKinds = [..._spokenKinds, ..._hrKinds, ..._quoteKinds];

/// Every persona the app ships. Adding a new persona here is what brings it
/// under every loop below (count, uniqueness, resolver completeness,
/// non-empty HR bank, denylist) — it is deliberately manual rather than
/// discovered by reflection, so a new pack cannot land without a reviewer
/// having to touch this line.
const _allPersonas = [steadyPersona, hypePersona, sergeantPersona];

/// Mirrors the args CoachingEngine attaches to a CoachingCue for this kind
/// (see coaching_engine.dart) — invoking with the wrong shape would surface
/// a cast failure at test time rather than mid-workout.
Map<String, Object> _argsFor(TrainerEventKind kind) => switch (kind) {
      TrainerEventKind.restCountdown => const {'secondsLeft': 3},
      TrainerEventKind.workoutFinished => const {'totalSets': 12},
      TrainerEventKind.hrZoneChanged => const {
          'zoneNumber': 3,
          'effortLabel': 'Moderate',
        },
      _ => const <String, Object>{},
    };

void main() {
  test('every persona has at least three phrases per spoken kind', () {
    for (final persona in _allPersonas) {
      for (final kind in _spokenKinds) {
        expect(
          persona.phrasesFor(kind).length,
          greaterThanOrEqualTo(3),
          reason: '${persona.id} persona is thin on $kind',
        );
      }
    }
  });

  test('the shared quote bank has a healthy number of entries', () {
    // "~40" per spec §5, but fix round 1 traced a licensing problem back to
    // this bank (a copyrighted song lyric with a false author credit, a
    // copyrighted translation presented as public-domain antiquity, and
    // several misattributed/apocryphal "quotes") to a licensing method that
    // checked the original author's death date but not the translator's or
    // the attribution's accuracy. Re-auditing every entry against a named
    // pre-1929 edition or translation — dropping anything that couldn't be
    // pinned down — took the count from 36 to 23 (24 after the first re-audit,
    // then the Helen Keller entry was dropped on a second pass: US
    // publication-date public domain does not hold under UK/EU life+70 terms,
    // and this project is not US-based). Fewer, individually
    // verified entries beat a rounder number with an unverified one in it.
    for (final persona in _allPersonas) {
      expect(
        persona.phrasesFor(TrainerEventKind.quote).length,
        greaterThanOrEqualTo(20),
        reason: '${persona.id} persona has too thin a quote bank',
      );
    }
  });

  test('phrase keys are unique within each persona\'s pack', () {
    for (final persona in _allPersonas) {
      final all = _allSpokenKinds.expand(persona.phrasesFor).toList();
      expect(
        all.toSet().length,
        all.length,
        reason: '${persona.id} persona has a duplicate phrase key',
      );
    }
  });

  test(
      'every phrase key in every persona has a resolver that produces '
      'text with the args its event kind actually supplies', () {
    final s = lookupS(const Locale('en'));
    for (final persona in _allPersonas) {
      for (final kind in _allSpokenKinds) {
        final args = _argsFor(kind);
        for (final key in persona.phrasesFor(kind)) {
          final builder = phraseResolvers[key];
          expect(builder, isNotNull,
              reason: 'no resolver entry for $key (${persona.id})');
          final text = builder!(s, args);
          expect(text, isNotEmpty,
              reason: '$key (${persona.id}) produced empty text');
        }
      }
    }
  });

  // Requirement A (carried forward from earlier reviews): _speak returns
  // null when a phrase bank is empty, so a persona shipped without phrases
  // for one of these kinds silently degrades to no speech at all — no
  // error, just silence. Iterates every persona so Hype and Sergeant are
  // covered the moment they land, not just Steady.
  //
  // Fix round 1: this previously checked hrAboveCap only. The
  // uniqueness/resolver/denylist loops above iterate `phrasesFor(kind)`,
  // which passes vacuously on an empty bank — without an explicit
  // non-empty assertion for every HR kind, hrZoneChanged or hrBackBelowCap
  // could ship with no phrases and nothing here would catch it.
  test('every persona has a non-empty bank for every HR cue kind', () {
    for (final persona in _allPersonas) {
      for (final kind in _hrKinds) {
        expect(
          persona.phrasesFor(kind),
          isNotEmpty,
          reason: '${persona.id} persona has no $kind phrases — that cue '
              'would silently degrade to no speech at all',
        );
      }
    }
  });

  test('no persona phrase uses banned language', () {
    // Spec §9: "no banned-language regressions (simple denylist check)".
    // Hype and Sergeant are exactly where this is easiest to breach —
    // celebratory energy drifting into ego-lifting, or firmness drifting
    // into something demeaning — so every persona is checked, not just
    // Steady.
    final s = lookupS(const Locale('en'));
    final offences = <String>[];

    for (final persona in _allPersonas) {
      for (final kind in _allSpokenKinds) {
        final args = _argsFor(kind);
        for (final key in persona.phrasesFor(kind)) {
          final text = _normalise(phraseResolvers[key]!(s, args));
          for (final entry in _bannedLanguage.entries) {
            for (final banned in entry.value) {
              if (_matchesBanned(text, banned)) {
                offences.add('${persona.id}/$key ("${entry.key}"): "$banned"');
              }
            }
          }
        }
      }
    }

    expect(offences, isEmpty,
        reason: 'persona phrases must obey the content language rules');
  });

  test('the denylist itself actually matches text that breaks the rules', () {
    // Without this the test above would silently pass on an empty or
    // mistyped denylist, and go on "passing" once phase 2 adds phrases.
    const offending = [
      'Add weight to the bar, you can take it.',
      "Push through the pain — don't stop now.",
      "Stronger than everyone else in here.",
      "Don't be lazy about it.",
      'You missed Monday, so make it up today.',
    ];

    for (final sample in offending) {
      final text = _normalise(sample);
      expect(
        _bannedLanguage.values
            .expand((l) => l)
            .any((b) => _matchesBanned(text, b)),
        isTrue,
        reason: 'the denylist failed to flag: $sample',
      );
    }
  });

  test(
      'the denylist does not false-positive on words that merely contain a '
      'banned word as a substring', () {
    // Regression: a plain substring check flagged "fatigue" for containing
    // "fat", "auto failure" for containing "to failure", and so on. Fixed by
    // matching on word boundaries rather than by deleting or weakening any
    // entry — every sample below still contains one of the exact substrings
    // above, just not as a standalone word/phrase.
    const safe = [
      'Fatigue is a normal part of training — rest well tonight.',
      'Please reload uploaded content before your next session.',
      "Auto failure detection isn't part of this app.",
      'Softly does it on the way down.',
      'The bearing showed weakness after the stress test.',
    ];

    for (final sample in safe) {
      final text = _normalise(sample);
      final hit = _bannedLanguage.entries
          .expand((e) => e.value.map((b) => MapEntry(e.key, b)))
          .where((e) => _matchesBanned(text, e.value))
          .toList();
      expect(hit, isEmpty, reason: 'false positive on "$sample": $hit');
    }
  });
}
