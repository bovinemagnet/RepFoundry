import 'package:flutter/material.dart';
import '../../domain/models/exercise.dart';

class ExerciseListTile extends StatelessWidget {
  const ExerciseListTile({
    super.key,
    required this.exercise,
    this.onTap,
    this.trailing,
  });

  final Exercise exercise;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _iconForCategory(exercise.category),
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(exercise.name),
      subtitle: Text(
        '${_labelForMuscleGroup(exercise.muscleGroup)}  •  ${_labelForEquipment(exercise.equipmentType)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  IconData _iconForCategory(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.strength:
        return Icons.fitness_center;
      case ExerciseCategory.cardio:
        return Icons.directions_run;
      case ExerciseCategory.flexibility:
        return Icons.self_improvement;
      case ExerciseCategory.custom:
        return Icons.star;
    }
  }

  String _labelForMuscleGroup(MuscleGroup group) {
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

  String _labelForEquipment(EquipmentType type) {
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
}
