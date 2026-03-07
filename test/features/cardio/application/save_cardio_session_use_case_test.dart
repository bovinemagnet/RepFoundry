import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/application/save_cardio_session_use_case.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';

void main() {
  late InMemoryCardioSessionRepository cardioRepo;
  late InMemoryWorkoutRepository workoutRepo;
  late SaveCardioSessionUseCase useCase;

  setUp(() {
    cardioRepo = InMemoryCardioSessionRepository();
    workoutRepo = InMemoryWorkoutRepository();
    useCase = SaveCardioSessionUseCase(
      cardioRepository: cardioRepo,
      workoutRepository: workoutRepo,
    );
  });

  group('SaveCardioSessionUseCase', () {
    group('validation', () {
      test('throws when exerciseId is empty', () async {
        expect(
          () => useCase.execute(
            const SaveCardioSessionInput(
              exerciseId: '',
              exerciseName: 'Treadmill',
              durationSeconds: 600,
            ),
          ),
          throwsA(isA<SaveCardioSessionException>()),
        );
      });

      test('throws when durationSeconds is zero', () async {
        expect(
          () => useCase.execute(
            const SaveCardioSessionInput(
              exerciseId: 'e1',
              exerciseName: 'Treadmill',
              durationSeconds: 0,
            ),
          ),
          throwsA(isA<SaveCardioSessionException>()),
        );
      });

      test('throws when durationSeconds is negative', () async {
        expect(
          () => useCase.execute(
            const SaveCardioSessionInput(
              exerciseId: 'e1',
              exerciseName: 'Treadmill',
              durationSeconds: -1,
            ),
          ),
          throwsA(isA<SaveCardioSessionException>()),
        );
      });

      test('throws when distanceMeters is negative', () async {
        expect(
          () => useCase.execute(
            const SaveCardioSessionInput(
              exerciseId: 'e1',
              exerciseName: 'Treadmill',
              durationSeconds: 600,
              distanceMeters: -100,
            ),
          ),
          throwsA(isA<SaveCardioSessionException>()),
        );
      });

      test('throws when avgHeartRate is below 30', () async {
        expect(
          () => useCase.execute(
            const SaveCardioSessionInput(
              exerciseId: 'e1',
              exerciseName: 'Treadmill',
              durationSeconds: 600,
              avgHeartRate: 20,
            ),
          ),
          throwsA(isA<SaveCardioSessionException>()),
        );
      });

      test('throws when avgHeartRate is above 250', () async {
        expect(
          () => useCase.execute(
            const SaveCardioSessionInput(
              exerciseId: 'e1',
              exerciseName: 'Treadmill',
              durationSeconds: 600,
              avgHeartRate: 300,
            ),
          ),
          throwsA(isA<SaveCardioSessionException>()),
        );
      });

      test('throws when incline is negative', () async {
        expect(
          () => useCase.execute(
            const SaveCardioSessionInput(
              exerciseId: 'e1',
              exerciseName: 'Treadmill',
              durationSeconds: 600,
              incline: -1,
            ),
          ),
          throwsA(isA<SaveCardioSessionException>()),
        );
      });
    });

    group('successful save', () {
      test('creates workout and cardio session', () async {
        final result = await useCase.execute(
          const SaveCardioSessionInput(
            exerciseId: 'e1',
            exerciseName: 'Treadmill',
            durationSeconds: 1800,
            distanceMeters: 5000,
            avgHeartRate: 145,
            incline: 2.0,
          ),
        );

        expect(result.session.exerciseId, 'e1');
        expect(result.session.durationSeconds, 1800);
        expect(result.session.distanceMeters, 5000);
        expect(result.session.avgHeartRate, 145);
        expect(result.session.incline, 2.0);
        expect(result.workout.notes, 'Cardio: Treadmill');
        expect(result.workout.completedAt, isNotNull);
      });

      test('persists session in repository', () async {
        await useCase.execute(
          const SaveCardioSessionInput(
            exerciseId: 'e1',
            exerciseName: 'Treadmill',
            durationSeconds: 600,
          ),
        );

        final sessions = await cardioRepo.getSessionsForExercise('e1');
        expect(sessions, hasLength(1));
      });

      test('persists workout in repository', () async {
        final result = await useCase.execute(
          const SaveCardioSessionInput(
            exerciseId: 'e1',
            exerciseName: 'Bike',
            durationSeconds: 600,
          ),
        );

        final workout = await workoutRepo.getWorkout(result.workout.id);
        expect(workout, isNotNull);
        expect(workout!.notes, 'Cardio: Bike');
      });

      test('allows zero distance', () async {
        final result = await useCase.execute(
          const SaveCardioSessionInput(
            exerciseId: 'e1',
            exerciseName: 'Bike',
            durationSeconds: 600,
            distanceMeters: 0,
          ),
        );
        expect(result.session.distanceMeters, 0);
      });

      test('allows null optional fields', () async {
        final result = await useCase.execute(
          const SaveCardioSessionInput(
            exerciseId: 'e1',
            exerciseName: 'Bike',
            durationSeconds: 600,
          ),
        );
        expect(result.session.distanceMeters, isNull);
        expect(result.session.avgHeartRate, isNull);
        expect(result.session.incline, isNull);
      });
    });
  });
}
