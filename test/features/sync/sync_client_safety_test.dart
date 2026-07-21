import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/sync/data/sync_snapshot_serialiser.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_snapshot.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';

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
    test('preserves the local client_id when the incoming row does not win',
        () async {
      // Seed a non-Me client and a local workout it owns, updated more
      // recently than the incoming snapshot row.
      await database.into(database.clients).insert(db.ClientsCompanion.insert(
            id: 'client-X',
            name: 'Client X',
            colour: 0xFF000000,
            createdAt: 0,
          ));
      await database.into(database.workouts).insert(db.WorkoutsCompanion.insert(
            id: 'w1',
            startedAt: 0,
            updatedAt: const Value(100),
            clientId: const Value('client-X'),
          ));

      final incoming = Workout(
        id: 'w1',
        startedAt: start,
        clientId: kSelfClientId,
        updatedAt: start, // well before the local row's updatedAt (epoch 100)
      );

      await serialiser.applyToDatabase(database, snapshotWith([incoming]));

      expect(await clientIdOf('w1'), 'client-X');
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
}
