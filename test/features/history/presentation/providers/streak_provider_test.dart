import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/history/presentation/providers/streak_provider.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/core/providers.dart';

void main() {
  group('StreakData', () {
    test('calculates zero streak when no workouts', () async {
      final repo = InMemoryWorkoutRepository();
      final container = ProviderContainer(
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final data = await container.read(streakProvider.future);
      expect(data.currentStreak, 0);
      expect(data.longestStreak, 0);
    });

    test('calculates current streak of consecutive days', () async {
      final repo = InMemoryWorkoutRepository();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Create workouts on today, yesterday, and day before.
      for (var i = 0; i < 3; i++) {
        final date = today.subtract(Duration(days: i));
        final workout = Workout(
          id: 'w$i',
          startedAt: date.toUtc(),
          completedAt: date.add(const Duration(hours: 1)).toUtc(),
        );
        await repo.createWorkout(workout);
      }

      final container = ProviderContainer(
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final data = await container.read(streakProvider.future);
      expect(data.currentStreak, 3);
      expect(data.longestStreak, 3);
    });

    test('current streak breaks on gap day', () async {
      final repo = InMemoryWorkoutRepository();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Today, yesterday, then skip a day, then 3 more days.
      final dates = [
        today,
        today.subtract(const Duration(days: 1)),
        // gap on day 2
        today.subtract(const Duration(days: 3)),
        today.subtract(const Duration(days: 4)),
        today.subtract(const Duration(days: 5)),
      ];

      for (var i = 0; i < dates.length; i++) {
        final date = dates[i];
        final workout = Workout(
          id: 'w$i',
          startedAt: date.toUtc(),
          completedAt: date.add(const Duration(hours: 1)).toUtc(),
        );
        await repo.createWorkout(workout);
      }

      final container = ProviderContainer(
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final data = await container.read(streakProvider.future);
      expect(data.currentStreak, 2);
      expect(data.longestStreak, 3);
    });

    test('current streak includes yesterday even if no workout today', () async {
      final repo = InMemoryWorkoutRepository();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Yesterday and day before — but not today.
      for (var i = 1; i <= 2; i++) {
        final date = today.subtract(Duration(days: i));
        final workout = Workout(
          id: 'w$i',
          startedAt: date.toUtc(),
          completedAt: date.add(const Duration(hours: 1)).toUtc(),
        );
        await repo.createWorkout(workout);
      }

      final container = ProviderContainer(
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final data = await container.read(streakProvider.future);
      expect(data.currentStreak, 2);
    });
  });
}
