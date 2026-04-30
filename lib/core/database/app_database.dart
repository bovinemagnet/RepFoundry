import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/body_metrics_table.dart';
import 'tables/cardio_sessions_table.dart';
import 'tables/exercises_table.dart';
import 'tables/personal_records_table.dart';
import 'tables/programme_days_table.dart';
import 'tables/programmes_table.dart';
import 'tables/progression_rules_table.dart';
import 'tables/stretching_sessions_table.dart';
import 'tables/template_exercises_table.dart';
import 'tables/workout_sets_table.dart';
import 'tables/workout_templates_table.dart';
import 'tables/workouts_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  BodyMetrics,
  Exercises,
  Workouts,
  WorkoutSets,
  CardioSessions,
  PersonalRecords,
  WorkoutTemplates,
  TemplateExercises,
  Programmes,
  ProgrammeDays,
  ProgressionRules,
  StretchingSessions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for tests — accepts any [QueryExecutor].
  AppDatabase.forTesting(super.e);

  /// Static accessor for the schema version, usable from non-database code
  /// (e.g. the sync serialiser) without an `AppDatabase` instance.
  static const int schemaVersionConst = 10;

  @override
  int get schemaVersion => schemaVersionConst;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onCreate: (m) async {
          await m.createAll();
          await batch((b) {
            b.insertAll(exercises, _defaultExercises);
          });
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_workout_sets_exercise_timestamp '
              'ON workout_sets (exercise_id, timestamp)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_workout_sets_workout_order '
              'ON workout_sets (workout_id, set_order)',
            );
          }
          if (from < 3) {
            await customStatement(
              'ALTER TABLE exercises ADD COLUMN image_asset TEXT',
            );
            for (final ex in _defaultExercises) {
              final id = ex.id.value;
              final img = ex.imageAsset;
              if (img.present && img.value != null) {
                await customStatement(
                  "UPDATE exercises SET image_asset = '${img.value}' "
                  "WHERE id = '$id'",
                );
              }
            }
          }
          if (from < 4) {
            await customStatement(
              'ALTER TABLE workout_sets ADD COLUMN is_warm_up INTEGER NOT NULL DEFAULT 0',
            );
            await customStatement(
              'ALTER TABLE workout_sets ADD COLUMN group_id TEXT',
            );
            await customStatement(
              'CREATE TABLE IF NOT EXISTS body_metrics ('
              'id TEXT NOT NULL PRIMARY KEY, '
              'date INTEGER NOT NULL, '
              'weight REAL NOT NULL, '
              'body_fat_percent REAL, '
              'notes TEXT'
              ')',
            );
          }
          if (from < 5) {
            await customStatement(
              'CREATE TABLE IF NOT EXISTS programmes ('
              'id TEXT NOT NULL PRIMARY KEY, '
              'name TEXT NOT NULL, '
              'duration_weeks INTEGER NOT NULL, '
              'created_at INTEGER NOT NULL, '
              'updated_at INTEGER NOT NULL'
              ')',
            );
            await customStatement(
              'CREATE TABLE IF NOT EXISTS programme_days ('
              'id TEXT NOT NULL PRIMARY KEY, '
              'programme_id TEXT NOT NULL, '
              'week_number INTEGER NOT NULL, '
              'day_of_week INTEGER NOT NULL, '
              'template_id TEXT NOT NULL, '
              'template_name TEXT NOT NULL'
              ')',
            );
            await customStatement(
              'CREATE TABLE IF NOT EXISTS progression_rules ('
              'id TEXT NOT NULL PRIMARY KEY, '
              'programme_id TEXT NOT NULL, '
              'exercise_id TEXT NOT NULL, '
              'type TEXT NOT NULL, '
              'value REAL NOT NULL, '
              'frequency_weeks INTEGER NOT NULL DEFAULT 1'
              ')',
            );
          }
          if (from < 6) {
            const tablesToAddUpdatedAt = [
              'exercises',
              'workouts',
              'workout_sets',
              'cardio_sessions',
              'personal_records',
              'body_metrics',
              'template_exercises',
              'programme_days',
              'progression_rules',
            ];
            for (final table in tablesToAddUpdatedAt) {
              await customStatement(
                'ALTER TABLE $table ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
              );
            }
          }
          if (from < 7) {
            await customStatement(
              'ALTER TABLE programmes ADD COLUMN started_at INTEGER',
            );
          }
          if (from < 8) {
            await batch((b) {
              b.insertAll(
                exercises,
                _defaultExercises.where((e) =>
                    e.id.value == '19' ||
                    e.id.value == '20' ||
                    e.id.value == '21'),
                mode: InsertMode.insertOrIgnore,
              );
            });
          }
          if (from < 9) {
            await m.createTable(stretchingSessions);
            await m.createIndex(
              Index(
                'idx_stretching_sessions_workout',
                'CREATE INDEX IF NOT EXISTS idx_stretching_sessions_workout '
                    'ON stretching_sessions (workout_id)',
              ),
            );
            await m.createIndex(
              Index(
                'idx_stretching_sessions_type_updated',
                'CREATE INDEX IF NOT EXISTS idx_stretching_sessions_type_updated '
                    'ON stretching_sessions (type, updated_at)',
              ),
            );
          }
          if (from < 10) {
            // Tombstone columns: 9 tables that were missing soft-delete.
            // Exercise / Workout / StretchingSession already have deleted_at.
            const tablesToAddDeletedAt = [
              'workout_sets',
              'cardio_sessions',
              'personal_records',
              'workout_templates',
              'template_exercises',
              'body_metrics',
              'programmes',
              'programme_days',
              'progression_rules',
            ];
            for (final t in tablesToAddDeletedAt) {
              await customStatement(
                'ALTER TABLE $t ADD COLUMN deleted_at INTEGER',
              );
            }

            // Backfill: the v6 migration defaulted updated_at to 0, which
            // poisons last-write-wins (any post-v6 write always beats a
            // pre-v6 row). Where the table carries a meaningful timestamp
            // column, lift updated_at to that value.
            await customStatement(
              "UPDATE workout_sets SET updated_at = "
              "MAX(updated_at, COALESCE(timestamp, 0)) "
              "WHERE updated_at = 0",
            );
            await customStatement(
              "UPDATE personal_records SET updated_at = "
              "MAX(updated_at, COALESCE(achieved_at, 0)) "
              "WHERE updated_at = 0",
            );
            await customStatement(
              "UPDATE body_metrics SET updated_at = "
              "MAX(updated_at, COALESCE(date, 0)) "
              "WHERE updated_at = 0",
            );
            await customStatement(
              "UPDATE workouts SET updated_at = "
              "MAX(updated_at, COALESCE(started_at, 0)) "
              "WHERE updated_at = 0",
            );
            await customStatement(
              "UPDATE workout_templates SET updated_at = "
              "MAX(updated_at, COALESCE(created_at, 0)) "
              "WHERE updated_at = 0",
            );
            await customStatement(
              "UPDATE programmes SET updated_at = "
              "MAX(updated_at, COALESCE(created_at, 0)) "
              "WHERE updated_at = 0",
            );

            // Tables without their own meaningful timestamp: stamp the
            // migration moment so post-migration rows do not always win.
            const migrationNow =
                "CAST((strftime('%s','now') * 1000) AS INTEGER)";
            const tablesWithoutOwnTimestamp = [
              'exercises',
              'cardio_sessions',
              'template_exercises',
              'programme_days',
              'progression_rules',
            ];
            for (final t in tablesWithoutOwnTimestamp) {
              await customStatement(
                'UPDATE $t SET updated_at = $migrationNow '
                'WHERE updated_at = 0',
              );
            }
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'rep_foundry',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}

