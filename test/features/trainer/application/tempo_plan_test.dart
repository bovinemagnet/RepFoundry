import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/application/tempo_plan.dart';

void main() {
  const s3 = Duration(seconds: 3);
  Duration at(int seconds) => Duration(seconds: seconds);

  group('tempoPlan', () {
    test('counts up one rep per beat and says when the set is done', () {
      expect(tempoPlan(targetReps: 3, perRep: s3), [
        (at: at(3), kind: TempoCueKind.count, value: 1),
        (at: at(6), kind: TempoCueKind.count, value: 2),
        (at: at(9), kind: TempoCueKind.done, value: 3),
      ]);
    });

    test('counting down speaks the reps still to go', () {
      expect(tempoPlan(targetReps: 3, perRep: s3, countDown: true), [
        (at: at(3), kind: TempoCueKind.count, value: 2),
        (at: at(6), kind: TempoCueKind.count, value: 1),
        (at: at(9), kind: TempoCueKind.done, value: 3),
      ]);
    });

    test('cluster pauses rest after every N reps, then resume', () {
      final plan = tempoPlan(
        targetReps: 5,
        perRep: s3,
        clusterSize: 2,
        clusterPause: const Duration(seconds: 10),
      );

      expect(plan, [
        (at: at(3), kind: TempoCueKind.count, value: 1),
        (at: at(6), kind: TempoCueKind.rest, value: 10),
        (at: at(16), kind: TempoCueKind.resume, value: 0),
        (at: at(19), kind: TempoCueKind.count, value: 3),
        (at: at(22), kind: TempoCueKind.rest, value: 10),
        (at: at(32), kind: TempoCueKind.resume, value: 0),
        (at: at(35), kind: TempoCueKind.done, value: 5),
      ]);
    });

    test('the last rep finishes the set rather than starting a rest', () {
      final plan = tempoPlan(targetReps: 4, perRep: s3, clusterSize: 2);

      expect(plan.last, (at: at(22), kind: TempoCueKind.done, value: 4));
      expect(plan.where((c) => c.kind == TempoCueKind.rest), hasLength(1));
    });

    test('counting down carries on from where the rest left off', () {
      final plan = tempoPlan(
        targetReps: 4,
        perRep: s3,
        countDown: true,
        clusterSize: 2,
        clusterPause: const Duration(seconds: 5),
      );

      expect(plan.map((c) => (c.kind, c.value)), [
        (TempoCueKind.count, 3),
        (TempoCueKind.rest, 5),
        (TempoCueKind.resume, 0),
        (TempoCueKind.count, 1),
        (TempoCueKind.done, 4),
      ]);
    });

    test('no target, no plan', () {
      expect(tempoPlan(targetReps: 0, perRep: s3), isEmpty);
    });
  });
}
