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
}
