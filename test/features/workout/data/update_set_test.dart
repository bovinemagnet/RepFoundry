import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';

void main() {
  group('WorkoutRepository.updateSet', () {
    late InMemoryWorkoutRepository repo;

    setUp(() {
      repo = InMemoryWorkoutRepository();
    });

    test('updates an existing set weight and reps', () async {
      final original = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 1,
        weight: 60,
        reps: 10,
      );
      await repo.addSet(original);

      final updated = original.copyWith(weight: 80, reps: 8);
      await repo.updateSet(updated);

      final sets = await repo.getSetsForWorkout('w1');
      expect(sets.length, 1);
      expect(sets.first.weight, 80);
      expect(sets.first.reps, 8);
    });

    test('updates RPE from null to a value', () async {
      final original = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 1,
        weight: 100,
        reps: 5,
      );
      await repo.addSet(original);
      expect(original.rpe, isNull);

      final updated = original.copyWith(rpe: 8.5);
      await repo.updateSet(updated);

      final sets = await repo.getSetsForWorkout('w1');
      expect(sets.first.rpe, 8.5);
    });

    test('preserves other sets when updating one', () async {
      final set1 = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 1,
        weight: 60,
        reps: 10,
      );
      final set2 = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 2,
        weight: 65,
        reps: 8,
      );
      await repo.addSet(set1);
      await repo.addSet(set2);

      await repo.updateSet(set1.copyWith(weight: 70));

      final sets = await repo.getSetsForWorkout('w1');
      expect(sets.length, 2);
      expect(sets[0].weight, 70);
      expect(sets[1].weight, 65);
    });
  });
}
