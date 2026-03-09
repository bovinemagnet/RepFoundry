import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/notifications/domain/models/reminder_settings.dart';

void main() {
  group('ReminderSettings', () {
    test('default has no days selected and 18:00 time', () {
      const settings = ReminderSettings();
      expect(settings.enabledDays, isEmpty);
      expect(settings.hour, 18);
      expect(settings.minute, 0);
      expect(settings.streakReminderEnabled, isFalse);
    });

    test('copyWith updates days', () {
      const settings = ReminderSettings();
      final updated =
          settings.copyWith(enabledDays: {DateTime.monday, DateTime.wednesday});
      expect(updated.enabledDays, {DateTime.monday, DateTime.wednesday});
      expect(updated.hour, 18);
    });

    test('hasReminders is true when days are selected', () {
      final settings = const ReminderSettings().copyWith(
        enabledDays: {DateTime.monday},
      );
      expect(settings.hasReminders, isTrue);
    });

    test('hasReminders is false when no days selected', () {
      const settings = ReminderSettings();
      expect(settings.hasReminders, isFalse);
    });
  });
}
