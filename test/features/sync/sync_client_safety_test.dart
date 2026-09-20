import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/sync/data/sync_snapshot_serialiser.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_snapshot.dart';
import 'package:rep_foundry/features/body_metrics/data/drift_body_metric_repository.dart';
import 'package:rep_foundry/features/body_metrics/domain/models/body_metric.dart';
import 'package:rep_foundry/features/cardio/data/drift_cardio_session_repository.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/history/data/drift_personal_record_repository.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/stretching/data/drift_stretching_session_repository.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';
import 'package:rep_foundry/features/workout/data/drift_workout_repository.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

/// Locks in the sync-safety guarantee: the sync companions in
/// [SyncSnapshotSerialiser.applyToDatabase] deliberately omit `clientId`, so
/// an existing row keeps its own client on conflict, and a brand-new row
/// falls back to the `client_id` column's DB-level default (the "Me"
/// client). Applying a snapshot must never reassign a row's ownership.
void main() {
  late db.AppDatabase database;
  late SyncSnapshotSerialiser serialiser;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    serialiser = SyncSnapshotSerialiser();
  });

  tearDown(() => database.close());

  final start = DateTime.utc(2026, 4, 30, 9, 0);

  SyncSnapshot snapshotWith(List<Workout> workouts) => SyncSnapshot(
        snapshotAt: DateTime.utc(2026, 4, 30, 12, 0),
        deviceId: 'remote-device',
        schemaVersion: db.AppDatabase.schemaVersionConst,
        workouts: workouts,
      );

  Future<String> clientIdOf(String workoutId) async {
    final row = await database
        .customSelect(
          "SELECT client_id FROM workouts WHERE id = '$workoutId'",
        )
        .getSingle();
    return row.read<String>('client_id');
  }

  group('SyncSnapshotSerialiser.applyToDatabase – client_id sync-safety', () {
    test(
        'blocks the write entirely (row untouched) when the incoming row '
        'does not win', () async {
      // Seed a non-Me client and a local workout it owns, updated more
      // recently than the incoming snapshot row, so the guarded upsert's
      // WHERE excluded.updated_at > updated_at is FALSE and the write never
      // happens.
      final localUpdatedAt = DateTime.utc(2026, 4, 30, 10, 0);
      await database.into(database.clients).insert(db.ClientsCompanion.insert(
            id: 'client-X',
            name: 'Client X',
            colour: 0xFF000000,
            createdAt: 0,
          ));
      await database.into(database.workouts).insert(db.WorkoutsCompanion.insert(
            id: 'w1',
            startedAt: 0,
            notes: const Value('local-original'),
            updatedAt: Value(localUpdatedAt.millisecondsSinceEpoch),
            clientId: const Value('client-X'),
          ));

      // Incoming row is strictly older than the local row, so the guard
      // blocks the write and the local row must remain untouched.
      final incoming = Workout(
        id: 'w1',
        startedAt: start,
        notes: 'incoming-should-be-ignored',
        clientId: kSelfClientId,
        updatedAt: start, // one hour before localUpdatedAt
      );

      await serialiser.applyToDatabase(database, snapshotWith([incoming]));

      final row = await database.select(database.workouts).getSingle();
      expect(row.clientId, 'client-X'); // ownership untouched
      expect(row.notes, 'local-original'); // write was blocked entirely
    });

    test(
        'preserves the local client_id even when the incoming row does win '
        '(companion omits clientId entirely)', () async {
      await database.into(database.clients).insert(db.ClientsCompanion.insert(
            id: 'client-X',
            name: 'Client X',
            colour: 0xFF000000,
            createdAt: 0,
          ));
      await database.into(database.workouts).insert(db.WorkoutsCompanion.insert(
            id: 'w1',
            startedAt: 0,
            notes: const Value('before'),
            updatedAt: const Value(100),
            clientId: const Value('client-X'),
          ));

      // Incoming row is strictly newer, so the guarded upsert DOES overwrite
      // — but its clientId ('some-other-id', deliberately not Me and not
      // client-X) must never reach the row, because the companion omits it.
      final incoming = Workout(
        id: 'w1',
        startedAt: start,
        notes: 'after',
        clientId: 'some-other-id',
        updatedAt: DateTime.utc(2026, 4, 30, 11, 0),
      );

      await serialiser.applyToDatabase(database, snapshotWith([incoming]));

      final row = await database.select(database.workouts).getSingle();
      expect(row.notes, 'after'); // overwrite did happen
      expect(row.clientId, 'client-X'); // ownership untouched
    });

    test('a brand-new row falls back to the Me client via the DB default',
        () async {
      // Not present locally, and its domain clientId ('some-other-id') is
      // deliberately not Me — proving the serialiser never writes clientId,
      // rather than coincidentally matching Me.
      final incoming = Workout(
        id: 'w2',
        startedAt: start,
        clientId: 'some-other-id',
        updatedAt: start,
      );

      await serialiser.applyToDatabase(database, snapshotWith([incoming]));

      expect(await clientIdOf('w2'), kSelfClientId);
    });
  });

  group('SyncSnapshotSerialiser.createFromDatabase – Me only', () {
    // The snapshot carries no roster and no ownership, so any other
    // client's rows would be re-owned by Me on the receiving device. Until
    // the snapshot can carry ownership, only Me's scoped rows leave the
    // device.
    test('leaves other clients\' scoped rows out of the snapshot', () async {
      await database.into(database.clients).insert(db.ClientsCompanion.insert(
          id: 'alice', name: 'Alice', colour: 0, createdAt: 0));
      final workouts = DriftWorkoutRepository(database);
      final mine = await workouts.createWorkout(Workout.create());
      final hers =
          await workouts.createWorkout(Workout.create(clientId: 'alice'));
      for (final w in [mine, hers]) {
        await workouts.addSet(WorkoutSet.create(
            workoutId: w.id, exerciseId: '1', setOrder: 1, weight: 1, reps: 1));
        await DriftStretchingSessionRepository(database).createSession(
          StretchingSession.create(
            workoutId: w.id,
            type: 'pigeon',
            durationSeconds: 30,
            entryMethod: StretchingEntryMethod.manual,
          ),
        );
      }
      final cardio = DriftCardioSessionRepository(database);
      await cardio.createSession(CardioSession.create(
          workoutId: mine.id, exerciseId: '1', durationSeconds: 60));
      await cardio.createSession(CardioSession.create(
          workoutId: hers.id,
          exerciseId: '1',
          durationSeconds: 60,
          clientId: 'alice'));
      final prs = DriftPersonalRecordRepository(database);
      await prs.createRecord(PersonalRecord.create(
          exerciseId: '1', recordType: RecordType.maxWeight, value: 1));
      await prs.createRecord(PersonalRecord.create(
          exerciseId: '1',
          recordType: RecordType.maxWeight,
          value: 1,
          clientId: 'alice'));
      final metrics = DriftBodyMetricRepository(database);
      await metrics.create(BodyMetric.create(weight: 70));
      await metrics.create(BodyMetric.create(weight: 60, clientId: 'alice'));

      final snapshot =
          await serialiser.createFromDatabase(database, deviceId: 'd');

      expect(snapshot.workouts.map((w) => w.id), [mine.id]);
      expect(snapshot.workoutSets.map((s) => s.workoutId), [mine.id]);
      expect(snapshot.stretchingSessions.map((s) => s.workoutId), [mine.id]);
      expect(snapshot.cardioSessions.map((c) => c.workoutId), [mine.id]);
      expect(snapshot.personalRecords.map((p) => p.clientId), [kSelfClientId]);
      expect(snapshot.bodyMetrics.map((m) => m.clientId), [kSelfClientId]);
    });
  });
}
