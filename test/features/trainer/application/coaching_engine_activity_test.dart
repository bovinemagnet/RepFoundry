import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/application/coaching_engine.dart';
import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';
import 'package:rep_foundry/features/trainer/domain/persona.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';

const _persona = Persona(
  id: 'test',
  phrasesByKind: {
    TrainerEventKind.activityDetected: ['nudge1', 'nudge2', 'nudge3'],
    TrainerEventKind.hrZoneChanged: ['zone1'],
    TrainerEventKind.hrAboveCap: ['abovecap1'],
    TrainerEventKind.hrBackBelowCap: ['backbelow1'],
  },
);

void main() {
  final t0 = DateTime.utc(2026, 9, 25, 7);
  late CoachingEngine engine;

  setUp(() => engine = CoachingEngine(persona: _persona, random: Random(1)));

  CoachingCue? nudge({bool cautionMode = false}) => engine.onEvent(
        const ActivityDetected(),
        now: t0.add(const Duration(minutes: 5)),
        cautionMode: cautionMode,
      );

  void zone(int zoneNumber) => engine.onEvent(
        HeartRateZoneChanged(
          zoneNumber: zoneNumber,
          effortLabel: 'Effort',
          descriptiveLabel: 'Descriptive',
        ),
        now: t0,
      );

  test('offers company at encouragement priority', () {
    final cue = nudge();

    expect(cue?.phraseKey, startsWith('nudge'));
    expect(cue?.priority, SpeechPriority.encouragement);
  });

  test('says nothing above the safety cap', () {
    engine.onEvent(const HeartRateAboveCap(bpm: 190, cap: 180), now: t0);

    expect(nudge(), isNull);
  });

  test('says nothing in caution mode', () {
    expect(nudge(cautionMode: true), isNull);
  });

  test('says nothing in zone 5', () {
    zone(5);

    expect(nudge(), isNull);
  });

  test('still offers company in zone 4', () {
    zone(4);

    expect(nudge(), isNotNull);
  });
}
