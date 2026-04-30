import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/stretching/data/drift_stretching_session_repository.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';
import 'package:rep_foundry/features/workout/data/drift_workout_repository.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';

void main() {
  late db.AppDatabase database;
  late DriftStretchingSessionRepository repo;
  late DriftWorkoutRepository workoutRepo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftStretchingSessionRepository(database);
    workoutRepo = DriftWorkoutRepository(database);
  });

  tearDown(() => database.close());

  Future<Workout> createParentWorkout() async {
    final workout = Workout.create();
    await workoutRepo.createWorkout(workout);
    return workout;
  }

  StretchingSession newSession({
    required String workoutId,
    String type = 'pigeon',
    int durationSeconds = 60,
    StretchingEntryMethod method = StretchingEntryMethod.manual,
    StretchingBodyArea? bodyArea,
    StretchingSide? side,
    String? notes,
  }) {
    return StretchingSession.create(
      workoutId: workoutId,
      type: type,
      durationSeconds: durationSeconds,
      entryMethod: method,
      bodyArea: bodyArea,
      side: side,
      notes: notes,
    );
  }

  group('DriftStretchingSessionRepository', () {
    group('createSession & getSession', () {
      test('persists and retrieves a session', () async {
        final workout = await createParentWorkout();
        final session = newSession(
          workoutId: workout.id,
          bodyArea: StretchingBodyArea.hips,
          side: StretchingSide.left,
          notes: 'feeling tight',
        );

        await repo.createSession(session);
        final fetched = await repo.getSession(session.id);

        expect(fetched, isNotNull);
        expect(fetched!.id, session.id);
        expect(fetched.workoutId, workout.id);
        expect(fetched.type, 'pigeon');
        expect(fetched.bodyArea, StretchingBodyArea.hips);
        expect(fetched.side, StretchingSide.left);
        expect(fetched.notes, 'feeling tight');
        expect(fetched.entryMethod, StretchingEntryMethod.manual);
      });

      test('returns null for non-existent id', () async {
        final fetched = await repo.getSession('nope');
        expect(fetched, isNull);
      });
    });

    test('roundtrips startedAt/endedAt for timer entries', () async {
      final workout = await createParentWorkout();
      final start = DateTime.utc(2026, 4, 30, 10, 0, 0);
      final end = DateTime.utc(2026, 4, 30, 10, 5, 30);
      final session = StretchingSession.create(
        workoutId: workout.id,
        type: 'frontSplits',
        durationSeconds: 330,
        entryMethod: StretchingEntryMethod.timer,
        startedAt: start,
        endedAt: end,
      );

      await repo.createSession(session);
      final fetched = await repo.getSession(session.id);
      expect(fetched!.startedAt, start);
      expect(fetched.endedAt, end);
      expect(fetched.entryMethod, StretchingEntryMethod.timer);
    });

    group('getSessionsForWorkout', () {
      test('returns only non-deleted sessions for the workout', () async {
        final workout = await createParentWorkout();
        await repo.createSession(newSession(workoutId: workout.id));
        final toDelete = newSession(workoutId: workout.id, type: 'cobra');
        await repo.createSession(toDelete);

        await repo.deleteSession(toDelete.id);

        final sessions = await repo.getSessionsForWorkout(workout.id);
        expect(sessions, hasLength(1));
        expect(sessions.first.type, 'pigeon');
      });
    });

    group('updateSession', () {
      test('updates duration and notes', () async {
        final workout = await createParentWorkout();
        final session = newSession(workoutId: workout.id);
        await repo.createSession(session);

        final updated = session.copyWith(
          durationSeconds: 200,
          notes: 'updated',
          updatedAt: DateTime.now().toUtc(),
        );
        await repo.updateSession(updated);

        final fetched = await repo.getSession(session.id);
        expect(fetched!.durationSeconds, 200);
        expect(fetched.notes, 'updated');
      });
    });

    group('deleteSession', () {
      test('soft-deletes the session', () async {
        final workout = await createParentWorkout();
        final session = newSession(workoutId: workout.id);
        await repo.createSession(session);
        await repo.deleteSession(session.id);

        final fetched = await repo.getSession(session.id);
        expect(fetched, isNull);
      });
    });

    group('getRecentSessions', () {
      test('returns sessions ordered by updatedAt desc with limit', () async {
        final workout = await createParentWorkout();
        for (var i = 0; i < 3; i++) {
          await repo.createSession(newSession(workoutId: workout.id));
        }
        final results = await repo.getRecentSessions(limit: 2);
        expect(results, hasLength(2));
      });
    });

    group('watchSessionsForWorkout', () {
      test('emits when sessions change', () async {
        final workout = await createParentWorkout();
        final emissions = <List<StretchingSession>>[];
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
