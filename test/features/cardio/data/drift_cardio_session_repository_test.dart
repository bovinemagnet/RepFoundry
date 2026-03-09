import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/cardio/data/drift_cardio_session_repository.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/workout/data/drift_workout_repository.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';

void main() {
  late db.AppDatabase database;
  late DriftCardioSessionRepository repo;
  late DriftWorkoutRepository workoutRepo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftCardioSessionRepository(database);
    workoutRepo = DriftWorkoutRepository(database);
  });

  tearDown(() => database.close());

  /// Helper: creates and persists a parent workout (FK requirement).
  Future<Workout> createParentWorkout() async {
    final workout = Workout.create();
    await workoutRepo.createWorkout(workout);
    return workout;
  }

  CardioSession newSession({
    required String workoutId,
    String exerciseId = '16', // Treadmill (seeded)
    int durationSeconds = 1800,
    double? distanceMeters = 5000,
    int? avgHeartRate = 145,
  }) {
    return CardioSession.create(
      workoutId: workoutId,
      exerciseId: exerciseId,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      avgHeartRate: avgHeartRate,
    );
  }

  group('DriftCardioSessionRepository', () {
    group('createSession & getSession', () {
      test('persists and retrieves a session', () async {
        final workout = await createParentWorkout();
        final session = newSession(workoutId: workout.id);
        await repo.createSession(session);

        final fetched = await repo.getSession(session.id);
        expect(fetched, isNotNull);
        expect(fetched!.id, session.id);
        expect(fetched.workoutId, workout.id);
        expect(fetched.exerciseId, '16');
        expect(fetched.durationSeconds, 1800);
        expect(fetched.distanceMeters, 5000);
        expect(fetched.avgHeartRate, 145);
      });

      test('returns null for non-existent id', () async {
        final fetched = await repo.getSession('non-existent');
        expect(fetched, isNull);
      });
    });

    group('getSessionsForWorkout', () {
      test('returns sessions for a workout', () async {
        final workout = await createParentWorkout();
        await repo.createSession(newSession(workoutId: workout.id));
        await repo.createSession(newSession(workoutId: workout.id));

        final sessions = await repo.getSessionsForWorkout(workout.id);
        expect(sessions, hasLength(2));
      });
    });

    group('getSessionsForExercise', () {
      test('returns sessions for an exercise with limit', () async {
        final workout = await createParentWorkout();
        for (var i = 0; i < 5; i++) {
          await repo.createSession(
            newSession(workoutId: workout.id, exerciseId: '17'),
          );
        }

        final sessions = await repo.getSessionsForExercise('17', limit: 3);
        expect(sessions, hasLength(3));
      });
    });

    group('getLastSessionForExercise', () {
      test('returns null when no sessions exist', () async {
        final result = await repo.getLastSessionForExercise('16');
        expect(result, isNull);
      });

      test('returns the most recent session by workout start time', () async {
        // Create two workouts at different times.
        final olderWorkout = Workout(
          id: 'older',
          startedAt: DateTime.utc(2026, 1, 1),
          completedAt: DateTime.utc(2026, 1, 1, 0, 30),
          updatedAt: DateTime.utc(2024),
        );
        final newerWorkout = Workout(
          id: 'newer',
          startedAt: DateTime.utc(2026, 3, 1),
          completedAt: DateTime.utc(2026, 3, 1, 0, 30),
          updatedAt: DateTime.utc(2024),
        );
        await workoutRepo.createWorkout(olderWorkout);
        await workoutRepo.createWorkout(newerWorkout);

        await repo.createSession(
          newSession(
              workoutId: 'older', exerciseId: '16', durationSeconds: 600),
        );
        final newerSession = newSession(
          workoutId: 'newer',
          exerciseId: '16',
          durationSeconds: 900,
        );
        await repo.createSession(newerSession);

        final result = await repo.getLastSessionForExercise('16');
        expect(result, isNotNull);
        expect(result!.id, newerSession.id);
        expect(result.durationSeconds, 900);
      });

      test('only returns sessions for the given exercise', () async {
        final workout = await createParentWorkout();
        await repo.createSession(
          newSession(workoutId: workout.id, exerciseId: '17'),
        );

        final result = await repo.getLastSessionForExercise('16');
        expect(result, isNull);
      });
    });

    group('deleteSession', () {
      test('hard-deletes a session', () async {
        final workout = await createParentWorkout();
        final session = newSession(workoutId: workout.id);
        await repo.createSession(session);
        await repo.deleteSession(session.id);

        final fetched = await repo.getSession(session.id);
        expect(fetched, isNull);
      });
    });

    group('watchSessionsForWorkout', () {
      test('emits when sessions change', () async {
        final workout = await createParentWorkout();

        final emissions = <List<CardioSession>>[];
        final sub =
            repo.watchSessionsForWorkout(workout.id).listen(emissions.add);
        addTearDown(sub.cancel);

        await pumpEventQueue();
        expect(emissions, hasLength(1));
        expect(emissions.first, isEmpty);

        await repo.createSession(newSession(workoutId: workout.id));
        await pumpEventQueue();

        expect(emissions.last, hasLength(1));
      });
    });
  });
}
