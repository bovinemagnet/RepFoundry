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
  },
);

CoachingEngine _engine({
  int encouragementEverySets = 2,
  Duration cooldown = const Duration(seconds: 20),
}) =>
    CoachingEngine(
      persona: _testPersona,
      random: Random(1),
      encouragementCooldown: cooldown,
      encouragementEverySets: encouragementEverySets,
    );

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);

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
}
