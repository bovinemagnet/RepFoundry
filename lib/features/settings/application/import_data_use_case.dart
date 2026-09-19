import 'dart:convert';

import 'package:csv/csv.dart';

import 'package:hr_zones/hr_zones.dart';

import '../../../core/units/weight_unit.dart';
import '../../body_metrics/domain/models/body_metric.dart';
import '../../body_metrics/domain/repositories/body_metric_repository.dart';
import '../../clients/domain/models/client.dart';
import '../../clients/domain/repositories/client_repository.dart';
import '../../clients/domain/repositories/health_profile_repository.dart';
import 'import/csv_format_adapter.dart';
import 'import/csv_import_engine.dart';
import '../../cardio/domain/models/cardio_session.dart';
import '../../cardio/domain/repositories/cardio_session_repository.dart';
import '../../exercises/domain/models/exercise.dart';
import '../../exercises/domain/repositories/exercise_repository.dart';
import '../../history/domain/models/personal_record.dart';
import '../../history/domain/repositories/personal_record_repository.dart';
import '../../programmes/domain/models/programme.dart';
import '../../programmes/domain/repositories/programme_repository.dart';
import '../../stretching/domain/models/stretching_session.dart';
import '../../stretching/domain/repositories/stretching_session_repository.dart';
import '../../templates/domain/models/workout_template.dart';
import '../../templates/domain/repositories/workout_template_repository.dart';
import '../../workout/domain/models/workout.dart';
import '../../workout/domain/models/workout_set.dart';
import '../../workout/domain/repositories/workout_repository.dart';

class ImportResult {
  final int clientsImported;
  final int templatesImported;
  final int programmesImported;
  final int bodyMetricsImported;
  final int exercisesImported;
  final int workoutsImported;
  final int setsImported;
  final int cardioSessionsImported;
  final int personalRecordsImported;
  final int stretchingSessionsImported;
  final int stretchingSessionsSkipped;

  /// Custom exercises created for CSV rows whose exercise name matched
  /// nothing in the library.
  final int exercisesCreated;

  /// Rows the parser could not import (cardio-shaped, zero reps,
  /// unparseable).
  final int rowsSkipped;

  /// Entities skipped because an identical import already exists
  /// (re-importing the same file).
  final int duplicatesSkipped;

  const ImportResult({
    this.clientsImported = 0,
    this.templatesImported = 0,
    this.programmesImported = 0,
    this.bodyMetricsImported = 0,
    this.exercisesImported = 0,
    this.workoutsImported = 0,
    this.setsImported = 0,
    this.cardioSessionsImported = 0,
    this.personalRecordsImported = 0,
    this.stretchingSessionsImported = 0,
    this.stretchingSessionsSkipped = 0,
    this.exercisesCreated = 0,
    this.rowsSkipped = 0,
    this.duplicatesSkipped = 0,
  });
}

/// What a CSV file was detected as, shown before the user confirms.
class CsvImportPreview {
  final String formatName;

  /// True when the file declares no weight unit and the user must choose.
  final bool needsUnitChoice;

  const CsvImportPreview({
    required this.formatName,
    required this.needsUnitChoice,
  });
}

class ImportDataUseCase {
  final WorkoutRepository workoutRepository;
  final ExerciseRepository exerciseRepository;
  final CardioSessionRepository cardioSessionRepository;
  final PersonalRecordRepository personalRecordRepository;
  final StretchingSessionRepository stretchingSessionRepository;
  final ClientRepository? clientRepository;
  final HealthProfileRepository? healthProfileRepository;
  final WorkoutTemplateRepository? workoutTemplateRepository;
  final ProgrammeRepository? programmeRepository;
  final BodyMetricRepository? bodyMetricRepository;

