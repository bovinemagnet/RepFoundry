import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../../body_metrics/domain/models/body_metric.dart';
import '../../cardio/domain/models/cardio_session.dart';
import '../../exercises/domain/models/exercise.dart';
import '../../history/domain/models/personal_record.dart';
import '../../programmes/domain/models/programme.dart';
import '../../templates/domain/models/workout_template.dart';
import '../../workout/domain/models/workout.dart';
import '../../workout/domain/models/workout_set.dart';
import '../domain/models/sync_snapshot.dart';

class SyncSnapshotSerialiser {
  /// Read all data from the database, including soft-deleted rows.
  Future<SyncSnapshot> createFromDatabase(
    db.AppDatabase database, {
    required String deviceId,
  }) async {
    // Exercises — include soft-deleted (no WHERE filter)
    final exerciseRows = await database.select(database.exercises).get();
    final exercises = exerciseRows.map(_exerciseToDomain).toList();

    // Workouts — include soft-deleted
    final workoutRows = await database.select(database.workouts).get();
    final workouts = workoutRows.map(_workoutToDomain).toList();

    // Workout sets
    final setRows = await database.select(database.workoutSets).get();
    final workoutSets = setRows.map(_setToDomain).toList();

    // Cardio sessions
    final cardioRows = await database.select(database.cardioSessions).get();
    final cardioSessions = cardioRows.map(_cardioToDomain).toList();

    // Personal records
    final prRows = await database.select(database.personalRecords).get();
    final personalRecords = prRows.map(_personalRecordToDomain).toList();

    // Workout templates
    final templateRows = await database.select(database.workoutTemplates).get();
    final workoutTemplates = templateRows
        .map((row) => WorkoutTemplate(
              id: row.id,
              name: row.name,
              createdAt: dateTimeFromEpochMs(row.createdAt),
              updatedAt: dateTimeFromEpochMs(row.updatedAt),
            ))
        .toList();

    // Template exercises
    final teRows = await database.select(database.templateExercises).get();
    final templateExercises = teRows.map(_templateExerciseToDomain).toList();

    // Body metrics
    final bmRows = await database.select(database.bodyMetrics).get();
    final bodyMetrics = bmRows.map(_bodyMetricToDomain).toList();

    // Programmes
    final progRows = await database.select(database.programmes).get();
    final programmes = progRows
        .map((row) => Programme(
              id: row.id,
              name: row.name,
              durationWeeks: row.durationWeeks,
              createdAt: dateTimeFromEpochMs(row.createdAt),
              updatedAt: dateTimeFromEpochMs(row.updatedAt),
              startedAt: row.startedAt == null
                  ? null
                  : dateTimeFromEpochMs(row.startedAt!),
            ))
        .toList();

    // Programme days
    final dayRows = await database.select(database.programmeDays).get();
    final programmeDays = dayRows.map(_programmeDayToDomain).toList();

    // Progression rules
    final ruleRows = await database.select(database.progressionRules).get();
    final progressionRules = ruleRows.map(_progressionRuleToDomain).toList();

    return SyncSnapshot(
      snapshotAt: DateTime.now().toUtc(),
      deviceId: deviceId,
      schemaVersion: 7,
      exercises: exercises,
      workouts: workouts,
      workoutSets: workoutSets,
      cardioSessions: cardioSessions,
      personalRecords: personalRecords,
      workoutTemplates: workoutTemplates,
      templateExercises: templateExercises,
      bodyMetrics: bodyMetrics,
      programmes: programmes,
      programmeDays: programmeDays,
      progressionRules: progressionRules,
    );
  }

