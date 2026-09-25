import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/application/coaching_engine.dart';
import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';
import 'package:rep_foundry/features/trainer/domain/persona.dart';
import 'package:rep_foundry/features/trainer/domain/tempo_cue.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';

const _persona = Persona(
  id: 'test',
  phrasesByKind: {
    TrainerEventKind.tempoCount: ['count'],
    TrainerEventKind.tempoCountDown: ['toGo'],
    TrainerEventKind.tempoRest: ['rest'],
    TrainerEventKind.tempoResume: ['go'],
    TrainerEventKind.tempoSetDone: ['done'],
    TrainerEventKind.hrZoneChanged: ['zone'],
    TrainerEventKind.hrAboveCap: ['abovecap'],
    TrainerEventKind.hrBackBelowCap: ['backbelow'],
  },
);

void main() {
  final t0 = DateTime.utc(2026, 9, 25, 7);
  late CoachingEngine engine;

  setUp(() => engine = CoachingEngine(persona: _persona, random: Random(1)));

  CoachingCue? say(RepTempo event, {bool cautionMode = false}) =>
      engine.onEvent(event, now: t0, cautionMode: cautionMode);

  test('counting up speaks the count at countdown priority', () {
    final cue = say(const RepTempo(cue: TempoCueKind.count, value: 3));

    expect(cue?.phraseKey, 'count');
    expect(cue?.args['count'], 3);
    expect(cue?.priority, SpeechPriority.countdown);
  });

  test('counting down speaks the reps to go', () {
    final cue = say(
      const RepTempo(cue: TempoCueKind.count, value: 2, countingDown: true),
    );

    expect(cue?.phraseKey, 'toGo');
    expect(cue?.args['count'], 2);
  });

  test('a cluster pause speaks its length', () {
    final cue = say(const RepTempo(cue: TempoCueKind.rest, value: 10));

    expect(cue?.phraseKey, 'rest');
    expect(cue?.args['seconds'], 10);
  });

  test('resume and set done have their own phrases', () {
    expect(say(const RepTempo(cue: TempoCueKind.resume, value: 0))?.phraseKey,
        'go');
    final done = say(const RepTempo(cue: TempoCueKind.done, value: 8));
    expect(done?.phraseKey, 'done');
    expect(done?.args['count'], 8);
  });

  test('stays silent above the safety cap', () {
    engine.onEvent(const HeartRateAboveCap(bpm: 190, cap: 180), now: t0);

    expect(say(const RepTempo(cue: TempoCueKind.count, value: 3)), isNull);
    expect(say(const RepTempo(cue: TempoCueKind.done, value: 8)), isNull);
  });

  test('counting is not encouragement: it still speaks in caution mode', () {
    expect(
      say(const RepTempo(cue: TempoCueKind.count, value: 3), cautionMode: true),
      isNotNull,
    );
  });
}
