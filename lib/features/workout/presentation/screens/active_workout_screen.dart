import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../controllers/active_workout_controller.dart';
import '../models/ghost_set.dart';
import '../widgets/pr_celebration_overlay.dart';
import '../widgets/edit_set_dialog.dart';
import '../widgets/set_input_card.dart';
import '../widgets/rest_timer_widget.dart';
import '../../domain/models/workout_set.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../programmes/domain/models/programme.dart';
import '../../../templates/domain/models/workout_template.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/loading_widget.dart';

final _templatePickerProvider =
    StreamProvider.autoDispose<List<WorkoutTemplate>>((ref) {
  return ref.watch(workoutTemplateRepositoryProvider).watchAllTemplates();
});

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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showProgrammePicker(context, ref),
            icon: const Icon(Icons.calendar_month),
            label: Text(s.startFromProgramme),
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
          final templatesAsync = ref.watch(_templatePickerProvider);
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

  void _showProgrammePicker(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    showModalBottomSheet<Programme>(
      context: context,
      builder: (ctx) => FutureBuilder<List<Programme>>(
        future: ref.read(programmeRepositoryProvider).getAllProgrammes(),
        builder: (ctx, snapshot) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  s.chooseProgramme,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(s.noProgrammesAvailable),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (ctx, index) {
                      final programme = snapshot.data![index];
                      return ListTile(
                        leading: const Icon(Icons.calendar_month),
                        title: Text(programme.name),
                        subtitle: Text(
                          s.programmeDaysCount(programme.days.length),
                        ),
                        onTap: () => Navigator.pop(ctx, programme),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    ).then((programme) async {
      if (programme != null) {
        final started = await ref
            .read(activeWorkoutControllerProvider.notifier)
            .startFromProgramme(programme);
        if (!started && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.noWorkoutScheduledForToday)),
          );
        }
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

    final supersetGroups = getSupersetGroups(state.setsByExercise);
    final supersetExerciseIds =
        supersetGroups.values.expand((ids) => ids).toSet();
    final renderedGroups = <String>{};

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        const RestTimerWidget(),
        for (final exercise in state.exercises) ...[
          if (supersetExerciseIds.contains(exercise.id)) ...[
            () {
              final groupId =
                  state.setsByExercise[exercise.id]?.firstOrNull?.groupId;
              if (groupId != null && !renderedGroups.contains(groupId)) {
                renderedGroups.add(groupId);
                final groupExerciseIds = supersetGroups[groupId]!;
                final groupExercises = state.exercises
                    .where((e) => groupExerciseIds.contains(e.id))
                    .toList();
                return _SupersetGroup(
                  exercises: groupExercises,
                  state: state,
                  controller: controller,
                  onUnlink: (exerciseId) =>
                      controller.unlinkSuperset(exerciseId),
                );
              }
              return const SizedBox.shrink();
            }(),
          ] else ...[
            _ExerciseSection(
              exercise: exercise,
              sets: state.setsByExercise[exercise.id] ?? [],
              ghostSets: state.remainingGhosts(exercise.id),
              suggestion: state.nextGhostSet(exercise.id),
              onLogSet: ({
                required double weight,
                required int reps,
                double? rpe,
                bool isWarmUp = false,
              }) {
                controller.logSet(
                  exerciseId: exercise.id,
                  weight: weight,
                  reps: reps,
                  rpe: rpe,
                  isWarmUp: isWarmUp,
                );
              },
              onDeleteSet: (setId) => controller.deleteSet(setId, exercise.id),
              onEditSet: (updatedSet) => controller.updateSet(updatedSet),
              onLinkSuperset: () =>
                  _showSupersetPicker(context, ref, exercise, state),
            ),
          ],
        ],
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

  void _showSupersetPicker(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
    ActiveWorkoutState state,
  ) {
    final s = S.of(context)!;
    final otherExercises =
        state.exercises.where((e) => e.id != exercise.id).toList();
    final supersetGroups = getSupersetGroups(state.setsByExercise);
    final supersetExerciseIds =
        supersetGroups.values.expand((ids) => ids).toSet();
    final available = otherExercises
        .where((e) => !supersetExerciseIds.contains(e.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.noOtherExercises)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              s.selectSupersetPartner,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          for (final other in available)
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(other.name),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(activeWorkoutControllerProvider.notifier)
                    .linkSuperset(exercise.id, other.id);
              },
            ),
        ],
      ),
    );
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
    required this.onEditSet,
    this.onLinkSuperset,
  });

  final Exercise exercise;
  final List<WorkoutSet> sets;
  final List<GhostSet> ghostSets;
  final GhostSet? suggestion;
  final void Function({
    required double weight,
    required int reps,
    double? rpe,
    bool isWarmUp,
  }) onLogSet;
  final void Function(String setId) onDeleteSet;
  final void Function(WorkoutSet updatedSet) onEditSet;
  final VoidCallback? onLinkSuperset;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return GestureDetector(
      onLongPress: onLinkSuperset != null
          ? () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: Text(s.linkAsSuperset),
                      onTap: () {
                        Navigator.pop(ctx);
                        onLinkSuperset!();
                      },
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: _ExerciseSectionContent(
            exercise: exercise,
            sets: sets,
            ghostSets: ghostSets,
            suggestion: suggestion,
            onLogSet: onLogSet,
            onDeleteSet: onDeleteSet,
            onEditSet: onEditSet,
          ),
        ),
      ),
    );
  }
}

