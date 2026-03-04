import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';

void main() {
  group('Exercise', () {
    const exercise = Exercise(
      id: 'test-id',
      name: 'Bench Press',
      category: ExerciseCategory.strength,
      muscleGroup: MuscleGroup.chest,
      equipmentType: EquipmentType.barbell,
    );

    test('isDeleted is false by default', () {
      expect(exercise.isDeleted, isFalse);
    });

    test('isDeleted is true when deletedAt is set', () {
      final deleted = exercise.copyWith(
        deletedAt: DateTime.now().toUtc(),
      );
      expect(deleted.isDeleted, isTrue);
    });

    test('create() sets isCustom to false by default', () {
      final e = Exercise.create(
        name: 'Push-up',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.bodyweight,
      );
      expect(e.isCustom, isFalse);
    });

    test('create() with isCustom=true marks exercise as custom', () {
      final e = Exercise.create(
        name: 'My Move',
        category: ExerciseCategory.custom,
        muscleGroup: MuscleGroup.fullBody,
        equipmentType: EquipmentType.other,
        isCustom: true,
      );
      expect(e.isCustom, isTrue);
    });

    test('equality is based on id', () {
      const a = Exercise(
        id: 'same',
        name: 'A',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
      );
      const b = Exercise(
        id: 'same',
        name: 'B',
        category: ExerciseCategory.cardio,
        muscleGroup: MuscleGroup.cardio,
        equipmentType: EquipmentType.cardioMachine,
      );
      const c = Exercise(
        id: 'different',
        name: 'A',
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('copyWith preserves unchanged fields', () {
      final updated = exercise.copyWith(name: 'Updated Name');
      expect(updated.id, exercise.id);
      expect(updated.name, 'Updated Name');
      expect(updated.category, exercise.category);
      expect(updated.muscleGroup, exercise.muscleGroup);
      expect(updated.equipmentType, exercise.equipmentType);
    });
  });
}
