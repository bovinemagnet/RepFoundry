import '../domain/persona.dart';
import '../domain/trainer_event.dart';

/// Calm and measured. The only persona in v1; Hype and Sergeant follow.
///
/// Every key here must exist in `app_en.arb` and obey the content rules:
/// praise completion and consistency, never urge more load or pushing through
/// pain.
const Persona steadyPersona = Persona(
  id: 'steady',
  phrasesByKind: {
    TrainerEventKind.workoutStarted: [
      'coachSteadyStart1',
      'coachSteadyStart2',
      'coachSteadyStart3',
    ],
    TrainerEventKind.setLogged: [
      'coachSteadySet1',
      'coachSteadySet2',
      'coachSteadySet3',
      'coachSteadySet4',
    ],
    TrainerEventKind.personalRecord: [
      'coachSteadyPr1',
      'coachSteadyPr2',
      'coachSteadyPr3',
    ],
    TrainerEventKind.restCountdown: [
      'coachSteadyCountdown1',
      'coachSteadyCountdown2',
      'coachSteadyCountdown3',
    ],
    TrainerEventKind.restFinished: [
      'coachSteadyRestDone1',
      'coachSteadyRestDone2',
      'coachSteadyRestDone3',
    ],
    TrainerEventKind.workoutFinished: [
      'coachSteadyFinish1',
      'coachSteadyFinish2',
      'coachSteadyFinish3',
    ],
  },
);
