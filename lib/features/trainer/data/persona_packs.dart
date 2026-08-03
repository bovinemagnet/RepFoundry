import '../domain/persona.dart';
import '../domain/trainer_event.dart';

/// Shared inspirational quote bank (spec §5). Public-domain sources only,
/// each pinned to a specific out-of-copyright edition or translation — see
/// the sourcing table in the fix-round report for the edition relied on per
/// entry; a quote whose provenance could not be pinned to a specific PD text
/// was dropped rather than kept on a general "old author" assumption, since
/// a translator's own copyright is independent of the original author's.
///
/// **Not yet wired to any event.** No `TrainerEvent` currently carries
/// `TrainerEventKind.quote`, and `CoachingEngine.onEvent` has no case for it,
/// so nothing in the app speaks these phrases yet — attaching them here is
/// content preparation only. Spoken-timing behaviour ("workout start and
/// after rests of two minutes or longer", per spec §5) is tracked as a
/// follow-up, issue #TBD.
///
/// Attached to every persona's [TrainerEventKind.quote] bank rather than
/// kept as a standalone list, so the existing per-persona
/// uniqueness/resolver/denylist test loops cover it automatically instead of
/// needing a parallel set of checks.
const List<String> _quoteBank = [
  'coachQuote1',
  'coachQuote2',
  'coachQuote3',
  'coachQuote4',
  'coachQuote5',
  'coachQuote6',
  'coachQuote7',
  'coachQuote8',
  'coachQuote9',
  'coachQuote10',
  'coachQuote11',
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
  'coachQuote24',
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
