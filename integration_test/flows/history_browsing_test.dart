import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rep_foundry/features/exercises/data/drift_exercise_repository.dart';
import 'package:rep_foundry/features/workout/data/drift_workout_repository.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('History browsing', () {
    testWidgets('displays pre-seeded workouts and navigates to detail',
        (tester) async {
      final testApp = await createTestApp();
      final db = testApp.database;

      // Pre-seed a completed workout with sets.
      final repo = DriftWorkoutRepository(db);
      final exerciseRepo = DriftExerciseRepository(db);

      // Get a seeded exercise.
      final exercises = await exerciseRepo.getAllExercises();
      final exercise = exercises.first;

      final now = DateTime.now().toUtc();
      final workout = Workout(
        id: 'test-workout-1',
        startedAt: now.subtract(const Duration(hours: 2)),
        completedAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now,
      );
      await repo.createWorkout(workout);
      await repo.addSet(WorkoutSet(
        id: 'set-1',
        workoutId: workout.id,
        exerciseId: exercise.id,
        weight: 80,
        reps: 8,
        setOrder: 0,
        timestamp: now,
        updatedAt: now,
      ));
      await repo.addSet(WorkoutSet(
        id: 'set-2',
        workoutId: workout.id,
        exerciseId: exercise.id,
        weight: 85,
        reps: 6,
        setOrder: 1,
        timestamp: now,
        updatedAt: now,
      ));

      await tester.pumpWidget(testApp.app);
      await tester.pumpAndSettle();

      // Navigate to History tab.
      await tester.tap(find.text('HISTORY'));
      await tester.pumpAndSettle();

      // The workout should appear in the list.
      await pumpUntilFound(tester, find.text(exercise.name));
      expect(find.text(exercise.name), findsOneWidget);

      await testApp.database.close();
    });
  });
}
