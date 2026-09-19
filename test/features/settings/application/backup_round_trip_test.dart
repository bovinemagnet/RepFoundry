import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/body_metrics/data/drift_body_metric_repository.dart';
import 'package:rep_foundry/features/body_metrics/domain/models/body_metric.dart';
import 'package:rep_foundry/features/cardio/data/drift_cardio_session_repository.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/clients/data/drift_client_repository.dart';
import 'package:rep_foundry/features/clients/data/drift_health_profile_repository.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/exercises/data/drift_exercise_repository.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/data/drift_personal_record_repository.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/programmes/data/drift_programme_repository.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';
import 'package:rep_foundry/features/settings/application/export_data_use_case.dart';
import 'package:rep_foundry/features/settings/application/import_data_use_case.dart';
import 'package:rep_foundry/features/stretching/data/drift_stretching_session_repository.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';
import 'package:rep_foundry/features/templates/data/drift_workout_template_repository.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/features/workout/data/drift_workout_repository.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

/// Everything a backup must restore, wired to one database.
class _Repos {
  _Repos(this.database)
      : workouts = DriftWorkoutRepository(database),
        exercises = DriftExerciseRepository(database),
        cardio = DriftCardioSessionRepository(database),
        prs = DriftPersonalRecordRepository(database),
        stretching = DriftStretchingSessionRepository(database),
        clients = DriftClientRepository(database),
        healthProfiles = DriftHealthProfileRepository(database),
        templates = DriftWorkoutTemplateRepository(database),
        programmes = DriftProgrammeRepository(database),
        bodyMetrics = DriftBodyMetricRepository(database);

  final db.AppDatabase database;
  final DriftWorkoutRepository workouts;
  final DriftExerciseRepository exercises;
  final DriftCardioSessionRepository cardio;
  final DriftPersonalRecordRepository prs;
  final DriftStretchingSessionRepository stretching;
  final DriftClientRepository clients;
  final DriftHealthProfileRepository healthProfiles;
  final DriftWorkoutTemplateRepository templates;
  final DriftProgrammeRepository programmes;
  final DriftBodyMetricRepository bodyMetrics;

  ExportDataUseCase get exporter => ExportDataUseCase(
        workoutRepository: workouts,
        exerciseRepository: exercises,
        cardioSessionRepository: cardio,
        personalRecordRepository: prs,
        stretchingSessionRepository: stretching,
        clientRepository: clients,
        bodyMetricRepository: bodyMetrics,
        healthProfileRepository: healthProfiles,
        workoutTemplateRepository: templates,
        programmeRepository: programmes,
      );

  ImportDataUseCase get importer => ImportDataUseCase(
        workoutRepository: workouts,
        exerciseRepository: exercises,
        cardioSessionRepository: cardio,
        personalRecordRepository: prs,
        stretchingSessionRepository: stretching,
        clientRepository: clients,
        healthProfileRepository: healthProfiles,
        workoutTemplateRepository: templates,
        programmeRepository: programmes,
        bodyMetricRepository: bodyMetrics,
      );
}

