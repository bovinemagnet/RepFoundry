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
/// Deliberately a blunt substring denylist rather than anything clever — its
/// job is to catch a phrase that drifts across the line when the Hype and
/// Sergeant packs land in phase 2, not to judge tone. Matching is
/// case-insensitive over the resolved English text with typographic
/// apostrophes normalised, so "don't" and "don’t" both match.
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

const _spokenKinds = [
  TrainerEventKind.workoutStarted,
  TrainerEventKind.setLogged,
  TrainerEventKind.personalRecord,
  TrainerEventKind.restCountdown,
  TrainerEventKind.restFinished,
  TrainerEventKind.workoutFinished,
];

void main() {
  test('steady persona has at least three phrases per spoken kind', () {
    for (final kind in _spokenKinds) {
      expect(
        steadyPersona.phrasesFor(kind).length,
        greaterThanOrEqualTo(3),
        reason: 'steady persona is thin on $kind',
      );
    }
  });

  test('phrase keys are unique across the pack', () {
    final all = _spokenKinds.expand(steadyPersona.phrasesFor).toList();

    expect(all.toSet().length, all.length, reason: 'duplicate phrase key');
  });

  test(
      'every phrase key in the steady persona has a resolver that produces '
      'text with the args its event kind actually supplies', () {
    final s = lookupS(const Locale('en'));
    for (final kind in _spokenKinds) {
      // Mirrors the args CoachingEngine attaches to a CoachingCue for this
      // kind (see coaching_engine.dart) — invoking with the wrong shape here
      // would surface a cast failure at test time rather than mid-workout.
      final args = switch (kind) {
        TrainerEventKind.restCountdown => const {'secondsLeft': 3},
        TrainerEventKind.workoutFinished => const {'totalSets': 12},
        _ => const <String, Object>{},
      };
      for (final key in steadyPersona.phrasesFor(kind)) {
        final builder = phraseResolvers[key];
        expect(builder, isNotNull, reason: 'no resolver entry for $key');
        final text = builder!(s, args);
        expect(text, isNotEmpty, reason: '$key produced empty text');
      }
    }
  });

  test('no persona phrase uses banned language', () {
    // Spec §9: "no banned-language regressions (simple denylist check)".
    // Steady is clean today; the value is the guard rail under the Hype and
    // Sergeant packs arriving in phase 2.
    final s = lookupS(const Locale('en'));
    final offences = <String>[];

    for (final kind in _spokenKinds) {
      final args = switch (kind) {
        TrainerEventKind.restCountdown => const {'secondsLeft': 3},
        TrainerEventKind.workoutFinished => const {'totalSets': 12},
        _ => const <String, Object>{},
      };
      for (final key in steadyPersona.phrasesFor(kind)) {
        final text = _normalise(phraseResolvers[key]!(s, args));
        for (final entry in _bannedLanguage.entries) {
          for (final banned in entry.value) {
            if (text.contains(banned)) {
              offences.add('$key ("${entry.key}"): "$banned"');
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
        _bannedLanguage.values.expand((l) => l).any(text.contains),
        isTrue,
        reason: 'the denylist failed to flag: $sample',
      );
    }
  });
}
