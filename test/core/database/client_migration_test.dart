import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/domain/models/client.dart';

void main() {
  test('fresh database has a Me self-client and scoped tables default to it',
      () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    // Me client exists and is self.
    final clients = await database.select(database.clients).get();
    expect(clients, hasLength(1));
    expect(clients.single.id, kSelfClientId);
    expect(clients.single.isSelf, isTrue);

    // A workout inserted without a client_id defaults to Me.
    await database.customStatement(
      "INSERT INTO workouts (id, started_at, updated_at) VALUES ('w1', 0, 0)",
    );
    final row = await database
        .customSelect(
          "SELECT client_id FROM workouts WHERE id = 'w1'",
        )
        .getSingle();
    expect(row.read<String>('client_id'), kSelfClientId);

    expect(database.schemaVersion, 13);
  });

  test(
      'v12 -> v13 upgrade backfills client_id on existing rows and seeds '
      'the Me client', () async {
    // Builds the pre-v13 ("v12") shape of the four coach-scoped tables by
    // hand — i.e. the current Drift table definitions minus the client_id
    // column the v13 migration adds — seeds one legacy row in each, then
    // stamps `PRAGMA user_version = 12`. The `setup` callback runs on the
    // raw sqlite3 connection *before* drift is "fully ready", so when the
    // AppDatabase below (declared schemaVersion 13) makes its first query
    // it finds a stored version of 12 and genuinely runs
    // `onUpgrade(m, from: 12, to: 13)` — not `onCreate`.
    final database = db.AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('''
            CREATE TABLE workouts (
              id TEXT NOT NULL PRIMARY KEY,
              started_at INTEGER NOT NULL,
              completed_at INTEGER NULL,
              template_id TEXT NULL,
              notes TEXT NULL,
              updated_at INTEGER NOT NULL DEFAULT 0,
              deleted_at INTEGER NULL
            )
          ''');
          rawDb.execute('''
            CREATE TABLE cardio_sessions (
              id TEXT NOT NULL PRIMARY KEY,
              workout_id TEXT NOT NULL,
              exercise_id TEXT NOT NULL,
              duration_seconds INTEGER NOT NULL,
              distance_meters REAL NULL,
              incline REAL NULL,
              avg_heart_rate INTEGER NULL,
              updated_at INTEGER NOT NULL DEFAULT 0,
              deleted_at INTEGER NULL
            )
          ''');
          rawDb.execute('''
            CREATE TABLE personal_records (
              id TEXT NOT NULL PRIMARY KEY,
              exercise_id TEXT NOT NULL,
              record_type TEXT NOT NULL,
              value REAL NOT NULL,
              achieved_at INTEGER NOT NULL,
              workout_set_id TEXT NULL,
              updated_at INTEGER NOT NULL DEFAULT 0,
              deleted_at INTEGER NULL
            )
          ''');
          rawDb.execute('''
            CREATE TABLE body_metrics (
              id TEXT NOT NULL PRIMARY KEY,
              date INTEGER NOT NULL,
              weight REAL NOT NULL,
              body_fat_percent REAL NULL,
              notes TEXT NULL,
              updated_at INTEGER NOT NULL DEFAULT 0,
              deleted_at INTEGER NULL
            )
          ''');

          // One pre-existing row per table, as a real upgrading install
          // would have accumulated before the roster feature shipped.
          rawDb.execute(
            "INSERT INTO workouts (id, started_at, updated_at) "
            "VALUES ('w-legacy', 1000, 1000)",
          );
          rawDb.execute(
            "INSERT INTO cardio_sessions "
            "(id, workout_id, exercise_id, duration_seconds, updated_at) "
            "VALUES ('c-legacy', 'w-legacy', '16', 1800, 1000)",
          );
          rawDb.execute(
            "INSERT INTO personal_records "
            "(id, exercise_id, record_type, value, achieved_at, updated_at) "
            "VALUES ('pr-legacy', '1', 'maxWeight', 100.0, 1000, 1000)",
          );
          rawDb.execute(
            "INSERT INTO body_metrics (id, date, weight, updated_at) "
            "VALUES ('bm-legacy', 1000, 80.0, 1000)",
          );

          rawDb.execute('PRAGMA user_version = 12');
        },
      ),
    );
    addTearDown(database.close);

    // Any query forces drift to run its migration first.
    final clients = await database.select(database.clients).get();

    // The upgrade — not onCreate — landed the schema at v13.
    expect(database.schemaVersion, 13);

    // The self ("Me") client was seeded by the v13 upgrade branch.
    expect(clients, hasLength(1));
    expect(clients.single.id, kSelfClientId);
    expect(clients.single.isSelf, isTrue);

    // The 3 new tables exist and are queryable.
    await database.select(database.clientPlanAssignments).get();
    await database.select(database.healthProfiles).get();

    // Pre-existing rows in all 4 coach-scoped tables backfilled to Me via
    // the `ALTER TABLE ... ADD COLUMN client_id ... DEFAULT` statements.
    final workoutRow = await (database.select(database.workouts)
          ..where((t) => t.id.equals('w-legacy')))
        .getSingle();
    expect(workoutRow.clientId, kSelfClientId);

    final cardioRow = await (database.select(database.cardioSessions)
          ..where((t) => t.id.equals('c-legacy')))
        .getSingle();
    expect(cardioRow.clientId, kSelfClientId);

    final prRow = await (database.select(database.personalRecords)
          ..where((t) => t.id.equals('pr-legacy')))
        .getSingle();
    expect(prRow.clientId, kSelfClientId);

    final bodyMetricRow = await (database.select(database.bodyMetrics)
          ..where((t) => t.id.equals('bm-legacy')))
        .getSingle();
    expect(bodyMetricRow.clientId, kSelfClientId);
  });
}