void main() {
  late _Repos source;
  late _Repos target;

  setUp(() {
    source = _Repos(db.AppDatabase.forTesting(NativeDatabase.memory()));
    target = _Repos(db.AppDatabase.forTesting(NativeDatabase.memory()));
  });

  tearDown(() async {
    await source.database.close();
    await target.database.close();
  });

  final t0 = DateTime.utc(2026, 3, 1, 9);

  /// A representative populated database: two clients with profiles, a
  /// custom exercise, a template, a programme, and every kind of record for
  /// the non-Me client so ownership is what the restore is judged on.
  Future<Client> populate(_Repos r) async {
    final alice = await r.clients
        .createClient(Client.create(name: 'Alice', colour: 0xFF112233));
    await r.healthProfiles.saveForClient(
      alice.id,
      const HealthProfile(
          age: 41, restingHr: 55, clinicianMaxHr: 150, betaBlocker: true),
    );
    await r.healthProfiles.saveForClient(
      kSelfClientId,
      const HealthProfile(age: 36, measuredMaxHr: 190),
    );
    await r.exercises.createExercise(Exercise(
      id: 'custom-1',
      name: 'Zercher Squat',
      category: ExerciseCategory.strength,
      muscleGroup: MuscleGroup.quadriceps,
      equipmentType: EquipmentType.barbell,
      isCustom: true,
      updatedAt: t0,
    ));
    await r.templates.createTemplate(WorkoutTemplate(
      id: 'tpl-1',
      name: 'Push A',
      createdAt: t0,
      updatedAt: t0,
      exercises: [
        TemplateExercise(
          id: 'te-1',
          templateId: 'tpl-1',
          exerciseId: '1',
          exerciseName: 'Barbell Bench Press',
          targetSets: 5,
          targetReps: 5,
          orderIndex: 0,
          updatedAt: t0,
        ),
      ],
    ));
    await r.programmes.createProgramme(Programme(
      id: 'prog-1',
      name: 'Linear',
      durationWeeks: 8,
      createdAt: t0,
      updatedAt: t0,
      startedAt: t0,
    ));
    await r.programmes.addDay(ProgrammeDay(
      id: 'day-1',
      programmeId: 'prog-1',
      weekNumber: 1,
      dayOfWeek: 1,
      templateId: 'tpl-1',
      templateName: 'Push A',
      updatedAt: t0,
    ));
    await r.programmes.addRule(ProgressionRule(
      id: 'rule-1',
      programmeId: 'prog-1',
      exerciseId: '1',
      type: ProgressionType.fixedIncrement,
      value: 2.5,
      frequencyWeeks: 2,
      updatedAt: t0,
    ));
    await r.workouts.createWorkout(Workout(
      id: 'w-alice',
      startedAt: t0,
      completedAt: t0.add(const Duration(hours: 1)),
      templateId: 'tpl-1',
      notes: 'felt strong',
      clientId: alice.id,
      updatedAt: t0,
    ));
    await r.workouts.addSet(WorkoutSet(
      id: 's-alice',
      workoutId: 'w-alice',
      exerciseId: '1',
      setOrder: 1,
      weight: 60,
      reps: 8,
      rpe: 7.5,
      timestamp: t0.add(const Duration(minutes: 10)),
      isWarmUp: true,
      groupId: 'ss-1',
      avgHeartRate: 132,
      peakHeartRate: 151,
      updatedAt: t0,
    ));
    await r.workouts.createWorkout(Workout(
      id: 'w-cardio',
      startedAt: t0,
      completedAt: t0.add(const Duration(minutes: 30)),
      clientId: alice.id,
      updatedAt: t0,
    ));
    await r.cardio.createSession(CardioSession(
      id: 'c-alice',
      workoutId: 'w-cardio',
      exerciseId: '1',
      durationSeconds: 1800,
      distanceMeters: 5000,
      incline: 1.5,
      avgHeartRate: 140,
      clientId: alice.id,
      updatedAt: t0,
    ));
    await r.prs.createRecord(PersonalRecord(
      id: 'pr-alice',
      exerciseId: '1',
      recordType: RecordType.maxWeight,
      value: 60,
      achievedAt: t0,
      workoutSetId: 's-alice',
      clientId: alice.id,
      updatedAt: t0,
    ));
    await r.bodyMetrics.create(BodyMetric(
      id: 'bm-alice',
      date: t0,
      weight: 71.5,
      bodyFatPercent: 22,
      notes: 'morning',
      clientId: alice.id,
      updatedAt: t0,
    ));
    await r.stretching.createSession(StretchingSession(
      id: 'st-1',
      workoutId: 'w-alice',
      type: 'pigeon',
      bodyArea: StretchingBodyArea.hips,
      side: StretchingSide.left,
      durationSeconds: 45,
      entryMethod: StretchingEntryMethod.timer,
      updatedAt: t0,
    ));
    return alice;
  }

  test('a JSON export restores every entity with its owner intact', () async {
    final alice = await populate(source);
    final json = await source.exporter.exportAsJson();
    expect((jsonDecode(json) as Map)['formatVersion'], 2);

    await target.importer.importFromJson(json);

    final restoredAlice = await target.clients.getClient(alice.id);
    expect(restoredAlice?.name, 'Alice');
    expect(restoredAlice?.colour, 0xFF112233);

    final aliceProfile = await target.healthProfiles.getForClient(alice.id);
    expect(aliceProfile.age, 41);
    expect(aliceProfile.clinicianMaxHr, 150);
    expect(aliceProfile.betaBlocker, isTrue);
    final meProfile = await target.healthProfiles.getForClient(kSelfClientId);
    expect(meProfile.measuredMaxHr, 190);

    expect((await target.exercises.getExercise('custom-1'))?.name,
        'Zercher Squat');

    final template = await target.templates.getTemplate('tpl-1');
    expect(template?.exercises.single.targetSets, 5);
    expect(template?.exercises.single.targetReps, 5);

    final programme = await target.programmes.getProgramme('prog-1');
    expect(programme?.durationWeeks, 8);
    expect(programme?.startedAt, t0);
    expect(programme?.days.single.templateId, 'tpl-1');
    expect(programme?.rules.single.value, 2.5);
    expect(programme?.rules.single.frequencyWeeks, 2);

    final workout = await target.workouts.getWorkout('w-alice');
    expect(workout?.clientId, alice.id);
    expect(workout?.templateId, 'tpl-1');
    expect(workout?.notes, 'felt strong');
    final set = (await target.workouts.getSetsForWorkout('w-alice')).single;
    expect(set.rpe, 7.5);
    expect(set.isWarmUp, isTrue);
    expect(set.groupId, 'ss-1');
    expect(set.avgHeartRate, 132);
    expect(set.peakHeartRate, 151);

    final cardio = await target.cardio.getSession('c-alice');
    expect(cardio?.clientId, alice.id);
    expect(cardio?.incline, 1.5);

    final pr =
        await target.prs.getBestRecord('1', RecordType.maxWeight, alice.id);
    expect(pr?.workoutSetId, 's-alice');

    final metric = (await target.bodyMetrics.getAll(clientId: alice.id)).single;
    expect(metric.weight, 71.5);
    expect(metric.bodyFatPercent, 22);

    final stretch = await target.stretching.getSession('st-1');
    expect(stretch?.bodyArea, StretchingBodyArea.hips);
  });

  test('restoring the same backup twice changes nothing', () async {
    await populate(source);
    final json = await source.exporter.exportAsJson();

    await target.importer.importFromJson(json);
    final second = await target.importer.importFromJson(json);

    expect(second.workoutsImported, 0);
    expect(second.setsImported, 0);
    expect(await target.clients.watchClients().first, hasLength(2));
    expect(await target.workouts.getSetsForWorkout('w-alice'), hasLength(1));
  });

  test('a retry after a partial restore fills in the missing sets', () async {
    await populate(source);
    final json = await source.exporter.exportAsJson();
    // Simulate an earlier attempt that created the parent but died before
    // its sets landed.
    final alice = (await source.clients.watchClients().first)
        .firstWhere((c) => !c.isSelf);
    await target.clients.createClient(alice);
    await target.workouts.createWorkout(Workout(
      id: 'w-alice',
      startedAt: t0,
      clientId: alice.id,
      updatedAt: t0,
    ));
    expect(await target.workouts.getSetsForWorkout('w-alice'), isEmpty);

    final result = await target.importer.importFromJson(json);

    expect(result.setsImported, 1);
    expect(await target.workouts.getSetsForWorkout('w-alice'), hasLength(1));
  });

  test('a storage failure that is not a duplicate surfaces as an error',
      () async {
    final json = jsonEncode({
      'formatVersion': 2,
      'workouts': [
        {
          'id': 'w-bad',
          'startedAt': t0.toIso8601String(),
          'clientId': kSelfClientId,
          'sets': [
            {
              'id': 's-bad',
              'exerciseId': 'no-such-exercise',
              'setOrder': 1,
              'weight': 50,
              'reps': 5,
              'timestamp': t0.toIso8601String(),
            }
          ],
        }
      ],
    });

    await expectLater(target.importer.importFromJson(json), throwsA(anything));
  });

  test('a version 1 file whose owner is unknown restores to Me', () async {
    final json = jsonEncode({
      'exportedAt': t0.toIso8601String(),
      'workouts': [
        {
          'id': 'w-v1',
          'startedAt': t0.toIso8601String(),
          'clientId': 'client-that-never-synced',
          'sets': <Map<String, dynamic>>[],
        }
      ],
    });

    await target.importer.importFromJson(json);

    expect((await target.workouts.getWorkout('w-v1'))?.clientId, kSelfClientId);
  });
}
