import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/screenshot_seed.dart';
import '../helpers/test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('workout-logging', (tester) async {
    // Android renders into a surface the framework cannot read back until
    // this runs; on iOS it is a no-op. Must happen before the first
    // takeScreenshot of the run, not before each one.
    await binding.convertFlutterSurfaceToImage();

    final testApp = await createTestApp(initialPrefs: screenshotPrefs());
    await seedScreenshotData(testApp.database);
    await tester.pumpWidget(testApp.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Exercise'));
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.text('Barbell Bench Press'));
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();

    // A session with nothing logged is the empty state of this screen: the
    // volume header reads 0 kg and no completed set rows exist. Log the
    // first two sets of the ghost suggestion, then leave the third typed
    // but unlogged so the shot shows completed sets, the next suggestion
    // and the input together.
    //
    // The frame deliberately sits on the card rather than the session
    // header: once any volume is logged the header grows an 80px sparkline
    // band, and with a single exercise that band holds one dot and pushes
    // the LOG SET button under the navigation bar.
    await _logSet(tester, weight: '55', reps: '10');
    await _logSet(tester, weight: '60', reps: '8');
    await _typeSet(tester, weight: '62.5', reps: '6');

    await binding.takeScreenshot('workout-logging');
    await testApp.database.close();
  });
}

/// Types [weight] and [reps] into the set input card's fields. The fields are
/// unkeyed; the card renders weight first, then reps.
Future<void> _typeSet(
  WidgetTester tester, {
  required String weight,
  required String reps,
}) async {
  // Logging a set scrolls the exercise into view from the bottom, which
  // pushes the input card out of the viewport — the fields are then offstage
  // and no onstage finder can reach them. Scroll them back first.
  final fields = find.byType(TextFormField, skipOffstage: false);
  await tester.ensureVisible(fields.first);
  await tester.pumpAndSettle();
  await tester.enterText(fields.at(0), weight);
  await tester.pumpAndSettle();
  await tester.enterText(fields.at(1), reps);
  await tester.pumpAndSettle();
}

/// Types a set and logs it. Logging resets the reps field, so every set after
/// the first has to be typed in full rather than relying on the ghost fill.
Future<void> _logSet(
  WidgetTester tester, {
  required String weight,
  required String reps,
}) async {
  await _typeSet(tester, weight: weight, reps: reps);
  await tester.tap(find.text('LOG SET'));
  await tester.pumpAndSettle();
}
