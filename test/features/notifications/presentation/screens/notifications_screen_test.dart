import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/notifications/data/notification_service.dart';
import 'package:rep_foundry/features/notifications/presentation/providers/reminder_settings_provider.dart';
import 'package:rep_foundry/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fakes/fake_notification_service.dart';

Widget _wrap(FakeNotificationService fake) {
  return ProviderScope(
    overrides: [
      notificationServiceProvider.overrideWithValue(fake),
    ],
    child: const MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: NotificationsScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders day chips, time tile, streak switch, and test button',
      (tester) async {
    final fake = FakeNotificationService();
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    // 7 day chips
    expect(find.byType(FilterChip), findsNWidgets(7));
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.text('Send test notification'), findsOneWidget);
  });

  testWidgets('hides permission denied banner when granted', (tester) async {
    final fake = FakeNotificationService()
      ..status = NotificationPermission.granted;
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('shows permission denied banner with open settings action',
      (tester) async {
    final fake = FakeNotificationService()
      ..status = NotificationPermission.denied
      ..requestResult = false;
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
  });

  testWidgets('tapping open settings calls openNotificationSettings',
      (tester) async {
    final fake = FakeNotificationService()
      ..status = NotificationPermission.denied
      ..requestResult = false;
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(fake.openSettingsCallCount, 1);
  });

  testWidgets('tapping a day chip toggles the day when permission granted',
      (tester) async {
    final fake = FakeNotificationService();
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    final mondayChip = find.widgetWithText(FilterChip, 'Mon');
    await tester.tap(mondayChip);
    await tester.pumpAndSettle();

    expect(fake.weeklyScheduleCallCount, greaterThanOrEqualTo(1));
    expect(fake.lastWeeklySettings?.enabledDays, contains(DateTime.monday));
  });

  testWidgets('test notification tile is disabled when permission denied',
      (tester) async {
    final fake = FakeNotificationService()
      ..status = NotificationPermission.denied
      ..requestResult = false;
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Send test notification'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.enabled, isFalse);
  });

  testWidgets('tapping send test notification fires the service when granted',
      (tester) async {
    final fake = FakeNotificationService();
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send test notification'));
    await tester.pumpAndSettle();

    expect(fake.testNotificationCallCount, 1);
    expect(find.text('Test notification sent'), findsOneWidget);
  });

  testWidgets('toggling chip with denied permission triggers a request',
      (tester) async {
    final fake = FakeNotificationService()
      ..status = NotificationPermission.denied
      ..requestResult = false;
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Mon'));
    await tester.pumpAndSettle();

    expect(fake.requestCallCount, 1);
    // Permission stayed denied so the day toggle should not have been scheduled.
    expect(fake.weeklyScheduleCallCount, 0);
  });
}
