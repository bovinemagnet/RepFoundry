import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/stretching/data/drift_stretching_session_repository.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';
import 'package:rep_foundry/features/sync/data/sync_snapshot_serialiser.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_snapshot.dart';
import 'package:rep_foundry/features/workout/data/drift_workout_repository.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';

/// Integration test: exercise [SyncSnapshotSerialiser.applyToDatabase] for
/// stretching sessions against an in-memory [db.AppDatabase]. The
/// stretching upsert path was added in the cloud-sync correctness sprint
/// and otherwise has no test coverage that touches a real DB.
void main() {
  late db.AppDatabase database;
  late SyncSnapshotSerialiser serialiser;
  late DriftWorkoutRepository workoutRepo;
  late DriftStretchingSessionRepository stretchingRepo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    serialiser = SyncSnapshotSerialiser();
    workoutRepo = DriftWorkoutRepository(database);
    stretchingRepo = DriftStretchingSessionRepository(database);
  });

  tearDown(() => database.close());

  Future<Workout> seedParentWorkout() async {
    final workout = Workout.create();
    await workoutRepo.createWorkout(workout);
    return workout;
  }

  StretchingSession buildSession({
    required String workoutId,
    String id = 'st-1',
    String type = 'pigeon',
    int durationSeconds = 60,
    StretchingEntryMethod entryMethod = StretchingEntryMethod.timer,
    StretchingBodyArea? bodyArea = StretchingBodyArea.hips,
    StretchingSide? side = StretchingSide.left,
    DateTime? deletedAt,
    String? customName,
    String? notes,
    DateTime? updatedAt,
  }) {
    final start = DateTime.utc(2026, 4, 30, 10, 0);
    return StretchingSession(
      id: id,
      workoutId: workoutId,
      type: type,
      customName: customName,
      bodyArea: bodyArea,
      side: side,
      durationSeconds: durationSeconds,
      startedAt: start,
      endedAt: start.add(Duration(seconds: durationSeconds)),
      entryMethod: entryMethod,
      notes: notes,
      updatedAt: updatedAt ?? start,
      deletedAt: deletedAt,
    );
  }

  SyncSnapshot snapshotWith(List<StretchingSession> sessions) {
    return SyncSnapshot(
      snapshotAt: DateTime.utc(2026, 4, 30, 12, 0),
      deviceId: 'remote-device',
      schemaVersion: db.AppDatabase.schemaVersionConst,
      stretchingSessions: sessions,
    );
  }

  SyncSnapshot snapshotWithWorkouts(List<Workout> workouts) {
    return SyncSnapshot(
      snapshotAt: DateTime.utc(2026, 4, 30, 12, 0),
      deviceId: 'remote-device',
      schemaVersion: db.AppDatabase.schemaVersionConst,
      workouts: workouts,
    );
  }

  Workout buildWorkout({
    String id = 'w-guard',
    String? notes,
    required DateTime updatedAt,
  }) {
    return Workout(
      id: id,
      startedAt: DateTime.utc(2026, 4, 30, 9, 0),
      notes: notes,
      clientId: kSelfClientId,
      updatedAt: updatedAt,
    );
  }

  group('SyncSnapshotSerialiser.applyToDatabase – stretching', () {
    test('inserts a stretching session that did not exist locally', () async {
      final workout = await seedParentWorkout();
      final incoming = buildSession(workoutId: workout.id);

      await serialiser.applyToDatabase(database, snapshotWith([incoming]));

      final raw = await database.select(database.stretchingSessions).get();
      expect(raw, hasLength(1));
      final row = raw.single;
      expect(row.id, 'st-1');
      expect(row.workoutId, workout.id);
      expect(row.type, 'pigeon');
      expect(row.bodyArea, 'hips');
      expect(row.side, 'left');
      expect(row.entryMethod, 'timer');
      expect(row.durationSeconds, 60);
      expect(row.startedAt, isNotNull);
      expect(row.endedAt, isNotNull);
      expect(row.deletedAt, isNull);
    });

    test('persists nullable enum + custom-name fields correctly', () async {
      final workout = await seedParentWorkout();
      final incoming = buildSession(
        workoutId: workout.id,
        id: 'st-custom',
        type: 'custom',
        customName: 'Wrist circles',
        bodyArea: null,
        side: null,
        entryMethod: StretchingEntryMethod.untimed,
        durationSeconds: 0,
      );

      await serialiser.applyToDatabase(database, snapshotWith([incoming]));

      final fetched = await stretchingRepo.getSession('st-custom');
      expect(fetched, isNotNull);
      expect(fetched!.type, 'custom');
      expect(fetched.customName, 'Wrist circles');
      expect(fetched.bodyArea, isNull);
      expect(fetched.side, isNull);
      expect(fetched.entryMethod, StretchingEntryMethod.untimed);
    });

    test('upserts on conflict: existing local row gets updated fields',
        () async {
      final workout = await seedParentWorkout();

      // Seed local row.
      final original = buildSession(
        workoutId: workout.id,
        notes: 'before',
      );
      await stretchingRepo.createSession(original);

      // Apply a snapshot that carries the same id with new field values and
      // a newer updatedAt (older or equal timestamps must not overwrite).
      final updated = buildSession(
        workoutId: workout.id,
        notes: 'after',
        durationSeconds: 90,
        updatedAt: DateTime.utc(2026, 4, 30, 10, 5),
      );
      await serialiser.applyToDatabase(database, snapshotWith([updated]));

      // The local repo must observe the merged values.
      final fetched = await stretchingRepo.getSession('st-1');
      expect(fetched, isNotNull);
      expect(fetched!.notes, 'after');
      expect(fetched.durationSeconds, 90);

      // Only one row in the table (upsert, not insert).
      final raw = await database.select(database.stretchingSessions).get();
      expect(raw, hasLength(1));
    });

    test('round-trips deletedAt when applying a tombstoned session', () async {
      final workout = await seedParentWorkout();
      final tombstoned = buildSession(
        workoutId: workout.id,
        deletedAt: DateTime.utc(2026, 4, 30, 11, 0),
      );

      await serialiser.applyToDatabase(database, snapshotWith([tombstoned]));

      // Row exists in the DB with deletedAt set.
      final raw = await database.select(database.stretchingSessions).get();
      expect(raw, hasLength(1));
      expect(raw.single.deletedAt, isNotNull);

      // Public reads (which filter deletedAt IS NULL) hide the tombstone.
      final visible = await stretchingRepo.getSessionsForWorkout(workout.id);
      expect(visible, isEmpty);
    });

    test('createFromDatabase round-trips a real stretching session', () async {
      // End-to-end: seed via the repo, snapshot via the serialiser, then
      // apply that snapshot to a fresh DB and confirm the row arrives.
      final workout = await seedParentWorkout();
      final session = StretchingSession.create(
        workoutId: workout.id,
        type: 'frontSplits',
        durationSeconds: 120,
        entryMethod: StretchingEntryMethod.manual,
        bodyArea: StretchingBodyArea.hamstrings,
        notes: 'tight',
      );
      await stretchingRepo.createSession(session);

      // Snapshot the source DB.
      final snapshot = await serialiser.createFromDatabase(
        database,
        deviceId: 'source-device',
      );
      expect(snapshot.stretchingSessions, hasLength(1));

      // Apply to a fresh DB.
      final destination = db.AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(destination.close);
      // Seed the parent workout in the destination too (FK requirement).
      await DriftWorkoutRepository(destination).createWorkout(workout);
      await serialiser.applyToDatabase(destination, snapshot);

      final landed =
          await DriftStretchingSessionRepository(destination).getSession(
        session.id,
      );
      expect(landed, isNotNull);
      expect(landed!.type, 'frontSplits');
      expect(landed.durationSeconds, 120);
      expect(landed.entryMethod, StretchingEntryMethod.manual);
      expect(landed.bodyArea, StretchingBodyArea.hamstrings);
      expect(landed.notes, 'tight');
    });
  });

  group('SyncSnapshotSerialiser.applyToDatabase – updatedAt guard', () {
    final t1 = DateTime.utc(2026, 4, 30, 10, 0);
    final t2 = DateTime.utc(2026, 4, 30, 11, 0);
    final t3 = DateTime.utc(2026, 4, 30, 12, 0);

    Future<String?> workoutNotes(String id) async {
      final rows = await database.select(database.workouts).get();
      return rows.singleWhere((r) => r.id == id).notes;
    }

    test('does not overwrite a local row with a newer updatedAt', () async {
      // Local row edited at t2 (e.g. by the user while a sync was in
      // flight); the incoming snapshot still carries the stale t1 value.
      await serialiser.applyToDatabase(
        database,
        snapshotWithWorkouts(
            [buildWorkout(notes: 'fresh edit', updatedAt: t2)]),
      );

      await serialiser.applyToDatabase(
        database,
        snapshotWithWorkouts([buildWorkout(notes: 'stale', updatedAt: t1)]),
      );

      expect(await workoutNotes('w-guard'), 'fresh edit');
    });

    test('a tie on updatedAt keeps the local row', () async {
      await serialiser.applyToDatabase(
        database,
        snapshotWithWorkouts([buildWorkout(notes: 'local', updatedAt: t2)]),
      );

      await serialiser.applyToDatabase(
        database,
        snapshotWithWorkouts(
            [buildWorkout(notes: 'remote tie', updatedAt: t2)]),
      );

      expect(await workoutNotes('w-guard'), 'local');
    });

    test('a strictly newer incoming row still overwrites', () async {
      await serialiser.applyToDatabase(
        database,
        snapshotWithWorkouts([buildWorkout(notes: 'old', updatedAt: t1)]),
      );

      await serialiser.applyToDatabase(
        database,
        snapshotWithWorkouts([buildWorkout(notes: 'newer', updatedAt: t3)]),
      );

      expect(await workoutNotes('w-guard'), 'newer');
    });
  });
}
