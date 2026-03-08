import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/features/history/presentation/providers/workout_duration_chart_provider.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/core/providers.dart';

void main() {
  group('workoutDurationChartProvider', () {
    test('returns empty list when no workouts', () async {
      final repo = InMemoryWorkoutRepository();
      final container = ProviderContainer(
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final data = await container.read(workoutDurationChartProvider.future);
      expect(data, isEmpty);
    });

    test('returns duration in minutes for completed workouts', () async {
      final repo = InMemoryWorkoutRepository();

      final start = DateTime.utc(2026, 1, 10, 10, 0);
      final end = DateTime.utc(2026, 1, 10, 11, 30); // 90 minutes

      final workout = Workout(
        id: 'w1',
        startedAt: start,
        completedAt: end,
      );
      await repo.createWorkout(workout);

      final container = ProviderContainer(
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final data = await container.read(workoutDurationChartProvider.future);
      expect(data.length, 1);
      expect(data.first.value, 90.0);
    });

    test('returns points in chronological order', () async {
      final repo = InMemoryWorkoutRepository();

      // Newer workout first (getWorkoutHistory returns newest first).
      final w1 = Workout(
        id: 'w1',
        startedAt: DateTime.utc(2026, 1, 12, 10, 0),
        completedAt: DateTime.utc(2026, 1, 12, 11, 0), // 60 mins
      );
      final w2 = Workout(
        id: 'w2',
        startedAt: DateTime.utc(2026, 1, 10, 10, 0),
        completedAt: DateTime.utc(2026, 1, 10, 10, 45), // 45 mins
      );
      await repo.createWorkout(w1);
      await repo.createWorkout(w2);

      final container = ProviderContainer(
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final data = await container.read(workoutDurationChartProvider.future);
      expect(data.length, 2);
      // Chronological: oldest first.
      expect(data.first.value, 45.0);
      expect(data.last.value, 60.0);
    });
  });
}