class _ExerciseSectionContent extends StatelessWidget {
  const _ExerciseSectionContent({
    required this.exercise,
    required this.sets,
    required this.ghostSets,
    required this.suggestion,
    required this.onLogSet,
    required this.onDeleteSet,
    required this.onEditSet,
  });

  final Exercise exercise;
  final List<WorkoutSet> sets;
  final List<GhostSet> ghostSets;
  final GhostSet? suggestion;
  final void Function({
    required double weight,
    required int reps,
    double? rpe,
    bool isWarmUp,
  }) onLogSet;
  final void Function(String setId) onDeleteSet;
  final void Function(WorkoutSet updatedSet) onEditSet;

  @override
  Widget build(BuildContext context) {
    final hasTableContent = sets.isNotEmpty || ghostSets.isNotEmpty;

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (sets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.history,
                              size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Last: ${sets.last.weight}kg x ${sets.last.reps}',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                exercise.muscleGroup.name,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Set cards grid
        if (hasTableContent) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < sets.length; i++)
                _SetCard(
                  index: i,
                  set: sets[i],
                  onDelete: () => onDeleteSet(sets[i].id),
                  onEdit: onEditSet,
                ),
              for (int i = 0; i < ghostSets.length; i++)
                _GhostSetCard(
                  index: sets.length + i,
                  ghost: ghostSets[i],
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        SetInputCard(onLogSet: onLogSet, suggestion: suggestion),
      ],
    );
  }
}

class _SupersetGroup extends StatelessWidget {
  const _SupersetGroup({
    required this.exercises,
    required this.state,
    required this.controller,
    required this.onUnlink,
  });

  final List<Exercise> exercises;
  final ActiveWorkoutState state;
  final ActiveWorkoutController controller;
  final void Function(String exerciseId) onUnlink;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.tertiary.withValues(alpha: 0.3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: cs.tertiaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Icon(Icons.link, size: 14, color: cs.tertiary),
                  const SizedBox(width: 6),
                  Text(
                    s.supersetLabel.toUpperCase(),
                    style: tt.labelSmall?.copyWith(
                      color: cs.tertiary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => onUnlink(exercises.first.id),
                    child: Icon(Icons.link_off, size: 16, color: cs.outline),
                  ),
                ],
              ),
            ),
            for (final exercise in exercises)
              Padding(
                padding: const EdgeInsets.all(16),
                child: _ExerciseSectionContent(
                  exercise: exercise,
                  sets: state.setsByExercise[exercise.id] ?? [],
                  ghostSets: state.remainingGhosts(exercise.id),
                  suggestion: state.nextGhostSet(exercise.id),
                  onLogSet: ({
                    required double weight,
                    required int reps,
                    double? rpe,
                    bool isWarmUp = false,
                  }) {
                    controller.logSet(
                      exerciseId: exercise.id,
                      weight: weight,
                      reps: reps,
                      rpe: rpe,
                      isWarmUp: isWarmUp,
                    );
                  },
                  onDeleteSet: (setId) =>
                      controller.deleteSet(setId, exercise.id),
                  onEditSet: (updatedSet) => controller.updateSet(updatedSet),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({
    required this.index,
    required this.set,
    required this.onDelete,
    required this.onEdit,
  });

  final int index;
  final WorkoutSet set;
  final VoidCallback onDelete;
  final void Function(WorkoutSet updatedSet) onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () async {
        final updated = await showEditSetDialog(context, set);
        if (updated != null) onEdit(updated);
      },
      onLongPress: onDelete,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              set.isWarmUp ? 'W' : 'SET ${index + 1}',
              style: tt.labelSmall?.copyWith(
                color: set.isWarmUp ? Colors.orange : cs.onSurfaceVariant,
                letterSpacing: 0.5,
                fontSize: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${set.weight}kg',
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontStyle: set.isWarmUp ? FontStyle.italic : null,
              ),
            ),
            Text(
              'x ${set.reps}',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _GhostSetCard extends StatelessWidget {
  const _GhostSetCard({
    required this.index,
    required this.ghost,
  });

  final int index;
  final GhostSet ghost;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Opacity(
      opacity: 0.4,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'SET ${index + 1}',
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
                fontSize: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${ghost.weight}kg',
              style: tt.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
            Text(
              'x ${ghost.reps}',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
