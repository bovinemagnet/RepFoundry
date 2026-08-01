import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/data/persona_packs.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/phrase_resolver.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

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
}
