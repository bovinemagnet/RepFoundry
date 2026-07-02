import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/workout/data/drift_workout_repository.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  group('clearAllData', () {
    test('removes all user data and re-seeds default exercises', () async {
      final repo = DriftWorkoutRepository(database);
      final workout = await repo.createWorkout(Workout.create());
      final seeded = await database.select(database.exercises).get();
      await repo.addSet(WorkoutSet.create(
        workoutId: workout.id,
        exerciseId: seeded.first.id,
        setOrder: 1,
        weight: 100,
        reps: 5,
      ));

      expect(await database.select(database.workouts).get(), isNotEmpty);
      expect(await database.select(database.workoutSets).get(), isNotEmpty);
      expect(seeded, isNotEmpty);

      await database.clearAllData();

      expect(await database.select(database.workouts).get(), isEmpty);
      expect(await database.select(database.workoutSets).get(), isEmpty);

      final reseeded = await database.select(database.exercises).get();
      expect(reseeded.length, seeded.length);
    });
  });
}