  /// The optional repositories cover the sections a version-2 backup adds;
  /// a section whose repository is absent is skipped. Without
  /// [clientRepository] every record is restored to Me.
  const ImportDataUseCase({
    required this.workoutRepository,
    required this.exerciseRepository,
    required this.cardioSessionRepository,
    required this.personalRecordRepository,
    required this.stretchingSessionRepository,
    this.clientRepository,
    this.healthProfileRepository,
    this.workoutTemplateRepository,
    this.programmeRepository,
    this.bodyMetricRepository,
  });

  /// Detects the CSV format of [content] for the confirmation dialog.
  /// Null when the content matches no supported CSV layout.
  CsvImportPreview? previewCsv(String content) {
    final rows = _decodeCsv(content);
    if (rows == null) return null;
    final adapter = detectCsvAdapter(rows);
    if (adapter == null) return null;
    return CsvImportPreview(
      formatName: adapter.formatName,
      needsUnitChoice: adapter.requiresUnitChoice(rows.first),
    );
  }

  /// Imports workout history from CSV [content] (RepFoundry, Strong, or
  /// Hevy layout). [fallbackUnit] applies only where the file declares no
  /// weight unit. Throws [FormatException] for unrecognised content.
  Future<ImportResult> importFromCsv(
    String content, {
    WeightUnit fallbackUnit = WeightUnit.kg,
  }) async {
    final rows = _decodeCsv(content);
    final adapter = rows == null ? null : detectCsvAdapter(rows);
    if (rows == null || adapter == null) {
      throw const FormatException('Unrecognised CSV format');
    }

    final history = adapter.parse(rows, fallbackUnit: fallbackUnit);
    final engine = CsvImportEngine(
      workoutRepository: workoutRepository,
      exerciseRepository: exerciseRepository,
      personalRecordRepository: personalRecordRepository,
    );
    return engine.import(history);
  }

  List<List<dynamic>>? _decodeCsv(String content) {
    try {
      final rows = Csv().decode(content);
      return rows.isEmpty ? null : rows;
    } on Exception {
      return null;
    }
  }

  /// Restores a JSON backup. Parents are restored before children and
  /// each record's owner is kept when that client is in the restored
  /// roster (falling back to Me otherwise, which is all a version-1 file
  /// can support).
  ///
  /// Every insert is preceded by an existence check, so re-running the same
  /// file — or retrying after a partial restore — adds only what is
  /// missing. Because duplicates never reach the repository, any error a
  /// repository does throw is a genuine storage failure and propagates
  /// rather than being mistaken for a duplicate.
  Future<ImportResult> importFromJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final now = DateTime.now().toUtc();

    var clientsImported = 0;
    var exercisesImported = 0;
    var templatesImported = 0;
    var programmesImported = 0;
    var workoutsImported = 0;
    var setsImported = 0;
    var cardioSessionsImported = 0;
    var prsImported = 0;
    var bodyMetricsImported = 0;
    var stretchingImported = 0;
    var stretchingSkipped = 0;
    var duplicatesSkipped = 0;

    // Clients and their health profiles first: everything else hangs off
    // them.
    final knownClientIds = <String>{kSelfClientId};
    final clients = clientRepository;
    if (clients != null) {
      for (final entry in data['clients'] as List<dynamic>? ?? const []) {
        final map = entry as Map<String, dynamic>;
        final id = map['id'] as String;
        final isSelf = map['isSelf'] as bool? ?? id == kSelfClientId;
        if (!isSelf) {
          if (await clients.getClient(id) == null) {
            await clients.createClient(Client(
              id: id,
              name: map['name'] as String,
              colour: map['colour'] as int,
              notes: map['notes'] as String?,
              isSelf: false,
              createdAt: _dateOr(map['createdAt'], now),
              updatedAt: now,
              deletedAt: null,
            ));
            clientsImported++;
          } else {
            duplicatesSkipped++;
          }
        }
        knownClientIds.add(isSelf ? kSelfClientId : id);

        final profileMap = map['healthProfile'] as Map<String, dynamic>?;
        if (profileMap != null) {
          await healthProfileRepository?.saveForClient(
            isSelf ? kSelfClientId : id,
            HealthProfile(
              age: profileMap['age'] as int?,
              restingHr: profileMap['restingHr'] as int?,
              measuredMaxHr: profileMap['measuredMaxHr'] as int?,
              clinicianMaxHr: profileMap['clinicianMaxHr'] as int?,
              betaBlocker: profileMap['betaBlocker'] as bool? ?? false,
              heartCondition: profileMap['heartCondition'] as bool? ?? false,
            ),
          );
        }
      }
    }
    String ownerOf(Map<String, dynamic> map) {
      final id = map['clientId'] as String?;
      return id != null && knownClientIds.contains(id) ? id : kSelfClientId;
    }

