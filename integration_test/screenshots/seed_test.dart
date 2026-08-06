import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/screenshot_seed.dart';
import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the screenshot fixture fills the screens we photograph',
      (tester) async {
    final testApp = await createTestApp(initialPrefs: screenshotPrefs());
    await seedScreenshotData(testApp.database);
    await tester.pumpWidget(testApp.app);
    await tester.pumpAndSettle();

    // The empty-state text lives on the History tab, not the Workout tab
    // the app lands on — navigate there so the assertion below actually
    // exercises the fixture instead of trivially passing on the landing
    // screen, which never shows this text either way.
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    // The history screen must not be showing its empty state — that is the
    // single failure this fixture exists to prevent, and it is invisible
    // in a screenshot review until someone notices the app looks unused.
    expect(find.textContaining('No workouts'), findsNothing);

    await testApp.database.close();
  });
}
