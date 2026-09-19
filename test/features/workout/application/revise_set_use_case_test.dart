import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/workout/application/log_set_use_case.dart';
import 'package:rep_foundry/features/workout/application/revise_set_use_case.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

void main() {
  late InMemoryWorkoutRepository workoutRepo;
  late InMemoryPersonalRecordRepository prRepo;
  late LogSetUseCase logSet;
  late ReviseSetUseCase revise;
  late Workout workout;

  setUp(() async {
    workoutRepo = InMemoryWorkoutRepository();
    prRepo = InMemoryPersonalRecordRepository();
    logSet = LogSetUseCase(
      workoutRepository: workoutRepo,
      personalRecordRepository: prRepo,
    );
    revise = ReviseSetUseCase(
      workoutRepository: workoutRepo,
      personalRecordRepository: prRepo,
    );
    workout = await workoutRepo.createWorkout(Workout.create());
  });

  Future<WorkoutSet> log(double weight, {int reps = 5, int order = 1}) async {
    final result = await logSet.execute(LogSetInput(
      workoutId: workout.id,
      exerciseId: 'bench',
      setOrder: order,
      weight: weight,
      reps: reps,
    ));
    return result.set;
  }

  Future<double?> bestWeight() async {
    final best = await prRepo.getBestRecord(
      'bench',
      RecordType.maxWeight,
      kSelfClientId,
    );
    return best?.value;
  }

  test('deleting a mistaken set withdraws the records it earned', () async {
    await log(100);
    final mistake = await log(1000, order: 2);
    expect(await bestWeight(), 1000);

    await revise.delete(mistake.id);

    expect(await bestWeight(), 100);
  });

  test('after a deletion a legitimate new record can be set again', () async {
    await log(100);
    final mistake = await log(1000, order: 2);
    await revise.delete(mistake.id);

    await log(110, order: 3);

    expect(await bestWeight(), 110);
  });

  test('correcting a set downward replaces its records with the new value',
      () async {
    final mistake = await log(1000);

    await revise.update(
      mistake.copyWith(weight: 90),
      clientId: kSelfClientId,
    );

    expect(await bestWeight(), 90);
  });

  test('correcting a set upward earns the record it now deserves', () async {
    await log(100);
    final under = await log(90, order: 2);
    expect(await bestWeight(), 100);

    final result = await revise.update(
      under.copyWith(weight: 120),
      clientId: kSelfClientId,
    );

    expect(await bestWeight(), 120);
    expect(result.newPersonalRecords.map((r) => r.recordType),
        contains(RecordType.maxWeight));
  });

  test('marking a set as warm-up withdraws its records', () async {
    await log(100);
    final heavy = await log(120, order: 2);

    await revise.update(
      heavy.copyWith(isWarmUp: true),
      clientId: kSelfClientId,
    );

    expect(await bestWeight(), 100);
  });

  test('update persists the revised set', () async {
    final set = await log(100);

    await revise.update(set.copyWith(reps: 8), clientId: kSelfClientId);

    final stored = await workoutRepo.getSetsForWorkout(workout.id);
    expect(stored.single.reps, 8);
  });

  test('delete removes the set', () async {
    final set = await log(100);

    await revise.delete(set.id);

    expect(await workoutRepo.getSetsForWorkout(workout.id), isEmpty);
  });
}
