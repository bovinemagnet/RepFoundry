import 'dart:convert';

import 'package:intl/intl.dart';

import '../../body_metrics/domain/models/body_metric.dart';
import '../../body_metrics/domain/repositories/body_metric_repository.dart';
import '../../cardio/domain/models/cardio_session.dart';
import '../../cardio/domain/repositories/cardio_session_repository.dart';
import '../../clients/domain/models/client.dart';
import '../../clients/domain/repositories/client_repository.dart';
import '../../exercises/domain/models/exercise.dart';
import '../../exercises/domain/repositories/exercise_repository.dart';
import '../../history/domain/models/personal_record.dart';
import '../../history/domain/repositories/personal_record_repository.dart';
import '../../stretching/domain/models/stretching_session.dart';
import '../../stretching/domain/repositories/stretching_session_repository.dart';
import '../../workout/domain/models/workout.dart';
import '../../workout/domain/models/workout_set.dart';
import '../../workout/domain/repositories/workout_repository.dart';

class ExportDataUseCase {
  final WorkoutRepository workoutRepository;
  final ExerciseRepository exerciseRepository;
  final CardioSessionRepository cardioSessionRepository;
  final PersonalRecordRepository personalRecordRepository;
  final StretchingSessionRepository stretchingSessionRepository;
  final ClientRepository clientRepository;
  final BodyMetricRepository bodyMetricRepository;

  const ExportDataUseCase({
    required this.workoutRepository,
    required this.exerciseRepository,
    required this.cardioSessionRepository,
    required this.personalRecordRepository,
    required this.stretchingSessionRepository,
    required this.clientRepository,
    required this.bodyMetricRepository,
  });

  /// "Export All Data" is a full backup, so it must cover every client in
  /// the roster — not just Me — otherwise a restore silently drops other
  /// clients' history. NOTE (v1 limitation): the import/restore side still
  /// consolidates everything onto Me; full client-aware restore is deferred
  /// to the roster-sync spec.
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

    final data = {
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'exercises': exercises.map(_exerciseToMap).toList(),
      'workouts': workoutsWithSets,
      'cardioSessions': cardioSessions.map(_cardioToMap).toList(),
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

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // sets.csv — client_id is the parent workout's, since WorkoutSet itself
    // is not directly client-scoped.
    final setLines = StringBuffer()
      ..writeln('client_id,date,exercise,weight,reps,rpe,volume,e1rm');
    for (final workout in workouts) {
      final sets = await workoutRepository.getSetsForWorkout(workout.id);
      for (final set in sets) {
        final name =
            _escapeCsv(exerciseNames[set.exerciseId] ?? set.exerciseId);
        final date = dateFormat.format(set.timestamp);
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
      final date = workout != null ? dateFormat.format(workout.startedAt) : '';
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
      final date = dateFormat.format(pr.achievedAt);
      prLines.writeln(
          '${pr.clientId},$date,$name,${pr.recordType.name},${pr.value}');
    }

    // body_metrics.csv
    final bodyMetricLines = StringBuffer()
      ..writeln('client_id,date,weight,body_fat_percent,notes');
    for (final metric in bodyMetrics) {
      final date = dateFormat.format(metric.date);
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
      final workoutDate =
          parent != null ? dateFormat.format(parent.startedAt) : '';
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
