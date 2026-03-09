import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

void main() {
  group('Superset linking', () {
    test('linkSupersetSets assigns same groupId to two exercises', () {
      final set1 = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 1,
        weight: 100,
        reps: 10,
      );
      final set2 = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e2',
        setOrder: 1,
        weight: 50,
        reps: 12,
      );

      final setsByExercise = {
        'e1': [set1],
        'e2': [set2],
      };
      final updatedSets = linkSupersetSets(setsByExercise, 'e1', 'e2');

      expect(updatedSets['e1']!.first.groupId, isNotNull);
      expect(updatedSets['e2']!.first.groupId, isNotNull);
      expect(
        updatedSets['e1']!.first.groupId,
        equals(updatedSets['e2']!.first.groupId),
      );
    });

    test('unlinkSupersetSets clears groupId from all sets in group', () {
      const sharedGroupId = 'group-123';
      final set1 = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 1,
        weight: 100,
        reps: 10,
        groupId: sharedGroupId,
      );
      final set2 = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e2',
        setOrder: 1,
        weight: 50,
        reps: 12,
        groupId: sharedGroupId,
      );

      final setsByExercise = {
        'e1': [set1],
        'e2': [set2],
      };
      final updatedSets = unlinkSupersetSets(setsByExercise, 'e1');

      expect(updatedSets['e1']!.first.groupId, isNull);
      expect(updatedSets['e2']!.first.groupId, isNull);
    });

    test('getSupersetGroups returns grouped exercise IDs', () {
      const groupA = 'group-a';
      final set1 = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: 1,
        weight: 100,
        reps: 10,
        groupId: groupA,
      );
      final set2 = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e2',
        setOrder: 1,
        weight: 50,
        reps: 12,
        groupId: groupA,
      );
      final set3 = WorkoutSet.create(
        workoutId: 'w1',
        exerciseId: 'e3',
        setOrder: 1,
        weight: 60,
        reps: 8,
      );

      final setsByExercise = {
        'e1': [set1],
        'e2': [set2],
        'e3': [set3],
      };
      final groups = getSupersetGroups(setsByExercise);

      expect(groups, hasLength(1));
      expect(groups[groupA], containsAll(['e1', 'e2']));
    });
  });
}
