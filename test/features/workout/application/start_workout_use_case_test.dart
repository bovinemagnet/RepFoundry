import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/application/start_workout_use_case.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/features/workout/domain/repositories/workout_repository.dart';

class _FakeWorkoutRepository implements WorkoutRepository {
  Workout? _active;
  final List<Workout> _created = [];

  @override
  Future<Workout?> getActiveWorkout() async => _active;

  @override
  Future<Workout> createWorkout(Workout workout) async {
    _created.add(workout);
    return workout;
  }

  // Unused stubs
  @override
  Future<Workout?> getWorkout(String id) async => null;
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
  Future<List<WorkoutSet>> getSetsForExercise(
    String exerciseId, {
    int limit = 50,
  }) async =>
      [];
  @override
  Future<WorkoutSet?> getLastSetForExercise(String exerciseId) async => null;
  @override
  Future<WorkoutSet> updateSet(WorkoutSet set) async => set;
  @override
  Future<void> deleteSet(String setId) async {}
  @override
  Future<List<WorkoutSet>> getSetsFromLastSession(String exerciseId) async =>
      [];
  @override
  Stream<List<Workout>> watchWorkoutHistory() => const Stream.empty();
  @override
  Stream<List<WorkoutSet>> watchSetsForWorkout(String workoutId) =>
      const Stream.empty();
}

void main() {
  late StartWorkoutUseCase useCase;
  late _FakeWorkoutRepository repository;

  setUp(() {
    repository = _FakeWorkoutRepository();
    useCase = StartWorkoutUseCase(workoutRepository: repository);
  });

  test(
    'execute_activeWorkoutExists_returnsExistingWorkoutWithoutCreatingNew',
    () async {
      final existing = Workout.create();
      repository._active = existing;

      final result = await useCase.execute();

      expect(result, equals(existing));
    },
  );

  test(
    'execute_noActiveWorkout_createsAndReturnsNewWorkout',
    () async {
      final result = await useCase.execute();

      expect(repository._created, hasLength(1));
      expect(result, equals(repository._created.first));
    },
  );

  test(
    'execute_templateIdProvided_createdWorkoutHasTemplateId',
    () async {
      final result = await useCase.execute(templateId: 'tmpl-42');

      expect(result.templateId, 'tmpl-42');
    },
  );

  test(
    'execute_noTemplateIdProvided_createdWorkoutHasNullTemplateId',
    () async {
      final result = await useCase.execute();

      expect(result.templateId, isNull);
    },
  );

  test(
    'execute_notesProvided_createdWorkoutHasNotes',
    () async {
      final result = await useCase.execute(notes: 'Leg day');

      expect(result.notes, 'Leg day');
    },
  );

  test(
    'execute_noNotesProvided_createdWorkoutHasNullNotes',
    () async {
      final result = await useCase.execute();

      expect(result.notes, isNull);
    },
  );

  test(
    'execute_activeWorkoutExists_doesNotCreateDuplicate',
    () async {
      repository._active = Workout.create();

      await useCase.execute();

      expect(repository._created, isEmpty);
    },
  );
}
