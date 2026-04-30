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
import 'package:rep_foundry/features/stretching/data/in_memory_stretching_session_repository.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

void main() {
  late ExportDataUseCase useCase;
  late InMemoryWorkoutRepository workoutRepo;
  late InMemoryExerciseRepository exerciseRepo;
  late InMemoryCardioSessionRepository cardioRepo;
  late InMemoryPersonalRecordRepository prRepo;
  late InMemoryStretchingSessionRepository stretchingRepo;

  setUp(() {
    workoutRepo = InMemoryWorkoutRepository();
    exerciseRepo = InMemoryExerciseRepository();
    cardioRepo = InMemoryCardioSessionRepository();
    prRepo = InMemoryPersonalRecordRepository();
    stretchingRepo = InMemoryStretchingSessionRepository();
    useCase = ExportDataUseCase(
      workoutRepository: workoutRepo,
      exerciseRepository: exerciseRepo,
      cardioSessionRepository: cardioRepo,
      personalRecordRepository: prRepo,
      stretchingSessionRepository: stretchingRepo,
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
      expect(data['stretchingSessions'], isEmpty);
    });

    test('exportAsJson preserves all stretching session fields', () async {
      // Acceptance criterion: round-trip preserves type, customName,
      // bodyArea, side, durationSeconds, startedAt, endedAt, entryMethod,
      // notes, updatedAt — re-linked to the original workout.
      final workout = Workout(
        id: 'w-stretch',
        startedAt: DateTime.utc(2026, 4, 30, 10),
        completedAt: DateTime.utc(2026, 4, 30, 11),
        updatedAt: DateTime.utc(2026, 4, 30),
      );
      await workoutRepo.createWorkout(workout);

      final ts = DateTime.utc(2026, 4, 30, 10, 5);
      final session = StretchingSession(
        id: 'st-1',
        workoutId: 'w-stretch',
        type: 'pigeon',
        customName: null,
        bodyArea: StretchingBodyArea.hips,
        side: StretchingSide.left,
        durationSeconds: 90,
        startedAt: ts,
        endedAt: ts.add(const Duration(seconds: 90)),
        entryMethod: StretchingEntryMethod.timer,
        notes: 'tight after squats',
        updatedAt: ts,
      );
      await stretchingRepo.createSession(session);

      final json = await useCase.exportAsJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      final list = data['stretchingSessions'] as List;
      expect(list, hasLength(1));
      final out = list.single as Map<String, dynamic>;
      expect(out['id'], 'st-1');
      expect(out['workoutId'], 'w-stretch');
      expect(out['type'], 'pigeon');
      expect(out['bodyArea'], 'hips');
      expect(out['side'], 'left');
      expect(out['durationSeconds'], 90);
      expect(out['entryMethod'], 'timer');
      expect(out['notes'], 'tight after squats');
      expect(out['startedAt'], ts.toIso8601String());
      expect(out['endedAt'],
          ts.add(const Duration(seconds: 90)).toIso8601String());
    });

    test('exportAsJson omits soft-deleted stretching sessions', () async {
      final workout = Workout(
        id: 'w-soft',
        startedAt: DateTime.utc(2026, 4, 30),
        updatedAt: DateTime.utc(2026, 4, 30),
      );
      await workoutRepo.createWorkout(workout);

      final live = StretchingSession.create(
        workoutId: 'w-soft',
        type: 'cobra',
        durationSeconds: 30,
        entryMethod: StretchingEntryMethod.manual,
      );
      final tombstoned = StretchingSession.create(
        workoutId: 'w-soft',
        type: 'butterfly',
        durationSeconds: 60,
        entryMethod: StretchingEntryMethod.manual,
      );
      await stretchingRepo.createSession(live);
      await stretchingRepo.createSession(tombstoned);
      await stretchingRepo.deleteSession(tombstoned.id);

      final json = await useCase.exportAsJson();
      final data = jsonDecode(json) as Map<String, dynamic>;
      final list = data['stretchingSessions'] as List;
      expect(list, hasLength(1));
      expect(
        (list.single as Map<String, dynamic>)['type'],
        'cobra',
      );
    });
  });

  group('exportAsCsv', () {
    test('returns four CSV files', () async {
      final csvFiles = await useCase.exportAsCsv();
      expect(
        csvFiles.keys,
        containsAll([
          'sets.csv',
          'cardio.csv',
          'personal_records.csv',
          'stretching.csv',
        ]),
      );
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

    test('stretching.csv has header and includes session data', () async {
      final workout = Workout(
        id: 'w-csv',
        startedAt: DateTime(2026, 4, 30, 10),
        completedAt: DateTime(2026, 4, 30, 11),
        updatedAt: DateTime.utc(2026, 4, 30),
      );
      await workoutRepo.createWorkout(workout);
      await stretchingRepo.createSession(StretchingSession(
        id: 'st-csv',
        workoutId: 'w-csv',
        type: 'pigeon',
        bodyArea: StretchingBodyArea.hips,
        side: StretchingSide.left,
        durationSeconds: 60,
        entryMethod: StretchingEntryMethod.timer,
        updatedAt: DateTime.utc(2026, 4, 30),
      ));

      final csvFiles = await useCase.exportAsCsv();
      final lines = csvFiles['stretching.csv']!.split('\n');
      expect(
        lines[0],
        'workout_date,type,custom_name,body_area,side,duration_seconds,'
        'started_at,ended_at,entry_method,notes',
      );
      expect(lines.length, greaterThan(1));
      expect(lines[1], contains('pigeon'));
      expect(lines[1], contains('hips'));
      expect(lines[1], contains('left'));
      expect(lines[1], contains('timer'));
      expect(lines[1], contains('60'));
    });

    test('stretching.csv escapes commas in custom names and notes', () async {
      final workout = Workout(
        id: 'w-csv2',
        startedAt: DateTime(2026, 4, 30, 10),
        completedAt: DateTime(2026, 4, 30, 11),
        updatedAt: DateTime.utc(2026, 4, 30),
      );
      await workoutRepo.createWorkout(workout);
      await stretchingRepo.createSession(StretchingSession(
        id: 'st-csv2',
        workoutId: 'w-csv2',
        type: 'custom',
        customName: 'Wrist, finger circles',
        durationSeconds: 30,
        entryMethod: StretchingEntryMethod.manual,
        notes: 'felt good, no pain',
        updatedAt: DateTime.utc(2026, 4, 30),
      ));

      final content = (await useCase.exportAsCsv())['stretching.csv']!;
      expect(content, contains('"Wrist, finger circles"'));
      expect(content, contains('"felt good, no pain"'));
    });
  });
}
