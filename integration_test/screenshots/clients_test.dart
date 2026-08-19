import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/screenshot_seed.dart';
import '../helpers/test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('clients', (tester) async {
    // Android renders into a surface the framework cannot read back until
    // this runs; on iOS it is a no-op. Must happen before the first
    // takeScreenshot of the run, not before each one.
    await binding.convertFlutterSurfaceToImage();

    final testApp = await createTestApp(initialPrefs: screenshotPrefs());
    await seedScreenshotData(testApp.database);
    await tester.pumpWidget(testApp.app);
    await tester.pumpAndSettle();

    // This capture is tapped through the rail rather than routed to with
    // goTo, because the rail is half of what the image documents: on a phone
    // there is no rail and no roster, which is the whole reason this one
    // screenshot is taken on an iPad.
    await tester.tap(find.text('Clients').first);
    await tester.pumpAndSettle();

    // Guard against photographing the wrong screen. A capture test that only
    // takes a picture passes just as happily when the tap missed and the
    // roster never opened; the seeded client is the proof it did.
    expect(find.text('Jamie Rivera'), findsOneWidget);

    await settleForCapture(tester);
    await binding.takeScreenshot('clients');
    await testApp.database.close();
  });
}
