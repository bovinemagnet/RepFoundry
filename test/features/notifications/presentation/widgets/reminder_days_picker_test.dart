import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/notifications/presentation/providers/reminder_settings_provider.dart';
import 'package:rep_foundry/features/notifications/presentation/widgets/reminder_days_picker.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fakes/fake_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildHost({
    Future<bool> Function()? onBeforeToggle,
    FakeNotificationService? service,
  }) {
    return ProviderScope(
      overrides: [
        notificationServiceProvider
            .overrideWithValue(service ?? FakeNotificationService()),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: ReminderDaysPicker(onBeforeToggle: onBeforeToggle),
        ),
      ),
    );
  }

  group('ReminderDaysPicker', () {
    testWidgets('renders a FilterChip for each weekday', (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNWidgets(7));
      // Day labels (English short names).
      for (final label in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('tapping a chip toggles the corresponding day on the notifier',
        (tester) async {
      final service = FakeNotificationService();
      await tester.pumpWidget(buildHost(service: service));
      await tester.pumpAndSettle();

      // Pre-condition: no enabled days.
      await tester.tap(find.widgetWithText(FilterChip, 'Mon'));
      await tester.pumpAndSettle();

      // toggleDay -> scheduleWeekly is invoked on the service.
      expect(service.weeklyScheduleCallCount, greaterThanOrEqualTo(1));
      expect(
        service.lastWeeklySettings?.enabledDays,
        contains(DateTime.monday),
      );
    });

    testWidgets('onBeforeToggle returning false short-circuits the toggle',
        (tester) async {
      final service = FakeNotificationService();
      await tester.pumpWidget(buildHost(
        service: service,
        onBeforeToggle: () async => false,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Wed'));
      await tester.pumpAndSettle();

      expect(service.weeklyScheduleCallCount, 0);
    });

    testWidgets('onBeforeToggle returning true allows the toggle to proceed',
        (tester) async {
      final service = FakeNotificationService();
      var beforeCalls = 0;
      await tester.pumpWidget(buildHost(
        service: service,
        onBeforeToggle: () async {
          beforeCalls++;
          return true;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Fri'));
      await tester.pumpAndSettle();

      expect(beforeCalls, 1);
      expect(service.weeklyScheduleCallCount, greaterThanOrEqualTo(1));
      expect(
        service.lastWeeklySettings?.enabledDays,
        contains(DateTime.friday),
      );
    });
  });
}
