import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/weekly_volume_provider.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/training_load_provider.dart';

void main() {
  group('Weekly volume calculation', () {
    test('computeWeeklyVolume groups sets by week', () {
      final now = DateTime.now();
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisWeekStart = DateTime(thisWeek.year, thisWeek.month, thisWeek.day);

      final result = computeWeeklyVolume([
        SetData(date: thisWeekStart, volume: 1000, rpe: null),
        SetData(date: thisWeekStart.add(const Duration(days: 1)), volume: 500, rpe: null),
        SetData(date: thisWeekStart.subtract(const Duration(days: 7)), volume: 800, rpe: null),
      ]);

      expect(result, hasLength(2));
      expect(result.last.totalVolume, 1500);
    });

    test('computeWeeklyVolume calculates percent change', () {
      final week1 = DateTime(2026, 1, 5); // Monday
      final week2 = DateTime(2026, 1, 12); // Next Monday

      final result = computeWeeklyVolume([
        SetData(date: week1, volume: 1000, rpe: null),
        SetData(date: week2, volume: 1200, rpe: null),
      ]);

      expect(result, hasLength(2));
      expect(result.first.percentChange, isNull); // First week has no previous
      expect(result.last.percentChange, closeTo(20.0, 0.01)); // (1200-1000)/1000 * 100
    });
  });

  group('Training load calculation', () {
    test('computeTrainingLoad calculates sets * avg RPE', () {
      final now = DateTime.now();
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisWeekStart = DateTime(thisWeek.year, thisWeek.month, thisWeek.day);

      final result = computeTrainingLoad([
        SetData(date: thisWeekStart, volume: 100, rpe: 8.0),
        SetData(date: thisWeekStart, volume: 100, rpe: 7.0),
      ]);

      expect(result, hasLength(1));
      expect(result.first.setCount, 2);
      expect(result.first.avgRpe, 7.5);
      expect(result.first.load, closeTo(15.0, 0.01));
    });

    test('computeTrainingLoad handles sets without RPE', () {
      final now = DateTime.now();
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));
      final thisWeekStart = DateTime(thisWeek.year, thisWeek.month, thisWeek.day);

      final result = computeTrainingLoad([
        SetData(date: thisWeekStart, volume: 100, rpe: null),
        SetData(date: thisWeekStart, volume: 100, rpe: null),
      ]);

      expect(result, hasLength(1));
      expect(result.first.setCount, 2);
      expect(result.first.avgRpe, 0.0);
      expect(result.first.load, 0.0);
    });
  });
}
