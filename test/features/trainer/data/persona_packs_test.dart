import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/data/persona_packs.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/phrase_resolver.dart';

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

  test('every phrase key in the steady persona has a resolver', () {
    for (final kind in _spokenKinds) {
      for (final key in steadyPersona.phrasesFor(kind)) {
        expect(phraseResolvers.containsKey(key), isTrue,
            reason: 'no resolver entry for $key');
      }
    }
  });
}
