import '../domain/persona.dart';
import '../domain/trainer_event.dart';

/// Shared inspirational quote bank (spec §5).
///
/// **Licensing rule for anyone adding a quote:** every named person whose
/// words we ship — original author *and* translator — must have died more
/// than 70 years ago. Publication date alone is not sufficient. The
/// translator clause matters just as much as the author clause: a
/// public-domain author can still have an in-copyright translation, which is
/// how Gregory Hays' 2002 rendering of Marcus Aurelius nearly shipped under
/// Marcus Aurelius' own (long-expired) name. Check both death dates before
/// adding an entry, and drop it rather than guess if either is unclear.
///
/// The per-quote sourcing table (author, work, translation/edition relied on)
/// is not yet in this repo — see issue #104.
///
/// Spoken at workout start and after rests of
/// `CoachingEngine.longRestThreshold` or longer, merged into the cue for that
/// moment rather than spoken as a separate one — see `CoachingCue`'s
/// `quotePhraseKey`.
///
/// Attached to every persona's [TrainerEventKind.quote] bank rather than
/// kept as a standalone list, so the existing per-persona
/// uniqueness/resolver/denylist test loops cover it automatically instead of
/// needing a parallel set of checks. That sharing is also what lets quote
/// memory survive a persona switch.
const List<String> _quoteBank = [
  'coachQuote1',
  'coachQuote2',
  'coachQuote3',
  'coachQuote5',
  'coachQuote6',
  'coachQuote7',
  'coachQuote8',
  'coachQuote9',
  'coachQuote10',
  'coachQuote12',
  'coachQuote13',
  'coachQuote14',
  'coachQuote15',
  'coachQuote16',
  'coachQuote17',
  'coachQuote18',
  'coachQuote19',
  'coachQuote20',
  'coachQuote21',
  'coachQuote22',
  'coachQuote23',
];

/// Calm and measured. The only persona in v1; Hype and Sergeant follow in
/// phase 2.
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
    TrainerEventKind.quote: _quoteBank,
    // Heart-rate cues (phase 2a). hrAboveCap is the safety path: a persona
    // shipped without a phrase here degrades to silence with no error (see
    // CoachingEngine._speak), so it must never be empty — enforced in
    // persona_packs_test.dart across every persona, not just this one.
    TrainerEventKind.hrZoneChanged: [
      'coachSteadyZone',
    ],
    TrainerEventKind.hrAboveCap: [
      'coachSteadyAboveCap1',
      'coachSteadyAboveCap2',
    ],
    TrainerEventKind.hrBackBelowCap: [
      'coachSteadyBackBelowCap',
    ],
  },
);

/// Energetic and celebratory (phase 2, spec §5). Excitement is aimed at
/// completion and consistency only — never at lifting more or lifting
/// heavier, and every heart-rate cue stays calm and informational rather
/// than hyped (see `coachHypeZone`, `coachHypeAboveCap*`,
/// `coachHypeBackBelowCap`). This matters most for `coachHypeZone`: unlike
/// the encouragement bank, `_onZoneChanged` exempts zone callouts from the
/// encouragement-suppression gate (`encouragement: false`), so this line is
/// spoken even in caution mode and at Zone 5 — praising the intensity there
/// would land on exactly the user it must never land on. Fix round 1:
/// `coachHypeZone` previously read "…Nice work getting there!"
const Persona hypePersona = Persona(
  id: 'hype',
  phrasesByKind: {
    TrainerEventKind.workoutStarted: [
      'coachHypeStart1',
      'coachHypeStart2',
      'coachHypeStart3',
    ],
    TrainerEventKind.setLogged: [
      'coachHypeSet1',
      'coachHypeSet2',
      'coachHypeSet3',
    ],
    TrainerEventKind.personalRecord: [
      'coachHypePr1',
      'coachHypePr2',
      'coachHypePr3',
    ],
    TrainerEventKind.restCountdown: [
      'coachHypeCountdown1',
      'coachHypeCountdown2',
      'coachHypeCountdown3',
    ],
    TrainerEventKind.restFinished: [
      'coachHypeRestDone1',
      'coachHypeRestDone2',
      'coachHypeRestDone3',
    ],
    TrainerEventKind.workoutFinished: [
      'coachHypeFinish1',
      'coachHypeFinish2',
      'coachHypeFinish3',
    ],
    TrainerEventKind.quote: _quoteBank,
    TrainerEventKind.hrZoneChanged: [
      'coachHypeZone',
    ],
    TrainerEventKind.hrAboveCap: [
      'coachHypeAboveCap1',
      'coachHypeAboveCap2',
    ],
    TrainerEventKind.hrBackBelowCap: [
      'coachHypeBackBelowCap',
    ],
  },
);

/// Firm, clipped, commanding (phase 2, spec §5) — but never demeaning. No
/// insults, no questioning the user's worth or effort, no shame. A good
/// coach who wastes no words, not a drill instructor. Heart-rate safety cues
/// stay just as calm and directive as every other persona's (see
/// `coachSergeantAboveCap*`/`coachSergeantBackBelowCap`).
const Persona sergeantPersona = Persona(
  id: 'sergeant',
  phrasesByKind: {
    TrainerEventKind.workoutStarted: [
      'coachSergeantStart1',
      'coachSergeantStart2',
      'coachSergeantStart3',
    ],
    TrainerEventKind.setLogged: [
      'coachSergeantSet1',
      'coachSergeantSet2',
      'coachSergeantSet3',
    ],
    TrainerEventKind.personalRecord: [
      'coachSergeantPr1',
      'coachSergeantPr2',
      'coachSergeantPr3',
    ],
    TrainerEventKind.restCountdown: [
      'coachSergeantCountdown1',
      'coachSergeantCountdown2',
      'coachSergeantCountdown3',
    ],
    TrainerEventKind.restFinished: [
      'coachSergeantRestDone1',
      'coachSergeantRestDone2',
      'coachSergeantRestDone3',
    ],
    TrainerEventKind.workoutFinished: [
      'coachSergeantFinish1',
      'coachSergeantFinish2',
      'coachSergeantFinish3',
    ],
    TrainerEventKind.quote: _quoteBank,
    TrainerEventKind.hrZoneChanged: [
      'coachSergeantZone',
    ],
    TrainerEventKind.hrAboveCap: [
      'coachSergeantAboveCap1',
      'coachSergeantAboveCap2',
    ],
    TrainerEventKind.hrBackBelowCap: [
      'coachSergeantBackBelowCap',
    ],
  },
);

/// Maps a persisted persona id (see `TrainerSettings.personaId`) to its pack,
/// defaulting to Steady for an unrecognised or legacy value.
Persona personaForId(String id) => switch (id) {
      'hype' => hypePersona,
      'sergeant' => sergeantPersona,
      _ => steadyPersona,
    };
