import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/analytics/application/training_aggregates.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

Exercise _exercise(String name, MuscleGroup group) => Exercise.create(
      name: name,
      category: group == MuscleGroup.cardio
          ? ExerciseCategory.cardio
          : ExerciseCategory.strength,
      muscleGroup: group,
      equipmentType: EquipmentType.barbell,
    );

WorkoutSet _set(Exercise e, double weight, int reps, {bool warmUp = false}) =>
    WorkoutSet.create(
      workoutId: 'w1',
      exerciseId: e.id,
      setOrder: 1,
      weight: weight,
      reps: reps,
      isWarmUp: warmUp,
    );

void main() {
  final bench = _exercise('Bench', MuscleGroup.chest);
  final squat = _exercise('Squat', MuscleGroup.quadriceps);
  final row = _exercise('Rower', MuscleGroup.cardio);
  final byId = {for (final e in [bench, squat, row]) e.id: e};

  group('computeMuscleBalance', () {
    test('returns an empty list for no sets', () {
      expect(computeMuscleBalance(const [], byId), isEmpty);
    });

    test('skips warm-up sets', () {
      final result = computeMuscleBalance([
        _set(bench, 100, 1),
        _set(squat, 100, 1, warmUp: true),
      ], byId);
      expect(result.map((m) => m.group), [MuscleGroup.chest]);
      expect(result.single.volumePercent, 100);
    });

    test('skips sets whose exercise is unknown', () {
      final ghost = _exercise('Ghost', MuscleGroup.back);
      final result = computeMuscleBalance([
        _set(bench, 100, 1),
        _set(ghost, 100, 1),
      ], byId);
      expect(result.map((m) => m.group), [MuscleGroup.chest]);
      expect(result.single.volumePercent, 100);
    });

    test('omits cardio from the output but counts it in the total', () {
      final result = computeMuscleBalance([
        _set(bench, 100, 1),
        _set(row, 100, 1),
      ], byId);
      expect(result.map((m) => m.group), [MuscleGroup.chest]);
      expect(result.single.volumePercent, 50);
    });

    test('orders groups by muscle group index', () {
      final result = computeMuscleBalance([
        _set(squat, 100, 3),
        _set(bench, 100, 1),
      ], byId);
      expect(result.map((m) => m.group),
          [MuscleGroup.chest, MuscleGroup.quadriceps]);
      expect(result.map((m) => m.volumePercent), [25, 75]);
    });
  });
}
