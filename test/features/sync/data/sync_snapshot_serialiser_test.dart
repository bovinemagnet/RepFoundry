import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' show AppDatabase;
import 'package:rep_foundry/features/body_metrics/domain/models/body_metric.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';
import 'package:rep_foundry/features/sync/data/sync_snapshot_serialiser.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_snapshot.dart';
import 'package:rep_foundry/features/sync/domain/sync_schema_version_exception.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

void main() {
  final ts = DateTime.utc(2026, 4, 1, 12, 0);
  final tombstone = DateTime.utc(2026, 4, 2, 9, 30);

  late SyncSnapshotSerialiser serialiser;

  setUp(() {
    serialiser = SyncSnapshotSerialiser();
  });

  SyncSnapshot makeFullSnapshot() {
    return SyncSnapshot(
      snapshotAt: ts,
      deviceId: 'device-a',
      schemaVersion: AppDatabase.schemaVersionConst,
      exercises: [
        Exercise(
          id: 'ex-1',
          name: 'Bench',
          category: ExerciseCategory.strength,
          muscleGroup: MuscleGroup.chest,
          equipmentType: EquipmentType.barbell,
          updatedAt: ts,
          deletedAt: tombstone,
        ),
      ],
      workouts: [
        Workout(
          id: 'wo-1',
          startedAt: ts,
          updatedAt: ts,
          deletedAt: tombstone,
        ),
      ],
      workoutSets: [
        WorkoutSet(
          id: 'set-1',
          workoutId: 'wo-1',
          exerciseId: 'ex-1',
          setOrder: 1,
          weight: 100,
          reps: 5,
          timestamp: ts,
          updatedAt: ts,
          deletedAt: tombstone,
        ),
      ],
      cardioSessions: [
        CardioSession(
          id: 'card-1',
          workoutId: 'wo-1',
          exerciseId: 'ex-1',
          durationSeconds: 600,
          updatedAt: ts,
          deletedAt: tombstone,
        ),
      ],
      personalRecords: [
        PersonalRecord(
          id: 'pr-1',
          exerciseId: 'ex-1',
          recordType: RecordType.maxWeight,
          value: 100,
          achievedAt: ts,
          updatedAt: ts,
          deletedAt: tombstone,
        ),
      ],
      workoutTemplates: [
        WorkoutTemplate(
          id: 'tpl-1',
          name: 'Push',
          createdAt: ts,
          updatedAt: ts,
          deletedAt: tombstone,
        ),
      ],
      templateExercises: [
        TemplateExercise(
          id: 'te-1',
          templateId: 'tpl-1',
          exerciseId: 'ex-1',
          exerciseName: 'Bench',
          targetSets: 3,
          targetReps: 5,
          orderIndex: 0,
          updatedAt: ts,
          deletedAt: tombstone,
        ),
      ],
      bodyMetrics: [
        BodyMetric(
          id: 'bm-1',
          date: ts,
          weight: 80,
          updatedAt: ts,
          deletedAt: tombstone,
        ),
      ],
      programmes: [
        Programme(
          id: 'prg-1',
          name: 'Strength',
          durationWeeks: 12,
          createdAt: ts,
          updatedAt: ts,
          deletedAt: tombstone,
        ),
      ],
      programmeDays: [
        ProgrammeDay(
          id: 'pd-1',
          programmeId: 'prg-1',
          weekNumber: 1,
          dayOfWeek: 1,
          templateId: 'tpl-1',
          templateName: 'Push',
          updatedAt: ts,
          deletedAt: tombstone,
        ),
      ],
      progressionRules: [
        ProgressionRule(
          id: 'pr-rule-1',
          programmeId: 'prg-1',
          exerciseId: 'ex-1',
          type: ProgressionType.fixedIncrement,
          value: 2.5,
          updatedAt: ts,
          deletedAt: tombstone,
        ),
      ],
      stretchingSessions: [
        StretchingSession(
          id: 'st-1',
          workoutId: 'wo-1',
          type: 'pigeon',
          durationSeconds: 60,
          entryMethod: StretchingEntryMethod.timer,
          startedAt: ts,
          endedAt: ts.add(const Duration(seconds: 60)),
          bodyArea: StretchingBodyArea.hips,
          side: StretchingSide.left,
          updatedAt: ts,
          deletedAt: tombstone,
        ),
      ],
    );
  }

  group('SyncSnapshotSerialiser JSON round-trip', () {
    test('preserves deletedAt for every entity type', () {
      final original = makeFullSnapshot();

      final json = serialiser.toJson(original);
      final round = serialiser.fromJson(json);

      // Every list should round-trip its single tombstoned entity.
      expect(round.exercises.single.deletedAt, equals(tombstone));
      expect(round.workouts.single.deletedAt, equals(tombstone));
      expect(round.workoutSets.single.deletedAt, equals(tombstone));
      expect(round.cardioSessions.single.deletedAt, equals(tombstone));
      expect(round.personalRecords.single.deletedAt, equals(tombstone));
      expect(round.workoutTemplates.single.deletedAt, equals(tombstone));
      expect(round.templateExercises.single.deletedAt, equals(tombstone));
      expect(round.bodyMetrics.single.deletedAt, equals(tombstone));
      expect(round.programmes.single.deletedAt, equals(tombstone));
      expect(round.programmeDays.single.deletedAt, equals(tombstone));
      expect(round.progressionRules.single.deletedAt, equals(tombstone));
      expect(round.stretchingSessions.single.deletedAt, equals(tombstone));
    });

    test('stretching sessions survive a full JSON round-trip', () {
      final original = makeFullSnapshot();

      final json = serialiser.toJson(original);
      final round = serialiser.fromJson(json);

      final s = round.stretchingSessions.single;
      expect(s.id, 'st-1');
      expect(s.type, 'pigeon');
      expect(s.bodyArea, StretchingBodyArea.hips);
      expect(s.side, StretchingSide.left);
      expect(s.entryMethod, StretchingEntryMethod.timer);
      expect(s.durationSeconds, 60);
    });

    test('schemaVersion in JSON matches AppDatabase.schemaVersionConst', () {
      final original = makeFullSnapshot();
      final json = serialiser.toJson(original);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['schemaVersion'], equals(AppDatabase.schemaVersionConst));
    });

    test('older snapshot without stretchingSessions key still parses', () {
      // Simulate a snapshot from an older client that did not write the
      // stretchingSessions key. The serialiser must accept it and produce
      // an empty list rather than throwing.
      final json = jsonEncode({
        'version': 1,
        'schemaVersion': AppDatabase.schemaVersionConst - 1,
        'snapshotAt': ts.toIso8601String(),
        'deviceId': 'old-device',
      });

      final round = serialiser.fromJson(json);
      expect(round.stretchingSessions, isEmpty);
      expect(round.exercises, isEmpty);
    });
  });

  group('SyncSnapshotSerialiser schema-version validation', () {
    test('fromJson rejects snapshot with schemaVersion > local', () {
      final json = jsonEncode({
        'version': 1,
        'schemaVersion': AppDatabase.schemaVersionConst + 1,
        'snapshotAt': ts.toIso8601String(),
        'deviceId': 'newer-device',
      });

      expect(
        () => serialiser.fromJson(json),
        throwsA(isA<SyncSchemaVersionException>()),
      );
    });

    test('fromJson accepts snapshot with schemaVersion < local', () {
      final json = jsonEncode({
        'version': 1,
        'schemaVersion': 1,
        'snapshotAt': ts.toIso8601String(),
        'deviceId': 'older-device',
      });

      final round = serialiser.fromJson(json);
      expect(round.deviceId, 'older-device');
      expect(round.schemaVersion, 1);
    });

    test('SyncSchemaVersionException carries user-facing message', () {
      final exception = SyncSchemaVersionException.tooNew(
        AppDatabase.schemaVersionConst + 1,
        AppDatabase.schemaVersionConst,
      );

      expect(exception.message, contains('newer version'));
      expect(exception.message, contains('Please update'));
    });
  });
}
