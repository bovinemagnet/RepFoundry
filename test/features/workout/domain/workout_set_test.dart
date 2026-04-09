import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

void main() {
  group('WorkoutSet', () {
    // Shared fixture used across tests that need a fully-constructed set.
    WorkoutSet makeSet({
      String id = 'set-id-1',
      String workoutId = 'workout-id-1',
      String exerciseId = 'exercise-id-1',
      int setOrder = 1,
      double weight = 100.0,
      int reps = 10,
      double? rpe,
      bool isWarmUp = false,
      String? groupId,
    }) {
      final now = DateTime.utc(2024, 1, 1, 12);
      return WorkoutSet(
        id: id,
        workoutId: workoutId,
        exerciseId: exerciseId,
        setOrder: setOrder,
        weight: weight,
        reps: reps,
        rpe: rpe,
        timestamp: now,
        isWarmUp: isWarmUp,
        groupId: groupId,
        updatedAt: now,
      );
    }

    // -------------------------------------------------------------------------
    // volume
    // -------------------------------------------------------------------------

    test('volume returns weight multiplied by reps', () {
      final set = makeSet(weight: 80.0, reps: 5);
      expect(set.volume, equals(400.0));
    });

    // -------------------------------------------------------------------------
    // estimatedOneRepMax
    // -------------------------------------------------------------------------

    test('estimatedOneRepMax_multipleReps_returnsEpleyFormula', () {
      // Epley: weight * (1 + reps / 30.0) = 100 * (1 + 10 / 30) = 133.333...
      final set = makeSet(weight: 100.0, reps: 10);
      expect(set.estimatedOneRepMax, closeTo(133.33, 0.01));
    });

    test('estimatedOneRepMax_singleRep_returnsWeightExactly', () {
      final set = makeSet(weight: 142.5, reps: 1);
      expect(set.estimatedOneRepMax, equals(142.5));
    });

    // -------------------------------------------------------------------------
    // create()
    // -------------------------------------------------------------------------

    test('create_generatesNonEmptyUuidAndUtcTimestamps', () {
      final set = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 1,
        weight: 60.0,
        reps: 8,
      );

      expect(set.id, isNotEmpty);
      // UUID v4 is 36 characters including hyphens.
      expect(set.id.length, equals(36));
      expect(set.timestamp.isUtc, isTrue);
      expect(set.updatedAt.isUtc, isTrue);
    });

    test('create_calledTwice_producesDifferentIds', () {
      final first = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 1,
        weight: 60.0,
        reps: 8,
      );
      final second = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 2,
        weight: 60.0,
        reps: 8,
      );

      expect(first.id, isNot(equals(second.id)));
    });

    // -------------------------------------------------------------------------
    // copyWith
    // -------------------------------------------------------------------------

    test('copyWith_changesWeight_preservesId', () {
      final original = makeSet(weight: 100.0);
      final updated = original.copyWith(weight: 120.0);

      expect(updated.weight, equals(120.0));
      expect(updated.id, equals(original.id));
    });

    test('copyWith_clearGroupIdTrue_nullifiesGroupId', () {
      final original = makeSet(groupId: 'group-abc');
      final updated = original.copyWith(clearGroupId: true);

      expect(updated.groupId, isNull);
    });

    test('copyWith_clearGroupIdFalse_preservesGroupId', () {
      final original = makeSet(groupId: 'group-abc');
      // clearGroupId defaults to false, so groupId must be retained.
      final updated = original.copyWith(weight: 90.0);

      expect(updated.groupId, equals('group-abc'));
    });

    // -------------------------------------------------------------------------
    // Equality
    // -------------------------------------------------------------------------

    test('equality_sameIdDifferentWeight_areEqual', () {
      final a = makeSet(id: 'shared-id', weight: 100.0);
      final b = makeSet(id: 'shared-id', weight: 200.0);

      expect(a, equals(b));
    });

    test('equality_differentIds_areNotEqual', () {
      final a = makeSet(id: 'id-alpha');
      final b = makeSet(id: 'id-beta');

      expect(a, isNot(equals(b)));
    });

    // -------------------------------------------------------------------------
    // hashCode
    // -------------------------------------------------------------------------

    test('hashCode_isBasedOnId', () {
      final a = makeSet(id: 'consistent-id', weight: 50.0);
      final b = makeSet(id: 'consistent-id', weight: 99.0);

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
