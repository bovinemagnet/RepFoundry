import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/show_exercise_images_provider.dart';
import '../../domain/models/exercise.dart';
import '../helpers/exercise_labels.dart';

class ExerciseListTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final showImages = ref.watch(showExerciseImagesProvider);
    final hasImage = showImages && exercise.imageAsset != null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundImage:
            hasImage ? AssetImage(exercise.imageAsset!) : null,
        child: hasImage
            ? null
            : Icon(
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
