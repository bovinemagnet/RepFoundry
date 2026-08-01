import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';
import 'package:rep_foundry/features/trainer/domain/persona.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';

void main() {
  test('each event reports its kind', () {
    expect(const WorkoutStarted().kind, TrainerEventKind.workoutStarted);
    expect(
      const SetLogged(setNumber: 3, isPersonalRecord: false).kind,
      TrainerEventKind.setLogged,
    );
    expect(
      const SetLogged(setNumber: 3, isPersonalRecord: true).kind,
      TrainerEventKind.personalRecord,
    );
    expect(const RestCountdown(secondsLeft: 3).kind,
        TrainerEventKind.restCountdown);
  });

  test('speech priority orders safety above everything else', () {
    expect(SpeechPriority.safety.index,
        greaterThan(SpeechPriority.countdown.index));
    expect(SpeechPriority.countdown.index,
        greaterThan(SpeechPriority.milestone.index));
    expect(SpeechPriority.milestone.index,
        greaterThan(SpeechPriority.encouragement.index));
  });

  test('a persona exposes phrase keys per event kind', () {
    const persona = Persona(
      id: 'steady',
      phrasesByKind: {
        TrainerEventKind.setLogged: ['coachSteadySetLogged1'],
      },
    );

    expect(persona.phrasesByKind[TrainerEventKind.setLogged],
        contains('coachSteadySetLogged1'));
  });
}
