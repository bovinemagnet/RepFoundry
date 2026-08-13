import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/notifications/presentation/providers/reminder_settings_provider.dart';
import 'package:rep_foundry/features/notifications/presentation/widgets/reminder_days_picker.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fakes/fake_notification_service.dart';

/// Phone-width layout guard for the day picker.
///
/// This lives in its own file because the surface size is the whole point.
/// The default test surface is 800x600 — wider than any phone — so the
/// sibling tests in reminder_days_picker_test.dart pass while the seven day
/// chips overflow the screen of every device the app ships on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildHost() {
    return ProviderScope(
      overrides: [
        notificationServiceProvider
            .overrideWithValue(FakeNotificationService()),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: ReminderDaysPicker()),
      ),
    );
  }

  /// Phone widths the app supports, narrowest first. 320 is an iPhone SE in
  /// portrait; 402 is an iPhone 16 Pro.
  const phoneWidths = <double>[320, 375, 402];

  for (final width in phoneWidths) {
    testWidgets('lays out seven days without overflowing at ${width}dp wide',
        (tester) async {
      tester.view.physicalSize = Size(width * 3, 874 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildHost());
      await tester.pumpAndSettle();

      // An overflowing RenderFlex reports the failure through the error
      // handler rather than by throwing out of pumpWidget, so ask for it.
      expect(tester.takeException(), isNull);

      // All seven have to be reachable: a fix that hides Sat and Sun off the
      // right-hand edge silences the overflow without solving anything.
      for (final label in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
        expect(find.text(label), findsOneWidget);
        expect(
          tester.getTopLeft(find.text(label)).dx,
          greaterThanOrEqualTo(0),
          reason: '$label starts off the left edge at ${width}dp',
        );
        expect(
          tester.getBottomRight(find.text(label)).dx,
          lessThanOrEqualTo(width),
          reason: '$label runs past the right edge at ${width}dp',
        );
      }
    });
  }
}
