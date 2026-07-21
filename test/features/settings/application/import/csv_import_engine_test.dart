import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/settings/application/import/csv_import_engine.dart';
import 'package:rep_foundry/features/settings/application/import/parsed_history.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';

void main() {
  late InMemoryWorkoutRepository workoutRepo;
  late InMemoryExerciseRepository exerciseRepo;
  late InMemoryPersonalRecordRepository prRepo;
  late CsvImportEngine engine;

  setUp(() {
    workoutRepo = InMemoryWorkoutRepository();
    exerciseRepo = InMemoryExerciseRepository();
    prRepo = InMemoryPersonalRecordRepository();
    engine = CsvImportEngine(
      workoutRepository: workoutRepo,
      exerciseRepository: exerciseRepo,
      personalRecordRepository: prRepo,
    );
  });

  final start = DateTime.utc(2024, 3, 15, 9, 10);

  ParsedHistory history({List<ParsedWorkout>? workouts, int rowsSkipped = 0}) {
    return ParsedHistory(
      source: 'strong',
      rowsSkipped: rowsSkipped,
      workouts: workouts ??
          [
            ParsedWorkout(
              sourceKey: '2024-03-15 09:10:00|Push Day',
              name: 'Push Day',
              startedAt: start,
              completedAt: start.add(const Duration(hours: 1)),
              sets: [
                ParsedSet(
                  exerciseName:
                      'barbell bench press', // seed exercise, lowercased
                  weightKg: 80,
                  reps: 5,
                  rpe: 8,
                  timestamp: start,
                ),
                ParsedSet(
                  exerciseName: 'Cable Woodchopper', // not in the library
                  weightKg: 30,
                  reps: 12,
                  timestamp: start.add(const Duration(minutes: 1)),
                ),
              ],
            ),
          ],
    );
  }

  group('CsvImportEngine', () {
    test('imports workouts and sets with counts', () async {
      final result = await engine.import(history(rowsSkipped: 3));

      expect(result.workoutsImported, 1);
      expect(result.setsImported, 2);
      expect(result.rowsSkipped, 3);
      expect(result.duplicatesSkipped, 0);

      final workouts =
          await workoutRepo.getWorkoutHistory(clientId: kSelfClientId);
      expect(workouts, hasLength(1));
      final sets = await workoutRepo.getSetsForWorkout(workouts.single.id);
      expect(sets, hasLength(2));
      expect(sets.first.weight, 80);
      expect(sets.first.rpe, 8);
    });

    test('imported workouts are completed, never active', () async {
      await engine.import(history());
      expect(await workoutRepo.getActiveWorkout(), isNull);
    });

    test('matches existing exercises case-insensitively', () async {
      final before = await exerciseRepo.getAllExercises();
      final bench = before.singleWhere((e) => e.name == 'Barbell Bench Press');

      await engine.import(history());

      final workouts =
          await workoutRepo.getWorkoutHistory(clientId: kSelfClientId);
      final sets = await workoutRepo.getSetsForWorkout(workouts.single.id);
      expect(sets.first.exerciseId, bench.id);
    });

    test('creates custom exercises for unmatched names', () async {
      final result = await engine.import(history());

      expect(result.exercisesCreated, 1);
      final all = await exerciseRepo.getAllExercises();
      final created = all.singleWhere((e) => e.name == 'Cable Woodchopper');
      expect(created.isCustom, isTrue);
    });

    test('importing the same history twice is a no-op', () async {
      await engine.import(history());
      final second = await engine.import(history());

      expect(second.workoutsImported, 0);
      expect(second.setsImported, 0);
      expect(second.exercisesCreated, 0);
      expect(second.duplicatesSkipped, greaterThan(0));

      final workouts =
          await workoutRepo.getWorkoutHistory(clientId: kSelfClientId);
      expect(workouts, hasLength(1));
      expect(await workoutRepo.getSetsForWorkout(workouts.single.id),
          hasLength(2));
      final all = await exerciseRepo.getAllExercises();
      expect(all.where((e) => e.name == 'Cable Woodchopper'), hasLength(1));
    });

    test('set updatedAt is the historical timestamp, not now', () async {
      await engine.import(history());
      final workouts =
          await workoutRepo.getWorkoutHistory(clientId: kSelfClientId);
      final sets = await workoutRepo.getSetsForWorkout(workouts.single.id);
      expect(sets.first.updatedAt, start);
    });

    group('PR backfill', () {
      test('creates records where imported history beats stored bests',
          () async {
        final result = await engine.import(history());

        expect(result.personalRecordsImported, greaterThan(0));
        final all = await exerciseRepo.getAllExercises();
        final bench = all.singleWhere((e) => e.name == 'Barbell Bench Press');
        final best = await prRepo.getBestRecord(
            bench.id, RecordType.maxWeight, kSelfClientId);
        expect(best, isNotNull);
        expect(best!.value, 80);
        expect(best.achievedAt, start);
      });

      test('does not create records the stored best already beats', () async {
        final all = await exerciseRepo.getAllExercises();
        final bench = all.singleWhere((e) => e.name == 'Barbell Bench Press');
        await prRepo.createRecord(PersonalRecord.create(
          exerciseId: bench.id,
          recordType: RecordType.maxWeight,
          value: 200,
        ));

        await engine.import(history());

        final best = await prRepo.getBestRecord(
            bench.id, RecordType.maxWeight, kSelfClientId);
        expect(best!.value, 200);
      });

      test('backfill is idempotent across re-imports', () async {
        await engine.import(history());
        final second = await engine.import(history());
        expect(second.personalRecordsImported, 0);
      });

      test('warm-up sets do not feed PR backfill', () async {
        final warmupOnly = ParsedHistory(
          source: 'strong',
          workouts: [
            ParsedWorkout(
              sourceKey: 'w1',
              startedAt: start,
              completedAt: start.add(const Duration(hours: 1)),
              sets: [
                ParsedSet(
                  exerciseName: 'barbell bench press',
                  weightKg: 60,
                  reps: 10,
                  isWarmUp: true,
                  timestamp: start,
                ),
              ],
            ),
          ],
        );
        final result = await engine.import(warmupOnly);
        expect(result.personalRecordsImported, 0);
      });
    });
  });
}
