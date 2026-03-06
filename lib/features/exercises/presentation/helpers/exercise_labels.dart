import '../../domain/models/exercise.dart';

String labelForCategory(ExerciseCategory category) {
  switch (category) {
    case ExerciseCategory.strength:
      return 'Strength';
    case ExerciseCategory.cardio:
      return 'Cardio';
    case ExerciseCategory.flexibility:
      return 'Flexibility';
    case ExerciseCategory.custom:
      return 'Custom';
  }
}

String labelForMuscleGroup(MuscleGroup group) {
  switch (group) {
    case MuscleGroup.chest:
      return 'Chest';
    case MuscleGroup.back:
      return 'Back';
    case MuscleGroup.shoulders:
      return 'Shoulders';
    case MuscleGroup.biceps:
      return 'Biceps';
    case MuscleGroup.triceps:
      return 'Triceps';
    case MuscleGroup.forearms:
      return 'Forearms';
    case MuscleGroup.core:
      return 'Core';
    case MuscleGroup.quadriceps:
      return 'Quadriceps';
    case MuscleGroup.hamstrings:
      return 'Hamstrings';
    case MuscleGroup.glutes:
      return 'Glutes';
    case MuscleGroup.calves:
      return 'Calves';
    case MuscleGroup.fullBody:
      return 'Full Body';
    case MuscleGroup.cardio:
      return 'Cardio';
  }
}

String labelForEquipment(EquipmentType type) {
  switch (type) {
    case EquipmentType.barbell:
      return 'Barbell';
    case EquipmentType.dumbbell:
      return 'Dumbbell';
    case EquipmentType.machine:
      return 'Machine';
    case EquipmentType.cable:
      return 'Cable';
    case EquipmentType.bodyweight:
      return 'Bodyweight';
    case EquipmentType.kettlebell:
      return 'Kettlebell';
    case EquipmentType.resistanceBand:
      return 'Resistance Band';
    case EquipmentType.cardioMachine:
      return 'Cardio Machine';
    case EquipmentType.other:
      return 'Other';
  }
}
