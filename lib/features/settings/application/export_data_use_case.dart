import 'dart:convert';

import '../../body_metrics/domain/models/body_metric.dart';
import '../../body_metrics/domain/repositories/body_metric_repository.dart';
import '../../cardio/domain/models/cardio_session.dart';
import '../../cardio/domain/repositories/cardio_session_repository.dart';
import 'package:hr_zones/hr_zones.dart';

import '../../clients/domain/models/client.dart';
import '../../clients/domain/repositories/client_repository.dart';
import '../../clients/domain/repositories/health_profile_repository.dart';
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

/// Version of the JSON backup written by [ExportDataUseCase.exportAsJson].
///
/// - 1: workouts, sets, cardio, PRs, body metrics, stretching; client ids
///   present on records but no roster, so restores collapsed onto Me.
/// - 2: adds the client roster with health profiles, templates and
///   programmes, per-set heart-rate fields, and a restore that keeps each
///   record's owner.
const int kBackupFormatVersion = 2;

class ExportDataUseCase {
  final WorkoutRepository workoutRepository;
  final ExerciseRepository exerciseRepository;
  final CardioSessionRepository cardioSessionRepository;
  final PersonalRecordRepository personalRecordRepository;
  final StretchingSessionRepository stretchingSessionRepository;
  final ClientRepository clientRepository;
  final BodyMetricRepository bodyMetricRepository;
  final HealthProfileRepository? healthProfileRepository;
  final WorkoutTemplateRepository? workoutTemplateRepository;
  final ProgrammeRepository? programmeRepository;

  /// The last three are optional so the CSV-only paths and older call
  /// sites need not supply them; a JSON backup without them simply omits
  /// those sections.
  const ExportDataUseCase({
    required this.workoutRepository,
    required this.exerciseRepository,
    required this.cardioSessionRepository,
    required this.personalRecordRepository,
    required this.stretchingSessionRepository,
    required this.clientRepository,
    required this.bodyMetricRepository,
    this.healthProfileRepository,
    this.workoutTemplateRepository,
    this.programmeRepository,
  });

  /// "Export All Data" is a full backup, so it must cover every client in
  /// the roster — not just Me — otherwise a restore silently drops other
  /// clients' history.
  Future<List<Client>> _allClients() => clientRepository.watchClients().first;

