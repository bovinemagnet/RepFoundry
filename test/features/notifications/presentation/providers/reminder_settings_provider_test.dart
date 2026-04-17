import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/notifications/data/notification_service.dart';
import 'package:rep_foundry/features/notifications/presentation/providers/reminder_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fakes/fake_notification_service.dart';

ProviderContainer _makeContainer(FakeNotificationService fake) {
  final container = ProviderContainer(
    overrides: [
      notificationServiceProvider.overrideWithValue(fake),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ReminderSettings serialisation', () {
    test('daysToString and stringToDays roundtrip', () {
      final days = {DateTime.monday, DateTime.wednesday, DateTime.friday};
      final encoded = daysToString(days);
      final decoded = stringToDays(encoded);
      expect(decoded, days);
    });

    test('empty days produce empty string', () {
      expect(daysToString({}), '');
      expect(stringToDays(''), isEmpty);
    });
  });

  group('ReminderSettingsNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('toggleDay adds the day, persists, and reschedules', () async {
      final fake = FakeNotificationService();
      final container = _makeContainer(fake);
      container.read(reminderSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container
          .read(reminderSettingsProvider.notifier)
          .toggleDay(DateTime.tuesday);

      expect(
        container.read(reminderSettingsProvider).enabledDays,
        contains(DateTime.tuesday),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('reminder_days'), '2');
      expect(fake.weeklyScheduleCallCount, 1);
      expect(fake.lastWeeklySettings?.enabledDays, {DateTime.tuesday});
    });

    test('toggleDay removes a previously set day', () async {
      SharedPreferences.setMockInitialValues({'reminder_days': '1,3,5'});
      final fake = FakeNotificationService();
      final container = _makeContainer(fake);
      // Allow async _load() to complete.
      container.read(reminderSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container
          .read(reminderSettingsProvider.notifier)
          .toggleDay(DateTime.wednesday);

      expect(
        container.read(reminderSettingsProvider).enabledDays,
        {DateTime.monday, DateTime.friday},
      );
    });

    test('setTime persists hour and minute and reschedules', () async {
      final fake = FakeNotificationService();
      final container = _makeContainer(fake);
      container.read(reminderSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(reminderSettingsProvider.notifier).setTime(7, 30);

      final state = container.read(reminderSettingsProvider);
      expect(state.hour, 7);
      expect(state.minute, 30);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('reminder_hour'), 7);
      expect(prefs.getInt('reminder_minute'), 30);
      expect(fake.weeklyScheduleCallCount, 1);
    });

    test('toggleStreakReminder enables and schedules streak reminder',
        () async {
      final fake = FakeNotificationService();
      final container = _makeContainer(fake);
      container.read(reminderSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container
          .read(reminderSettingsProvider.notifier)
          .toggleStreakReminder();

      expect(
        container.read(reminderSettingsProvider).streakReminderEnabled,
        isTrue,
      );
      expect(fake.streakScheduleCallCount, 1);
      expect(fake.streakCancelCallCount, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('streak_reminder'), isTrue);
    });

    test('toggleStreakReminder disables and cancels when previously enabled',
        () async {
      SharedPreferences.setMockInitialValues({'streak_reminder': true});
      final fake = FakeNotificationService();
      final container = _makeContainer(fake);
      container.read(reminderSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container
          .read(reminderSettingsProvider.notifier)
          .toggleStreakReminder();

      expect(
        container.read(reminderSettingsProvider).streakReminderEnabled,
        isFalse,
      );
      expect(fake.streakCancelCallCount, 1);
    });
  });

  group('NotificationPermissionNotifier', () {
    test('build returns current platform status', () async {
      final fake = FakeNotificationService()
        ..status = NotificationPermission.denied;
      final container = _makeContainer(fake);

      final result =
          await container.read(notificationPermissionProvider.future);

      expect(result, NotificationPermission.denied);
    });

    test('request grants permission when service returns true', () async {
      final fake = FakeNotificationService()
        ..status = NotificationPermission.denied
        ..requestResult = true;
      final container = _makeContainer(fake);
      // Wait for initial build to settle.
      await container.read(notificationPermissionProvider.future);

      final result = await container
          .read(notificationPermissionProvider.notifier)
          .request();

      expect(result, NotificationPermission.granted);
      expect(fake.requestCallCount, 1);
      expect(
        container.read(notificationPermissionProvider).value,
        NotificationPermission.granted,
      );
    });

    test('request denies permission when service returns false', () async {
      final fake = FakeNotificationService()
        ..requestResult = false;
      final container = _makeContainer(fake);
      await container.read(notificationPermissionProvider.future);

      final result = await container
          .read(notificationPermissionProvider.notifier)
          .request();

      expect(result, NotificationPermission.denied);
      expect(
        container.read(notificationPermissionProvider).value,
        NotificationPermission.denied,
      );
    });

    test('refresh re-reads the platform status', () async {
      final fake = FakeNotificationService()
        ..status = NotificationPermission.denied;
      final container = _makeContainer(fake);
      await container.read(notificationPermissionProvider.future);

      fake.status = NotificationPermission.granted;
      await container
          .read(notificationPermissionProvider.notifier)
          .refresh();

      expect(
        container.read(notificationPermissionProvider).value,
        NotificationPermission.granted,
      );
    });
  });
}
