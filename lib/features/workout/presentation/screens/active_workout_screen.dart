import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/active_workout_controller.dart';
import '../models/ghost_set.dart';
import '../widgets/set_input_card.dart';
import '../widgets/rest_timer_widget.dart';
import '../../domain/models/workout_set.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/widgets/loading_widget.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutControllerProvider);
    final controller = ref.read(activeWorkoutControllerProvider.notifier);

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        controller.clearError();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: state.hasActiveWorkout
            ? Text(
                'Workout  •  ${state.activeWorkout!.startedAt.timeOfDay}',
              )
            : const Text('Workout'),
        actions: [
          if (state.hasActiveWorkout)
            TextButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => _confirmFinish(context, controller),
              icon: const Icon(Icons.check),
              label: const Text('Finish'),
            ),
        ],
      ),
      body: state.isLoading
          ? const LoadingWidget(message: 'Loading workout…')
          : state.hasActiveWorkout
              ? _buildActiveWorkout(context, ref, state, controller)
              : _buildNoWorkout(context, controller),
      floatingActionButton: state.hasActiveWorkout
          ? FloatingActionButton.extended(
              onPressed: () => _pickExercise(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
            )
          : null,
    );
  }

  Widget _buildNoWorkout(
    BuildContext context,
    ActiveWorkoutController controller,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'No active workout',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new workout to begin logging sets.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: controller.startWorkout,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Workout'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWorkout(
    BuildContext context,
    WidgetRef ref,
    ActiveWorkoutState state,
    ActiveWorkoutController controller,
  ) {
    if (state.exercises.isEmpty) {
      return Column(
        children: [
          const RestTimerWidget(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add exercises using the button below',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        const RestTimerWidget(),
        for (final exercise in state.exercises)
          _ExerciseSection(
            exercise: exercise,
            sets: state.setsByExercise[exercise.id] ?? [],
            ghostSets: state.remainingGhosts(exercise.id),
            suggestion: state.nextGhostSet(exercise.id),
            onLogSet: ({
              required double weight,
              required int reps,
              double? rpe,
            }) {
              controller.logSet(
                exerciseId: exercise.id,
                weight: weight,
                reps: reps,
                rpe: rpe,
              );
            },
            onDeleteSet: (setId) => controller.deleteSet(setId, exercise.id),
          ),
      ],
    );
  }

  Future<void> _pickExercise(BuildContext context, WidgetRef ref) async {
    final exercise = await context.push<Exercise>('/exercises');
    if (exercise != null) {
      ref.read(activeWorkoutControllerProvider.notifier).addExercise(exercise);
    }
  }

  Future<void> _confirmFinish(
    BuildContext context,
    ActiveWorkoutController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Workout?'),
        content: const Text('This will save your workout and end the session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.finishWorkout();
    }
  }
}

class _ExerciseSection extends StatelessWidget {
  const _ExerciseSection({
    required this.exercise,
    required this.sets,
    required this.ghostSets,
    required this.suggestion,
    required this.onLogSet,
    required this.onDeleteSet,
  });

  final Exercise exercise;
  final List<WorkoutSet> sets;
  final List<GhostSet> ghostSets;
  final GhostSet? suggestion;
  final void Function({
    required double weight,
    required int reps,
    double? rpe,
  }) onLogSet;
  final void Function(String setId) onDeleteSet;

  @override
  Widget build(BuildContext context) {
    final hasTableContent = sets.isNotEmpty || ghostSets.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text(
                    exercise.muscleGroup.name,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasTableContent) ...[
              _SetTableHeader(context),
              const Divider(height: 8),
              for (int i = 0; i < sets.length; i++)
                _SetRow(
                  index: i,
                  set: sets[i],
                  onDelete: () => onDeleteSet(sets[i].id),
                ),
              for (int i = 0; i < ghostSets.length; i++)
                _GhostSetRow(
                  index: sets.length + i,
                  ghost: ghostSets[i],
                ),
              const SizedBox(height: 8),
            ],
            SetInputCard(onLogSet: onLogSet, suggestion: suggestion),
          ],
        ),
      ),
    );
  }

  Widget _SetTableHeader(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 32),
        Expanded(
          child: Text(
            'Weight',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            'Reps',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            'e1RM',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.onDelete,
  });

  final int index;
  final WorkoutSet set;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${set.weight} kg',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              '${set.reps}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              set.estimatedOneRepMax.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          SizedBox(
            width: 36,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Theme.of(context).colorScheme.error,
              onPressed: onDelete,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostSetRow extends StatelessWidget {
  const _GhostSetRow({
    required this.index,
    required this.ghost,
  });

  final int index;
  final GhostSet ghost;

  @override
  Widget build(BuildContext context) {
    final dimStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          fontStyle: FontStyle.italic,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.4),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${ghost.weight} kg',
              textAlign: TextAlign.center,
              style: dimStyle,
            ),
          ),
          Expanded(
            child: Text(
              '${ghost.reps}',
              textAlign: TextAlign.center,
              style: dimStyle,
            ),
          ),
          // No e1RM column for ghost rows.
          const Expanded(child: SizedBox.shrink()),
          // No delete button for ghost rows.
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
