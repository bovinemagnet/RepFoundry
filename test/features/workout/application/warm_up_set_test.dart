import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/application/log_set_use_case.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';

void main() {
  group('LogSetUseCase warm-up sets', () {
    late InMemoryWorkoutRepository workoutRepo;
    late InMemoryPersonalRecordRepository prRepo;
    late LogSetUseCase useCase;

    setUp(() {
      workoutRepo = InMemoryWorkoutRepository();
      prRepo = InMemoryPersonalRecordRepository();
      useCase = LogSetUseCase(
        workoutRepository: workoutRepo,
        personalRecordRepository: prRepo,
      );
    });

    test('warm-up sets do not generate personal records', () async {
      final result = await useCase.execute(const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 1,
        weight: 100,
        reps: 10,
        isWarmUp: true,
      ));

      expect(result.newPersonalRecords, isEmpty);
      expect(result.set.isWarmUp, isTrue);
    });

    test('non-warm-up sets generate personal records', () async {
      final result = await useCase.execute(const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 1,
        weight: 100,
        reps: 10,
        isWarmUp: false,
      ));

      expect(result.newPersonalRecords, isNotEmpty);
      expect(result.set.isWarmUp, isFalse);
    });

    test('warm-up sets are excluded from PR comparison', () async {
      // Log a warm-up set with heavy weight.
      await useCase.execute(const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 1,
        weight: 200,
        reps: 10,
        isWarmUp: true,
      ));

      // Log a working set with less weight — should still be a PR
      // since the warm-up set is excluded.
      final result = await useCase.execute(const LogSetInput(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 2,
        weight: 100,
        reps: 10,
        isWarmUp: false,
      ));

      expect(result.newPersonalRecords, isNotEmpty);
    });
  });
}
