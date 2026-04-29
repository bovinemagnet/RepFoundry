import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../workout/domain/models/workout.dart';
import '../../../workout/domain/models/workout_set.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/extensions/datetime_extensions.dart';

class _WorkoutDetailData {
  final Workout workout;
  final Map<String, List<WorkoutSet>> setsByExercise;
  final Map<String, Exercise> exercisesById;
  final Set<String> prSetIds;

  const _WorkoutDetailData({
    required this.workout,
    required this.setsByExercise,
    required this.exercisesById,
    this.prSetIds = const {},
  });
}

final _workoutDetailProvider =
    FutureProvider.autoDispose.family<_WorkoutDetailData?, String>(
  (ref, workoutId) async {
    final workoutRepo = ref.watch(workoutRepositoryProvider);
    final exerciseRepo = ref.watch(exerciseRepositoryProvider);

    final workout = await workoutRepo.getWorkout(workoutId);
    if (workout == null) return null;

    final sets = await workoutRepo.getSetsForWorkout(workoutId);
    final Map<String, List<WorkoutSet>> byExercise = {};
    for (final s in sets) {
      byExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }

    final allExercises = await exerciseRepo.getAllExercises();
    final Map<String, Exercise> exercisesById = {
      for (final e in allExercises) e.id: e,
    };

    final prRepo = ref.watch(personalRecordRepositoryProvider);
    final allPrs = await prRepo.getAllRecords(limit: 500);
    final setIds = sets.map((s) => s.id).toSet();
    final prSetIds = allPrs
        .where(
            (pr) => pr.workoutSetId != null && setIds.contains(pr.workoutSetId))
        .map((pr) => pr.workoutSetId!)
        .toSet();

    return _WorkoutDetailData(
      workout: workout,
      setsByExercise: byExercise,
      exercisesById: exercisesById,
      prSetIds: prSetIds,
    );
  },
);

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final dataAsync = ref.watch(_workoutDetailProvider(workoutId));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.workoutDetailTitle),
        leading: BackButton(onPressed: () => context.go('/history')),
      ),
      body: dataAsync.when(
        data: (data) {
          if (data == null) {
            return Center(child: Text(s.workoutNotFound));
          }
          return _WorkoutDetailBody(data: data);
        },
        loading: () => LoadingWidget(message: s.loadingWorkout),
        error: (e, _) => Center(child: Text(s.errorPrefix(e.toString()))),
      ),
    );
  }
}

class _WorkoutDetailBody extends StatelessWidget {
  const _WorkoutDetailBody({required this.data});

  final _WorkoutDetailData data;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final workout = data.workout;
    final duration = workout.completedAt != null
        ? workout.startedAt.durationUntil(workout.completedAt!)
        : null;

    final totalSets = data.setsByExercise.values
        .fold<int>(0, (sum, sets) => sum + sets.length);
    final totalVolume = data.setsByExercise.values
        .expand((sets) => sets)
        .fold<double>(0, (sum, s) => sum + s.volume);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.startedAt.toLocal().relativeLabel,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  workout.startedAt.toLocal().timeOfDay,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox(
                      label: s.durationLabel,
                      value: duration ?? '—',
                    ),
                    _StatBox(
                      label: s.setsLabel,
                      value: '$totalSets',
                    ),
                    _StatBox(
                      label: s.volumeLabel,
                      value: '${totalVolume.toStringAsFixed(0)} kg',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in data.setsByExercise.entries)
          _ExerciseSetsCard(
            exercise: data.exercisesById[entry.key],
            exerciseId: entry.key,
            sets: entry.value,
            prSetIds: data.prSetIds,
          ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ExerciseSetsCard extends StatelessWidget {
  const _ExerciseSetsCard({
    required this.exercise,
    required this.exerciseId,
    required this.sets,
    required this.prSetIds,
  });

  final Exercise? exercise;
  final String exerciseId;
  final List<WorkoutSet> sets;
  final Set<String> prSetIds;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final name = exercise?.name ?? exerciseId;
    final volume = sets.fold<double>(0, (sum, s) => sum + s.volume);
    final hasPr = sets.any((s) => prSetIds.contains(s.id));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (hasPr) ...[
                  Icon(
                    Icons.emoji_events,
                    size: 20,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/history/exercise/$exerciseId'),
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ),
                Text(
                  'Vol: ${volume.toStringAsFixed(0)} kg',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(32),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    _tableHeader(context, s.tableHeaderHash),
                    _tableHeader(context, s.tableHeaderWeight),
                    _tableHeader(context, s.tableHeaderReps),
                    _tableHeader(context, s.tableHeaderE1rm),
                  ],
                ),
                for (int i = 0; i < sets.length; i++)
                  TableRow(
                    children: [
                      _tableCell(context, '${i + 1}', isHeader: true),
                      _tableCell(context, '${sets[i].weight} kg'),
                      _tableCell(context, '${sets[i].reps}'),
                      _tableCell(
                        context,
                        sets[i].estimatedOneRepMax.toStringAsFixed(1),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _tableCell(
    BuildContext context,
    String text, {
    bool isHeader = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
