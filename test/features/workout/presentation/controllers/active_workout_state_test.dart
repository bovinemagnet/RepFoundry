import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';
import 'package:rep_foundry/features/workout/presentation/models/ghost_set.dart';

void main() {
  group('ActiveWorkoutState ghost helpers', () {
    final ghosts = [
      const GhostSet(weight: 80, reps: 5, setOrder: 1),
      const GhostSet(weight: 85, reps: 5, setOrder: 2),
      const GhostSet(weight: 90, reps: 3, rpe: 8.5, setOrder: 3),
    ];

    WorkoutSet makeSet(int setOrder) {
      return WorkoutSet(
        id: 'set-$setOrder',
        workoutId: 'w1',
        exerciseId: 'e1',
        setOrder: setOrder,
        weight: 80,
        reps: 5,
        timestamp: DateTime.now().toUtc(),
      );
    }

    test('nextGhostSet returns first ghost when no sets logged', () {
      final state = ActiveWorkoutState(
        ghostSetsByExercise: {'e1': ghosts},
        setsByExercise: {'e1': []},
      );

      expect(state.nextGhostSet('e1'), ghosts[0]);
    });

    test('nextGhostSet advances as sets are logged', () {
      final state = ActiveWorkoutState(
        ghostSetsByExercise: {'e1': ghosts},
        setsByExercise: {
          'e1': [makeSet(1)],
        },
      );

      expect(state.nextGhostSet('e1'), ghosts[1]);
    });

    test('nextGhostSet returns null when all ghosts consumed', () {
      final state = ActiveWorkoutState(
        ghostSetsByExercise: {'e1': ghosts},
        setsByExercise: {
          'e1': [makeSet(1), makeSet(2), makeSet(3)],
        },
      );

      expect(state.nextGhostSet('e1'), isNull);
    });

    test('nextGhostSet returns null when more sets than ghosts', () {
      final state = ActiveWorkoutState(
        ghostSetsByExercise: {'e1': ghosts},
        setsByExercise: {
          'e1': [makeSet(1), makeSet(2), makeSet(3), makeSet(4)],
        },
      );

      expect(state.nextGhostSet('e1'), isNull);
    });

    test('nextGhostSet returns null for exercise with no ghosts', () {
      final state = ActiveWorkoutState(
        ghostSetsByExercise: const {},
        setsByExercise: {'e1': []},
      );

      expect(state.nextGhostSet('e1'), isNull);
    });

    test('remainingGhosts returns all ghosts when no sets logged', () {
      final state = ActiveWorkoutState(
        ghostSetsByExercise: {'e1': ghosts},
        setsByExercise: {'e1': []},
      );

      expect(state.remainingGhosts('e1'), ghosts);
    });

    test('remainingGhosts shrinks as sets are logged', () {
      final state = ActiveWorkoutState(
        ghostSetsByExercise: {'e1': ghosts},
        setsByExercise: {
          'e1': [makeSet(1)],
        },
      );

      expect(state.remainingGhosts('e1'), hasLength(2));
      expect(state.remainingGhosts('e1').first, ghosts[1]);
    });

    test('remainingGhosts returns empty when all consumed', () {
      final state = ActiveWorkoutState(
        ghostSetsByExercise: {'e1': ghosts},
        setsByExercise: {
          'e1': [makeSet(1), makeSet(2), makeSet(3)],
        },
      );

      expect(state.remainingGhosts('e1'), isEmpty);
    });

    test('remainingGhosts returns empty for exercise with no ghosts', () {
      final state = ActiveWorkoutState(
        ghostSetsByExercise: const {},
        setsByExercise: {'e1': []},
      );

      expect(state.remainingGhosts('e1'), isEmpty);
    });

    test('remainingGhosts recalculates when set is deleted', () {
      // Simulate: 3 ghosts, 2 sets logged, then one deleted → back to 1 set.
      final stateWith2Sets = ActiveWorkoutState(
        ghostSetsByExercise: {'e1': ghosts},
        setsByExercise: {
          'e1': [makeSet(1), makeSet(2)],
        },
      );
      expect(stateWith2Sets.remainingGhosts('e1'), hasLength(1));

      // After deleting set 2.
      final stateWith1Set = ActiveWorkoutState(
        ghostSetsByExercise: {'e1': ghosts},
        setsByExercise: {
          'e1': [makeSet(1)],
        },
      );
      expect(stateWith1Set.remainingGhosts('e1'), hasLength(2));
    });

    test('copyWith preserves ghostSetsByExercise', () {
      final state = ActiveWorkoutState(
        ghostSetsByExercise: {'e1': ghosts},
      );
      final copied = state.copyWith(isLoading: true);

      expect(copied.ghostSetsByExercise, {'e1': ghosts});
      expect(copied.isLoading, isTrue);
    });
  });
}
