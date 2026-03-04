import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';

void main() {
  group('Workout', () {
    test('create() produces a workout with inProgress status', () {
      final workout = Workout.create();
      expect(workout.status, WorkoutStatus.inProgress);
      expect(workout.completedAt, isNull);
      expect(workout.isDeleted, isFalse);
    });

    test('status is completed when completedAt is set', () {
      final now = DateTime.now().toUtc();
      final workout = Workout(
        id: 'test-id',
        startedAt: now.subtract(const Duration(hours: 1)),
        completedAt: now,
      );
      expect(workout.status, WorkoutStatus.completed);
    });

    test('isDeleted returns true when deletedAt is set', () {
      final workout = Workout(
        id: 'test-id',
        startedAt: DateTime.now().toUtc(),
        deletedAt: DateTime.now().toUtc(),
      );
      expect(workout.isDeleted, isTrue);
    });

    test('copyWith overrides specified fields only', () {
      final original = Workout.create();
      final completed = original.copyWith(
        completedAt: DateTime.now().toUtc(),
      );
      expect(completed.id, original.id);
      expect(completed.startedAt, original.startedAt);
      expect(completed.completedAt, isNotNull);
      expect(completed.status, WorkoutStatus.completed);
    });

    test('equality is based on id', () {
      final a = Workout(id: 'same', startedAt: DateTime.now().toUtc());
      final b = Workout(id: 'same', startedAt: DateTime.now().toUtc());
      final c = Workout(id: 'other', startedAt: DateTime.now().toUtc());
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('elapsed returns duration between start and completion', () {
      final start = DateTime(2024, 1, 1, 9, 0);
      final end = DateTime(2024, 1, 1, 10, 30);
      final workout = Workout(
        id: 'id',
        startedAt: start,
        completedAt: end,
      );
      expect(workout.elapsed.inMinutes, 90);
    });
  });
}