    // Custom exercises.
    for (final entry in data['exercises'] as List<dynamic>? ?? const []) {
      final map = entry as Map<String, dynamic>;
      if (map['isCustom'] != true) continue;
      final id = map['id'] as String;
      if (await exerciseRepository.getExercise(id) != null) {
        duplicatesSkipped++;
        continue;
      }
      await exerciseRepository.createExercise(Exercise(
        id: id,
        name: map['name'] as String,
        category:
            _parseEnum(ExerciseCategory.values, map['category'] as String),
        muscleGroup:
            _parseEnum(MuscleGroup.values, map['muscleGroup'] as String),
        equipmentType:
            _parseEnum(EquipmentType.values, map['equipmentType'] as String),
        isCustom: true,
        updatedAt: now,
      ));
      exercisesImported++;
    }

    // Templates, then programmes (whose days reference templates).
    final templates = workoutTemplateRepository;
    if (templates != null) {
      for (final entry
          in data['workoutTemplates'] as List<dynamic>? ?? const []) {
        final map = entry as Map<String, dynamic>;
        final id = map['id'] as String;
        if (await templates.getTemplate(id) != null) {
          duplicatesSkipped++;
          continue;
        }
        await templates.createTemplate(WorkoutTemplate(
          id: id,
          name: map['name'] as String,
          createdAt: _dateOr(map['createdAt'], now),
          updatedAt: now,
          exercises: [
            for (final e in map['exercises'] as List<dynamic>? ?? const [])
              TemplateExercise(
                id: (e as Map<String, dynamic>)['id'] as String,
                templateId: id,
                exerciseId: e['exerciseId'] as String,
                exerciseName: e['exerciseName'] as String,
                targetSets: e['targetSets'] as int,
                targetReps: e['targetReps'] as int,
                orderIndex: e['orderIndex'] as int,
                updatedAt: now,
              ),
          ],
        ));
        templatesImported++;
      }
    }

    final programmes = programmeRepository;
    if (programmes != null) {
      for (final entry in data['programmes'] as List<dynamic>? ?? const []) {
        final map = entry as Map<String, dynamic>;
        final id = map['id'] as String;
        if (await programmes.getProgramme(id) != null) {
          duplicatesSkipped++;
          continue;
        }
        await programmes.createProgramme(Programme(
          id: id,
          name: map['name'] as String,
          durationWeeks: map['durationWeeks'] as int,
          createdAt: _dateOr(map['createdAt'], now),
          updatedAt: now,
          startedAt: map['startedAt'] != null
              ? DateTime.parse(map['startedAt'] as String)
              : null,
        ));
        for (final d in map['days'] as List<dynamic>? ?? const []) {
          final dayMap = d as Map<String, dynamic>;
          await programmes.addDay(ProgrammeDay(
            id: dayMap['id'] as String,
            programmeId: id,
            weekNumber: dayMap['weekNumber'] as int,
            dayOfWeek: dayMap['dayOfWeek'] as int,
            templateId: dayMap['templateId'] as String,
            templateName: dayMap['templateName'] as String,
            updatedAt: now,
          ));
        }
        for (final r in map['rules'] as List<dynamic>? ?? const []) {
          final ruleMap = r as Map<String, dynamic>;
          await programmes.addRule(ProgressionRule(
            id: ruleMap['id'] as String,
            programmeId: id,
            exerciseId: ruleMap['exerciseId'] as String,
            type: _parseEnum(ProgressionType.values, ruleMap['type'] as String),
            value: (ruleMap['value'] as num).toDouble(),
            frequencyWeeks: ruleMap['frequencyWeeks'] as int? ?? 1,
            updatedAt: now,
          ));
        }
        programmesImported++;
      }
    }

