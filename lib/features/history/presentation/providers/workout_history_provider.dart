import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';
import '../../../workout/domain/models/workout.dart';
import '../../../workout/domain/models/workout_set.dart';

/// A completed workout paired with its logged sets, with derived totals.
class WorkoutWithSets {
  final Workout workout;
  final List<WorkoutSet> sets;

  const WorkoutWithSets({required this.workout, required this.sets});

  double get totalVolume => sets.fold<double>(0, (sum, s) => sum + s.volume);

  int get setCount => sets.length;

  int get exerciseCount => sets.map((s) => s.exerciseId).toSet().length;

  /// Minutes between start and completion, or null if not yet completed.
  int? get durationMinutes {
    final completed = workout.completedAt;
    if (completed == null) return null;
    return completed.difference(workout.startedAt).inMinutes;
  }
}

/// Workout history (newest first) with each workout's sets eagerly loaded.
/// Shared by the desktop master-detail History layout.
final workoutHistoryWithSetsProvider =
    FutureProvider.autoDispose<List<WorkoutWithSets>>((ref) async {
  final clientId = (await ref.watch(activeClientProvider.future)).id;
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(
    clientId: clientId,
    limit: 50,
  );
  final result = <WorkoutWithSets>[];
  for (final w in workouts) {
    final sets = await repo.getSetsForWorkout(w.id);
    result.add(WorkoutWithSets(workout: w, sets: sets));
  }
  return result;
});
