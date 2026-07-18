import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/settings/application/import_data_use_case.dart';
import 'package:rep_foundry/features/stretching/data/in_memory_stretching_session_repository.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';

String fixture(String name) =>
    File('test/features/settings/fixtures/$name').readAsStringSync();

void main() {
  late InMemoryWorkoutRepository workoutRepo;
  late ImportDataUseCase useCase;

  setUp(() {
    workoutRepo = InMemoryWorkoutRepository();
    useCase = ImportDataUseCase(
      workoutRepository: workoutRepo,
      exerciseRepository: InMemoryExerciseRepository(),
      cardioSessionRepository: InMemoryCardioSessionRepository(),
      personalRecordRepository: InMemoryPersonalRecordRepository(),
      stretchingSessionRepository: InMemoryStretchingSessionRepository(),
    );
  });

  group('previewCsv', () {
    test('names the detected format and flags ambiguous units', () {
      final strong = useCase.previewCsv(fixture('strong.csv'));
      expect(strong!.formatName, 'Strong');
      expect(strong.needsUnitChoice, isTrue);

      final strongWithUnits = useCase.previewCsv(fixture('strong_lbs.csv'));
      expect(strongWithUnits!.formatName, 'Strong');
      expect(strongWithUnits.needsUnitChoice, isFalse);

      final hevy = useCase.previewCsv(fixture('hevy.csv'));
      expect(hevy!.formatName, 'Hevy');
      expect(hevy.needsUnitChoice, isFalse);
    });

    test('returns null for unrecognised content', () {
      expect(useCase.previewCsv(fixture('malformed.csv')), isNull);
      expect(useCase.previewCsv('{"workouts": []}'), isNull);
    });
  });

  group('importFromCsv', () {
    test('imports a Strong export end to end', () async {
      final result = await useCase.importFromCsv(fixture('strong.csv'));

      expect(result.workoutsImported, 2);
      expect(result.setsImported, 5);
      expect(result.rowsSkipped, 1); // the Running row
      expect(result.exercisesCreated, greaterThan(0));

      final workouts = await workoutRepo.getWorkoutHistory();
      expect(workouts, hasLength(2));
    });

    test('applies the chosen fallback unit', () async {
      final kgResult = await useCase.importFromCsv(fixture('strong.csv'));
      final workouts = await workoutRepo.getWorkoutHistory();
      final sets = await workoutRepo.getSetsForWorkout(workouts.last.id);
      expect(kgResult.setsImported, greaterThan(0));
      expect(sets.any((s) => s.weight == 80.0), isTrue);

      // A fresh use case importing the same file as lbs stores converted kg.
      final lbsRepo = InMemoryWorkoutRepository();
      final lbsUseCase = ImportDataUseCase(
        workoutRepository: lbsRepo,
        exerciseRepository: InMemoryExerciseRepository(),
        cardioSessionRepository: InMemoryCardioSessionRepository(),
        personalRecordRepository: InMemoryPersonalRecordRepository(),
        stretchingSessionRepository: InMemoryStretchingSessionRepository(),
      );
      await lbsUseCase.importFromCsv(
        fixture('strong.csv'),
        fallbackUnit: WeightUnit.lbs,
      );
      final lbsWorkouts = await lbsRepo.getWorkoutHistory();
      final lbsSets = await lbsRepo.getSetsForWorkout(lbsWorkouts.first.id);
      expect(
        lbsSets.map((s) => s.weight),
        everyElement(lessThan(80.0)),
      );
    });

    test('throws FormatException for unrecognised content', () async {
      expect(
        () => useCase.importFromCsv(fixture('malformed.csv')),
        throwsFormatException,
      );
    });

    test('re-import of the same file is a no-op', () async {
      await useCase.importFromCsv(fixture('hevy.csv'));
      final second = await useCase.importFromCsv(fixture('hevy.csv'));
      expect(second.workoutsImported, 0);
      expect(second.setsImported, 0);
      expect(second.duplicatesSkipped, greaterThan(0));
    });
  });
}
