import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/log_set_use_case.dart';
import '../../domain/models/workout.dart';
import '../../domain/models/workout_set.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../history/domain/models/personal_record.dart';
import '../models/ghost_set.dart';
import '../../../../core/providers.dart';

class ActiveWorkoutState {
  final Workout? activeWorkout;
  final Map<String, List<WorkoutSet>> setsByExercise;
  final Map<String, List<GhostSet>> ghostSetsByExercise;
  final List<Exercise> exercises;
  final bool isLoading;
  final String? error;
  final PersonalRecord? latestPR;
  final String? latestPRExerciseName;

  const ActiveWorkoutState({
    this.activeWorkout,
    this.setsByExercise = const {},
    this.ghostSetsByExercise = const {},
    this.exercises = const [],
    this.isLoading = false,
    this.error,
    this.latestPR,
    this.latestPRExerciseName,
  });

  bool get hasActiveWorkout => activeWorkout != null;

  List<String> get exerciseIds => setsByExercise.keys.toList();

  /// Returns the next ghost set suggestion for the given exercise,
  /// based on how many sets have already been logged.
  GhostSet? nextGhostSet(String exerciseId) {
    final ghosts = ghostSetsByExercise[exerciseId] ?? [];
    final loggedCount = (setsByExercise[exerciseId] ?? []).length;
    if (loggedCount >= ghosts.length) return null;
    return ghosts[loggedCount];
  }

  /// Returns the ghost sets that have not yet been consumed
  /// (i.e. beyond the number of logged sets).
  List<GhostSet> remainingGhosts(String exerciseId) {
    final ghosts = ghostSetsByExercise[exerciseId] ?? [];
    final loggedCount = (setsByExercise[exerciseId] ?? []).length;
    if (loggedCount >= ghosts.length) return [];
    return ghosts.sublist(loggedCount);
  }

  ActiveWorkoutState copyWith({
    Workout? activeWorkout,
    Map<String, List<WorkoutSet>>? setsByExercise,
    Map<String, List<GhostSet>>? ghostSetsByExercise,
    List<Exercise>? exercises,
    bool? isLoading,
    String? error,
    bool clearWorkout = false,
    PersonalRecord? latestPR,
    String? latestPRExerciseName,
    bool clearPR = false,
  }) {
    return ActiveWorkoutState(
      activeWorkout:
          clearWorkout ? null : (activeWorkout ?? this.activeWorkout),
      setsByExercise: setsByExercise ?? this.setsByExercise,
      ghostSetsByExercise: ghostSetsByExercise ?? this.ghostSetsByExercise,
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      latestPR: clearPR ? null : (latestPR ?? this.latestPR),
      latestPRExerciseName:
          clearPR ? null : (latestPRExerciseName ?? this.latestPRExerciseName),
    );
  }
}

class ActiveWorkoutController extends StateNotifier<ActiveWorkoutState> {
  final WorkoutRepository _workoutRepository;
  final Ref _ref;

