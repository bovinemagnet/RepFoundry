import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/extensions/datetime_extensions.dart';

void main() {
  group('DateTimeFormatting', () {
    test('relativeLabel returns "Today" for today', () {
      final now = DateTime.now();
      expect(now.relativeLabel, 'Today');
    });

    test('relativeLabel returns "Yesterday" for yesterday', () {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      expect(yesterday.relativeLabel, 'Yesterday');
    });

    test('relativeLabel returns month/day for older dates', () {
      final date = DateTime(DateTime.now().year, 3, 15);
      expect(date.relativeLabel, contains('Mar'));
      expect(date.relativeLabel, contains('15'));
    });

    test('timeOfDay formats midnight as 12:00 AM', () {
      final midnight = DateTime(2024, 1, 1, 0, 0);
      expect(midnight.timeOfDay, '12:00 AM');
    });

    test('timeOfDay formats noon as 12:00 PM', () {
      final noon = DateTime(2024, 1, 1, 12, 0);
      expect(noon.timeOfDay, '12:00 PM');
    });

    test('timeOfDay formats 9:05 correctly', () {
      final time = DateTime(2024, 1, 1, 9, 5);
      expect(time.timeOfDay, '9:05 AM');
    });

    test('timeOfDay formats 13:30 as 1:30 PM', () {
      final time = DateTime(2024, 1, 1, 13, 30);
      expect(time.timeOfDay, '1:30 PM');
    });

    test('durationUntil returns correct duration string', () {
      final start = DateTime(2024, 1, 1, 9, 0);
      final end = DateTime(2024, 1, 1, 10, 30);
      expect(start.durationUntil(end), '1h 30m');
    });

    test('durationUntil returns minutes only for < 1 hour', () {
      final start = DateTime(2024, 1, 1, 9, 0);
      final end = DateTime(2024, 1, 1, 9, 45);
      expect(start.durationUntil(end), '45m');
    });
  });

  group('DurationFormatting', () {
    test('formatted returns MM:SS for durations under 1 hour', () {
      const d = Duration(minutes: 3, seconds: 7);
      expect(d.formatted, '03:07');
    });

    test('formatted returns H:MM:SS for durations >= 1 hour', () {
      const d = Duration(hours: 1, minutes: 5, seconds: 9);
      expect(d.formatted, '1:05:09');
    });

    test('formatted pads seconds correctly', () {
      const d = Duration(minutes: 1, seconds: 5);
      expect(d.formatted, '01:05');
    });
  });
}
