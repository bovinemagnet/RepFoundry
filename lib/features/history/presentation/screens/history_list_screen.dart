import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/workout_history_tile.dart';
import '../../../workout/domain/models/workout.dart';
import '../../../workout/domain/models/workout_set.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/loading_widget.dart';

class _WorkoutWithSets {
  final Workout workout;
  final List<WorkoutSet> sets;

  const _WorkoutWithSets({required this.workout, required this.sets});
}

final _workoutHistoryProvider =
    FutureProvider.autoDispose<List<_WorkoutWithSets>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(limit: 50);
  final result = <_WorkoutWithSets>[];
  for (final w in workouts) {
    final sets = await repo.getSetsForWorkout(w.id);
    result.add(_WorkoutWithSets(workout: w, sets: sets));
  }
  return result;
});

class HistoryListScreen extends ConsumerWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_workoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: historyAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No workouts yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completed workouts will appear here.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return WorkoutHistoryTile(
                workout: item.workout,
                setCount: item.sets.length,
                onTap: () => context.go('/history/${item.workout.id}'),
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Loading history…'),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
