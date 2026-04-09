import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/body_metrics/domain/models/body_metric.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_snapshot.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

void main() {
  group('SyncSnapshot', () {
    final snapshotAt = DateTime.utc(2024, 6, 1, 12, 0);

    group('construction with only required fields', () {
      late SyncSnapshot snapshot;

      setUp(() {
        snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-abc',
          schemaVersion: 1,
        );
      });

      test('stores snapshotAt', () {
        expect(snapshot.snapshotAt, snapshotAt);
      });

      test('stores deviceId', () {
        expect(snapshot.deviceId, 'device-abc');
      });

      test('stores schemaVersion', () {
        expect(snapshot.schemaVersion, 1);
      });

      test('exercises defaults to empty list', () {
        expect(snapshot.exercises, isEmpty);
      });

      test('workouts defaults to empty list', () {
        expect(snapshot.workouts, isEmpty);
      });

      test('workoutSets defaults to empty list', () {
        expect(snapshot.workoutSets, isEmpty);
      });

      test('cardioSessions defaults to empty list', () {
        expect(snapshot.cardioSessions, isEmpty);
      });

      test('personalRecords defaults to empty list', () {
        expect(snapshot.personalRecords, isEmpty);
      });

      test('workoutTemplates defaults to empty list', () {
        expect(snapshot.workoutTemplates, isEmpty);
      });

      test('templateExercises defaults to empty list', () {
        expect(snapshot.templateExercises, isEmpty);
      });

      test('bodyMetrics defaults to empty list', () {
        expect(snapshot.bodyMetrics, isEmpty);
      });

      test('programmes defaults to empty list', () {
        expect(snapshot.programmes, isEmpty);
      });

      test('programmeDays defaults to empty list', () {
        expect(snapshot.programmeDays, isEmpty);
      });

      test('progressionRules defaults to empty list', () {
        expect(snapshot.progressionRules, isEmpty);
      });
    });

    group('construction with non-empty lists', () {
      test('preserves provided exercises list', () {
        final exercise = Exercise.create(
          name: 'Squat',
          category: ExerciseCategory.strength,
          muscleGroup: MuscleGroup.quadriceps,
          equipmentType: EquipmentType.barbell,
        );
        final snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-1',
          schemaVersion: 1,
          exercises: [exercise],
        );

        expect(snapshot.exercises, hasLength(1));
        expect(snapshot.exercises.first, exercise);
      });

      test('preserves provided workouts list', () {
        final workout = Workout.create();
        final snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-1',
          schemaVersion: 1,
          workouts: [workout],
        );

        expect(snapshot.workouts, hasLength(1));
        expect(snapshot.workouts.first, workout);
      });

      test('preserves provided workoutSets list', () {
        final set = WorkoutSet.create(
          workoutId: 'w-1',
          exerciseId: 'e-1',
          setOrder: 1,
          weight: 100.0,
          reps: 5,
        );
        final snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-1',
          schemaVersion: 1,
          workoutSets: [set],
        );

        expect(snapshot.workoutSets, hasLength(1));
        expect(snapshot.workoutSets.first, set);
      });

      test('preserves provided cardioSessions list', () {
        final session = CardioSession.create(
          workoutId: 'w-1',
          exerciseId: 'e-1',
          durationSeconds: 1800,
        );
        final snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-1',
          schemaVersion: 1,
          cardioSessions: [session],
        );

        expect(snapshot.cardioSessions, hasLength(1));
        expect(snapshot.cardioSessions.first, session);
      });

      test('preserves provided personalRecords list', () {
        final pr = PersonalRecord.create(
          exerciseId: 'e-1',
          recordType: RecordType.maxWeight,
          value: 120.0,
        );
        final snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-1',
          schemaVersion: 1,
          personalRecords: [pr],
        );

        expect(snapshot.personalRecords, hasLength(1));
        expect(snapshot.personalRecords.first, pr);
      });

      test('preserves provided workoutTemplates list', () {
        final template = WorkoutTemplate.create(name: 'Push Day');
        final snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-1',
          schemaVersion: 1,
          workoutTemplates: [template],
        );

        expect(snapshot.workoutTemplates, hasLength(1));
        expect(snapshot.workoutTemplates.first, template);
      });

      test('preserves provided bodyMetrics list', () {
        final metric = BodyMetric.create(weight: 80.5);
        final snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-1',
          schemaVersion: 1,
          bodyMetrics: [metric],
        );

        expect(snapshot.bodyMetrics, hasLength(1));
        expect(snapshot.bodyMetrics.first, metric);
      });

      test('preserves provided programmes list', () {
        final programme = Programme.create(
          name: 'Strength Block',
          durationWeeks: 8,
        );
        final snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-1',
          schemaVersion: 1,
          programmes: [programme],
        );

        expect(snapshot.programmes, hasLength(1));
        expect(snapshot.programmes.first, programme);
      });

      test('preserves provided templateExercises list', () {
        final now = DateTime.now().toUtc();
        final templateExercise = TemplateExercise(
          id: 'te-1',
          templateId: 't-1',
          exerciseId: 'e-1',
          exerciseName: 'Deadlift',
          targetSets: 4,
          targetReps: 5,
          orderIndex: 0,
          updatedAt: now,
        );
        final snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-1',
          schemaVersion: 1,
          templateExercises: [templateExercise],
        );

        expect(snapshot.templateExercises, hasLength(1));
        expect(snapshot.templateExercises.first.exerciseName, 'Deadlift');
      });

      test('preserves provided programmeDays list', () {
        final day = ProgrammeDay.create(
          programmeId: 'p-1',
          weekNumber: 1,
          dayOfWeek: DateTime.monday,
          templateId: 't-1',
          templateName: 'Push Day',
        );
        final snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-1',
          schemaVersion: 1,
          programmeDays: [day],
        );

        expect(snapshot.programmeDays, hasLength(1));
        expect(snapshot.programmeDays.first, day);
      });

      test('preserves provided progressionRules list', () {
        final rule = ProgressionRule.create(
          programmeId: 'p-1',
          exerciseId: 'e-1',
          type: ProgressionType.fixedIncrement,
          value: 2.5,
        );
        final snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-1',
          schemaVersion: 1,
          progressionRules: [rule],
        );

        expect(snapshot.progressionRules, hasLength(1));
        expect(snapshot.progressionRules.first, rule);
      });

      test('all list fields populated simultaneously are each preserved', () {
        final exercise = Exercise.create(
          name: 'Bench Press',
          category: ExerciseCategory.strength,
          muscleGroup: MuscleGroup.chest,
          equipmentType: EquipmentType.barbell,
        );
        final workout = Workout.create();
        final snapshot = SyncSnapshot(
          snapshotAt: snapshotAt,
          deviceId: 'device-1',
          schemaVersion: 2,
          exercises: [exercise],
          workouts: [workout],
        );

        expect(snapshot.exercises, hasLength(1));
        expect(snapshot.workouts, hasLength(1));
        // All other lists remain empty
        expect(snapshot.workoutSets, isEmpty);
        expect(snapshot.cardioSessions, isEmpty);
        expect(snapshot.schemaVersion, 2);
      });
    });
  });
}