    // Workouts and their sets. An existing parent is still walked so a
    // retry after a partial restore can add its missing sets.
    final landedWorkoutIds = <String>{};
    for (final entry in data['workouts'] as List<dynamic>? ?? const []) {
      final map = entry as Map<String, dynamic>;
      final workoutId = map['id'] as String;
      if (await workoutRepository.getWorkout(workoutId) == null) {
        await workoutRepository.createWorkout(Workout(
          id: workoutId,
          startedAt: DateTime.parse(map['startedAt'] as String),
          completedAt: map['completedAt'] != null
              ? DateTime.parse(map['completedAt'] as String)
              : null,
          templateId: map['templateId'] as String?,
          notes: map['notes'] as String?,
          clientId: ownerOf(map),
          updatedAt: now,
        ));
        workoutsImported++;
      } else {
        duplicatesSkipped++;
      }
      landedWorkoutIds.add(workoutId);

      final existingSetIds = (await workoutRepository.getSetsForWorkout(
        workoutId,
      ))
          .map((s) => s.id)
          .toSet();
      for (final setEntry in map['sets'] as List<dynamic>? ?? const []) {
        final s = setEntry as Map<String, dynamic>;
        final setId = s['id'] as String;
        if (existingSetIds.contains(setId)) {
          duplicatesSkipped++;
          continue;
        }
        await workoutRepository.addSet(WorkoutSet(
          id: setId,
          workoutId: workoutId,
          exerciseId: s['exerciseId'] as String,
          setOrder: s['setOrder'] as int,
          weight: (s['weight'] as num).toDouble(),
          reps: s['reps'] as int,
          rpe: s['rpe'] != null ? (s['rpe'] as num).toDouble() : null,
          timestamp: DateTime.parse(s['timestamp'] as String),
          isWarmUp: s['isWarmUp'] as bool? ?? false,
          groupId: s['groupId'] as String?,
          avgHeartRate: s['avgHeartRate'] as int?,
          peakHeartRate: s['peakHeartRate'] as int?,
          updatedAt: now,
        ));
        existingSetIds.add(setId);
        setsImported++;
      }
    }

    // Cardio sessions.
    for (final entry in data['cardioSessions'] as List<dynamic>? ?? const []) {
      final map = entry as Map<String, dynamic>;
      final id = map['id'] as String;
      if (await cardioSessionRepository.getSession(id) != null) {
        duplicatesSkipped++;
        continue;
      }
      await cardioSessionRepository.createSession(CardioSession(
        id: id,
        workoutId: map['workoutId'] as String,
        exerciseId: map['exerciseId'] as String,
        durationSeconds: map['durationSeconds'] as int,
        distanceMeters: map['distanceMeters'] != null
            ? (map['distanceMeters'] as num).toDouble()
            : null,
        incline:
            map['incline'] != null ? (map['incline'] as num).toDouble() : null,
        avgHeartRate: map['avgHeartRate'] as int?,
        clientId: ownerOf(map),
        updatedAt: now,
      ));
      cardioSessionsImported++;
    }

    // Personal records.
    for (final entry in data['personalRecords'] as List<dynamic>? ?? const []) {
      final map = entry as Map<String, dynamic>;
      final id = map['id'] as String;
      if (await personalRecordRepository.getRecord(id) != null) {
        duplicatesSkipped++;
        continue;
      }
      await personalRecordRepository.createRecord(PersonalRecord(
        id: id,
        exerciseId: map['exerciseId'] as String,
        recordType: _parseEnum(RecordType.values, map['recordType'] as String),
        value: (map['value'] as num).toDouble(),
        achievedAt: DateTime.parse(map['achievedAt'] as String),
        workoutSetId: map['workoutSetId'] as String?,
        clientId: ownerOf(map),
        updatedAt: now,
      ));
      prsImported++;
    }

