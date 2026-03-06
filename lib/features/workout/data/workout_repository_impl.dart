import 'dart:async';
import '../domain/models/workout.dart';
import '../domain/models/workout_set.dart';
import '../domain/repositories/workout_repository.dart';

class InMemoryWorkoutRepository implements WorkoutRepository {
  final List<Workout> _workouts = [];
  final List<WorkoutSet> _sets = [];

  final _historyController = StreamController<List<Workout>>.broadcast();
  final Map<String, StreamController<List<WorkoutSet>>> _setControllers = {};

  @override
  Future<Workout> createWorkout(Workout workout) async {
    _workouts.add(workout);
    _notifyHistoryListeners();
    return workout;
  }

  @override
  Future<Workout?> getWorkout(String id) async {
    try {
      return _workouts.firstWhere((w) => w.id == id && !w.isDeleted);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Workout?> getActiveWorkout() async {
    try {
      return _workouts.firstWhere(
        (w) => w.status == WorkoutStatus.inProgress && !w.isDeleted,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<Workout>> getWorkoutHistory({
    int limit = 20,
    DateTime? before,
  }) async {
    var results = _workouts
        .where(
          (w) =>
              w.status == WorkoutStatus.completed &&
              !w.isDeleted &&
              (before == null || w.startedAt.isBefore(before)),
        )
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    if (results.length > limit) {
      results = results.sublist(0, limit);
    }
    return results;
  }

  @override
  Future<Workout> updateWorkout(Workout workout) async {
    final index = _workouts.indexWhere((w) => w.id == workout.id);
    if (index != -1) {
      _workouts[index] = workout;
      _notifyHistoryListeners();
    }
    return workout;
  }

  @override
  Future<void> deleteWorkout(String id) async {
    final index = _workouts.indexWhere((w) => w.id == id);
    if (index != -1) {
      _workouts[index] =
          _workouts[index].copyWith(deletedAt: DateTime.now().toUtc());
      _notifyHistoryListeners();
    }
  }

  @override
  Future<WorkoutSet> addSet(WorkoutSet set) async {
    _sets.add(set);
    _notifySetListeners(set.workoutId);
    return set;
  }

  @override
  Future<List<WorkoutSet>> getSetsForWorkout(String workoutId) async {
    return _sets.where((s) => s.workoutId == workoutId).toList()
      ..sort((a, b) => a.setOrder.compareTo(b.setOrder));
  }

  @override
  Future<List<WorkoutSet>> getSetsForExercise(
    String exerciseId, {
    int limit = 50,
  }) async {
    final results = _sets.where((s) => s.exerciseId == exerciseId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results.length > limit ? results.sublist(0, limit) : results;
  }

  @override
  Future<WorkoutSet?> getLastSetForExercise(String exerciseId) async {
    final sets = _sets.where((s) => s.exerciseId == exerciseId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sets.isEmpty ? null : sets.first;
  }

  @override
  Future<List<WorkoutSet>> getSetsFromLastSession(String exerciseId) async {
    // Find the most recent completed, non-deleted workout containing this exercise.
    final completedWorkouts = _workouts
        .where((w) => w.status == WorkoutStatus.completed && !w.isDeleted)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    for (final workout in completedWorkouts) {
      final sets = _sets
          .where(
            (s) => s.workoutId == workout.id && s.exerciseId == exerciseId,
          )
          .toList()
        ..sort((a, b) => a.setOrder.compareTo(b.setOrder));
      if (sets.isNotEmpty) return sets;
    }
    return [];
  }

  @override
  Future<void> deleteSet(String setId) async {
    final index = _sets.indexWhere((s) => s.id == setId);
    if (index != -1) {
      final workoutId = _sets[index].workoutId;
      _sets.removeAt(index);
      _notifySetListeners(workoutId);
    }
  }

  @override
  Stream<List<Workout>> watchWorkoutHistory() => _historyController.stream;

  @override
  Stream<List<WorkoutSet>> watchSetsForWorkout(String workoutId) {
    _setControllers.putIfAbsent(
      workoutId,
      () => StreamController<List<WorkoutSet>>.broadcast(),
    );
    return _setControllers[workoutId]!.stream;
  }

  void _notifyHistoryListeners() {
    final completed = _workouts
        .where((w) => w.status == WorkoutStatus.completed)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    _historyController.add(completed);
  }

  void _notifySetListeners(String workoutId) {
    final controller = _setControllers[workoutId];
    if (controller != null) {
      final sets = _sets.where((s) => s.workoutId == workoutId).toList()
        ..sort((a, b) => a.setOrder.compareTo(b.setOrder));
      controller.add(sets);
    }
  }
}
