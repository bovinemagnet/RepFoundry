import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../controllers/active_workout_controller.dart';
import '../models/ghost_set.dart';
import '../widgets/pr_celebration_overlay.dart';
import '../widgets/set_input_card.dart';
import '../widgets/rest_timer_widget.dart';
import '../../domain/models/workout_set.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../templates/domain/models/workout_template.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/loading_widget.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final state = ref.watch(activeWorkoutControllerProvider);
    final controller = ref.read(activeWorkoutControllerProvider.notifier);

    ref.listen<ActiveWorkoutState>(
      activeWorkoutControllerProvider,
      (previous, next) {
        if (previous?.latestPR == null && next.latestPR != null) {
          _showPRCelebration(context, ref, next);
        }
      },
    );

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
                '${s.workoutTitle}  •  ${state.activeWorkout!.startedAt.timeOfDay}',
              )
            : Text(s.workoutTitle),
        actions: [
          if (state.hasActiveWorkout)
            TextButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => _confirmFinish(context, controller),
              icon: const Icon(Icons.check),
              label: Text(s.finish),
            ),
        ],
      ),
      body: state.isLoading
          ? LoadingWidget(message: s.loadingWorkout)
          : state.hasActiveWorkout
              ? _buildActiveWorkout(context, ref, state, controller)
              : _buildNoWorkout(context, ref, controller),
      floatingActionButton: state.hasActiveWorkout
          ? FloatingActionButton.extended(
              onPressed: () => _pickExercise(context, ref),
              icon: const Icon(Icons.add),
              label: Text(s.addExercise),
            )
          : null,
    );
  }

  Widget _buildNoWorkout(
    BuildContext context,
    WidgetRef ref,
    ActiveWorkoutController controller,
  ) {
    final s = S.of(context)!;
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
            s.noActiveWorkout,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            s.noActiveWorkoutSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: controller.startWorkout,
            icon: const Icon(Icons.play_arrow),
            label: Text(s.startWorkout),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showTemplatePicker(context, ref),
            icon: const Icon(Icons.view_list),
            label: Text(s.startFromTemplate),
          ),
        ],
      ),
    );
  }

  void _showTemplatePicker(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    showModalBottomSheet<WorkoutTemplate>(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final templatesAsync = ref.watch(
            StreamProvider.autoDispose<List<WorkoutTemplate>>((ref) {
              return ref
                  .watch(workoutTemplateRepositoryProvider)
                  .watchAllTemplates();
            }),
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  s.chooseTemplate,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              templatesAsync.when(
                data: (templates) {
                  if (templates.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(s.noTemplatesAvailable),
                    );
                  }
                  return Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: templates.length,
                      itemBuilder: (ctx, index) {
                        final template = templates[index];
                        return ListTile(
                          leading: const Icon(Icons.view_list),
                          title: Text(template.name),
                          subtitle: Text(
                            s.exerciseCount(template.exercises.length),
                          ),
                          onTap: () => Navigator.pop(ctx, template),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(s.noTemplatesAvailable),
                ),
              ),
            ],
          );
        },
      ),
    ).then((template) {
      if (template != null) {
        ref
            .read(activeWorkoutControllerProvider.notifier)
            .startFromTemplate(template);
      }
    });
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
                    S.of(context)!.addExercisesHint,
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

  void _showPRCelebration(
    BuildContext context,
    WidgetRef ref,
    ActiveWorkoutState state,
  ) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => PRCelebrationOverlay(
        exerciseName: state.latestPRExerciseName ?? 'Exercise',
        value: state.latestPR!.value,
        recordType: state.latestPR!.recordType,
        onDismiss: () {
          entry.remove();
          ref.read(activeWorkoutControllerProvider.notifier).clearPR();
        },
      ),
    );
    overlay.insert(entry);
  }

  Future<void> _confirmFinish(
    BuildContext context,
    ActiveWorkoutController controller,
  ) async {
    final s = S.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.finishWorkoutTitle),
        content: Text(s.finishWorkoutContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.finish),
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
    final s = S.of(context)!;
    return Row(
      children: [
        const SizedBox(width: 32),
        Expanded(
          child: Text(
            s.tableHeaderWeight,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            s.tableHeaderReps,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            s.tableHeaderE1rm,
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
