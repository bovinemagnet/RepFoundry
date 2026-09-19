import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/features/clients/data/drift_client_repository.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/exercises/presentation/providers/exercise_sparkline_provider.dart';
import 'package:rep_foundry/features/workout/data/drift_workout_repository.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the sparkline follows the active client', () async {
    SharedPreferences.setMockInitialValues({});
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    container.listen(exerciseSparklineProvider('1'), (_, __) {});

    final workouts = DriftWorkoutRepository(database);
    final alice = await DriftClientRepository(database)
        .createClient(Client.create(name: 'Alice', colour: 0));
    final mine = await workouts.createWorkout(Workout.create());
    final hers =
        await workouts.createWorkout(Workout.create(clientId: alice.id));
    await workouts.addSet(WorkoutSet.create(
        workoutId: mine.id,
        exerciseId: '1',
        setOrder: 1,
        weight: 100,
        reps: 1));
    await workouts.addSet(WorkoutSet.create(
        workoutId: hers.id,
        exerciseId: '1',
        setOrder: 1,
        weight: 200,
        reps: 1));

    await container.read(activeClientProvider.future);
    container.invalidate(exerciseSparklineProvider('1'));
    expect(await container.read(exerciseSparklineProvider('1').future), [
      WorkoutSet.create(
              workoutId: mine.id,
              exerciseId: '1',
              setOrder: 1,
              weight: 100,
              reps: 1)
          .estimatedOneRepMax
    ]);

    await container.read(activeClientProvider.notifier).setActive(alice);
    await Future<void>.delayed(Duration.zero);
    expect(await container.read(exerciseSparklineProvider('1').future), [
      WorkoutSet.create(
              workoutId: hers.id,
              exerciseId: '1',
              setOrder: 1,
              weight: 200,
              reps: 1)
          .estimatedOneRepMax
    ]);
  });
}
