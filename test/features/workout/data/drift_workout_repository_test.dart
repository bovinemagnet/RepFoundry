import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/workout/data/drift_workout_repository.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

void main() {
  late db.AppDatabase database;
  late DriftWorkoutRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftWorkoutRepository(database);
  });

  tearDown(() => database.close());

  Workout newWorkout({DateTime? startedAt}) {
    return Workout.create().copyWith(
      startedAt: startedAt ?? DateTime.now().toUtc(),
    );
  }

  WorkoutSet newSet({
    required String workoutId,
    String exerciseId = '1',
    int setOrder = 1,
    double weight = 100.0,
    int reps = 5,
  }) {
    return WorkoutSet.create(
      workoutId: workoutId,
      exerciseId: exerciseId,
      setOrder: setOrder,
      weight: weight,
      reps: reps,
    );
  }

  group('DriftWorkoutRepository', () {
    group('createWorkout & getWorkout', () {
      test('persists and retrieves a workout', () async {
        final workout = newWorkout();
        await repo.createWorkout(workout);

        final fetched = await repo.getWorkout(workout.id);
        expect(fetched, isNotNull);
        expect(fetched!.id, workout.id);
        expect(fetched.status, WorkoutStatus.inProgress);
      });

      test('returns null for non-existent id', () async {
        final fetched = await repo.getWorkout('non-existent');
        expect(fetched, isNull);
      });
    });

    group('getActiveWorkout', () {
      test('returns the in-progress workout', () async {
        final workout = newWorkout();
        await repo.createWorkout(workout);

        final active = await repo.getActiveWorkout();
        expect(active, isNotNull);
        expect(active!.id, workout.id);
      });

      test('returns null when no workout is active', () async {
        final active = await repo.getActiveWorkout();
        expect(active, isNull);
      });

      test('ignores completed workouts', () async {
        final workout = newWorkout();
        await repo.createWorkout(workout);
        final completed = workout.copyWith(completedAt: DateTime.now().toUtc());
        await repo.updateWorkout(completed);

        final active = await repo.getActiveWorkout();
        expect(active, isNull);
      });

      test('ignores soft-deleted workouts', () async {
        final workout = newWorkout();
        await repo.createWorkout(workout);
        await repo.deleteWorkout(workout.id);

        final active = await repo.getActiveWorkout();
        expect(active, isNull);
      });
    });

    group('getWorkoutHistory', () {
      test('returns completed workouts newest first', () async {
        final w1 = newWorkout(
          startedAt: DateTime.utc(2025, 1, 1),
        );
        final w2 = newWorkout(
          startedAt: DateTime.utc(2025, 1, 2),
        );
        await repo.createWorkout(w1);
        await repo.createWorkout(w2);

        // Complete both.
        await repo.updateWorkout(
          w1.copyWith(completedAt: DateTime.utc(2025, 1, 1, 1)),
        );
        await repo.updateWorkout(
          w2.copyWith(completedAt: DateTime.utc(2025, 1, 2, 1)),
        );

        final history = await repo.getWorkoutHistory();
        expect(history, hasLength(2));
        expect(history.first.id, w2.id); // newer first
      });

      test('respects limit parameter', () async {
        for (var i = 0; i < 5; i++) {
          final w = newWorkout(
            startedAt: DateTime.utc(2025, 1, i + 1),
          );
          await repo.createWorkout(w);
          await repo.updateWorkout(
            w.copyWith(completedAt: DateTime.utc(2025, 1, i + 1, 1)),
          );
        }

        final history = await repo.getWorkoutHistory(limit: 3);
        expect(history, hasLength(3));
      });

      test('respects before parameter', () async {
        final old = newWorkout(startedAt: DateTime.utc(2025, 1, 1));
        final recent = newWorkout(startedAt: DateTime.utc(2025, 6, 1));

        await repo.createWorkout(old);
        await repo.createWorkout(recent);
        await repo.updateWorkout(
          old.copyWith(completedAt: DateTime.utc(2025, 1, 1, 1)),
        );
        await repo.updateWorkout(
          recent.copyWith(completedAt: DateTime.utc(2025, 6, 1, 1)),
        );

        final history = await repo.getWorkoutHistory(
          before: DateTime.utc(2025, 3, 1),
        );
        expect(history, hasLength(1));
        expect(history.first.id, old.id);
      });

      test('excludes soft-deleted workouts', () async {
        final w = newWorkout();
        await repo.createWorkout(w);
        await repo.updateWorkout(
          w.copyWith(completedAt: DateTime.now().toUtc()),
        );
        await repo.deleteWorkout(w.id);

        final history = await repo.getWorkoutHistory();
        expect(history, isEmpty);
      });
    });

    group('updateWorkout', () {
      test('updates workout fields', () async {
        final workout = newWorkout();
        await repo.createWorkout(workout);

        final completed = workout.copyWith(completedAt: DateTime.now().toUtc());
        await repo.updateWorkout(completed);

        final fetched = await repo.getWorkout(workout.id);
        expect(fetched!.status, WorkoutStatus.completed);
        expect(fetched.completedAt, isNotNull);
      });
    });

    group('deleteWorkout', () {
      test('soft-deletes a workout', () async {
        final workout = newWorkout();
        await repo.createWorkout(workout);
        await repo.deleteWorkout(workout.id);

        final fetched = await repo.getWorkout(workout.id);
        expect(fetched, isNull);
      });
    });

    group('addSet & getSetsForWorkout', () {
      test('persists and retrieves sets ordered by setOrder', () async {
        final workout = newWorkout();
        await repo.createWorkout(workout);

        final s1 = newSet(workoutId: workout.id, setOrder: 2);
        final s2 = newSet(workoutId: workout.id, setOrder: 1);
        await repo.addSet(s1);
        await repo.addSet(s2);

        final sets = await repo.getSetsForWorkout(workout.id);
        expect(sets, hasLength(2));
        expect(sets.first.setOrder, 1);
        expect(sets.last.setOrder, 2);
      });
    });

    group('getSetsForExercise', () {
      test('returns sets for an exercise newest first', () async {
        final workout = newWorkout();
        await repo.createWorkout(workout);

        final s1 = newSet(workoutId: workout.id, setOrder: 1);
        final s2 = newSet(workoutId: workout.id, setOrder: 2);
        await repo.addSet(s1);
        await repo.addSet(s2);

        final sets = await repo.getSetsForExercise('1');
        expect(sets, hasLength(2));
        // Newest first (by timestamp).
        expect(
          sets.first.timestamp.isAfter(sets.last.timestamp) ||
              sets.first.timestamp.isAtSameMomentAs(sets.last.timestamp),
          isTrue,
        );
      });

      test('respects limit parameter', () async {
        final workout = newWorkout();
        await repo.createWorkout(workout);

        for (var i = 0; i < 5; i++) {
          await repo.addSet(newSet(workoutId: workout.id, setOrder: i));
        }

        final sets = await repo.getSetsForExercise('1', limit: 3);
        expect(sets, hasLength(3));
      });
    });

    group('getLastSetForExercise', () {
      test('returns the most recent set', () async {
        final workout = newWorkout();
        await repo.createWorkout(workout);

        final earlyTime = DateTime.utc(2025, 1, 1);
        final laterTime = DateTime.utc(2025, 6, 1);

        final s1 = WorkoutSet(
          id: 'set-1',
          workoutId: workout.id,
          exerciseId: '1',
          setOrder: 1,
          weight: 80,
          reps: 5,
          timestamp: earlyTime,
        );
        final s2 = WorkoutSet(
          id: 'set-2',
          workoutId: workout.id,
          exerciseId: '1',
          setOrder: 2,
          weight: 100,
          reps: 5,
          timestamp: laterTime,
        );
        await repo.addSet(s1);
        await repo.addSet(s2);

        final last = await repo.getLastSetForExercise('1');
        expect(last, isNotNull);
        expect(last!.weight, 100.0);
      });

      test('returns null when no sets exist', () async {
        final last = await repo.getLastSetForExercise('1');
        expect(last, isNull);
      });
    });

    group('deleteSet', () {
      test('hard-deletes a set', () async {
        final workout = newWorkout();
        await repo.createWorkout(workout);

        final set = newSet(workoutId: workout.id);
        await repo.addSet(set);
        await repo.deleteSet(set.id);

        final sets = await repo.getSetsForWorkout(workout.id);
        expect(sets, isEmpty);
      });
    });

    group('watchWorkoutHistory', () {
      test('emits when workouts change', () async {
        final emissions = <List<Workout>>[];
        final sub = repo.watchWorkoutHistory().listen(emissions.add);
        addTearDown(sub.cancel);

        await pumpEventQueue();
        expect(emissions, hasLength(1));
        expect(emissions.first, isEmpty);

        final workout = newWorkout();
        await repo.createWorkout(workout);
        await repo.updateWorkout(
          workout.copyWith(completedAt: DateTime.now().toUtc()),
        );
        await pumpEventQueue();

        expect(emissions.last, hasLength(1));
      });
    });

    group('watchSetsForWorkout', () {
      test('emits when sets change for a workout', () async {
        final workout = newWorkout();
        await repo.createWorkout(workout);

        final emissions = <List<WorkoutSet>>[];
        final sub = repo.watchSetsForWorkout(workout.id).listen(emissions.add);
        addTearDown(sub.cancel);

        await pumpEventQueue();
        expect(emissions.last, isEmpty);

        await repo.addSet(newSet(workoutId: workout.id));
        await pumpEventQueue();

        expect(emissions.last, hasLength(1));
      });
    });
  });
}