  Future<String> exportAsJson() async {
    final exercises = await exerciseRepository.getAllExercises();
    final clients = await _allClients();

    final workouts = <Workout>[];
    final cardioSessions = <CardioSession>[];
    final personalRecords = <PersonalRecord>[];
    final bodyMetrics = <BodyMetric>[];
    for (final client in clients) {
      workouts.addAll(await workoutRepository.getWorkoutHistory(
        clientId: client.id,
        limit: 10000,
      ));
      cardioSessions.addAll(
        await cardioSessionRepository.getAllSessions(client.id),
      );
      personalRecords.addAll(await personalRecordRepository.getAllRecords(
        clientId: client.id,
        limit: 10000,
      ));
      bodyMetrics.addAll(await bodyMetricRepository.getAll(
        clientId: client.id,
        limit: 10000,
      ));
    }
    final stretchingSessions =
        await stretchingSessionRepository.getAllSessions();

    final workoutsWithSets = <Map<String, dynamic>>[];
    for (final workout in workouts) {
      final sets = await workoutRepository.getSetsForWorkout(workout.id);
      workoutsWithSets.add({
        ..._workoutToMap(workout),
        'sets': sets.map(_setToMap).toList(),
      });
    }

    final clientMaps = <Map<String, dynamic>>[];
    for (final client in clients) {
      final profile = await healthProfileRepository?.getForClient(client.id);
      clientMaps.add(_clientToMap(client, profile));
    }
    final templates =
        await workoutTemplateRepository?.getAllTemplates() ?? const [];
    final programmes =
        await programmeRepository?.getAllProgrammes() ?? const [];

    final cardioMaps = <Map<String, dynamic>>[];
    for (final session in cardioSessions) {
      final points = await cardioSessionRepository.getTrackPoints(session.id);
      final samples =
          await cardioSessionRepository.getHeartRateSamples(session.id);
      cardioMaps.add({
        ..._cardioToMap(session),
        'trackPoints': [
          for (final p in points)
            {
              'timestamp': p.timestamp.toIso8601String(),
              'latitude': p.latitude,
              'longitude': p.longitude,
              'altitude': p.altitude,
              'accuracy': p.accuracy,
            },
        ],
        'heartRateSamples': [
          for (final h in samples)
            {'timestamp': h.timestamp.toIso8601String(), 'bpm': h.bpm},
        ],
      });
    }

    final data = {
      'formatVersion': kBackupFormatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'clients': clientMaps,
      'exercises': exercises.map(_exerciseToMap).toList(),
      'workoutTemplates': templates.map(_templateToMap).toList(),
      'programmes': programmes.map(_programmeToMap).toList(),
      'workouts': workoutsWithSets,
      'cardioSessions': cardioMaps,
      'personalRecords': personalRecords.map(_prToMap).toList(),
      'bodyMetrics': bodyMetrics.map(_bodyMetricToMap).toList(),
      'stretchingSessions': stretchingSessions.map(_stretchingToMap).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<Map<String, String>> exportAsCsv() async {
    final exercises = await exerciseRepository.getAllExercises();
    final exerciseNames = {for (final e in exercises) e.id: e.name};

    final clients = await _allClients();

    final workouts = <Workout>[];
    final cardioSessions = <CardioSession>[];
    final personalRecords = <PersonalRecord>[];
    final bodyMetrics = <BodyMetric>[];
    for (final client in clients) {
      workouts.addAll(await workoutRepository.getWorkoutHistory(
        clientId: client.id,
        limit: 10000,
      ));
      cardioSessions.addAll(
        await cardioSessionRepository.getAllSessions(client.id),
      );
      personalRecords.addAll(await personalRecordRepository.getAllRecords(
        clientId: client.id,
        limit: 10000,
      ));
      bodyMetrics.addAll(await bodyMetricRepository.getAll(
        clientId: client.id,
        limit: 10000,
      ));
    }
    final stretchingSessions =
        await stretchingSessionRepository.getAllSessions();

    // ISO-8601 in UTC with an explicit Z: the value is an unambiguous
    // instant, so the app's own importer (and any other consumer) reads it
    // back identically whatever timezone the device is in.
    String stamp(DateTime t) => t.toUtc().toIso8601String();

    // sets.csv — client_id is the parent workout's, since WorkoutSet itself
    // is not directly client-scoped.
    final setLines = StringBuffer()
      ..writeln('client_id,date,exercise,weight,reps,rpe,volume,e1rm');
    for (final workout in workouts) {
      final sets = await workoutRepository.getSetsForWorkout(workout.id);
      for (final set in sets) {
        final name =
            _escapeCsv(exerciseNames[set.exerciseId] ?? set.exerciseId);
        final date = stamp(set.timestamp);
        final rpe = set.rpe?.toStringAsFixed(1) ?? '';
        setLines.writeln(
          '${workout.clientId},$date,$name,${set.weight},${set.reps},$rpe,${set.volume},${set.estimatedOneRepMax.toStringAsFixed(1)}',
        );
      }
    }

    // cardio.csv
    final cardioLines = StringBuffer()
      ..writeln(
          'client_id,date,exercise,duration_min,distance_km,avg_pace,avg_heart_rate');
    for (final session in cardioSessions) {
      final name =
          _escapeCsv(exerciseNames[session.exerciseId] ?? session.exerciseId);
      // Find workout date
      final workout = await workoutRepository.getWorkout(session.workoutId);
      final date = workout != null ? stamp(workout.startedAt) : '';
      final durationMin = (session.durationSeconds / 60).toStringAsFixed(1);
      final distanceKm = session.distanceMeters != null
          ? (session.distanceMeters! / 1000).toStringAsFixed(2)
          : '';
      final pace = session.paceMinutesPerKm?.toStringAsFixed(2) ?? '';
      final hr = session.avgHeartRate?.toString() ?? '';
      cardioLines.writeln(
          '${session.clientId},$date,$name,$durationMin,$distanceKm,$pace,$hr');
    }

    // personal_records.csv
    final prLines = StringBuffer()
      ..writeln('client_id,date,exercise,record_type,value');
    for (final pr in personalRecords) {
      final name = _escapeCsv(exerciseNames[pr.exerciseId] ?? pr.exerciseId);
      final date = stamp(pr.achievedAt);
      prLines.writeln(
          '${pr.clientId},$date,$name,${pr.recordType.name},${pr.value}');
    }

    // body_metrics.csv
    final bodyMetricLines = StringBuffer()
      ..writeln('client_id,date,weight,body_fat_percent,notes');
    for (final metric in bodyMetrics) {
      final date = stamp(metric.date);
      final bodyFat = metric.bodyFatPercent?.toString() ?? '';
      bodyMetricLines.writeln(
        '${metric.clientId},$date,${metric.weight},$bodyFat,${_escapeCsv(metric.notes ?? '')}',
      );
    }

    // stretching.csv — one row per session. workoutDate is the parent
    // workout's startedAt (blank if the parent has been deleted).
    final stretchingLines = StringBuffer()
      ..writeln(
        'workout_date,type,custom_name,body_area,side,duration_seconds,'
        'started_at,ended_at,entry_method,notes',
      );
    for (final s in stretchingSessions) {
      final parent = await workoutRepository.getWorkout(s.workoutId);
      final workoutDate = parent != null ? stamp(parent.startedAt) : '';
      final startedAt =
          s.startedAt != null ? s.startedAt!.toUtc().toIso8601String() : '';
      final endedAt =
          s.endedAt != null ? s.endedAt!.toUtc().toIso8601String() : '';
      stretchingLines.writeln(
        '$workoutDate,'
        '${_escapeCsv(s.type)},'
        '${_escapeCsv(s.customName ?? '')},'
        '${s.bodyArea?.name ?? ''},'
        '${s.side?.name ?? ''},'
        '${s.durationSeconds},'
        '$startedAt,'
        '$endedAt,'
        '${s.entryMethod.name},'
        '${_escapeCsv(s.notes ?? '')}',
      );
    }

    return {
      'sets.csv': setLines.toString(),
      'cardio.csv': cardioLines.toString(),
      'personal_records.csv': prLines.toString(),
      'body_metrics.csv': bodyMetricLines.toString(),
      'stretching.csv': stretchingLines.toString(),
    };
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Map<String, dynamic> _clientToMap(Client c, HealthProfile? profile) => {
        'id': c.id,
        'name': c.name,
        'colour': c.colour,
        'notes': c.notes,
        'isSelf': c.isSelf,
        'createdAt': c.createdAt.toIso8601String(),
        if (profile != null)
          'healthProfile': {
            'age': profile.age,
            'restingHr': profile.restingHr,
            'measuredMaxHr': profile.measuredMaxHr,
            'clinicianMaxHr': profile.clinicianMaxHr,
            'betaBlocker': profile.betaBlocker,
            'heartCondition': profile.heartCondition,
          },
      };

  Map<String, dynamic> _templateToMap(WorkoutTemplate t) => {
        'id': t.id,
        'name': t.name,
        'createdAt': t.createdAt.toIso8601String(),
        'exercises': [
          for (final e in t.exercises)
            {
              'id': e.id,
              'exerciseId': e.exerciseId,
              'exerciseName': e.exerciseName,
              'targetSets': e.targetSets,
              'targetReps': e.targetReps,
              'orderIndex': e.orderIndex,
            },
        ],
      };

  Map<String, dynamic> _programmeToMap(Programme p) => {
        'id': p.id,
        'name': p.name,
        'durationWeeks': p.durationWeeks,
        'createdAt': p.createdAt.toIso8601String(),
        'startedAt': p.startedAt?.toIso8601String(),
        'days': [
          for (final d in p.days)
            {
              'id': d.id,
              'weekNumber': d.weekNumber,
              'dayOfWeek': d.dayOfWeek,
              'templateId': d.templateId,
              'templateName': d.templateName,
            },
        ],
        'rules': [
          for (final r in p.rules)
            {
              'id': r.id,
              'exerciseId': r.exerciseId,
              'type': r.type.name,
              'value': r.value,
              'frequencyWeeks': r.frequencyWeeks,
            },
        ],
      };

  Map<String, dynamic> _exerciseToMap(Exercise e) => {
        'id': e.id,
        'name': e.name,
        'category': e.category.name,
        'muscleGroup': e.muscleGroup.name,
        'equipmentType': e.equipmentType.name,
        'isCustom': e.isCustom,
      };

  Map<String, dynamic> _workoutToMap(Workout w) => {
        'id': w.id,
        'startedAt': w.startedAt.toIso8601String(),
        'completedAt': w.completedAt?.toIso8601String(),
        'templateId': w.templateId,
        'notes': w.notes,
        'clientId': w.clientId,
      };

  Map<String, dynamic> _setToMap(WorkoutSet s) => {
        'id': s.id,
        'exerciseId': s.exerciseId,
        'setOrder': s.setOrder,
        'weight': s.weight,
        'reps': s.reps,
        'rpe': s.rpe,
        'timestamp': s.timestamp.toIso8601String(),
        'volume': s.volume,
        'estimatedOneRepMax': s.estimatedOneRepMax,
        'isWarmUp': s.isWarmUp,
        'groupId': s.groupId,
        'avgHeartRate': s.avgHeartRate,
        'peakHeartRate': s.peakHeartRate,
      };

  Map<String, dynamic> _cardioToMap(CardioSession c) => {
        'id': c.id,
        'workoutId': c.workoutId,
        'exerciseId': c.exerciseId,
        'durationSeconds': c.durationSeconds,
        'distanceMeters': c.distanceMeters,
        'incline': c.incline,
        'avgHeartRate': c.avgHeartRate,
        'clientId': c.clientId,
      };

  Map<String, dynamic> _prToMap(PersonalRecord pr) => {
        'id': pr.id,
        'exerciseId': pr.exerciseId,
        'recordType': pr.recordType.name,
        'value': pr.value,
        'achievedAt': pr.achievedAt.toIso8601String(),
        'workoutSetId': pr.workoutSetId,
        'clientId': pr.clientId,
      };

  Map<String, dynamic> _bodyMetricToMap(BodyMetric m) => {
        'id': m.id,
        'date': m.date.toIso8601String(),
        'weight': m.weight,
        'bodyFatPercent': m.bodyFatPercent,
        'notes': m.notes,
        'clientId': m.clientId,
      };

  Map<String, dynamic> _stretchingToMap(StretchingSession s) => {
        'id': s.id,
        'workoutId': s.workoutId,
        'type': s.type,
        'customName': s.customName,
        'bodyArea': s.bodyArea?.name,
        'side': s.side?.name,
        'durationSeconds': s.durationSeconds,
        'startedAt': s.startedAt?.toIso8601String(),
        'endedAt': s.endedAt?.toIso8601String(),
        'entryMethod': s.entryMethod.name,
        'notes': s.notes,
        'updatedAt': s.updatedAt.toIso8601String(),
      };
}
