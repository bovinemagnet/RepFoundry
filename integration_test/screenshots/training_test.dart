import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:rep_foundry/features/cardio/data/heart_rate_service.dart';
import 'package:rep_foundry/features/workout/presentation/widgets/rest_timer_widget.dart';

import '../helpers/fakes.dart';
import '../helpers/screenshot_seed.dart';
import '../helpers/test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('workout-logging', (tester) async {
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

    await startWorkoutWith(tester, 'Barbell Bench Press');

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

  testWidgets('first-workout', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    final testApp = await createTestApp(initialPrefs: screenshotPrefs());
    await seedScreenshotData(testApp.database);
    await tester.pumpWidget(testApp.app);
    await tester.pumpAndSettle();

    await startWorkoutWith(tester, 'Barbell Bench Press');

    // Start the rest timer before logging, not after: a logged set that
    // beats a record raises the personal-record overlay, and that overlay
    // absorbs pointer events, so the tap on the chip would be swallowed
    // without failing the test.
    await tester.tap(find.text('1:30'));
    await tester.pump();

    await _logSet(tester, weight: '55', reps: '10');

    // The first set of a session always sets some record, so the
    // celebration overlay covers the middle of the screen. It dismisses on
    // a real three-second Timer that neither pump(duration) nor runAsync
    // advances under this binding, so tap it away instead.
    await tester.tap(find.text('Barbell Bench Press').last);
    await tester.pumpAndSettle();

    // A second set, so the volume sparkline draws a line rather than a lone
    // dot floating in an otherwise empty band. One set is the smallest
    // session that is not an empty state; it is not the most useful one to
    // photograph.
    await _logSet(tester, weight: '60', reps: '8');
    await tester.tap(find.text('Barbell Bench Press').last);
    await tester.pumpAndSettle();

    await scrollToTop(
      tester,
      find.text('Barbell Bench Press', skipOffstage: false),
    );

    // A running rest timer rebuilds every second, so the tree never settles
    // and pumpAndSettle would time out rather than return.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    final logSet = find.text('LOG SET');
    await scrollClearOfFab(tester, logSet);
    // Once the card is clear of the FAB the rest timer band no longer fits
    // above it, and a band sliced through the middle at the top edge reads as
    // a rendering fault rather than a scrolled list. Push it fully out of
    // frame; the running timer is described in the prose beside this image.
    await scrollPastTop(tester, find.byType(RestTimerWidget));
    await tester.pump(const Duration(milliseconds: 500));

    // The whole point of this shot is a beginner's first logged set, so the
    // button they press next cannot be half hidden behind the Add Exercise
    // FAB. Asserted rather than eyeballed: a capture test photographs an
    // obscured button just as happily as a clear one.
    expect(
      tester.getRect(logSet).bottom,
      lessThanOrEqualTo(
        tester.getRect(find.byType(FloatingActionButton)).top,
      ),
      reason: 'the Add Exercise button is covering the LOG SET call to action',
    );

    await binding.takeScreenshot('first-workout');
    await testApp.database.close();
  });

  testWidgets('stretching', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    final testApp = await createTestApp(initialPrefs: screenshotPrefs());
    await seedScreenshotData(testApp.database);
    await tester.pumpWidget(testApp.app);
    await tester.pumpAndSettle();

    await startWorkoutWith(tester, 'Barbell Bench Press');

    // Stretching has no route of its own: it is a section of the active
    // workout screen. The sheet is what documents the feature, since the
    // section itself is one button until something has been added.
    // Unscrolled, this button sits underneath the navigation bar, and a tap
    // on it lands on the History tab instead — silently, since the finder
    // itself matches.
    final addStretching = find.text('Add Stretching', skipOffstage: false);
    await tester.ensureVisible(addStretching);
    await tester.pumpAndSettle();
    await tester.tap(addStretching);
    await settleForCapture(tester);

    await binding.takeScreenshot('stretching');
    await testApp.database.close();
  });

  testWidgets('cardio-session', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    final locationService = FakeLocationService();
    final heartRateService = FakeHeartRateService(
      devicesToReturn: const [
        DiscoveredHrDevice(id: 'polar-h9', name: 'Polar H9'),
      ],
    );
    final testApp = await createTestApp(
      initialPrefs: screenshotPrefs(),
      locationService: locationService,
      heartRateService: heartRateService,
    );
    await seedScreenshotData(testApp.database);
    await tester.pumpWidget(testApp.app);
    await tester.pumpAndSettle();

    await goTo(tester, '/cardio');

    // Distance and pace stay blank unless GPS tracking is switched on, so
    // the emitted fixes below would otherwise change nothing on screen.
    final gpsToggle = find.byType(Switch).first;
    await tester.ensureVisible(gpsToggle);
    await tester.pumpAndSettle();
    await tester.tap(gpsToggle);
    await tester.pumpAndSettle();

    // Connect a strap so the session shows a heart rate alongside pace.
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Polar H9'));
    await tester.pumpAndSettle();

    final startSession = find.text('START SESSION', skipOffstage: false);
    await tester.ensureVisible(startSession);
    await tester.pumpAndSettle();
    await tester.tap(startSession);
    await tester.pump();

    // Feed the route a few fixes so distance and pace read as a session in
    // progress rather than a stopwatch on zero.
    for (var i = 0; i < 5; i++) {
      locationService.emitPosition(
        latitude: 51.5074 + i * 0.002,
        longitude: -0.1278 + i * 0.001,
      );
      heartRateService.emitHeartRate(132 + i * 3);
      await tester.pump(const Duration(seconds: 1));
    }

    // The clock is the subject of this shot; ensureVisible left the list
    // scrolled past it.
    await scrollToTop(
      tester,
      find.text('GPS Distance Tracking', skipOffstage: false),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await binding.takeScreenshot('cardio-session');
    await testApp.database.close();
  });

  testWidgets('heart-rate-panel', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    final heartRateService = FakeHeartRateService(
      devicesToReturn: const [
        DiscoveredHrDevice(id: 'polar-h9', name: 'Polar H9'),
      ],
    );
    final testApp = await createTestApp(
      initialPrefs: screenshotPrefs(),
      heartRateService: heartRateService,
    );
    await seedScreenshotData(testApp.database);
    await tester.pumpWidget(testApp.app);
    await tester.pumpAndSettle();

    await goTo(tester, '/heart-rate');

    // Connect a strap through the device picker, exactly as a reader would.
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Polar H9'));
    await tester.pumpAndSettle();

    // Enough readings to draw a trace rather than a flat line.
    const beats = [96, 108, 121, 133, 142, 148, 151, 147, 153, 158];
    for (final bpm in beats) {
      heartRateService.emitHeartRate(bpm);
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 500));

    await binding.takeScreenshot('heart-rate-panel');
    await testApp.database.close();
  });

  testWidgets('coach-mode', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    final testApp = await createTestApp(initialPrefs: screenshotPrefs());
    await seedScreenshotData(testApp.database);
    await tester.pumpWidget(testApp.app);
    await tester.pumpAndSettle();

    // Reachable only because the fixture unlocks the virtualTrainer
    // entitlement; without it this route renders nothing to photograph.
    await goTo(tester, '/settings/trainer');
    await settleForCapture(tester);

    await binding.takeScreenshot('coach-mode');
    await testApp.database.close();
  });
}

/// Starts a workout and adds [exercise] to it, leaving the set input card on
/// screen ready to type into.
Future<void> startWorkoutWith(WidgetTester tester, String exercise) async {
  await tester.tap(find.text('Start Workout'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add Exercise'));
  await tester.pumpAndSettle();
  await pumpUntilFound(tester, find.text(exercise));
  await tester.tap(find.text(exercise));
  await tester.pumpAndSettle();
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
