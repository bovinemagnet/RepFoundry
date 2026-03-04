import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/history/application/calculate_progress_use_case.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/features/workout/domain/repositories/workout_repository.dart';

class _FakeWorkoutRepository implements WorkoutRepository {
  final List<WorkoutSet> _sets;

  _FakeWorkoutRepository(this._sets);

  @override
  Future<List<WorkoutSet>> getSetsForExercise(
    String exerciseId, {
    int limit = 50,
  }) async {
    return _sets.where((s) => s.exerciseId == exerciseId).take(limit).toList();
  }

  // Unused stubs
  @override
  Future<Workout> createWorkout(Workout workout) async => workout;
  @override
  Future<Workout?> getWorkout(String id) async => null;
  @override
  Future<Workout?> getActiveWorkout() async => null;
  @override
  Future<List<Workout>> getWorkoutHistory({
    int limit = 20,
    DateTime? before,
  }) async =>
      [];
  @override
  Future<Workout> updateWorkout(Workout workout) async => workout;
  @override
  Future<void> deleteWorkout(String id) async {}
  @override
  Future<WorkoutSet> addSet(WorkoutSet set) async => set;
  @override
  Future<List<WorkoutSet>> getSetsForWorkout(String workoutId) async => [];
  @override
  Future<WorkoutSet?> getLastSetForExercise(String exerciseId) async => null;
  @override
  Future<void> deleteSet(String setId) async {}
  @override
  Stream<List<Workout>> watchWorkoutHistory() => const Stream.empty();
  @override
  Stream<List<WorkoutSet>> watchSetsForWorkout(String workoutId) =>
      const Stream.empty();
}

WorkoutSet _makeSet({
  required String id,
  required String exerciseId,
  required double weight,
  required int reps,
}) {
  return WorkoutSet(
    id: id,
    workoutId: 'w1',
    exerciseId: exerciseId,
    setOrder: 1,
    weight: weight,
    reps: reps,
    timestamp: DateTime.now().toUtc(),
  );
}

void main() {
  group('CalculateProgressUseCase', () {
    test('returns empty progress when no sets exist', () async {
      final useCase = CalculateProgressUseCase(
        workoutRepository: _FakeWorkoutRepository([]),
      );
      final progress = await useCase.execute('e1');
      expect(progress.sets, isEmpty);
      expect(progress.maxEstimated1RM, isNull);
      expect(progress.totalVolume, isNull);
    });

    test('calculates max e1RM across sets', () async {
      final sets = [
        _makeSet(id: '1', exerciseId: 'e1', weight: 100, reps: 5),
        _makeSet(id: '2', exerciseId: 'e1', weight: 120, reps: 3),
        _makeSet(id: '3', exerciseId: 'e1', weight: 80, reps: 10),
      ];
      final useCase = CalculateProgressUseCase(
        workoutRepository: _FakeWorkoutRepository(sets),
      );
      final progress = await useCase.execute('e1');
      // 120 * (1 + 3/30) = 132
      expect(progress.maxEstimated1RM, closeTo(132.0, 0.1));
    });

    test('calculates total volume across sets', () async {
      final sets = [
        _makeSet(id: '1', exerciseId: 'e1', weight: 100, reps: 5),
        _makeSet(id: '2', exerciseId: 'e1', weight: 100, reps: 5),
      ];
      final useCase = CalculateProgressUseCase(
        workoutRepository: _FakeWorkoutRepository(sets),
      );
      final progress = await useCase.execute('e1');
      // 100*5 + 100*5 = 1000
      expect(progress.totalVolume, closeTo(1000.0, 0.001));
    });

    test('only includes sets for requested exercise', () async {
      final sets = [
        _makeSet(id: '1', exerciseId: 'e1', weight: 100, reps: 5),
        _makeSet(id: '2', exerciseId: 'e2', weight: 200, reps: 5),
      ];
      final useCase = CalculateProgressUseCase(
        workoutRepository: _FakeWorkoutRepository(sets),
      );
      final progress = await useCase.execute('e1');
      expect(progress.sets, hasLength(1));
      expect(progress.sets.first.exerciseId, 'e1');
    });
  });
}
