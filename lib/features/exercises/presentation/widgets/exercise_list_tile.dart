import 'package:flutter/material.dart';
import '../../domain/models/exercise.dart';
import '../helpers/exercise_labels.dart';

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
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _iconForCategory(exercise.category),
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(exercise.name),
      subtitle: Text(
        '${labelForMuscleGroup(exercise.muscleGroup)}  •  ${labelForEquipment(exercise.equipmentType)}',
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
}
