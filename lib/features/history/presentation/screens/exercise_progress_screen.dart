import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../history/application/calculate_progress_use_case.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/extensions/datetime_extensions.dart';

final _exerciseProgressProvider =
    FutureProvider.autoDispose.family<ExerciseProgress, String>(
  (ref, exerciseId) async {
    final useCase = ref.watch(calculateProgressUseCaseProvider);
    return useCase.execute(exerciseId);
  },
);

final _exerciseDetailProvider =
    FutureProvider.autoDispose.family<Exercise?, String>(
  (ref, exerciseId) async {
    final repo = ref.watch(exerciseRepositoryProvider);
    return repo.getExercise(exerciseId);
  },
);

class ExerciseProgressScreen extends ConsumerWidget {
  const ExerciseProgressScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(_exerciseProgressProvider(exerciseId));
    final exerciseAsync = ref.watch(_exerciseDetailProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          exerciseAsync.valueOrNull?.name ?? 'Exercise Progress',
        ),
      ),
      body: progressAsync.when(
        data: (progress) => _ProgressBody(
          progress: progress,
          exerciseName: exerciseAsync.valueOrNull?.name,
        ),
        loading: () => const LoadingWidget(message: 'Loading progress…'),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({
    required this.progress,
    this.exerciseName,
  });

  final ExerciseProgress progress;
  final String? exerciseName;

  @override
  Widget build(BuildContext context) {
    if (progress.sets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No data yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Log sets for this exercise to see your progress.'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary stats row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Best e1RM',
                value:
                    '${progress.maxEstimated1RM?.toStringAsFixed(1) ?? '—'} kg',
                icon: Icons.emoji_events,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Total Volume',
                value: '${progress.totalVolume?.toStringAsFixed(0) ?? '—'} kg',
                icon: Icons.bar_chart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Total Sets',
                value: '${progress.sets.length}',
                icon: Icons.repeat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Recent Sets',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Weight',
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Reps',
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'e1RM',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (final set in progress.sets.take(30))
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          set.timestamp.toLocal().relativeLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${set.weight} kg',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${set.reps}',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          set.estimatedOneRepMax.toStringAsFixed(1),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