    // Body metrics.
    final bodyMetrics = bodyMetricRepository;
    if (bodyMetrics != null) {
      final existingMetricIds = <String>{};
      for (final clientId in knownClientIds) {
        final existing =
            await bodyMetrics.getAll(clientId: clientId, limit: 100000);
        existingMetricIds.addAll(existing.map((m) => m.id));
      }
      for (final entry in data['bodyMetrics'] as List<dynamic>? ?? const []) {
        final map = entry as Map<String, dynamic>;
        final id = map['id'] as String;
        if (existingMetricIds.contains(id)) {
          duplicatesSkipped++;
          continue;
        }
        await bodyMetrics.create(BodyMetric(
          id: id,
          date: DateTime.parse(map['date'] as String),
          weight: (map['weight'] as num).toDouble(),
          bodyFatPercent: map['bodyFatPercent'] != null
              ? (map['bodyFatPercent'] as num).toDouble()
              : null,
          notes: map['notes'] as String?,
          clientId: ownerOf(map),
          updatedAt: now,
        ));
        bodyMetricsImported++;
      }
    }

    // Stretching sessions. Older exports lack this key; sessions whose
    // parent workout is absent are skipped rather than failing the import.
    for (final entry
        in data['stretchingSessions'] as List<dynamic>? ?? const []) {
      final map = entry as Map<String, dynamic>;
      final workoutId = map['workoutId'] as String;
      if (!landedWorkoutIds.contains(workoutId)) {
        if (await workoutRepository.getWorkout(workoutId) == null) {
          stretchingSkipped++;
          continue;
        }
        landedWorkoutIds.add(workoutId);
      }
      final id = map['id'] as String;
      if (await stretchingSessionRepository.getSession(id) != null) {
        duplicatesSkipped++;
        continue;
      }
      await stretchingSessionRepository.createSession(StretchingSession(
        id: id,
        workoutId: workoutId,
        type: map['type'] as String,
        customName: map['customName'] as String?,
        bodyArea: map['bodyArea'] != null
            ? _parseEnum(StretchingBodyArea.values, map['bodyArea'] as String)
            : null,
        side: map['side'] != null
            ? _parseEnum(StretchingSide.values, map['side'] as String)
            : null,
        durationSeconds: map['durationSeconds'] as int,
        startedAt: map['startedAt'] != null
            ? DateTime.parse(map['startedAt'] as String)
            : null,
        endedAt: map['endedAt'] != null
            ? DateTime.parse(map['endedAt'] as String)
            : null,
        entryMethod: _parseEnum(
          StretchingEntryMethod.values,
          map['entryMethod'] as String,
        ),
        notes: map['notes'] as String?,
        updatedAt: now,
      ));
      stretchingImported++;
    }

    return ImportResult(
      clientsImported: clientsImported,
      templatesImported: templatesImported,
      programmesImported: programmesImported,
      bodyMetricsImported: bodyMetricsImported,
      exercisesImported: exercisesImported,
      workoutsImported: workoutsImported,
      setsImported: setsImported,
      cardioSessionsImported: cardioSessionsImported,
      personalRecordsImported: prsImported,
      stretchingSessionsImported: stretchingImported,
      stretchingSessionsSkipped: stretchingSkipped,
      duplicatesSkipped: duplicatesSkipped,
    );
  }

  DateTime _dateOr(Object? iso, DateTime fallback) =>
      iso is String ? DateTime.parse(iso) : fallback;

  T _parseEnum<T extends Enum>(List<T> values, String name) {
    return values.firstWhere(
      (v) => v.name == name,
      orElse: () => throw FormatException('Unrecognised value "$name"'),
    );
  }
}
