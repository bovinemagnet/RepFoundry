import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/exercises/data/drift_exercise_repository.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';

void main() {
  late db.AppDatabase database;
  late DriftExerciseRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftExerciseRepository(database);
  });

  tearDown(() => database.close());

  group('DriftExerciseRepository', () {
    group('getAllExercises', () {
      test('returns the 18 seeded exercises sorted by name', () async {
        final exercises = await repo.getAllExercises();

        expect(exercises, hasLength(18));
        for (var i = 0; i < exercises.length - 1; i++) {
          expect(
            exercises[i].name.compareTo(exercises[i + 1].name),
            isNonPositive,
          );
        }
      });

      test('does not return soft-deleted exercises', () async {
        await repo.deleteExercise('1');
        final exercises = await repo.getAllExercises();

        expect(exercises, hasLength(17));
        expect(exercises.any((e) => e.id == '1'), isFalse);
      });
    });

    group('getExercise', () {
      test('returns an exercise by id', () async {
        final exercise = await repo.getExercise('1');

        expect(exercise, isNotNull);
        expect(exercise!.name, 'Barbell Bench Press');
        expect(exercise.category, ExerciseCategory.strength);
        expect(exercise.muscleGroup, MuscleGroup.chest);
        expect(exercise.equipmentType, EquipmentType.barbell);
        expect(exercise.isCustom, isFalse);
      });

      test('returns null for non-existent id', () async {
        final exercise = await repo.getExercise('non-existent');
        expect(exercise, isNull);
      });

      test('returns null for soft-deleted exercise', () async {
        await repo.deleteExercise('1');
        final exercise = await repo.getExercise('1');
        expect(exercise, isNull);
      });
    });

    group('searchExercises', () {
      test('finds exercises by case-insensitive name match', () async {
        final results = await repo.searchExercises('barbell');

        expect(results.length, greaterThanOrEqualTo(3));
        for (final e in results) {
          expect(e.name.toLowerCase(), contains('barbell'));
        }
      });

      test('returns empty list when nothing matches', () async {
        final results = await repo.searchExercises('zzznonexistent');
        expect(results, isEmpty);
      });

      test('excludes soft-deleted exercises', () async {
        await repo.deleteExercise('1');
        final results = await repo.searchExercises('barbell bench');
        expect(results, isEmpty);
      });
    });

    group('getExercisesByMuscleGroup', () {
      test('filters by muscle group', () async {
        final backExercises =
            await repo.getExercisesByMuscleGroup(MuscleGroup.back);

        expect(backExercises, isNotEmpty);
        for (final e in backExercises) {
          expect(e.muscleGroup, MuscleGroup.back);
        }
      });

      test('returns results sorted by name', () async {
        final exercises =
            await repo.getExercisesByMuscleGroup(MuscleGroup.chest);
        for (var i = 0; i < exercises.length - 1; i++) {
          expect(
            exercises[i].name.compareTo(exercises[i + 1].name),
            isNonPositive,
          );
        }
      });
    });

    group('createExercise', () {
      test('persists a new custom exercise', () async {
        final exercise = Exercise.create(
          name: 'Bulgarian Split Squat',
          category: ExerciseCategory.strength,
          muscleGroup: MuscleGroup.quadriceps,
          equipmentType: EquipmentType.dumbbell,
          isCustom: true,
        );

        final created = await repo.createExercise(exercise);

        expect(created.id, exercise.id);
        expect(created.name, 'Bulgarian Split Squat');

        final fetched = await repo.getExercise(exercise.id);
        expect(fetched, isNotNull);
        expect(fetched!.name, 'Bulgarian Split Squat');
        expect(fetched.isCustom, isTrue);
      });
    });

    group('updateExercise', () {
      test('updates an existing exercise', () async {
        final original = await repo.getExercise('1');
        final updated = original!.copyWith(name: 'Flat Bench Press');

        await repo.updateExercise(updated);
        final fetched = await repo.getExercise('1');

        expect(fetched!.name, 'Flat Bench Press');
      });
    });

    group('deleteExercise', () {
      test('soft-deletes an exercise', () async {
        await repo.deleteExercise('2');

        final exercise = await repo.getExercise('2');
        expect(exercise, isNull);

        // Still in database (soft delete).
        final row = await (database.select(database.exercises)
              ..where((t) => t.id.equals('2')))
            .getSingleOrNull();
        expect(row, isNotNull);
        expect(row!.deletedAt, isNotNull);
      });
    });

    group('watchAllExercises', () {
      test('emits updated list when exercises change', () async {
        final emissions = <List<Exercise>>[];
        final sub = repo.watchAllExercises().listen(emissions.add);
        addTearDown(sub.cancel);

        // Wait for the initial emission.
        await pumpEventQueue();
        expect(emissions, hasLength(1));
        expect(emissions.first, hasLength(18));

        final newExercise = Exercise.create(
          name: 'Arnold Press',
          category: ExerciseCategory.strength,
          muscleGroup: MuscleGroup.shoulders,
          equipmentType: EquipmentType.dumbbell,
        );
        await repo.createExercise(newExercise);
        await pumpEventQueue();

        expect(emissions, hasLength(2));
        expect(emissions.last, hasLength(19));
      });
    });
  });
}
