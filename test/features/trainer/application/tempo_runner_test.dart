import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/application/tempo_plan.dart';
import 'package:rep_foundry/features/trainer/application/tempo_runner.dart';

void main() {
  const perRep = Duration(seconds: 3);

  late List<(Duration, TempoCueKind, int)> fired;
  late List<int> finished;

  TempoRunner runner(FakeAsync async, List<TempoCue> plan) {
    fired = [];
    finished = [];
    final started = async.elapsed;
    return TempoRunner(
      plan: plan,
      onCue: (cue) => fired.add((async.elapsed - started, cue.kind, cue.value)),
      onFinished: finished.add,
    )..start();
  }

  test('speaks each cue at its planned moment', () {
    fakeAsync((async) {
      runner(async, tempoPlan(targetReps: 3, perRep: perRep));

      async.elapse(const Duration(seconds: 10));

      expect(fired, [
        (const Duration(seconds: 3), TempoCueKind.count, 1),
        (const Duration(seconds: 6), TempoCueKind.count, 2),
        (const Duration(seconds: 9), TempoCueKind.done, 3),
      ]);
    });
  });

  test('reports the finished set once, then stops running', () {
    fakeAsync((async) {
      final r = runner(async, tempoPlan(targetReps: 3, perRep: perRep));
      expect(r.isRunning, isTrue);

      async.elapse(const Duration(seconds: 30));

      expect(finished, [3]);
      expect(r.isRunning, isFalse);
    });
  });

  test('stopping early reports the reps done and silences the rest', () {
    fakeAsync((async) {
      final r = runner(async, tempoPlan(targetReps: 8, perRep: perRep));
      async.elapse(const Duration(seconds: 7));

      final done = r.stop();
      async.elapse(const Duration(seconds: 60));

      expect(done, 2);
      expect(fired, hasLength(2));
      expect(finished, isEmpty);
      expect(r.isRunning, isFalse);
    });
  });

  test('a rep followed by a cluster pause still counts as done', () {
    fakeAsync((async) {
      final r = runner(
        async,
        tempoPlan(targetReps: 6, perRep: perRep, clusterSize: 2),
      );
      // Rep 2 ends at 6 s and starts a 10 s pause.
      async.elapse(const Duration(seconds: 8));

      expect(r.stop(), 2);
    });
  });
}