  String toJson(SyncSnapshot snapshot) {
    final data = {
      'version': 1,
      'schemaVersion': snapshot.schemaVersion,
      'snapshotAt': snapshot.snapshotAt.toIso8601String(),
      'deviceId': snapshot.deviceId,
      'exercises': snapshot.exercises.map(_exerciseToMap).toList(),
      'workouts': snapshot.workouts.map(_workoutToMap).toList(),
      'workoutSets': snapshot.workoutSets.map(_setToMap).toList(),
      'cardioSessions': snapshot.cardioSessions.map(_cardioToMap).toList(),
      'personalRecords':
          snapshot.personalRecords.map(_personalRecordToMap).toList(),
      'workoutTemplates':
          snapshot.workoutTemplates.map(_workoutTemplateToMap).toList(),
      'templateExercises':
          snapshot.templateExercises.map(_templateExerciseToMap).toList(),
      'bodyMetrics': snapshot.bodyMetrics.map(_bodyMetricToMap).toList(),
      'programmes': snapshot.programmes.map(_programmeToMap).toList(),
      'programmeDays': snapshot.programmeDays.map(_programmeDayToMap).toList(),
      'progressionRules':
          snapshot.progressionRules.map(_progressionRuleToMap).toList(),
    };
    return jsonEncode(data);
  }

  SyncSnapshot fromJson(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return SyncSnapshot(
      snapshotAt: DateTime.parse(data['snapshotAt'] as String),
      deviceId: data['deviceId'] as String,
      schemaVersion: data['schemaVersion'] as int,
      exercises: _mapList(data['exercises'], _exerciseFromMap),
      workouts: _mapList(data['workouts'], _workoutFromMap),
      workoutSets: _mapList(data['workoutSets'], _setFromMap),
      cardioSessions: _mapList(data['cardioSessions'], _cardioFromMap),
      personalRecords:
          _mapList(data['personalRecords'], _personalRecordFromMap),
      workoutTemplates:
          _mapList(data['workoutTemplates'], _workoutTemplateFromMap),
      templateExercises:
          _mapList(data['templateExercises'], _templateExerciseFromMap),
      bodyMetrics: _mapList(data['bodyMetrics'], _bodyMetricFromMap),
      programmes: _mapList(data['programmes'], _programmeFromMap),
      programmeDays: _mapList(data['programmeDays'], _programmeDayFromMap),
      progressionRules:
          _mapList(data['progressionRules'], _progressionRuleFromMap),
    );
  }