/// The 21 default exercises seeded on first run.
/// IDs '1'–'21' match the in-memory implementation.
const _defaultExercises = [
  ExercisesCompanion(
    id: Value('1'),
    name: Value('Barbell Bench Press'),
    category: Value('strength'),
    muscleGroup: Value('chest'),
    equipmentType: Value('barbell'),
    imageAsset: Value('assets/images/exercises/1.webp'),
  ),
  ExercisesCompanion(
    id: Value('2'),
    name: Value('Barbell Squat'),
    category: Value('strength'),
    muscleGroup: Value('quadriceps'),
    equipmentType: Value('barbell'),
    imageAsset: Value('assets/images/exercises/2.webp'),
  ),
  ExercisesCompanion(
    id: Value('3'),
    name: Value('Deadlift'),
    category: Value('strength'),
    muscleGroup: Value('back'),
    equipmentType: Value('barbell'),
    imageAsset: Value('assets/images/exercises/3.webp'),
  ),
  ExercisesCompanion(
    id: Value('4'),
    name: Value('Pull-up'),
    category: Value('strength'),
    muscleGroup: Value('back'),
    equipmentType: Value('bodyweight'),
    imageAsset: Value('assets/images/exercises/4.webp'),
  ),
  ExercisesCompanion(
    id: Value('5'),
    name: Value('Overhead Press'),
    category: Value('strength'),
    muscleGroup: Value('shoulders'),
    equipmentType: Value('barbell'),
    imageAsset: Value('assets/images/exercises/5.webp'),
  ),
  ExercisesCompanion(
    id: Value('6'),
    name: Value('Barbell Row'),
    category: Value('strength'),
    muscleGroup: Value('back'),
    equipmentType: Value('barbell'),
    imageAsset: Value('assets/images/exercises/6.webp'),
  ),
  ExercisesCompanion(
    id: Value('7'),
    name: Value('Dumbbell Curl'),
    category: Value('strength'),
    muscleGroup: Value('biceps'),
    equipmentType: Value('dumbbell'),
    imageAsset: Value('assets/images/exercises/7.webp'),
  ),
  ExercisesCompanion(
    id: Value('8'),
    name: Value('Tricep Pushdown'),
    category: Value('strength'),
    muscleGroup: Value('triceps'),
    equipmentType: Value('cable'),
    imageAsset: Value('assets/images/exercises/8.webp'),
  ),
  ExercisesCompanion(
    id: Value('9'),
    name: Value('Incline Dumbbell Press'),
    category: Value('strength'),
    muscleGroup: Value('chest'),
    equipmentType: Value('dumbbell'),
    imageAsset: Value('assets/images/exercises/9.webp'),
  ),
  ExercisesCompanion(
    id: Value('10'),
    name: Value('Leg Press'),
    category: Value('strength'),
    muscleGroup: Value('quadriceps'),
    equipmentType: Value('machine'),
    imageAsset: Value('assets/images/exercises/10.webp'),
  ),
  ExercisesCompanion(
    id: Value('11'),
    name: Value('Romanian Deadlift'),
    category: Value('strength'),
    muscleGroup: Value('hamstrings'),
    equipmentType: Value('barbell'),
    imageAsset: Value('assets/images/exercises/11.webp'),
  ),
  ExercisesCompanion(
    id: Value('12'),
    name: Value('Hip Thrust'),
    category: Value('strength'),
    muscleGroup: Value('glutes'),
    equipmentType: Value('barbell'),
    imageAsset: Value('assets/images/exercises/12.webp'),
  ),
  ExercisesCompanion(
    id: Value('13'),
    name: Value('Lat Pulldown'),
    category: Value('strength'),
    muscleGroup: Value('back'),
    equipmentType: Value('cable'),
    imageAsset: Value('assets/images/exercises/13.webp'),
  ),
  ExercisesCompanion(
    id: Value('14'),
    name: Value('Cable Fly'),
    category: Value('strength'),
    muscleGroup: Value('chest'),
    equipmentType: Value('cable'),
    imageAsset: Value('assets/images/exercises/14.webp'),
  ),
  ExercisesCompanion(
    id: Value('15'),
    name: Value('Plank'),
    category: Value('strength'),
    muscleGroup: Value('core'),
    equipmentType: Value('bodyweight'),
    imageAsset: Value('assets/images/exercises/15.webp'),
  ),
  ExercisesCompanion(
    id: Value('16'),
    name: Value('Treadmill'),
    category: Value('cardio'),
    muscleGroup: Value('cardio'),
    equipmentType: Value('cardioMachine'),
    imageAsset: Value('assets/images/exercises/16.webp'),
  ),
  ExercisesCompanion(
    id: Value('17'),
    name: Value('Stationary Bike'),
    category: Value('cardio'),
    muscleGroup: Value('cardio'),
    equipmentType: Value('cardioMachine'),
    imageAsset: Value('assets/images/exercises/17.webp'),
  ),
  ExercisesCompanion(
    id: Value('18'),
    name: Value('Rowing Machine'),
    category: Value('cardio'),
    muscleGroup: Value('fullBody'),
    equipmentType: Value('cardioMachine'),
    imageAsset: Value('assets/images/exercises/18.webp'),
  ),
  ExercisesCompanion(
    id: Value('19'),
    name: Value('Leg Extensions'),
    category: Value('strength'),
    muscleGroup: Value('quadriceps'),
    equipmentType: Value('machine'),
  ),
  ExercisesCompanion(
    id: Value('20'),
    name: Value('Pec Deck'),
    category: Value('strength'),
    muscleGroup: Value('chest'),
    equipmentType: Value('machine'),
  ),
  ExercisesCompanion(
    id: Value('21'),
    name: Value('Leg Curl'),
    category: Value('strength'),
    muscleGroup: Value('hamstrings'),
    equipmentType: Value('machine'),
  ),
];
