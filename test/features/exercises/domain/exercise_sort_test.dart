import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/exercises/domain/exercise_sort.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';

Exercise _exercise(String id, String name) => Exercise(
      id: id,
      name: name,
      category: ExerciseCategory.strength,
      muscleGroup: MuscleGroup.chest,
      equipmentType: EquipmentType.barbell,
      updatedAt: DateTime.utc(2026),
    );

void main() {
  final bench = _exercise('bench', 'Bench Press');
  final curl = _exercise('curl', 'Curl');
  final deadlift = _exercise('deadlift', 'Deadlift');
  final squat = _exercise('squat', 'Squat');
  final all = [bench, curl, deadlift, squat];

  List<String> names(List<Exercise> list) => list.map((e) => e.name).toList();

  group('sortExercisesForPicker', () {
    test('mostUsed puts the most used first, then ties and unused A–Z', () {
      final sorted = sortExercisesForPicker(
        all,
        order: ExerciseSortOrder.mostUsed,
        usageCounts: {'squat': 5, 'deadlift': 2, 'curl': 2},
      );

      expect(names(sorted), ['Squat', 'Curl', 'Deadlift', 'Bench Press']);
    });

    test('alphabetical ignores usage', () {
      final sorted = sortExercisesForPicker(
        [squat, deadlift, curl, bench],
        order: ExerciseSortOrder.alphabetical,
        usageCounts: {'squat': 5, 'deadlift': 2},
      );

      expect(names(sorted), ['Bench Press', 'Curl', 'Deadlift', 'Squat']);
    });

    test('mostUsed moves exercises already in the session to the bottom', () {
      final sorted = sortExercisesForPicker(
        all,
        order: ExerciseSortOrder.mostUsed,
        usageCounts: {'squat': 5, 'deadlift': 2, 'curl': 1},
        sessionExerciseIds: {'squat', 'curl'},
      );

      expect(names(sorted), ['Deadlift', 'Bench Press', 'Squat', 'Curl']);
    });

    test('alphabetical also moves session exercises to the bottom', () {
      final sorted = sortExercisesForPicker(
        all,
        order: ExerciseSortOrder.alphabetical,
        sessionExerciseIds: {'bench'},
      );

      expect(names(sorted), ['Curl', 'Deadlift', 'Squat', 'Bench Press']);
    });

    test('does not modify the input list', () {
      final input = [squat, bench];

      sortExercisesForPicker(input, order: ExerciseSortOrder.alphabetical);

      expect(names(input), ['Squat', 'Bench Press']);
    });
  });
}
