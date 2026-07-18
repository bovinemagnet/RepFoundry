import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';
import 'package:rep_foundry/features/settings/application/import/csv_format_adapter.dart';
import 'package:rep_foundry/features/settings/application/import/hevy_csv_adapter.dart';
import 'package:rep_foundry/features/settings/application/import/repfoundry_csv_adapter.dart';
import 'package:rep_foundry/features/settings/application/import/strong_csv_adapter.dart';

List<List<dynamic>> loadFixture(String name) {
  final content =
      File('test/features/settings/fixtures/$name').readAsStringSync();
  return Csv().decode(content);
}

void main() {
  group('detectCsvAdapter', () {
    test('recognises a Strong export', () {
      final adapter = detectCsvAdapter(loadFixture('strong.csv'));
      expect(adapter, isA<StrongCsvAdapter>());
    });

    test('recognises a Strong export with unit columns', () {
      final adapter = detectCsvAdapter(loadFixture('strong_lbs.csv'));
      expect(adapter, isA<StrongCsvAdapter>());
    });

    test('recognises a Hevy export', () {
      final adapter = detectCsvAdapter(loadFixture('hevy.csv'));
      expect(adapter, isA<HevyCsvAdapter>());
    });

    test('recognises a RepFoundry sets export', () {
      final adapter = detectCsvAdapter(loadFixture('repfoundry_sets.csv'));
      expect(adapter, isA<RepFoundryCsvAdapter>());
    });

    test('returns null for unrecognised content', () {
      expect(detectCsvAdapter(loadFixture('malformed.csv')), isNull);
    });
  });

  group('StrongCsvAdapter', () {
    test('groups rows into workouts by date and name', () {
      final history = StrongCsvAdapter().parse(loadFixture('strong.csv'));

      expect(history.source, 'strong');
      expect(history.workouts, hasLength(2));

      final push = history.workouts.first;
      expect(push.name, 'Push Day');
      expect(push.startedAt, DateTime(2024, 3, 15, 9, 10).toUtc());
      // Duration "1h 5m" sets the completion time.
      expect(
        push.completedAt,
        DateTime(2024, 3, 15, 9, 10)
            .add(const Duration(hours: 1, minutes: 5))
            .toUtc(),
      );
      expect(push.sets, hasLength(4));

      final pull = history.workouts.last;
      expect(pull.name, 'Pull Day');
      expect(pull.sets, hasLength(1));
      expect(pull.sets.single.rpe, 9.0);
    });

    test('marks W set-order rows as warm-ups', () {
      final history = StrongCsvAdapter().parse(loadFixture('strong.csv'));
      final benchSets = history.workouts.first.sets
          .where((s) => s.exerciseName == 'Bench Press (Barbell)')
          .toList();
      expect(benchSets, hasLength(3));
      expect(benchSets.first.isWarmUp, isTrue);
      expect(benchSets[1].isWarmUp, isFalse);
    });

    test('keeps quoted exercise names containing commas intact', () {
      final history = StrongCsvAdapter().parse(loadFixture('strong.csv'));
      expect(
        history.workouts.first.sets.map((s) => s.exerciseName),
        contains('Press, Overhead (Barbell)'),
      );
    });

    test('skips cardio-shaped rows and counts them', () {
      final history = StrongCsvAdapter().parse(loadFixture('strong.csv'));
      expect(history.rowsSkipped, 1); // The Running row.
      expect(
        history.workouts.first.sets.map((s) => s.exerciseName),
        isNot(contains('Running')),
      );
    });

    test('blank RPE parses as null', () {
      final history = StrongCsvAdapter().parse(loadFixture('strong.csv'));
      final overhead = history.workouts.first.sets
          .singleWhere((s) => s.exerciseName == 'Press, Overhead (Barbell)');
      expect(overhead.rpe, isNull);
    });

    test('needs a unit choice only when no Weight Unit column exists', () {
      expect(
        StrongCsvAdapter().requiresUnitChoice(loadFixture('strong.csv').first),
        isTrue,
      );
      expect(
        StrongCsvAdapter()
            .requiresUnitChoice(loadFixture('strong_lbs.csv').first),
        isFalse,
      );
    });

    test('converts lbs weights to kg using the per-row unit column', () {
      final history = StrongCsvAdapter().parse(loadFixture('strong_lbs.csv'));
      final squat = history.workouts.single.sets.first;
      expect(squat.weightKg, closeTo(225 / lbsPerKg, 0.001));
    });

    test('applies the fallback unit when the file declares none', () {
      final history = StrongCsvAdapter()
          .parse(loadFixture('strong.csv'), fallbackUnit: WeightUnit.lbs);
      final bench = history.workouts.first.sets[1];
      expect(bench.weightKg, closeTo(80 / lbsPerKg, 0.001));
    });
  });

  group('HevyCsvAdapter', () {
    test('groups rows into workouts by title and start time', () {
      final history = HevyCsvAdapter().parse(loadFixture('hevy.csv'));

      expect(history.source, 'hevy');
      expect(history.workouts, hasLength(2));
      final push = history.workouts.first;
      expect(push.name, 'Push Session');
      expect(push.startedAt, DateTime(2024, 3, 15, 9, 10).toUtc());
      expect(push.completedAt, DateTime(2024, 3, 15, 10, 5).toUtc());
      expect(push.sets, hasLength(3));
    });

    test('parses ISO start times too', () {
      final history = HevyCsvAdapter().parse(loadFixture('hevy.csv'));
      final pull = history.workouts.last;
      expect(pull.startedAt, DateTime.utc(2024, 3, 17, 10));
      expect(pull.completedAt, DateTime.utc(2024, 3, 17, 10, 45));
    });

    test('maps set_type warmup to the warm-up flag', () {
      final history = HevyCsvAdapter().parse(loadFixture('hevy.csv'));
      final sets = history.workouts.first.sets;
      expect(sets[0].isWarmUp, isTrue);
      expect(sets[1].isWarmUp, isFalse);
      expect(sets[2].isWarmUp, isFalse); // failure is a working set
    });

    test('weights are already kg', () {
      final history = HevyCsvAdapter().parse(loadFixture('hevy.csv'));
      expect(history.workouts.first.sets[1].weightKg, 80.0);
    });
  });

  group('RepFoundryCsvAdapter', () {
    test('groups sets into one workout per calendar day', () {
      final history =
          RepFoundryCsvAdapter().parse(loadFixture('repfoundry_sets.csv'));

      expect(history.source, 'repfoundry');
      expect(history.workouts, hasLength(2));
      final day1 = history.workouts.first;
      expect(day1.startedAt, DateTime(2024, 3, 15, 9, 10).toUtc());
      expect(day1.sets, hasLength(2));
      // Completed at the last set of the day.
      expect(day1.completedAt.isAfter(day1.startedAt), isTrue);
      expect(history.workouts.last.sets.single.exerciseName, 'Deadlift');
    });

    test('preserves per-set timestamps', () {
      final history =
          RepFoundryCsvAdapter().parse(loadFixture('repfoundry_sets.csv'));
      final sets = history.workouts.first.sets;
      expect(sets[0].timestamp, DateTime(2024, 3, 15, 9, 10).toUtc());
      expect(sets[1].timestamp, DateTime(2024, 3, 15, 9, 15).toUtc());
    });
  });

  group('parsed workout invariants', () {
    test('every parsed workout has a completion time', () {
      for (final fixture in [
        'strong.csv',
        'strong_lbs.csv',
        'hevy.csv',
        'repfoundry_sets.csv'
      ]) {
        final adapter = detectCsvAdapter(loadFixture(fixture))!;
        final history = adapter.parse(loadFixture(fixture));
        for (final workout in history.workouts) {
          expect(workout.completedAt, isNotNull,
              reason: '$fixture produced an incomplete workout');
        }
      }
    });
  });
}
