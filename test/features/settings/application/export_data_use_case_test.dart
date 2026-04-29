import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart'
    as domain;
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/settings/application/export_data_use_case.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

void main() {
  late ExportDataUseCase useCase;
  late InMemoryWorkoutRepository workoutRepo;
  late InMemoryExerciseRepository exerciseRepo;
  late InMemoryCardioSessionRepository cardioRepo;
  late InMemoryPersonalRecordRepository prRepo;

  setUp(() {
    workoutRepo = InMemoryWorkoutRepository();
    exerciseRepo = InMemoryExerciseRepository();
    cardioRepo = InMemoryCardioSessionRepository();
    prRepo = InMemoryPersonalRecordRepository();
    useCase = ExportDataUseCase(
      workoutRepository: workoutRepo,
      exerciseRepository: exerciseRepo,
      cardioSessionRepository: cardioRepo,
      personalRecordRepository: prRepo,
    );
  });

  group('exportAsJson', () {
    test('returns valid JSON with required keys', () async {
      final json = await useCase.exportAsJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      expect(data.containsKey('exportedAt'), isTrue);
      expect(data.containsKey('exercises'), isTrue);
      expect(data.containsKey('workouts'), isTrue);
      expect(data.containsKey('cardioSessions'), isTrue);
      expect(data.containsKey('personalRecords'), isTrue);
    });

    test('includes exercises from repository', () async {
      final json = await useCase.exportAsJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      final exercises = data['exercises'] as List;
      expect(exercises, isNotEmpty);
    });

    test('includes workout sets nested under workouts', () async {
      final workout = Workout(
        id: 'w1',
        startedAt: DateTime(2024, 1, 1),
        completedAt: DateTime(2024, 1, 1, 1),
        updatedAt: DateTime.utc(2024),
      );
      await workoutRepo.createWorkout(workout);
      await workoutRepo.addSet(WorkoutSet(
        id: 's1',
        workoutId: 'w1',
        exerciseId: '1',
        setOrder: 1,
        weight: 100,
        reps: 5,
        timestamp: DateTime(2024, 1, 1),
        updatedAt: DateTime.utc(2024),
      ));

      final json = await useCase.exportAsJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      final workouts = data['workouts'] as List;
      expect(workouts, hasLength(1));
      final sets = workouts[0]['sets'] as List;
      expect(sets, hasLength(1));
      expect(sets[0]['weight'], 100);
    });

    test('handles empty data gracefully', () async {
      final json = await useCase.exportAsJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      expect(data['workouts'], isEmpty);
      expect(data['cardioSessions'], isEmpty);
      expect(data['personalRecords'], isEmpty);
    });
  });

  group('exportAsCsv', () {
    test('returns three CSV files', () async {
      final csvFiles = await useCase.exportAsCsv();
      expect(csvFiles.keys,
          containsAll(['sets.csv', 'cardio.csv', 'personal_records.csv']));
    });

    test('sets.csv has header row', () async {
      final csvFiles = await useCase.exportAsCsv();
      final lines = csvFiles['sets.csv']!.split('\n');
      expect(lines[0], 'date,exercise,weight,reps,rpe,volume,e1rm');
    });

    test('sets.csv includes workout set data', () async {
      final workout = Workout(
        id: 'w1',
        startedAt: DateTime(2024, 1, 1),
        completedAt: DateTime(2024, 1, 1, 1),
        updatedAt: DateTime.utc(2024),
      );
      await workoutRepo.createWorkout(workout);
      await workoutRepo.addSet(WorkoutSet(
        id: 's1',
        workoutId: 'w1',
        exerciseId: '1',
        setOrder: 1,
        weight: 100,
        reps: 5,
        rpe: 8.0,
        timestamp: DateTime(2024, 1, 1, 0, 30),
        updatedAt: DateTime.utc(2024),
      ));

      final csvFiles = await useCase.exportAsCsv();
      final lines = csvFiles['sets.csv']!.split('\n');
      expect(lines.length, greaterThan(1));
      expect(lines[1], contains('Barbell Bench Press'));
      expect(lines[1], contains('100.0'));
    });

    test('escapes commas in exercise names', () async {
      final exercise = await exerciseRepo.createExercise(
        domain.Exercise(
          id: 'comma-ex',
          name: 'Press, Bench',
          category: domain.ExerciseCategory.strength,
          muscleGroup: domain.MuscleGroup.chest,
          equipmentType: domain.EquipmentType.barbell,
          isCustom: true,
          updatedAt: DateTime.utc(2024),
        ),
      );

      final workout = Workout(
        id: 'w2',
        startedAt: DateTime(2024, 2, 1),
        completedAt: DateTime(2024, 2, 1, 1),
        updatedAt: DateTime.utc(2024),
      );
      await workoutRepo.createWorkout(workout);
      await workoutRepo.addSet(WorkoutSet(
        id: 's2',
        workoutId: 'w2',
        exerciseId: exercise.id,
        setOrder: 1,
        weight: 50,
        reps: 10,
        timestamp: DateTime(2024, 2, 1),
        updatedAt: DateTime.utc(2024),
      ));

      final csvFiles = await useCase.exportAsCsv();
      final content = csvFiles['sets.csv']!;
      expect(content, contains('"Press, Bench"'));
    });

    test('cardio.csv includes session data', () async {
      final workout = Workout(
        id: 'w3',
        startedAt: DateTime(2024, 3, 1),
        completedAt: DateTime(2024, 3, 1, 1),
        updatedAt: DateTime.utc(2024),
      );
      await workoutRepo.createWorkout(workout);
      await cardioRepo.createSession(CardioSession(
        id: 'c1',
        workoutId: 'w3',
        exerciseId: '16',
        durationSeconds: 1800,
        distanceMeters: 5000,
        updatedAt: DateTime.utc(2024),
      ));

      final csvFiles = await useCase.exportAsCsv();
      final lines = csvFiles['cardio.csv']!.split('\n');
      expect(lines.length, greaterThan(1));
      expect(lines[1], contains('Treadmill'));
    });

    test('personal_records.csv includes PR data', () async {
      await prRepo.createRecord(PersonalRecord(
        id: 'pr1',
        exerciseId: '1',
        recordType: RecordType.estimatedOneRepMax,
        value: 120.0,
        achievedAt: DateTime(2024, 4, 1),
        updatedAt: DateTime.utc(2024),
      ));

      final csvFiles = await useCase.exportAsCsv();
      final lines = csvFiles['personal_records.csv']!.split('\n');
      expect(lines.length, greaterThan(1));
      expect(lines[1], contains('estimatedOneRepMax'));
      expect(lines[1], contains('120.0'));
    });
  });
}
