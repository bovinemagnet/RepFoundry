import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../application/log_set_use_case.dart';
import '../../domain/models/workout.dart';
import '../../domain/models/workout_set.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../health_sync/presentation/providers/health_sync_settings_provider.dart';
import '../../../history/domain/models/personal_record.dart';
import '../../../programmes/domain/models/programme.dart';
import '../../../templates/domain/models/workout_template.dart';
import '../models/ghost_set.dart';
import '../../../../core/providers.dart';
import '../../../sync/presentation/providers/sync_settings_provider.dart';

/// Pure function: assigns a shared groupId to all sets for two exercises.
Map<String, List<WorkoutSet>> linkSupersetSets(
  Map<String, List<WorkoutSet>> setsByExercise,
  String exerciseId1,
  String exerciseId2,
) {
  final groupId = const Uuid().v4();
  final updated = Map<String, List<WorkoutSet>>.from(setsByExercise);
  for (final eid in [exerciseId1, exerciseId2]) {
    updated[eid] = (updated[eid] ?? [])
        .map((s) => s.copyWith(groupId: groupId))
        .toList();
  }
  return updated;
}

/// Pure function: clears groupId from all sets sharing the same group as exerciseId.
Map<String, List<WorkoutSet>> unlinkSupersetSets(
  Map<String, List<WorkoutSet>> setsByExercise,
  String exerciseId,
) {
  final sets = setsByExercise[exerciseId] ?? [];
  if (sets.isEmpty) return setsByExercise;
  final targetGroupId = sets.first.groupId;
  if (targetGroupId == null) return setsByExercise;

  final updated = Map<String, List<WorkoutSet>>.from(setsByExercise);
  for (final entry in updated.entries) {
    updated[entry.key] = entry.value
        .map((s) =>
            s.groupId == targetGroupId ? s.copyWith(clearGroupId: true) : s)
        .toList();
  }
  return updated;
}

/// Pure function: returns a map of groupId to list of exerciseIds in that superset.
Map<String, List<String>> getSupersetGroups(
  Map<String, List<WorkoutSet>> setsByExercise,
) {
  final groups = <String, List<String>>{};
  for (final entry in setsByExercise.entries) {
    final firstGroupId =
        entry.value.isNotEmpty ? entry.value.first.groupId : null;
    if (firstGroupId != null) {
      groups.putIfAbsent(firstGroupId, () => []).add(entry.key);
    }
  }
  groups.removeWhere((_, ids) => ids.length < 2);
  return groups;
}

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

class ActiveWorkoutController extends Notifier<ActiveWorkoutState> {
  WorkoutRepository get _workoutRepository =>
      ref.read(workoutRepositoryProvider);

