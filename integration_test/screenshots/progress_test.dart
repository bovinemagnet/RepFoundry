import 'package:rep_foundry/core/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/screenshot_seed.dart';
import '../helpers/test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Boots a seeded app and navigates to [location].
  Future<AppDatabase> open(
    WidgetTester tester, {
    required String location,
  }) async {
    final testApp = await createTestApp(initialPrefs: screenshotPrefs());
    await seedScreenshotData(testApp.database);
    await tester.pumpWidget(testApp.app);
    await tester.pumpAndSettle();
    await goTo(tester, location);
    return testApp.database;
  }

  testWidgets('history', (tester) async {
    // Android renders into a surface the framework cannot read back until
    // this runs; on iOS it is a no-op. Must happen before the first
    // takeScreenshot of the run, not before each one.
    await binding.convertFlutterSurfaceToImage();

    final database = await open(tester, location: '/history');
    await settleForCapture(tester);
    await binding.takeScreenshot('history');
    await database.close();
  });

  testWidgets('analytics', (tester) async {
    final database = await open(tester, location: '/analytics');
    await settleForCapture(tester);
    await binding.takeScreenshot('analytics');
    await database.close();
  });

  testWidgets('body-metrics', (tester) async {
    final database = await open(tester, location: '/body-metrics');
    await settleForCapture(tester);
    await binding.takeScreenshot('body-metrics');
    await database.close();
  });

  testWidgets('sync-ios', (tester) async {
    final database = await open(tester, location: '/settings');
    // Cloud sync is a section part-way down the settings list rather than a
    // screen of its own. The list builds lazily, so the tile does not exist
    // until it is scrolled near — ensureVisible cannot reach it.
    await tester.scrollUntilVisible(
      find.text('Enable Cross-Device Sync'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible stops the moment the tile appears, which leaves it
    // clipped against the top edge. Nudge the list back so the whole
    // section sits inside the frame.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 220));
    await tester.pumpAndSettle();
    await settleForCapture(tester);
    await binding.takeScreenshot('sync-ios');
    await database.close();
  });

  testWidgets('nav-ios', (tester) async {
    // The subject is the bottom navigation bar, not the screen behind it —
    // the orchestration script crops this one to the bar. History is used
    // only because it is populated and unambiguous.
    final database = await open(tester, location: '/history');
    await settleForCapture(tester);
    await binding.takeScreenshot('nav-ios');
    await database.close();
  });
}
