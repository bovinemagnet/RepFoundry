import 'package:uuid/uuid.dart';

import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/body_metrics/data/drift_body_metric_repository.dart';
import 'package:rep_foundry/features/body_metrics/domain/models/body_metric.dart';
import 'package:rep_foundry/features/cardio/data/drift_cardio_session_repository.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/clients/data/drift_client_repository.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/exercises/data/drift_exercise_repository.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/data/drift_personal_record_repository.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/programmes/data/drift_programme_repository.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';
import 'package:rep_foundry/features/templates/data/drift_workout_template_repository.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/features/workout/data/drift_workout_repository.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

const _uuid = Uuid();

/// Preferences read by the app at start-up, needed so the screenshot
/// capture can reach every screen it photographs.
///
/// Coach mode is gated behind an entitlement that is empty by default, so
/// without this its screens cannot be reached at all — the capture would
/// silently photograph the wrong thing rather than fail.
Map<String, Object> screenshotPrefs() => {
      'unlocked_entitlements': <String>['virtualTrainer'],
      // The heart rate panel opens a disclaimer on first visit and a profile
      // onboarding sheet whenever the age is unset. Both would sit over the
      // screen being photographed. The hr_* keys are read once and migrated
      // into the self client's health profile, which also gives the zones
      // real numbers to work from.
      'hr_disclaimer_shown': true,
      'hr_age': 34,
      'hr_resting_hr': 58,
      'hr_measured_max_hr': 186,
      // Cloud sync renders as a single toggle until it is switched on, so
      // the sync capture would otherwise show none of what it documents.
      'cloud_sync_enabled': true,
      'cloud_sync_consent_given': true,
      'cloud_sync_last_sync_at': DateTime.now()
          .subtract(const Duration(hours: 2))
          .millisecondsSinceEpoch,
      // The coach is off until accepted, so its settings screen would
      // otherwise document the feature in its switched-off state.
      'trainer_enabled': true,
      'trainer_disclaimer_accepted': true,
    };

