import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/presentation/providers/trained_exercises_provider.dart';

void main() {
  test('TrainedExercise holds exercise and set count', () {
    final exercise = Exercise(
      id: '1',
      name: 'Bench Press',
      category: ExerciseCategory.strength,
      muscleGroup: MuscleGroup.chest,
      equipmentType: EquipmentType.barbell,
      updatedAt: DateTime.utc(2024),
    );
    final trained = TrainedExercise(exercise: exercise, setCount: 42);
    expect(trained.exercise.name, 'Bench Press');
    expect(trained.setCount, 42);
  });

  test('sorting by set count descending works', () {
    final ex1 = Exercise(
      id: '1',
      name: 'A',
      category: ExerciseCategory.strength,
      muscleGroup: MuscleGroup.chest,
      equipmentType: EquipmentType.barbell,
      updatedAt: DateTime.utc(2024),
    );
    final ex2 = Exercise(
      id: '2',
      name: 'B',
      category: ExerciseCategory.strength,
      muscleGroup: MuscleGroup.back,
      equipmentType: EquipmentType.barbell,
      updatedAt: DateTime.utc(2024),
    );
    final list = [
      TrainedExercise(exercise: ex1, setCount: 10),
      TrainedExercise(exercise: ex2, setCount: 50),
    ];
    list.sort((a, b) => b.setCount.compareTo(a.setCount));
    expect(list.first.exercise.name, 'B');
  });
}
