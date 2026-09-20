import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/application/build_cardio_history_use_case.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';

void main() {
  late InMemoryWorkoutRepository workouts;
  late InMemoryCardioSessionRepository cardio;
  late InMemoryExerciseRepository exercises;
  late BuildCardioHistoryUseCase useCase;

  setUp(() {
    workouts = InMemoryWorkoutRepository();
    cardio = InMemoryCardioSessionRepository();
    exercises = InMemoryExerciseRepository();
    useCase = BuildCardioHistoryUseCase(
      workoutRepository: workouts,
      cardioSessionRepository: cardio,
      exerciseRepository: exercises,
    );
  });

  Future<void> seed(String id, DateTime at,
      {String clientId = kSelfClientId, String exerciseId = '16'}) async {
    await workouts.createWorkout(Workout(
      id: 'w-$id',
      startedAt: at,
      completedAt: at.add(const Duration(minutes: 30)),
      clientId: clientId,
      updatedAt: at,
    ));
    await cardio.createSession(CardioSession(
      id: id,
      workoutId: 'w-$id',
      exerciseId: exerciseId,
      durationSeconds: 1800,
      distanceMeters: 5000,
      clientId: clientId,
      updatedAt: at,
    ));
  }

  test('lists the client\'s sessions newest first with sport and start time',
      () async {
    final run = await exercises.createExercise(Exercise.create(
      name: 'Outdoor Run',
      category: ExerciseCategory.cardio,
      muscleGroup: MuscleGroup.cardio,
      equipmentType: EquipmentType.bodyweight,
    ));
    await seed('old', DateTime.utc(2026, 9, 1, 7), exerciseId: run.id);
    await seed('new', DateTime.utc(2026, 9, 18, 7), exerciseId: run.id);
    await seed('theirs', DateTime.utc(2026, 9, 19, 7),
        clientId: 'alice', exerciseId: run.id);

    final entries = await useCase.execute(clientId: kSelfClientId);

    expect(entries.map((e) => e.session.id), ['new', 'old']);
    expect(entries.first.startedAt, DateTime.utc(2026, 9, 18, 7));
    expect(entries.first.exerciseName, 'Outdoor Run');
  });

  test('falls back to the exercise id when the exercise is unknown', () async {
    await seed('a', DateTime.utc(2026, 9, 18, 7), exerciseId: 'gone');

    final entries = await useCase.execute(clientId: kSelfClientId);

    expect(entries.single.exerciseName, 'gone');
  });
}
