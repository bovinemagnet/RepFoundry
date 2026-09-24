import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

void main() {
  late InMemoryWorkoutRepository repo;

  setUp(() => repo = InMemoryWorkoutRepository());

  WorkoutSet newSet(String workoutId, String exerciseId, {int setOrder = 1}) =>
      WorkoutSet.create(
        workoutId: workoutId,
        exerciseId: exerciseId,
        setOrder: setOrder,
        weight: 100,
        reps: 5,
      );

  group('InMemoryWorkoutRepository.getExerciseUsageCounts', () {
    test('counts distinct workouts per exercise, not sets', () async {
      final w1 = await repo.createWorkout(Workout.create());
      final w2 = await repo.createWorkout(Workout.create());
      await repo.addSet(newSet(w1.id, '1'));
      await repo.addSet(newSet(w1.id, '1', setOrder: 2));
      await repo.addSet(newSet(w2.id, '1'));
      await repo.addSet(newSet(w2.id, '2'));

      final counts = await repo.getExerciseUsageCounts(kSelfClientId);

      expect(counts, {'1': 2, '2': 1});
    });

    test('excludes other clients, deleted workouts and deleted sets', () async {
      final mine = await repo.createWorkout(Workout.create());
      final alices =
          await repo.createWorkout(Workout.create(clientId: 'alice'));
      final deleted = await repo.createWorkout(Workout.create());
      await repo.addSet(newSet(mine.id, '1'));
      final withdrawn = await repo.addSet(newSet(mine.id, '3'));
      await repo.addSet(newSet(alices.id, '2'));
      await repo.addSet(newSet(deleted.id, '2'));
      await repo.deleteWorkout(deleted.id);
      await repo.deleteSet(withdrawn.id);

      final counts = await repo.getExerciseUsageCounts(kSelfClientId);

      expect(counts, {'1': 1});
    });
  });
}
