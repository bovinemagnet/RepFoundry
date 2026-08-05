import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/application/coaching_engine.dart';
import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';
import 'package:rep_foundry/features/trainer/domain/persona.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';

const _testPersona = Persona(
  id: 'test',
  phrasesByKind: {
    TrainerEventKind.workoutStarted: ['start1', 'start2', 'start3'],
    TrainerEventKind.setLogged: ['set1', 'set2', 'set3'],
    TrainerEventKind.personalRecord: ['pr1', 'pr2', 'pr3'],
    TrainerEventKind.restCountdown: ['count1'],
    TrainerEventKind.restFinished: ['go1', 'go2', 'go3'],
    TrainerEventKind.workoutFinished: ['done1', 'done2', 'done3'],
    TrainerEventKind.quote: ['quote1', 'quote2', 'quote3'],
  },
);

/// Defaults to a *fixed* cadence so the majority of tests stay deterministic;
/// the randomised 2–3 default is exercised explicitly in its own group.
CoachingEngine _engine({
  int encouragementEverySets = 2,
  Duration cooldown = const Duration(seconds: 20),
}) =>
    CoachingEngine(
      persona: _testPersona,
      random: Random(1),
      encouragementCooldown: cooldown,
      encouragementMinSets: encouragementEverySets,
      encouragementMaxSets: encouragementEverySets,
    );

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);
  const min5 = Duration(minutes: 5);

  group('countdown', () {
    test('always speaks, ignoring the encouragement cooldown', () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(
        const RestCountdown(secondsLeft: 3),
        now: t0.add(const Duration(seconds: 1)),
      );

      expect(cue, isNotNull);
      expect(cue!.priority, SpeechPriority.countdown);
      expect(cue.args['secondsLeft'], 3);
    });
  });

  group('encouragement quota', () {
    test('stays quiet on the first set and speaks on the second', () {
      final engine =
          _engine(encouragementEverySets: 2, cooldown: Duration.zero);

      final first = engine.onEvent(
        const SetLogged(setNumber: 1, isPersonalRecord: false),
        now: t0,
      );
      final second = engine.onEvent(
        const SetLogged(setNumber: 2, isPersonalRecord: false),
        now: t0.add(const Duration(minutes: 1)),
      );

      expect(first, isNull);
      expect(second, isNotNull);
    });
  });

  group('randomised encouragement quota', () {
    /// Returns how many logged sets it took before the engine first spoke.
    int setsUntilFirstEncouragement(int seed) {
      final engine = CoachingEngine(
        persona: _testPersona,
        random: Random(seed),
        encouragementCooldown: Duration.zero,
      );
      for (var i = 1; i <= 10; i++) {
        final cue = engine.onEvent(
          SetLogged(setNumber: i, isPersonalRecord: false),
          now: t0.add(Duration(minutes: i)),
        );
        if (cue != null) return i;
      }
      return -1;
    }

    test('by default speaks on the 2nd or 3rd set, never sooner or later', () {
      // Spec §4.4: "roughly every 2nd–3rd logged set (randomised)".
      final observed = <int>{};
      for (var seed = 1; seed <= 40; seed++) {
        observed.add(setsUntilFirstEncouragement(seed));
      }

      expect(observed.difference({2, 3}), isEmpty,
          reason: 'the quota must stay inside the 2–3 band, got $observed');
      expect(observed, containsAll(<int>[2, 3]),
          reason: 'a fixed cadence would only ever produce one of the two; '
              'the gap must actually be randomised');
    });

    test('redraws the gap after each encouragement rather than fixing it once',
        () {
      // Two consecutive gaps differing within a single session can only
      // happen if the quota is redrawn, not chosen once at construction.
      var sawDifferingGaps = false;
      for (var seed = 1; seed <= 40 && !sawDifferingGaps; seed++) {
        final engine = CoachingEngine(
          persona: _testPersona,
          random: Random(seed),
          encouragementCooldown: Duration.zero,
        );
        final gaps = <int>[];
        var sinceCue = 0;
        for (var i = 1; i <= 12; i++) {
          sinceCue++;
          final cue = engine.onEvent(
            SetLogged(setNumber: i, isPersonalRecord: false),
            now: t0.add(Duration(minutes: i)),
          );
          if (cue != null) {
            gaps.add(sinceCue);
            sinceCue = 0;
          }
        }
        if (gaps.toSet().length > 1) sawDifferingGaps = true;
      }

      expect(sawDifferingGaps, isTrue);
    });

    test('a min equal to max gives a fixed cadence and draws no randomness',
        () {
      // Relied upon by the seeded tests above and below: a fixed cadence must
      // not perturb the phrase-picking sequence.
      final engine =
          _engine(encouragementEverySets: 3, cooldown: Duration.zero);

      expect(
        engine.onEvent(const SetLogged(setNumber: 1, isPersonalRecord: false),
            now: t0),
        isNull,
      );
      expect(
        engine.onEvent(const SetLogged(setNumber: 2, isPersonalRecord: false),
            now: t0),
        isNull,
      );
      expect(
        engine.onEvent(const SetLogged(setNumber: 3, isPersonalRecord: false),
            now: t0),
        isNotNull,
      );
    });
  });

  group('cue toggles', () {
    test('a suppressed countdown does not consume a phrase from the bank', () {
      // The engine — not the caller — owns "whether to speak", so a cue the
      // user has switched off must leave no trace at all: same phrase bank,
      // same position in the random sequence.
      final suppressedFirst = _engine();
      for (var i = 0; i < 2; i++) {
        expect(
          suppressedFirst.onEvent(const RestFinished(),
              now: t0.add(Duration(seconds: i)), countdownsEnabled: false),
          isNull,
        );
      }
      final afterSuppression = suppressedFirst.onEvent(
        const RestFinished(),
        now: t0.add(const Duration(seconds: 5)),
      );

      final untouched = _engine();
      final firstEver = untouched.onEvent(const RestFinished(), now: t0);

      expect(afterSuppression!.phraseKey, firstEver!.phraseKey,
          reason: 'the two suppressed cues burned phrases from the variety '
              'bank that the user never heard');
    });

    test('a suppressed countdown does not restart the encouragement cooldown',
        () {
      final engine = _engine(encouragementEverySets: 1);

      // A real encouragement cue at t0 starts the 20-second cooldown.
      expect(
        engine.onEvent(const SetLogged(setNumber: 1, isPersonalRecord: false),
            now: t0),
        isNotNull,
      );

      // Rest runs with countdowns switched off, finishing at t0 + 30s.
      for (final secondsLeft in [3, 2, 1]) {
        expect(
          engine.onEvent(
            RestCountdown(secondsLeft: secondsLeft),
            now: t0.add(Duration(seconds: 27 + (3 - secondsLeft))),
            countdownsEnabled: false,
          ),
          isNull,
        );
      }
      expect(
        engine.onEvent(const RestFinished(),
            now: t0.add(const Duration(seconds: 30)), countdownsEnabled: false),
        isNull,
      );

      // The next set lands 35s after the last thing actually spoken, well
      // past the cooldown — so encouragement is due.
      final next = engine.onEvent(
        const SetLogged(setNumber: 2, isPersonalRecord: false),
        now: t0.add(const Duration(seconds: 35)),
      );

      expect(next, isNotNull,
          reason: 'switching countdowns off must not silently make the coach '
              'quieter by pushing the cooldown forward on every rest');
    });

    test('the encouragement toggle suppresses only encouragement cues', () {
      final engine =
          _engine(encouragementEverySets: 1, cooldown: Duration.zero);

      expect(
        engine.onEvent(const SetLogged(setNumber: 1, isPersonalRecord: false),
            now: t0, encouragementEnabled: false),
        isNull,
      );
      expect(
        engine.onEvent(const SetLogged(setNumber: 2, isPersonalRecord: true),
            now: t0, encouragementEnabled: false),
        isNotNull,
        reason: 'a personal record is a milestone, not encouragement',
      );
      expect(
        engine.onEvent(const RestFinished(),
            now: t0, encouragementEnabled: false),
        isNotNull,
      );
    });
  });

  group('cooldown', () {
    test('suppresses encouragement inside the cooldown window', () {
      final engine = _engine(encouragementEverySets: 1);

      final first = engine.onEvent(
        const SetLogged(setNumber: 1, isPersonalRecord: false),
        now: t0,
      );
      final tooSoon = engine.onEvent(
        const SetLogged(setNumber: 2, isPersonalRecord: false),
        now: t0.add(const Duration(seconds: 5)),
      );
      final later = engine.onEvent(
        const SetLogged(setNumber: 3, isPersonalRecord: false),
        now: t0.add(const Duration(seconds: 30)),
      );

      expect(first, isNotNull);
      expect(tooSoon, isNull);
      expect(later, isNotNull);
    });

    test('a personal record is a milestone and ignores the cooldown', () {
      final engine = _engine(encouragementEverySets: 1);
      engine.onEvent(const SetLogged(setNumber: 1, isPersonalRecord: false),
          now: t0);

      final pr = engine.onEvent(
        const SetLogged(setNumber: 2, isPersonalRecord: true),
        now: t0.add(const Duration(seconds: 2)),
      );

      expect(pr, isNotNull);
      expect(pr!.priority, SpeechPriority.milestone);
      expect(pr.phraseKey, startsWith('pr'));
    });
  });

  group('variety', () {
    test('never repeats a phrase within a session', () {
      final engine =
          _engine(encouragementEverySets: 1, cooldown: Duration.zero);
      final seen = <String>{};

      for (var i = 1; i <= 3; i++) {
        final cue = engine.onEvent(
          const SetLogged(setNumber: 1, isPersonalRecord: false),
          now: t0.add(Duration(minutes: i)),
        );
        expect(cue, isNotNull);
        expect(seen.add(cue!.phraseKey), isTrue,
            reason: 'phrase ${cue.phraseKey} was repeated');
      }
    });

    test('recycles the bank once every phrase has been used', () {
      final engine =
          _engine(encouragementEverySets: 1, cooldown: Duration.zero);

      for (var i = 1; i <= 4; i++) {
        final cue = engine.onEvent(
          const SetLogged(setNumber: 1, isPersonalRecord: false),
          now: t0.add(Duration(minutes: i)),
        );
        expect(cue, isNotNull, reason: 'engine fell silent on call $i');
      }
    });

    test('reset clears session state', () {
      final engine =
          _engine(encouragementEverySets: 1, cooldown: Duration.zero);
      final first = engine.onEvent(
        const SetLogged(setNumber: 1, isPersonalRecord: false),
        now: t0,
      );

      engine.reset();

      final afterReset = engine.onEvent(
        const SetLogged(setNumber: 1, isPersonalRecord: false),
        now: t0.add(const Duration(seconds: 1)),
      );

      expect(afterReset, isNotNull);
      expect(afterReset!.phraseKey, first!.phraseKey,
          reason: 'a reset engine with a seeded Random repeats its first pick');
    });
  });

  group('empty banks', () {
    test('stays silent when the persona has no phrases for a kind', () {
      const bare = Persona(id: 'bare', phrasesByKind: {});
      final engine = CoachingEngine(persona: bare, random: Random(1));

      expect(engine.onEvent(const WorkoutStarted(), now: t0), isNull);
    });
  });

  group('other events', () {
    test('workout finished is a milestone carrying the total sets', () {
      final engine = _engine();

      final cue = engine.onEvent(const WorkoutFinished(totalSets: 5), now: t0);

      expect(cue, isNotNull);
      expect(cue!.priority, SpeechPriority.milestone);
      expect(cue.args['totalSets'], 5);
    });

    test('rest finished cues a countdown-priority phrase', () {
      final engine = _engine();

      final cue = engine.onEvent(const RestFinished(), now: t0);

      expect(cue, isNotNull);
      expect(cue!.priority, SpeechPriority.countdown);
      expect(cue.phraseKey, startsWith('go'));
    });

    test('rest started never produces a cue', () {
      final engine = _engine();

      final cue = engine.onEvent(
        const RestStarted(duration: Duration(seconds: 60)),
        now: t0,
      );

      expect(cue, isNull);
    });
  });

  group('default random source', () {
    test('falls back to an unseeded Random when none is supplied', () {
      final engine = CoachingEngine(persona: _testPersona);

      final cue = engine.onEvent(const WorkoutStarted(), now: t0);

      expect(cue, isNotNull);
    });
  });

  group('quotes', () {
    const longRest = RestFinished(restDuration: Duration(minutes: 2));
    const shortRest = RestFinished(restDuration: Duration(seconds: 90));

    test('attaches a quote to the workout-start greeting', () {
      final cue = _engine().onEvent(const WorkoutStarted(), now: t0);

      expect(cue!.phraseKey, startsWith('start'));
      expect(cue.quotePhraseKey, startsWith('quote'));
      expect(cue.priority, SpeechPriority.milestone);
    });

    test('attaches no quote at workout start when quotes are switched off', () {
      final cue = _engine()
          .onEvent(const WorkoutStarted(), now: t0, quotesEnabled: false);

      expect(cue!.phraseKey, startsWith('start'));
      expect(cue.quotePhraseKey, isNull);
    });

    test('attaches a quote to the countdown cue after a rest of two minutes',
        () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(longRest, now: t0.add(min5));

      expect(cue!.phraseKey, startsWith('go'));
      expect(cue.quotePhraseKey, startsWith('quote'));
      expect(cue.priority, SpeechPriority.countdown);
    });

    test('attaches no quote after a rest shorter than two minutes', () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(shortRest, now: t0.add(min5));

      expect(cue!.phraseKey, startsWith('go'));
      expect(cue.quotePhraseKey, isNull);
    });

    test('attaches no quote when the rest duration is unknown', () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(const RestFinished(), now: t0.add(min5));

      expect(cue!.phraseKey, startsWith('go'));
      expect(cue.quotePhraseKey, isNull);
    });

    test(
        'speaks the quote alone after a long rest when countdowns are off, so '
        'the countdown toggle is not a second mute for quotes', () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(
        longRest,
        now: t0.add(min5),
        countdownsEnabled: false,
      );

      expect(cue!.phraseKey, startsWith('quote'));
      expect(cue.quotePhraseKey, isNull);
      expect(cue.priority, SpeechPriority.milestone);
    });

    test('says nothing at rest end when both countdowns and quotes are off',
        () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(
        longRest,
        now: t0.add(min5),
        countdownsEnabled: false,
        quotesEnabled: false,
      );

      expect(cue, isNull);
    });

    test('does not attach a quote while the reading is above the safety cap',
        () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);
      engine.onEvent(
        const HeartRateAboveCap(bpm: 190, cap: 175),
        now: t0.add(const Duration(seconds: 10)),
      );

      final cue = engine.onEvent(longRest, now: t0.add(min5));

      // The countdown cue itself is exempt from the encouragement gate — a
      // missed countdown makes the feature useless — but the quote must not
      // ride along on that exemption.
      expect(cue!.phraseKey, startsWith('go'));
      expect(cue.quotePhraseKey, isNull);
    });

    test('does not attach a quote in caution mode', () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(
        longRest,
        now: t0.add(min5),
        cautionMode: true,
      );

      expect(cue!.quotePhraseKey, isNull);
    });

    test('does not attach a quote once the user has reached zone 5', () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);
      engine.onEvent(
        const HeartRateZoneChanged(
          zoneNumber: 5,
          effortLabel: 'Maximum',
          descriptiveLabel: 'Anaerobic',
        ),
        now: t0.add(const Duration(seconds: 10)),
      );

      final cue = engine.onEvent(longRest, now: t0.add(min5));

      expect(cue!.quotePhraseKey, isNull);
    });

    test('exhausts the bank before repeating a quote', () {
      final engine = _engine();
      final bank = _testPersona.phrasesFor(TrainerEventKind.quote);
      final heard = <String>{};

      var at = t0;
      for (var i = 0; i < bank.length; i++) {
        final cue = engine.onEvent(longRest, now: at, countdownsEnabled: false);
        heard.add(cue!.phraseKey);
        at = at.add(min5);
      }

      expect(heard, hasLength(bank.length));
    });

    test(
        'a suppressed quote does not consume the bank — switching quotes back '
        'on still offers every quote', () {
      final engine = _engine();
      var at = t0;
      for (var i = 0; i < 10; i++) {
        engine.onEvent(
          longRest,
          now: at,
          countdownsEnabled: false,
          quotesEnabled: false,
        );
        at = at.add(min5);
      }

      final bank = _testPersona.phrasesFor(TrainerEventKind.quote);
      final heard = <String>{};
      for (var i = 0; i < bank.length; i++) {
        final cue = engine.onEvent(longRest, now: at, countdownsEnabled: false);
        heard.add(cue!.phraseKey);
        at = at.add(min5);
      }

      expect(heard, hasLength(bank.length));
    });

    test(
        'attaches a distinct quote to each merged countdown cue until the '
        'bank is exhausted, not just on the standalone path', () {
      final engine = _engine();
      final bank = _testPersona.phrasesFor(TrainerEventKind.quote);
      final heard = <String>{};

      var at = t0;
      for (var i = 0; i < bank.length; i++) {
        final cue = engine.onEvent(longRest, now: at);
        heard.add(cue!.quotePhraseKey!);
        at = at.add(min5);
      }

      expect(heard, hasLength(bank.length));
    });

    test('attaches no quote to the countdown cue when quotes are switched off',
        () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(
        longRest,
        now: t0.add(min5),
        quotesEnabled: false,
      );

      expect(cue!.phraseKey, startsWith('go'));
      expect(cue.quotePhraseKey, isNull);
    });
  });
}