  @override
  ActiveWorkoutState build() {
    _init();
    return const ActiveWorkoutState();
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

    final exerciseRepo = ref.read(exerciseRepositoryProvider);
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
      final useCase = ref.read(startWorkoutUseCaseProvider);
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

  Future<void> startFromTemplate(WorkoutTemplate template) async {
    state = state.copyWith(isLoading: true);
    try {
      final useCase = ref.read(startWorkoutUseCaseProvider);
      final workout = await useCase.execute(templateId: template.id);
      state = state.copyWith(
        activeWorkout: workout,
        setsByExercise: {},
        exercises: [],
        isLoading: false,
      );

      // Add each exercise from the template
      final exerciseRepo = ref.read(exerciseRepositoryProvider);
      final allExercises = await exerciseRepo.getAllExercises();
      final exercisesById = {for (final e in allExercises) e.id: e};

      for (final templateExercise in template.exercises) {
        final exercise = exercisesById[templateExercise.exerciseId];
        if (exercise != null) {
          await addExercise(exercise);
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Starts a workout from a programme, applying progression rules to ghost
  /// set weights where applicable.
  ///
  /// Returns `true` if a workout was started, `false` if no template was
  /// found for today's day of the week.
  Future<bool> startFromProgramme(Programme programme) async {
    final today = DateTime.now().weekday; // 1 = Monday … 7 = Sunday
    final todayDay = programme.days.cast<ProgrammeDay?>().firstWhere(
          (d) => d!.dayOfWeek == today,
          orElse: () => null,
        );

    if (todayDay == null) return false;

    // Fetch the full template so we can pass it to startFromTemplate.
    final templateRepo = ref.read(workoutTemplateRepositoryProvider);
    final template = await templateRepo.getTemplate(todayDay.templateId);
    if (template == null) return false;

    await startFromTemplate(template);

    // Apply progression rules to ghost set weights.
    if (programme.rules.isNotEmpty) {
      final updatedGhosts =
          Map<String, List<GhostSet>>.from(state.ghostSetsByExercise);
      for (final rule in programme.rules) {
        final ghosts = updatedGhosts[rule.exerciseId];
        if (ghosts != null && ghosts.isNotEmpty) {
          updatedGhosts[rule.exerciseId] = ghosts
              .map((g) => GhostSet(
                    weight: double.parse(
                      rule.applyProgression(g.weight).toStringAsFixed(2),
                    ),
                    reps: g.reps,
                    rpe: g.rpe,
                    setOrder: g.setOrder,
                  ))
              .toList();
        }
      }
      state = state.copyWith(ghostSetsByExercise: updatedGhosts);
    }

    return true;
  }

  Future<void> finishWorkout() async {
    final workout = state.activeWorkout;
    if (workout == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final completed = workout.copyWith(completedAt: DateTime.now().toUtc());
      await _workoutRepository.updateWorkout(completed);

      // Sync to health store if enabled
      try {
        final healthSettings = ref.read(healthSyncSettingsProvider);
        if (healthSettings.enabled && healthSettings.writeWorkouts) {
          final healthService = ref.read(healthSyncServiceProvider);
          final sets =
              await _workoutRepository.getSetsForWorkout(workout.id);
          final totalVolume = sets
              .where((s) => !s.isWarmUp)
              .fold(0.0, (sum, s) => sum + s.volume);
          // Rough calorie estimate: 0.05 kcal per kg of volume moved
          final calories = (totalVolume * 0.05).round();
          await healthService.writeWorkout(
            startTime: workout.startedAt,
            endTime: completed.completedAt!,
            totalCalories: calories,
          );
        }
      } catch (_) {
        // Health sync is best-effort — don't fail the workout
      }

      // Cloud sync after workout — fire-and-forget
      try {
        final syncSettings = ref.read(syncSettingsProvider);
        if (syncSettings.enabled) {
          final orchestrator = ref.read(syncOrchestratorProvider);
          unawaited(orchestrator.sync());
        }
      } catch (_) {
        // Cloud sync is best-effort — don't fail the workout
      }

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
    bool isWarmUp = false,
  }) async {
    final workout = state.activeWorkout;
    if (workout == null) return;

    try {
      final existingSets = state.setsByExercise[exerciseId] ?? [];
      final useCase = ref.read(logSetUseCaseProvider);
      final result = await useCase.execute(
        LogSetInput(
          workoutId: workout.id,
          exerciseId: exerciseId,
          setOrder: existingSets.length + 1,
          weight: weight,
          reps: reps,
          rpe: rpe,
          isWarmUp: isWarmUp,
        ),
      );

      final updated = Map<String, List<WorkoutSet>>.from(state.setsByExercise);
      updated[exerciseId] = [
        ...(updated[exerciseId] ?? []),
        result.set,
      ];

      if (result.newPersonalRecords.isNotEmpty) {
        final exerciseName = state.exercises
            .where((e) => e.id == exerciseId)
            .map((e) => e.name)
            .firstOrNull;
        state = state.copyWith(
          setsByExercise: updated,
          latestPR: result.newPersonalRecords.first,
          latestPRExerciseName: exerciseName,
        );
      } else {
        state = state.copyWith(setsByExercise: updated);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateSet(WorkoutSet updatedSet) async {
    try {
      await _workoutRepository.updateSet(updatedSet);
      final updated = Map<String, List<WorkoutSet>>.from(state.setsByExercise);
      final exerciseSets = updated[updatedSet.exerciseId] ?? [];
      updated[updatedSet.exerciseId] = exerciseSets
          .map((s) => s.id == updatedSet.id ? updatedSet : s)
          .toList();
      state = state.copyWith(setsByExercise: updated);
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

  Future<void> linkSuperset(String exerciseId1, String exerciseId2) async {
    final updated =
        linkSupersetSets(state.setsByExercise, exerciseId1, exerciseId2);
    state = state.copyWith(setsByExercise: updated);
    for (final eid in [exerciseId1, exerciseId2]) {
      for (final s in updated[eid] ?? []) {
        await _workoutRepository.updateSet(s);
      }
    }
  }

  Future<void> unlinkSuperset(String exerciseId) async {
    final oldSets = state.setsByExercise;
    final targetGroupId = (oldSets[exerciseId] ?? []).isNotEmpty
        ? oldSets[exerciseId]!.first.groupId
        : null;
    if (targetGroupId == null) return;

    final updated = unlinkSupersetSets(oldSets, exerciseId);
    state = state.copyWith(setsByExercise: updated);
    for (final entry in updated.entries) {
      for (final s in entry.value) {
        if (oldSets[entry.key]
                ?.any((old) => old.id == s.id && old.groupId == targetGroupId) ==
            true) {
          await _workoutRepository.updateSet(s);
        }
      }
    }
  }

  void clearPR() => state = state.copyWith(clearPR: true);

  void clearError() => state = state.copyWith(error: null);
}

final activeWorkoutControllerProvider =
    NotifierProvider<ActiveWorkoutController, ActiveWorkoutState>(
  ActiveWorkoutController.new,
);
