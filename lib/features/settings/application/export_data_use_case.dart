import 'dart:convert';

import 'package:intl/intl.dart';

import '../../cardio/domain/models/cardio_session.dart';
import '../../cardio/domain/repositories/cardio_session_repository.dart';
import '../../exercises/domain/models/exercise.dart';
import '../../exercises/domain/repositories/exercise_repository.dart';
import '../../history/domain/models/personal_record.dart';
import '../../history/domain/repositories/personal_record_repository.dart';
import '../../workout/domain/models/workout.dart';
import '../../workout/domain/models/workout_set.dart';
import '../../workout/domain/repositories/workout_repository.dart';

class ExportDataUseCase {
  final WorkoutRepository workoutRepository;
  final ExerciseRepository exerciseRepository;
  final CardioSessionRepository cardioSessionRepository;
  final PersonalRecordRepository personalRecordRepository;

  const ExportDataUseCase({
    required this.workoutRepository,
    required this.exerciseRepository,
    required this.cardioSessionRepository,
    required this.personalRecordRepository,
  });

  Future<String> exportAsJson() async {
    final exercises = await exerciseRepository.getAllExercises();
    final workouts = await workoutRepository.getWorkoutHistory(limit: 10000);
    final cardioSessions = await cardioSessionRepository.getAllSessions();
    final personalRecords = await personalRecordRepository.getAllRecords(
      limit: 10000,
    );

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
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<Map<String, String>> exportAsCsv() async {
    final exercises = await exerciseRepository.getAllExercises();
    final exerciseNames = {for (final e in exercises) e.id: e.name};

    final workouts = await workoutRepository.getWorkoutHistory(limit: 10000);
    final cardioSessions = await cardioSessionRepository.getAllSessions();
    final personalRecords = await personalRecordRepository.getAllRecords(
      limit: 10000,
    );

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // sets.csv
    final setLines = StringBuffer()
      ..writeln('date,exercise,weight,reps,rpe,volume,e1rm');
    for (final workout in workouts) {
      final sets = await workoutRepository.getSetsForWorkout(workout.id);
      for (final set in sets) {
        final name = _escapeCsv(exerciseNames[set.exerciseId] ?? set.exerciseId);
        final date = dateFormat.format(set.timestamp);
        final rpe = set.rpe?.toStringAsFixed(1) ?? '';
        setLines.writeln(
          '$date,$name,${set.weight},${set.reps},$rpe,${set.volume},${set.estimatedOneRepMax.toStringAsFixed(1)}',
        );
      }
    }

    // cardio.csv
    final cardioLines = StringBuffer()
      ..writeln('date,exercise,duration_min,distance_km,avg_pace,avg_heart_rate');
    for (final session in cardioSessions) {
      final name = _escapeCsv(exerciseNames[session.exerciseId] ?? session.exerciseId);
      // Find workout date
      final workout = await workoutRepository.getWorkout(session.workoutId);
      final date = workout != null
          ? dateFormat.format(workout.startedAt)
          : '';
      final durationMin = (session.durationSeconds / 60).toStringAsFixed(1);
      final distanceKm = session.distanceMeters != null
          ? (session.distanceMeters! / 1000).toStringAsFixed(2)
          : '';
      final pace = session.paceMinutesPerKm?.toStringAsFixed(2) ?? '';
      final hr = session.avgHeartRate?.toString() ?? '';
      cardioLines.writeln('$date,$name,$durationMin,$distanceKm,$pace,$hr');
    }

    // personal_records.csv
    final prLines = StringBuffer()
      ..writeln('date,exercise,record_type,value');
    for (final pr in personalRecords) {
      final name = _escapeCsv(exerciseNames[pr.exerciseId] ?? pr.exerciseId);
      final date = dateFormat.format(pr.achievedAt);
      prLines.writeln('$date,$name,${pr.recordType.name},${pr.value}');
    }

    return {
      'sets.csv': setLines.toString(),
      'cardio.csv': cardioLines.toString(),
      'personal_records.csv': prLines.toString(),
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
      };

  Map<String, dynamic> _prToMap(PersonalRecord pr) => {
        'id': pr.id,
        'exerciseId': pr.exerciseId,
        'recordType': pr.recordType.name,
        'value': pr.value,
        'achievedAt': pr.achievedAt.toIso8601String(),
        'workoutSetId': pr.workoutSetId,
      };
}