  /// Apply a merged snapshot to the database via upsert.
  Future<void> applyToDatabase(
    db.AppDatabase database,
    SyncSnapshot snapshot,
  ) async {
    await database.transaction(() async {
      for (final e in snapshot.exercises) {
        await database.into(database.exercises).insertOnConflictUpdate(
              db.ExercisesCompanion.insert(
                id: e.id,
                name: e.name,
                category: e.category.name,
                muscleGroup: e.muscleGroup.name,
                equipmentType: e.equipmentType.name,
                isCustom: Value(e.isCustom),
                imageAsset: Value(e.imageAsset),
                updatedAt: Value(dateTimeToEpochMs(e.updatedAt)),
                deletedAt: Value(nullableDateTimeToEpochMs(e.deletedAt)),
              ),
            );
      }

      for (final w in snapshot.workouts) {
        await database.into(database.workouts).insertOnConflictUpdate(
              db.WorkoutsCompanion.insert(
                id: w.id,
                startedAt: dateTimeToEpochMs(w.startedAt),
                completedAt:
                    Value(nullableDateTimeToEpochMs(w.completedAt)),
                templateId: Value(w.templateId),
                notes: Value(w.notes),
                updatedAt: Value(dateTimeToEpochMs(w.updatedAt)),
                deletedAt: Value(nullableDateTimeToEpochMs(w.deletedAt)),
              ),
            );
      }

      for (final s in snapshot.workoutSets) {
        await database.into(database.workoutSets).insertOnConflictUpdate(
              db.WorkoutSetsCompanion.insert(
                id: s.id,
                workoutId: s.workoutId,
                exerciseId: s.exerciseId,
                setOrder: s.setOrder,
                weight: s.weight,
                reps: s.reps,
                rpe: Value(s.rpe),
                timestamp: dateTimeToEpochMs(s.timestamp),
                isWarmUp: Value(s.isWarmUp),
                groupId: Value(s.groupId),
                updatedAt: Value(dateTimeToEpochMs(s.updatedAt)),
              ),
            );
      }

      for (final c in snapshot.cardioSessions) {
        await database.into(database.cardioSessions).insertOnConflictUpdate(
              db.CardioSessionsCompanion.insert(
                id: c.id,
                workoutId: c.workoutId,
                exerciseId: c.exerciseId,
                durationSeconds: c.durationSeconds,
                distanceMeters: Value(c.distanceMeters),
                incline: Value(c.incline),
                avgHeartRate: Value(c.avgHeartRate),
                updatedAt: Value(dateTimeToEpochMs(c.updatedAt)),
              ),
            );
      }

      for (final pr in snapshot.personalRecords) {
        await database.into(database.personalRecords).insertOnConflictUpdate(
              db.PersonalRecordsCompanion.insert(
                id: pr.id,
                exerciseId: pr.exerciseId,
                recordType: pr.recordType.name,
                value: pr.value,
                achievedAt: dateTimeToEpochMs(pr.achievedAt),
                workoutSetId: Value(pr.workoutSetId),
                updatedAt: Value(dateTimeToEpochMs(pr.updatedAt)),
              ),
            );
      }

      for (final t in snapshot.workoutTemplates) {
        await database
            .into(database.workoutTemplates)
            .insertOnConflictUpdate(
              db.WorkoutTemplatesCompanion.insert(
                id: t.id,
                name: t.name,
                createdAt: dateTimeToEpochMs(t.createdAt),
                updatedAt: dateTimeToEpochMs(t.updatedAt),
              ),
            );
      }

      for (final te in snapshot.templateExercises) {
        await database
            .into(database.templateExercises)
            .insertOnConflictUpdate(
              db.TemplateExercisesCompanion.insert(
                id: te.id,
                templateId: te.templateId,
                exerciseId: te.exerciseId,
                exerciseName: te.exerciseName,
                targetSets: te.targetSets,
                targetReps: te.targetReps,
                orderIndex: te.orderIndex,
                updatedAt: Value(dateTimeToEpochMs(te.updatedAt)),
              ),
            );
      }

      for (final bm in snapshot.bodyMetrics) {
        await database.into(database.bodyMetrics).insertOnConflictUpdate(
              db.BodyMetricsCompanion.insert(
                id: bm.id,
                date: dateTimeToEpochMs(bm.date),
                weight: bm.weight,
                bodyFatPercent: Value(bm.bodyFatPercent),
                notes: Value(bm.notes),
                updatedAt: Value(dateTimeToEpochMs(bm.updatedAt)),
              ),
            );
      }

      for (final p in snapshot.programmes) {
        await database.into(database.programmes).insertOnConflictUpdate(
              db.ProgrammesCompanion.insert(
                id: p.id,
                name: p.name,
                durationWeeks: p.durationWeeks,
                createdAt: dateTimeToEpochMs(p.createdAt),
                updatedAt: dateTimeToEpochMs(p.updatedAt),
                startedAt: Value(p.startedAt == null
                    ? null
                    : dateTimeToEpochMs(p.startedAt!)),
              ),
            );
      }

      for (final d in snapshot.programmeDays) {
        await database.into(database.programmeDays).insertOnConflictUpdate(
              db.ProgrammeDaysCompanion.insert(
                id: d.id,
                programmeId: d.programmeId,
                weekNumber: d.weekNumber,
                dayOfWeek: d.dayOfWeek,
                templateId: d.templateId,
                templateName: d.templateName,
                updatedAt: Value(dateTimeToEpochMs(d.updatedAt)),
              ),
            );
      }

      for (final r in snapshot.progressionRules) {
        await database
            .into(database.progressionRules)
            .insertOnConflictUpdate(
              db.ProgressionRulesCompanion.insert(
                id: r.id,
                programmeId: r.programmeId,
                exerciseId: r.exerciseId,
                type: r.type.name,
                value: r.value,
                frequencyWeeks: Value(r.frequencyWeeks),
                updatedAt: Value(dateTimeToEpochMs(r.updatedAt)),
              ),
            );
      }
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  List<T> _mapList<T>(
    dynamic list,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    if (list == null) return [];
    return (list as List).map((e) => fromMap(e as Map<String, dynamic>)).toList();
  }

  // ── Domain ↔ DB mappers ─────────────────────────────────────────────

  Exercise _exerciseToDomain(db.Exercise row) => Exercise(
        id: row.id,
        name: row.name,
        category: enumFromString(ExerciseCategory.values, row.category),
        muscleGroup: enumFromString(MuscleGroup.values, row.muscleGroup),
        equipmentType:
            enumFromString(EquipmentType.values, row.equipmentType),
        isCustom: row.isCustom,
        imageAsset: row.imageAsset,
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
        deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
      );

  Workout _workoutToDomain(db.Workout row) => Workout(
        id: row.id,
        startedAt: dateTimeFromEpochMs(row.startedAt),
        completedAt: nullableDateTimeFromEpochMs(row.completedAt),
        templateId: row.templateId,
        notes: row.notes,
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
        deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
      );

  WorkoutSet _setToDomain(db.WorkoutSet row) => WorkoutSet(
        id: row.id,
        workoutId: row.workoutId,
        exerciseId: row.exerciseId,
        setOrder: row.setOrder,
        weight: row.weight,
        reps: row.reps,
        rpe: row.rpe,
        timestamp: dateTimeFromEpochMs(row.timestamp),
        isWarmUp: row.isWarmUp,
        groupId: row.groupId,
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
      );

  CardioSession _cardioToDomain(db.CardioSession row) => CardioSession(
        id: row.id,
        workoutId: row.workoutId,
        exerciseId: row.exerciseId,
        durationSeconds: row.durationSeconds,
        distanceMeters: row.distanceMeters,
        incline: row.incline,
        avgHeartRate: row.avgHeartRate,
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
      );

  PersonalRecord _personalRecordToDomain(db.PersonalRecord row) =>
      PersonalRecord(
        id: row.id,
        exerciseId: row.exerciseId,
        recordType: enumFromString(RecordType.values, row.recordType),
        value: row.value,
        achievedAt: dateTimeFromEpochMs(row.achievedAt),
        workoutSetId: row.workoutSetId,
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
      );

  TemplateExercise _templateExerciseToDomain(db.TemplateExercise row) =>
      TemplateExercise(
        id: row.id,
        templateId: row.templateId,
        exerciseId: row.exerciseId,
        exerciseName: row.exerciseName,
        targetSets: row.targetSets,
        targetReps: row.targetReps,
        orderIndex: row.orderIndex,
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
      );

  BodyMetric _bodyMetricToDomain(db.BodyMetric row) => BodyMetric(
        id: row.id,
        date: dateTimeFromEpochMs(row.date),
        weight: row.weight,
        bodyFatPercent: row.bodyFatPercent,
        notes: row.notes,
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
      );

  ProgrammeDay _programmeDayToDomain(db.ProgrammeDay row) => ProgrammeDay(
        id: row.id,
        programmeId: row.programmeId,
        weekNumber: row.weekNumber,
        dayOfWeek: row.dayOfWeek,
        templateId: row.templateId,
        templateName: row.templateName,
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
      );

  ProgressionRule _progressionRuleToDomain(db.ProgressionRule row) =>
      ProgressionRule(
        id: row.id,
        programmeId: row.programmeId,
        exerciseId: row.exerciseId,
        type: ProgressionType.values.byName(row.type),
        value: row.value,
        frequencyWeeks: row.frequencyWeeks,
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
      );

  // ── Domain → JSON maps ─────────────────────────────────────────────

  Map<String, dynamic> _exerciseToMap(Exercise e) => {
        'id': e.id,
        'name': e.name,
        'category': e.category.name,
        'muscleGroup': e.muscleGroup.name,
        'equipmentType': e.equipmentType.name,
        'isCustom': e.isCustom,
        'imageAsset': e.imageAsset,
        'updatedAt': e.updatedAt.toIso8601String(),
        'deletedAt': e.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _workoutToMap(Workout w) => {
        'id': w.id,
        'startedAt': w.startedAt.toIso8601String(),
        'completedAt': w.completedAt?.toIso8601String(),
        'templateId': w.templateId,
        'notes': w.notes,
        'updatedAt': w.updatedAt.toIso8601String(),
        'deletedAt': w.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _setToMap(WorkoutSet s) => {
        'id': s.id,
        'workoutId': s.workoutId,
        'exerciseId': s.exerciseId,
        'setOrder': s.setOrder,
        'weight': s.weight,
        'reps': s.reps,
        'rpe': s.rpe,
        'timestamp': s.timestamp.toIso8601String(),
        'isWarmUp': s.isWarmUp,
        'groupId': s.groupId,
        'updatedAt': s.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _cardioToMap(CardioSession c) => {
        'id': c.id,
        'workoutId': c.workoutId,
        'exerciseId': c.exerciseId,
        'durationSeconds': c.durationSeconds,
        'distanceMeters': c.distanceMeters,
        'incline': c.incline,
        'avgHeartRate': c.avgHeartRate,
        'updatedAt': c.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _personalRecordToMap(PersonalRecord pr) => {
        'id': pr.id,
        'exerciseId': pr.exerciseId,
        'recordType': pr.recordType.name,
        'value': pr.value,
        'achievedAt': pr.achievedAt.toIso8601String(),
        'workoutSetId': pr.workoutSetId,
        'updatedAt': pr.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _workoutTemplateToMap(WorkoutTemplate t) => {
        'id': t.id,
        'name': t.name,
        'createdAt': t.createdAt.toIso8601String(),
        'updatedAt': t.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _templateExerciseToMap(TemplateExercise te) => {
        'id': te.id,
        'templateId': te.templateId,
        'exerciseId': te.exerciseId,
        'exerciseName': te.exerciseName,
        'targetSets': te.targetSets,
        'targetReps': te.targetReps,
        'orderIndex': te.orderIndex,
        'updatedAt': te.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _bodyMetricToMap(BodyMetric bm) => {
        'id': bm.id,
        'date': bm.date.toIso8601String(),
        'weight': bm.weight,
        'bodyFatPercent': bm.bodyFatPercent,
        'notes': bm.notes,
        'updatedAt': bm.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _programmeToMap(Programme p) => {
        'id': p.id,
        'name': p.name,
        'durationWeeks': p.durationWeeks,
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
        'startedAt': p.startedAt?.toIso8601String(),
      };

  Map<String, dynamic> _programmeDayToMap(ProgrammeDay d) => {
        'id': d.id,
        'programmeId': d.programmeId,
        'weekNumber': d.weekNumber,
        'dayOfWeek': d.dayOfWeek,
        'templateId': d.templateId,
        'templateName': d.templateName,
        'updatedAt': d.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _progressionRuleToMap(ProgressionRule r) => {
        'id': r.id,
        'programmeId': r.programmeId,
        'exerciseId': r.exerciseId,
        'type': r.type.name,
        'value': r.value,
        'frequencyWeeks': r.frequencyWeeks,
        'updatedAt': r.updatedAt.toIso8601String(),
      };

  // ── JSON → Domain maps ─────────────────────────────────────────────

  Exercise _exerciseFromMap(Map<String, dynamic> m) => Exercise(
        id: m['id'] as String,
        name: m['name'] as String,
        category: ExerciseCategory.values.byName(m['category'] as String),
        muscleGroup: MuscleGroup.values.byName(m['muscleGroup'] as String),
        equipmentType:
            EquipmentType.values.byName(m['equipmentType'] as String),
        isCustom: m['isCustom'] as bool? ?? false,
        imageAsset: m['imageAsset'] as String?,
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        deletedAt: m['deletedAt'] != null
            ? DateTime.parse(m['deletedAt'] as String)
            : null,
      );

  Workout _workoutFromMap(Map<String, dynamic> m) => Workout(
        id: m['id'] as String,
        startedAt: DateTime.parse(m['startedAt'] as String),
        completedAt: m['completedAt'] != null
            ? DateTime.parse(m['completedAt'] as String)
            : null,
        templateId: m['templateId'] as String?,
        notes: m['notes'] as String?,
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        deletedAt: m['deletedAt'] != null
            ? DateTime.parse(m['deletedAt'] as String)
            : null,
      );

  WorkoutSet _setFromMap(Map<String, dynamic> m) => WorkoutSet(
        id: m['id'] as String,
        workoutId: m['workoutId'] as String,
        exerciseId: m['exerciseId'] as String,
        setOrder: m['setOrder'] as int,
        weight: (m['weight'] as num).toDouble(),
        reps: m['reps'] as int,
        rpe: (m['rpe'] as num?)?.toDouble(),
        timestamp: DateTime.parse(m['timestamp'] as String),
        isWarmUp: m['isWarmUp'] as bool? ?? false,
        groupId: m['groupId'] as String?,
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  CardioSession _cardioFromMap(Map<String, dynamic> m) => CardioSession(
        id: m['id'] as String,
        workoutId: m['workoutId'] as String,
        exerciseId: m['exerciseId'] as String,
        durationSeconds: m['durationSeconds'] as int,
        distanceMeters: (m['distanceMeters'] as num?)?.toDouble(),
        incline: (m['incline'] as num?)?.toDouble(),
        avgHeartRate: m['avgHeartRate'] as int?,
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  PersonalRecord _personalRecordFromMap(Map<String, dynamic> m) =>
      PersonalRecord(
        id: m['id'] as String,
        exerciseId: m['exerciseId'] as String,
        recordType: RecordType.values.byName(m['recordType'] as String),
        value: (m['value'] as num).toDouble(),
        achievedAt: DateTime.parse(m['achievedAt'] as String),
        workoutSetId: m['workoutSetId'] as String?,
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  WorkoutTemplate _workoutTemplateFromMap(Map<String, dynamic> m) =>
      WorkoutTemplate(
        id: m['id'] as String,
        name: m['name'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  TemplateExercise _templateExerciseFromMap(Map<String, dynamic> m) =>
      TemplateExercise(
        id: m['id'] as String,
        templateId: m['templateId'] as String,
        exerciseId: m['exerciseId'] as String,
        exerciseName: m['exerciseName'] as String,
        targetSets: m['targetSets'] as int,
        targetReps: m['targetReps'] as int,
        orderIndex: m['orderIndex'] as int,
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  BodyMetric _bodyMetricFromMap(Map<String, dynamic> m) => BodyMetric(
        id: m['id'] as String,
        date: DateTime.parse(m['date'] as String),
        weight: (m['weight'] as num).toDouble(),
        bodyFatPercent: (m['bodyFatPercent'] as num?)?.toDouble(),
        notes: m['notes'] as String?,
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  Programme _programmeFromMap(Map<String, dynamic> m) => Programme(
        id: m['id'] as String,
        name: m['name'] as String,
        durationWeeks: m['durationWeeks'] as int,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        startedAt: m['startedAt'] == null
            ? null
            : DateTime.parse(m['startedAt'] as String),
      );

  ProgrammeDay _programmeDayFromMap(Map<String, dynamic> m) => ProgrammeDay(
        id: m['id'] as String,
        programmeId: m['programmeId'] as String,
        weekNumber: m['weekNumber'] as int,
        dayOfWeek: m['dayOfWeek'] as int,
        templateId: m['templateId'] as String,
        templateName: m['templateName'] as String,
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  ProgressionRule _progressionRuleFromMap(Map<String, dynamic> m) =>
      ProgressionRule(
        id: m['id'] as String,
        programmeId: m['programmeId'] as String,
        exerciseId: m['exerciseId'] as String,
        type: ProgressionType.values.byName(m['type'] as String),
        value: (m['value'] as num).toDouble(),
        frequencyWeeks: m['frequencyWeeks'] as int? ?? 1,
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );
}