  ActiveWorkoutController(this._workoutRepository, this._ref)
      : super(const ActiveWorkoutState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final workout = await _workoutRepository.getActiveWorkout();
      if (workout != null) {
        await _loadSets(workout);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadSets(Workout workout) async {
    final sets = await _workoutRepository.getSetsForWorkout(workout.id);
    final Map<String, List<WorkoutSet>> byExercise = {};
    for (final s in sets) {
      byExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }

    final exerciseRepo = _ref.read(exerciseRepositoryProvider);
    final allExercises = await exerciseRepo.getAllExercises();
    final usedExercises =
        allExercises.where((e) => byExercise.containsKey(e.id)).toList();

    // Load ghost sets for all exercises already in the workout.
    final ghosts = await _loadGhostsForExercises(byExercise.keys.toList());

    state = state.copyWith(
      activeWorkout: workout,
      setsByExercise: byExercise,
      ghostSetsByExercise: ghosts,
      exercises: usedExercises,
      isLoading: false,
    );
  }

  Future<void> startWorkout() async {
    state = state.copyWith(isLoading: true);
    try {
      final useCase = _ref.read(startWorkoutUseCaseProvider);
      final workout = await useCase.execute();
      state = state.copyWith(
        activeWorkout: workout,
        setsByExercise: {},
        exercises: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> finishWorkout() async {
    final workout = state.activeWorkout;
    if (workout == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final completed = workout.copyWith(completedAt: DateTime.now().toUtc());
      await _workoutRepository.updateWorkout(completed);
      state = const ActiveWorkoutState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addExercise(Exercise exercise) async {
    if (state.activeWorkout == null) return;

    final updated = Map<String, List<WorkoutSet>>.from(state.setsByExercise);
    updated.putIfAbsent(exercise.id, () => []);

    final updatedExercises = List<Exercise>.from(state.exercises);
    if (!updatedExercises.any((e) => e.id == exercise.id)) {
      updatedExercises.add(exercise);
    }

    // Fetch ghost sets from the last session for this exercise.
    final lastSessionSets =
        await _workoutRepository.getSetsFromLastSession(exercise.id);
    final updatedGhosts =
        Map<String, List<GhostSet>>.from(state.ghostSetsByExercise);
    if (lastSessionSets.isNotEmpty) {
      updatedGhosts[exercise.id] = lastSessionSets
          .map(
            (s) => GhostSet(
              weight: s.weight,
              reps: s.reps,
              rpe: s.rpe,
              setOrder: s.setOrder,
            ),
          )
          .toList();
    }

    state = state.copyWith(
      setsByExercise: updated,
      exercises: updatedExercises,
      ghostSetsByExercise: updatedGhosts,
    );
  }

  Future<Map<String, List<GhostSet>>> _loadGhostsForExercises(
    List<String> exerciseIds,
  ) async {
    final ghosts = <String, List<GhostSet>>{};
    for (final exerciseId in exerciseIds) {
      final lastSessionSets =
          await _workoutRepository.getSetsFromLastSession(exerciseId);
      if (lastSessionSets.isNotEmpty) {
        ghosts[exerciseId] = lastSessionSets
            .map(
              (s) => GhostSet(
                weight: s.weight,
                reps: s.reps,
                rpe: s.rpe,
                setOrder: s.setOrder,
              ),
            )
            .toList();
      }
    }
    return ghosts;
  }

  Future<void> logSet({
    required String exerciseId,
    required double weight,
    required int reps,
    double? rpe,
  }) async {
    final workout = state.activeWorkout;
    if (workout == null) return;

    try {
      final existingSets = state.setsByExercise[exerciseId] ?? [];
      final useCase = _ref.read(logSetUseCaseProvider);
      final result = await useCase.execute(
        LogSetInput(
          workoutId: workout.id,
          exerciseId: exerciseId,
          setOrder: existingSets.length + 1,
          weight: weight,
          reps: reps,
          rpe: rpe,
        ),
      );

      final updated = Map<String, List<WorkoutSet>>.from(state.setsByExercise);
      updated[exerciseId] = [
        ...(updated[exerciseId] ?? []),
        result.set,
      ];

      if (result.newPersonalRecord != null) {
        final exerciseName = state.exercises
            .where((e) => e.id == exerciseId)
            .map((e) => e.name)
            .firstOrNull;
        state = state.copyWith(
          setsByExercise: updated,
          latestPR: result.newPersonalRecord,
          latestPRExerciseName: exerciseName,
        );
      } else {
        state = state.copyWith(setsByExercise: updated);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSet(String setId, String exerciseId) async {
    try {
      await _workoutRepository.deleteSet(setId);
      final updated = Map<String, List<WorkoutSet>>.from(state.setsByExercise);
      updated[exerciseId] =
          (updated[exerciseId] ?? []).where((s) => s.id != setId).toList();
      state = state.copyWith(setsByExercise: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearPR() => state = state.copyWith(clearPR: true);

  void clearError() => state = state.copyWith(error: null);
}

final activeWorkoutControllerProvider =
    StateNotifierProvider<ActiveWorkoutController, ActiveWorkoutState>((ref) {
  return ActiveWorkoutController(
    ref.watch(workoutRepositoryProvider),
    ref,
  );
});
