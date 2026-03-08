import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/history/presentation/providers/workout_frequency_provider.dart';

void main() {
  test('WeeklyFrequency holds weekStart and count', () {
    final week = WeeklyFrequency(
      weekStart: DateTime(2024, 1, 1),
      count: 3,
    );
    expect(week.count, 3);
    expect(week.weekStart, DateTime(2024, 1, 1));
  });

  test('WeeklyFrequency computation returns 12 weeks', () {
    final weeks = <WeeklyFrequency>[];
    final now = DateTime.now();
    final currentWeekStart =
        DateTime(now.year, now.month, now.day - (now.weekday - 1));

    for (var i = 11; i >= 0; i--) {
      final weekStart = currentWeekStart.subtract(Duration(days: 7 * i));
      weeks.add(WeeklyFrequency(weekStart: weekStart, count: 0));
    }

    expect(weeks.length, 12);
    expect(weeks.last.weekStart, currentWeekStart);
  });
}