/// Fills [database] with three weeks of realistic training history so that
/// every screen the documentation screenshots cover has data behind it
/// rather than an empty state.
///
/// Seeds through the Drift repositories rather than raw table inserts, so
/// the fixture keeps working if the schema moves:
/// - three weeks of completed workouts across six exercises, with some sets
///   carrying heart-rate data
/// - two personal records
/// - one cardio session with a heart-rate reading
/// - several body-metric entries
/// - three workout templates and two multi-week programmes
/// - a second client alongside the always-present self client
Future<void> seedScreenshotData(db.AppDatabase database) async {
  final now = DateTime.now().toUtc();

  final exerciseRepo = DriftExerciseRepository(database);
  final workoutRepo = DriftWorkoutRepository(database);
  final prRepo = DriftPersonalRecordRepository(database);
  final bodyMetricRepo = DriftBodyMetricRepository(database);
  final cardioRepo = DriftCardioSessionRepository(database);
  final templateRepo = DriftWorkoutTemplateRepository(database);
  final programmeRepo = DriftProgrammeRepository(database);
  final clientRepo = DriftClientRepository(database);

  final exercises = await exerciseRepo.getAllExercises();
  Exercise byName(String name) => exercises.firstWhere((e) => e.name == name);

  final benchPress = byName('Barbell Bench Press');
  final overheadPress = byName('Overhead Press');
  final dumbbellCurl = byName('Dumbbell Curl');
  final squat = byName('Barbell Squat');
  final deadlift = byName('Deadlift');
  final barbellRow = byName('Barbell Row');
  final treadmill = byName('Treadmill');

  // Push day: chest/shoulders/arms. Pull-and-legs day: back/hamstrings.
  final pushDay = [benchPress, overheadPress, dumbbellCurl];
  final pullDay = [squat, deadlift, barbellRow];

  // Working weight (kg) for the most recent week; earlier weeks are lighter
  // so the history shows progressive overload leading up to today.
  final currentWeekWeight = <String, double>{
    benchPress.id: 60,
    overheadPress.id: 40,
    dumbbellCurl.id: 14,
    squat.id: 80,
    deadlift.id: 100,
    barbellRow.id: 55,
  };
  const kgPerWeekOfProgression = 2.5;

  // Nine workouts (three per week) spread across the last three weeks,
  // most recent first, alternating push and pull-and-legs days.
  const daysAgoByWorkout = [2, 4, 6, 9, 11, 13, 16, 18, 20];

  WorkoutSet? heaviestBenchSet;
  DateTime? heaviestBenchWorkoutStart;
  WorkoutSet? heaviestSquatSet;
  DateTime? heaviestSquatWorkoutStart;

  for (var i = 0; i < daysAgoByWorkout.length; i++) {
    final daysAgo = daysAgoByWorkout[i];
    final weekIndex = i ~/ 3; // 0 = most recent week, 2 = oldest.
    final isPush = i.isEven;
    final dayExercises = isPush ? pushDay : pullDay;

    final day = now.subtract(Duration(days: daysAgo));
    final startedAt = DateTime.utc(day.year, day.month, day.day, 9);
    final completedAt = startedAt.add(const Duration(minutes: 50));
    // The two most recent workouts were logged with a heart-rate monitor
    // connected; earlier ones were not.
    final hasHeartRate = i < 2;

    final workout = Workout(
      id: _uuid.v4(),
      startedAt: startedAt,
      completedAt: completedAt,
      clientId: kSelfClientId,
      updatedAt: completedAt,
    );
    await workoutRepo.createWorkout(workout);

    var setOrder = 0;
    for (final exercise in dayExercises) {
      final baseWeight =
          currentWeekWeight[exercise.id]! - weekIndex * kgPerWeekOfProgression;
      // A light-to-heavy triple: warm-up-ish first set, top set last.
      const weightDeltas = [-5.0, 0.0, 2.5];
      const repsBySet = [10, 8, 6];

      for (var setIndex = 0; setIndex < 3; setIndex++) {
        final timestamp = startedAt.add(
          Duration(minutes: setOrder * 3),
        );
        final avgHeartRate = hasHeartRate ? 118 + setIndex * 4 : null;
        final peakHeartRate = hasHeartRate ? avgHeartRate! + 15 : null;

        final set = WorkoutSet(
          id: _uuid.v4(),
          workoutId: workout.id,
          exerciseId: exercise.id,
          setOrder: setOrder,
          weight: baseWeight + weightDeltas[setIndex],
          reps: repsBySet[setIndex],
          timestamp: timestamp,
          isWarmUp: false,
          avgHeartRate: avgHeartRate,
          peakHeartRate: peakHeartRate,
          updatedAt: timestamp,
        );
        await workoutRepo.addSet(set);

        if (exercise.id == benchPress.id && setIndex == 2) {
          heaviestBenchSet = set;
          heaviestBenchWorkoutStart = startedAt;
        }
        if (exercise.id == squat.id && setIndex == 2) {
          heaviestSquatSet = set;
          heaviestSquatWorkoutStart = startedAt;
        }

        setOrder++;
      }
    }
  }

  // Two personal records, so the PR timeline has points on it.
  await prRepo.createRecord(
    PersonalRecord(
      id: _uuid.v4(),
      exerciseId: benchPress.id,
      recordType: RecordType.estimatedOneRepMax,
      value: heaviestBenchSet!.estimatedOneRepMax,
      achievedAt: heaviestBenchWorkoutStart!,
      workoutSetId: heaviestBenchSet.id,
      clientId: kSelfClientId,
      updatedAt: heaviestBenchWorkoutStart,
    ),
  );
  await prRepo.createRecord(
    PersonalRecord(
      id: _uuid.v4(),
      exerciseId: squat.id,
      recordType: RecordType.maxWeight,
      value: heaviestSquatSet!.weight,
      achievedAt: heaviestSquatWorkoutStart!,
      workoutSetId: heaviestSquatSet.id,
      clientId: kSelfClientId,
      updatedAt: heaviestSquatWorkoutStart,
    ),
  );

  // One cardio session with a heart-rate reading, logged as its own workout
  // the way SaveCardioSessionUseCase does it.
  final cardioDay = now.subtract(const Duration(days: 5));
  final cardioStartedAt = DateTime.utc(
    cardioDay.year,
    cardioDay.month,
    cardioDay.day,
    18,
  );
  const cardioDurationSeconds = 32 * 60;
  final cardioCompletedAt =
      cardioStartedAt.add(const Duration(seconds: cardioDurationSeconds));
  final cardioWorkout = Workout(
    id: _uuid.v4(),
    startedAt: cardioStartedAt,
    completedAt: cardioCompletedAt,
    notes: 'Cardio: ${treadmill.name}',
    clientId: kSelfClientId,
    updatedAt: cardioCompletedAt,
  );
  await workoutRepo.createWorkout(cardioWorkout);
  await cardioRepo.createSession(
    CardioSession(
      id: _uuid.v4(),
      workoutId: cardioWorkout.id,
      exerciseId: treadmill.id,
      durationSeconds: cardioDurationSeconds,
      distanceMeters: 5000,
      incline: 1.5,
      avgHeartRate: 142,
      clientId: kSelfClientId,
      updatedAt: cardioCompletedAt,
    ),
  );

  // Several body-metric entries spread over the three weeks, trending down
  // slightly, with a body-fat reading on the two most recent entries.
  const bodyMetricDaysAgo = [20, 14, 7, 3, 0];
  const bodyMetricWeights = [82.5, 82.0, 81.4, 81.0, 80.6];
  for (var i = 0; i < bodyMetricDaysAgo.length; i++) {
    final date = now.subtract(Duration(days: bodyMetricDaysAgo[i]));
    await bodyMetricRepo.create(
      BodyMetric(
        id: _uuid.v4(),
        date: date,
        weight: bodyMetricWeights[i],
        bodyFatPercent: i >= 3 ? 18.5 - (i - 3) * 0.2 : null,
        clientId: kSelfClientId,
        updatedAt: date,
      ),
    );
  }

  // Three workout templates. One would satisfy "not an empty state", but a
  // single row on an otherwise blank screen is a poor documentation image.
  final templateNow = DateTime.now().toUtc();
  Future<WorkoutTemplate> createTemplate(
    String name,
    List<Exercise> exercises,
  ) async {
    final templateId = _uuid.v4();
    final template = WorkoutTemplate(
      id: templateId,
      name: name,
      createdAt: templateNow,
      updatedAt: templateNow,
      exercises: [
        for (var i = 0; i < exercises.length; i++)
          TemplateExercise(
            id: _uuid.v4(),
            templateId: templateId,
            exerciseId: exercises[i].id,
            exerciseName: exercises[i].name,
            targetSets: 3,
            targetReps: 8,
            orderIndex: i,
            updatedAt: templateNow,
          ),
      ],
    );
    await templateRepo.createTemplate(template);
    return template;
  }

  final template = await createTemplate('Push Day', pushDay);
  final pullTemplate = await createTemplate('Pull & Legs', pullDay);
  await createTemplate(
    'Upper Body Volume',
    [benchPress, barbellRow, overheadPress, dumbbellCurl],
  );

  // One multi-week programme built from that template, already under way
  // so the current-week indicator has something to show.
  final programme = Programme.create(
    name: '4-Week Push Focus',
    durationWeeks: 4,
  );
  await programmeRepo.createProgramme(programme);
  for (var week = 1; week <= 4; week++) {
    await programmeRepo.addDay(
      ProgrammeDay.create(
        programmeId: programme.id,
        weekNumber: week,
        dayOfWeek: DateTime.monday,
        templateId: template.id,
        templateName: template.name,
      ),
    );
  }
  await programmeRepo.addRule(
    ProgressionRule.create(
      programmeId: programme.id,
      exerciseId: benchPress.id,
      type: ProgressionType.fixedIncrement,
      value: kgPerWeekOfProgression,
    ),
  );
  await programmeRepo.markProgrammeStarted(
    programme.id,
    startedAt: now.subtract(const Duration(days: 15)),
  );

  // A second programme, never started, so the list shows both a programme
  // under way and one waiting to begin.
  final strengthBase = Programme.create(
    name: '8-Week Strength Base',
    durationWeeks: 8,
  );
  await programmeRepo.createProgramme(strengthBase);
  for (var week = 1; week <= 8; week++) {
    await programmeRepo.addDay(
      ProgrammeDay.create(
        programmeId: strengthBase.id,
        weekNumber: week,
        dayOfWeek: DateTime.wednesday,
        templateId: pullTemplate.id,
        templateName: pullTemplate.name,
      ),
    );
  }

  // A second client alongside the always-present self client.
  await clientRepo.createClient(
    Client.create(
      name: 'Jamie Rivera',
      colour: 0xFF2196F3,
      notes: 'Marathon training block',
    ),
  );
}
