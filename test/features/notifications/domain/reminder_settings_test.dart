import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/notifications/domain/models/reminder_settings.dart';

void main() {
  group('ReminderSettings', () {
    test('default constructor sets hour to 18', () {
      const settings = ReminderSettings();
      expect(settings.hour, 18);
    });

    test('default constructor sets minute to 0', () {
      const settings = ReminderSettings();
      expect(settings.minute, 0);
    });

    test('default constructor sets streakReminderEnabled to false', () {
      const settings = ReminderSettings();
      expect(settings.streakReminderEnabled, isFalse);
    });

    test('default constructor sets enabledDays to empty set', () {
      const settings = ReminderSettings();
      expect(settings.enabledDays, isEmpty);
    });

    test('hasReminders is false when enabledDays is empty', () {
      const settings = ReminderSettings();
      expect(settings.hasReminders, isFalse);
    });

    test('hasReminders is true when enabledDays contains at least one day', () {
      const settings = ReminderSettings(enabledDays: {DateTime.monday});
      expect(settings.hasReminders, isTrue);
    });

    test('hasReminders is true when multiple days are enabled', () {
      const settings = ReminderSettings(
        enabledDays: {DateTime.monday, DateTime.wednesday, DateTime.friday},
      );
      expect(settings.hasReminders, isTrue);
    });

    test('copyWith updates hour and preserves other fields', () {
      const original = ReminderSettings(
        hour: 18,
        minute: 0,
        enabledDays: {DateTime.tuesday},
        streakReminderEnabled: false,
      );
      final updated = original.copyWith(hour: 9);

      expect(updated.hour, 9);
      expect(updated.minute, original.minute);
      expect(updated.enabledDays, original.enabledDays);
      expect(updated.streakReminderEnabled, original.streakReminderEnabled);
    });

    test('copyWith updates minute and preserves other fields', () {
      const original = ReminderSettings(hour: 18, minute: 0);
      final updated = original.copyWith(minute: 30);

      expect(updated.minute, 30);
      expect(updated.hour, original.hour);
    });

    test('copyWith updates streakReminderEnabled and preserves other fields',
        () {
      const original = ReminderSettings(streakReminderEnabled: false);
      final updated = original.copyWith(streakReminderEnabled: true);

      expect(updated.streakReminderEnabled, isTrue);
      expect(updated.hour, original.hour);
      expect(updated.minute, original.minute);
      expect(updated.enabledDays, original.enabledDays);
    });

    test('copyWith updates enabledDays and preserves other fields', () {
      const original = ReminderSettings(enabledDays: {DateTime.monday});
      final updated = original.copyWith(
        enabledDays: {DateTime.wednesday, DateTime.friday},
      );

      expect(updated.enabledDays, {DateTime.wednesday, DateTime.friday});
      expect(updated.hour, original.hour);
      expect(updated.minute, original.minute);
      expect(updated.streakReminderEnabled, original.streakReminderEnabled);
    });

    test('copyWith with no arguments returns equivalent settings', () {
      const original = ReminderSettings(
        hour: 7,
        minute: 15,
        enabledDays: {DateTime.monday, DateTime.thursday},
        streakReminderEnabled: true,
      );
      final copy = original.copyWith();

      expect(copy.hour, original.hour);
      expect(copy.minute, original.minute);
      expect(copy.enabledDays, original.enabledDays);
      expect(copy.streakReminderEnabled, original.streakReminderEnabled);
    });

    test('copyWith can clear enabledDays to empty set', () {
      const original = ReminderSettings(enabledDays: {DateTime.monday});
      final updated = original.copyWith(enabledDays: {});

      expect(updated.enabledDays, isEmpty);
      expect(updated.hasReminders, isFalse);
    });
  });
}
