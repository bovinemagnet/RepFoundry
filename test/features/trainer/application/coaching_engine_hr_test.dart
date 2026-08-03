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
    TrainerEventKind.hrZoneChanged: ['zone1'],
    TrainerEventKind.hrAboveCap: ['abovecap1', 'abovecap2'],
    TrainerEventKind.hrBackBelowCap: ['backbelow1'],
  },
);

/// Fixed cadence by default so tests stay deterministic.
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

  test('above cap produces a safety-priority cue', () {
    final engine = _engine();
    final cue = engine.onEvent(
      const HeartRateAboveCap(bpm: 180, cap: 170),
      now: t0,
    );

    expect(cue, isNotNull);
    expect(cue!.priority, SpeechPriority.safety);
    expect(cue.args['bpm'], 180);
    expect(engine.isAboveCap, isTrue);
  });

  test('the cap warning repeats no more than every 30 seconds', () {
    final engine = _engine();
    engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);

    final tooSoon = engine.onEvent(
      const HeartRateAboveCap(bpm: 182, cap: 170),
      now: t0.add(const Duration(seconds: 10)),
    );
    final later = engine.onEvent(
      const HeartRateAboveCap(bpm: 182, cap: 170),
      now: t0.add(const Duration(seconds: 31)),
    );

    expect(tooSoon, isNull);
    expect(later, isNotNull);
  });

  test('encouragement is suppressed entirely while above cap', () {
    final engine = _engine(encouragementEverySets: 1, cooldown: Duration.zero);
    engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);

    final cue = engine.onEvent(
      const SetLogged(setNumber: 1, isPersonalRecord: false),
      now: t0.add(const Duration(seconds: 5)),
    );

    expect(cue, isNull);
  });

  test('dropping back below the cap lifts the suppression', () {
    final engine = _engine(encouragementEverySets: 1, cooldown: Duration.zero);
    engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);
    engine.onEvent(const HeartRateBackBelowCap(),
        now: t0.add(const Duration(seconds: 20)));

    final cue = engine.onEvent(
      const SetLogged(setNumber: 1, isPersonalRecord: false),
      now: t0.add(const Duration(seconds: 25)),
    );

    expect(cue, isNotNull);
    expect(engine.isAboveCap, isFalse);
  });

  test('a personal record is still suppressed above cap', () {
    // PRs are milestone priority and normally bypass the cooldown, so they are
    // the most likely cue to escape the safety suppression.
    final engine = _engine();
    engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);

    final cue = engine.onEvent(
      const SetLogged(setNumber: 1, isPersonalRecord: true),
      now: t0.add(const Duration(seconds: 5)),
    );

    expect(cue, isNull);
  });

  test('caution mode produces zone callouts but no encouragement', () {
    final engine = _engine(encouragementEverySets: 1, cooldown: Duration.zero);

    final zone = engine.onEvent(
      const HeartRateZoneChanged(
          zoneNumber: 3, effortLabel: 'Moderate', descriptiveLabel: 'Aerobic'),
      now: t0,
      cautionMode: true,
    );
    final encouragement = engine.onEvent(
      const SetLogged(setNumber: 1, isPersonalRecord: false),
      now: t0.add(const Duration(minutes: 1)),
      cautionMode: true,
    );

    expect(zone, isNotNull);
    expect(encouragement, isNull);
  });

  test('encouragement never fires in zone 5', () {
    final engine = _engine(encouragementEverySets: 1, cooldown: Duration.zero);
    engine.onEvent(
      const HeartRateZoneChanged(
          zoneNumber: 5, effortLabel: 'Maximum', descriptiveLabel: 'VO₂ Max'),
      now: t0,
    );

    final cue = engine.onEvent(
      const SetLogged(setNumber: 1, isPersonalRecord: false),
      now: t0.add(const Duration(minutes: 1)),
    );

    expect(cue, isNull);
  });

  test('hrCalloutsEnabled false silences zone callouts', () {
    final engine = _engine();

    final cue = engine.onEvent(
      const HeartRateZoneChanged(
          zoneNumber: 3, effortLabel: 'Moderate', descriptiveLabel: 'Aerobic'),
      now: t0,
      hrCalloutsEnabled: false,
    );

    expect(cue, isNull);
  });

  test('hrCalloutsEnabled false still allows cap warnings', () {
    // The safety path must not be switchable off by a convenience toggle.
    final engine = _engine();

    final cue = engine.onEvent(
      const HeartRateAboveCap(bpm: 180, cap: 170),
      now: t0,
      hrCalloutsEnabled: false,
    );

    expect(cue, isNotNull);
    expect(cue!.priority, SpeechPriority.safety);
  });

  group('milestone cues respect the encouragement gate', () {
    // Fix round 1, Critical 1: WorkoutFinished (and, defensively, every other
    // milestone-priority cue) must not congratulate the user while their
    // heart rate is above the safety cap, in caution mode, or in zone 5 —
    // the engine must not rely on the caller resetting it at the right time.
    test('workout finished is suppressed above cap', () {
      final engine = _engine();
      engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);

      final cue = engine.onEvent(
        const WorkoutFinished(totalSets: 15),
        now: t0.add(const Duration(seconds: 5)),
      );

      expect(cue, isNull);
    });

    test('workout finished is suppressed in caution mode', () {
      final engine = _engine();

      final cue = engine.onEvent(
        const WorkoutFinished(totalSets: 15),
        now: t0,
        cautionMode: true,
      );

      expect(cue, isNull);
    });

    test('workout finished is suppressed in zone 5', () {
      final engine = _engine();
      engine.onEvent(
        const HeartRateZoneChanged(
            zoneNumber: 5, effortLabel: 'Maximum', descriptiveLabel: 'VO₂ Max'),
        now: t0,
      );

      final cue = engine.onEvent(
        const WorkoutFinished(totalSets: 15),
        now: t0.add(const Duration(minutes: 1)),
      );

      expect(cue, isNull);
    });

    test('workout started is suppressed above cap', () {
      // Masked in the original implementation only by the bridge resetting
      // the engine before this event — the engine itself must not depend on
      // that caller ordering.
      final engine = _engine();
      engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);

      final cue = engine.onEvent(
        const WorkoutStarted(),
        now: t0.add(const Duration(seconds: 5)),
      );

      expect(cue, isNull);
    });
  });

  group('reset clears the new heart-rate state', () {
    // Fix round 1, Important 3: without this, reset() runs inside other
    // tests and its lines count as "covered" while nothing asserts the
    // fields it clears actually unblock the engine afterwards.
    test('reset lifts above-cap suppression', () {
      final engine =
          _engine(encouragementEverySets: 1, cooldown: Duration.zero);
      engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);

      engine.reset();

      final cue = engine.onEvent(
        const SetLogged(setNumber: 1, isPersonalRecord: false),
        now: t0.add(const Duration(seconds: 1)),
      );

      expect(cue, isNotNull);
      expect(engine.isAboveCap, isFalse);
    });

    test('reset clears the cap-warning repeat timer', () {
      // Fix round 2, Important 2: reset() clears _lastCapWarningAt, but
      // nothing re-issued HeartRateAboveCap afterwards to prove it. Live
      // consequence: coach_bridge.dart calls reset() on both WorkoutStarted
      // and WorkoutFinished, so a session ending above cap followed by a new
      // one starting within 30s would have its first safety warning
      // swallowed by a stale repeat window.
      final engine = _engine();
      engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);

      engine.reset();

      final cue = engine.onEvent(
        const HeartRateAboveCap(bpm: 180, cap: 170),
        now: t0.add(const Duration(seconds: 5)),
      );

      expect(cue, isNotNull);
      expect(cue!.priority, SpeechPriority.safety);
    });

    test('reset lifts zone-5 suppression', () {
      final engine =
          _engine(encouragementEverySets: 1, cooldown: Duration.zero);
      engine.onEvent(
        const HeartRateZoneChanged(
            zoneNumber: 5, effortLabel: 'Maximum', descriptiveLabel: 'VO₂ Max'),
        now: t0,
      );

      engine.reset();

      final cue = engine.onEvent(
        const SetLogged(setNumber: 1, isPersonalRecord: false),
        now: t0.add(const Duration(seconds: 1)),
      );

      expect(cue, isNotNull);
    });
  });

  group('back below cap without a genuine crossing', () {
    // Fix round 1, Important 5: the reassurance cue only makes sense as the
    // bookend to a warning the user actually heard.
    test('stays silent when the engine was never above cap', () {
      final engine = _engine();

      final cue = engine.onEvent(const HeartRateBackBelowCap(), now: t0);

      expect(cue, isNull);
    });

    test('a genuine departure and a fresh crossing both warn', () {
      // Fix round 1 ruling: resetting _lastCapWarningAt on a genuine
      // below-cap departure is correct — pinned here so it cannot regress.
      final engine = _engine();
      engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);
      engine.onEvent(const HeartRateBackBelowCap(),
          now: t0.add(const Duration(seconds: 5)));

      final secondCrossing = engine.onEvent(
        const HeartRateAboveCap(bpm: 180, cap: 170),
        now: t0.add(const Duration(seconds: 10)),
      );

      expect(secondCrossing, isNotNull);
      expect(secondCrossing!.priority, SpeechPriority.safety);
    });
  });

  group('hrSafetyWarningsEnabled', () {
    test('false silences the cap warning without starting its cooldown', () {
      final engine = _engine();
      final silenced = engine.onEvent(
        const HeartRateAboveCap(bpm: 180, cap: 170),
        now: t0,
        hrSafetyWarningsEnabled: false,
      );

      final reEnabled = engine.onEvent(
        const HeartRateAboveCap(bpm: 182, cap: 170),
        now: t0.add(const Duration(seconds: 1)),
      );

      expect(silenced, isNull);
      expect(reEnabled, isNotNull);
    });

    test('false still suppresses encouragement while above cap', () {
      final engine =
          _engine(encouragementEverySets: 1, cooldown: Duration.zero);
      engine.onEvent(
        const HeartRateAboveCap(bpm: 180, cap: 170),
        now: t0,
        hrSafetyWarningsEnabled: false,
      );

      final cue = engine.onEvent(
        const SetLogged(setNumber: 1, isPersonalRecord: false),
        now: t0.add(const Duration(seconds: 5)),
      );

      expect(cue, isNull);
      expect(engine.isAboveCap, isTrue);
    });

    // Requirement B (carried forward from earlier reviews): the toggle must
    // also govern HeartRateBackBelowCap, not just HeartRateAboveCap — a user
    // who muted safety warnings must never hear "back under your maximum"
    // having never heard a warning.
    test('false silences the back-below-cap reassurance too', () {
      final engine = _engine();
      engine.onEvent(
        const HeartRateAboveCap(bpm: 180, cap: 170),
        now: t0,
        hrSafetyWarningsEnabled: false,
      );

      final cue = engine.onEvent(
        const HeartRateBackBelowCap(),
        now: t0.add(const Duration(seconds: 5)),
        hrSafetyWarningsEnabled: false,
      );

      expect(cue, isNull);
      expect(engine.isAboveCap, isFalse,
          reason: 'the suppression must still lift even though the '
              'reassurance itself stays silent');
    });

    test(
        'false still lets encouragement resume once back below cap — the '
        'toggle must not leave the session silenced for good', () {
      // Critical constraint: _onBackBelowCap must clear _aboveCap and
      // _lastCapWarningAt before checking the toggle, not after an early
      // return. Getting the order wrong here leaves encouragement suppressed
      // for the rest of the session with no event able to lift it.
      final engine =
          _engine(encouragementEverySets: 1, cooldown: Duration.zero);
      engine.onEvent(
        const HeartRateAboveCap(bpm: 180, cap: 170),
        now: t0,
        hrSafetyWarningsEnabled: false,
      );
      final reassurance = engine.onEvent(
        const HeartRateBackBelowCap(),
        now: t0.add(const Duration(seconds: 5)),
        hrSafetyWarningsEnabled: false,
      );

      final cue = engine.onEvent(
        const SetLogged(setNumber: 1, isPersonalRecord: false),
        now: t0.add(const Duration(seconds: 10)),
      );

      expect(reassurance, isNull, reason: 'muted, so no speech');
      expect(cue, isNotNull,
          reason: 'encouragement must resume once genuinely back below cap, '
              'even though the toggle kept the bookend line silent');
    });
  });
}
