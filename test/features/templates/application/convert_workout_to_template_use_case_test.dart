import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/templates/application/convert_workout_to_template_use_case.dart';
import 'package:rep_foundry/features/templates/data/workout_template_repository_impl.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

void main() {
  late InMemoryWorkoutRepository workoutRepo;
  late InMemoryExerciseRepository exerciseRepo;
  late InMemoryWorkoutTemplateRepository templateRepo;
  late ConvertWorkoutToTemplateUseCase useCase;

  late Exercise bench;
  late Exercise squat;

  setUp(() async {
    workoutRepo = InMemoryWorkoutRepository();
    exerciseRepo = InMemoryExerciseRepository();
    templateRepo = InMemoryWorkoutTemplateRepository();
    useCase = ConvertWorkoutToTemplateUseCase(
      workoutRepository: workoutRepo,
      exerciseRepository: exerciseRepo,
      templateRepository: templateRepo,
    );

    bench = Exercise.create(
      name: 'Bench Press',
      category: ExerciseCategory.strength,
      muscleGroup: MuscleGroup.chest,
      equipmentType: EquipmentType.barbell,
    );
    squat = Exercise.create(
      name: 'Squat',
      category: ExerciseCategory.strength,
      muscleGroup: MuscleGroup.quadriceps,
      equipmentType: EquipmentType.barbell,
    );
    await exerciseRepo.createExercise(bench);
    await exerciseRepo.createExercise(squat);
  });

  Future<Workout> seedWorkout(List<WorkoutSet> Function(String id) sets) async {
    final now = DateTime.utc(2026, 6, 1, 9);
    final workout = Workout(
      id: 'w1',
      startedAt: now,
      completedAt: now.add(const Duration(minutes: 45)),
      clientId: kSelfClientId,
      updatedAt: now,
    );
    await workoutRepo.createWorkout(workout);
    for (final set in sets(workout.id)) {
      await workoutRepo.addSet(set);
    }
    return workout;
  }

  test('builds a template with one TemplateExercise per exercise', () async {
    await seedWorkout((id) => [
          WorkoutSet.create(
              workoutId: id,
              exerciseId: bench.id,
              setOrder: 0,
              weight: 60,
              reps: 5),
          WorkoutSet.create(
              workoutId: id,
              exerciseId: bench.id,
              setOrder: 1,
              weight: 60,
              reps: 5),
          WorkoutSet.create(
              workoutId: id,
              exerciseId: squat.id,
              setOrder: 2,
              weight: 100,
              reps: 8),
        ]);

    final template = await useCase.execute(workoutId: 'w1', name: 'Leg Day');

    expect(template.name, 'Leg Day');
    expect(template.exercises, hasLength(2));
    final benchEx =
        template.exercises.firstWhere((e) => e.exerciseId == bench.id);
    expect(benchEx.exerciseName, 'Bench Press');
    expect(benchEx.templateId, template.id);
    expect(benchEx.targetSets, 2);
    expect(benchEx.targetReps, 5);
  });

  test('persists the template via the repository', () async {
    await seedWorkout((id) => [
          WorkoutSet.create(
              workoutId: id,
              exerciseId: bench.id,
              setOrder: 0,
              weight: 60,
              reps: 5),
        ]);

    final template = await useCase.execute(workoutId: 'w1', name: 'Push');

    final stored = await templateRepo.getTemplate(template.id);
    expect(stored, isNotNull);
    expect(stored!.exercises, hasLength(1));
  });

  test('preserves exercise order by first appearance and sets orderIndex',
      () async {
    await seedWorkout((id) => [
          WorkoutSet.create(
              workoutId: id,
              exerciseId: squat.id,
              setOrder: 0,
              weight: 100,
              reps: 8),
          WorkoutSet.create(
              workoutId: id,
              exerciseId: bench.id,
              setOrder: 1,
              weight: 60,
              reps: 5),
        ]);

    final template = await useCase.execute(workoutId: 'w1', name: 'Full Body');

    expect(template.exercises[0].exerciseId, squat.id);
    expect(template.exercises[0].orderIndex, 0);
    expect(template.exercises[1].exerciseId, bench.id);
    expect(template.exercises[1].orderIndex, 1);
  });

  test('counts only working sets, ignoring warm-ups, for targetSets', () async {
    await seedWorkout((id) => [
          WorkoutSet.create(
              workoutId: id,
              exerciseId: bench.id,
              setOrder: 0,
              weight: 20,
              reps: 10,
              isWarmUp: true),
          WorkoutSet.create(
              workoutId: id,
              exerciseId: bench.id,
              setOrder: 1,
              weight: 60,
              reps: 5),
          WorkoutSet.create(
              workoutId: id,
              exerciseId: bench.id,
              setOrder: 2,
              weight: 60,
              reps: 5),
        ]);

    final template = await useCase.execute(workoutId: 'w1', name: 'Push');

    expect(template.exercises.single.targetSets, 2);
    expect(template.exercises.single.targetReps, 5);
  });

  test('uses the most common rep count for targetReps', () async {
    await seedWorkout((id) => [
          WorkoutSet.create(
              workoutId: id,
              exerciseId: bench.id,
              setOrder: 0,
              weight: 60,
              reps: 8),
          WorkoutSet.create(
              workoutId: id,
              exerciseId: bench.id,
              setOrder: 1,
              weight: 60,
              reps: 6),
          WorkoutSet.create(
              workoutId: id,
              exerciseId: bench.id,
              setOrder: 2,
              weight: 60,
              reps: 6),
        ]);

    final template = await useCase.execute(workoutId: 'w1', name: 'Push');

    expect(template.exercises.single.targetReps, 6);
  });

  test('throws when the workout does not exist', () async {
    expect(
      () => useCase.execute(workoutId: 'missing', name: 'X'),
      throwsA(isA<ConvertWorkoutToTemplateException>()),
    );
  });

  test('throws when the workout has no sets', () async {
    await seedWorkout((id) => []);
    expect(
      () => useCase.execute(workoutId: 'w1', name: 'X'),
      throwsA(isA<ConvertWorkoutToTemplateException>()),
    );
  });

  test('throws when the name is blank', () async {
    await seedWorkout((id) => [
          WorkoutSet.create(
              workoutId: id,
              exerciseId: bench.id,
              setOrder: 0,
              weight: 60,
              reps: 5),
        ]);
    expect(
      () => useCase.execute(workoutId: 'w1', name: '   '),
      throwsA(isA<ConvertWorkoutToTemplateException>()),
    );
  });

  test('trims the template name', () async {
    await seedWorkout((id) => [
          WorkoutSet.create(
              workoutId: id,
              exerciseId: bench.id,
              setOrder: 0,
              weight: 60,
              reps: 5),
        ]);
    final template =
        await useCase.execute(workoutId: 'w1', name: '  Leg Day  ');
    expect(template.name, 'Leg Day');
  });
}
