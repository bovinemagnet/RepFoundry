import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/screenshot_seed.dart';
import '../helpers/test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Boots a seeded app, navigates to [location] and captures [name].
  ///
  /// Every capture in this file is a plain "open a screen and photograph it"
  /// shot, so they share one body rather than repeating it five times.
  Future<void> captureScreen(
    WidgetTester tester, {
    required String location,
    required String name,
  }) async {
    // Android renders into a surface the framework cannot read back until
    // this runs; on iOS it is a no-op. It belongs in every capturing test,
    // not once per run: integration_test registers an addTearDown that
    // reverts the surface when the test ends, so a single call at the start
    // leaves every later test throwing "Call convertFlutterSurfaceToImage()
    // before taking a screenshot".
    await binding.convertFlutterSurfaceToImage();

    final testApp = await createTestApp(initialPrefs: screenshotPrefs());
    await seedScreenshotData(testApp.database);
    await tester.pumpWidget(testApp.app);
    await tester.pumpAndSettle();

    await goTo(tester, location);
    await settleForCapture(tester);
    await binding.takeScreenshot(name);
    await testApp.database.close();
  }

  testWidgets('exercise-library', (tester) async {
    await captureScreen(tester,
        location: '/exercises', name: 'exercise-library');
  });

  testWidgets('templates', (tester) async {
    await captureScreen(tester, location: '/templates', name: 'templates');
  });

  testWidgets('programmes', (tester) async {
    await captureScreen(tester, location: '/programmes', name: 'programmes');
  });

  testWidgets('settings', (tester) async {
    await captureScreen(tester, location: '/settings', name: 'settings');
  });

  testWidgets('notifications', (tester) async {
    await captureScreen(
      tester,
      location: '/settings/notifications',
      name: 'notifications',
    );
  });
}
