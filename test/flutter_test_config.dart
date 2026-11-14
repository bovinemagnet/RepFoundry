import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Runs before every test file (see `flutter test` docs on
/// `flutter_test_config.dart`).
///
/// google_fonts loads each family/weight lazily, the first time a widget asks
/// for it. When the load finishes the engine sends a `fontsChange` system
/// message, and every text render object schedules a frame callback to
/// re-layout. If that lands after a test's last pump, the callback is still
/// pending at teardown and the test fails with "An animation is still running
/// even after the widget tree was disposed" (#151).
///
/// Loading every bundled variant here, before any widget exists, means the
/// message arrives with nothing listening and no test pays for it.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _preloadBundledFonts();
  await testMain();
}

/// The variants bundled under `assets/fonts/` (see `pubspec.yaml`).
Future<void> _preloadBundledFonts() async {
  const all = FontWeight.values;
  for (final weight in all.sublist(0, 8)) {
    GoogleFonts.jetBrainsMono(fontWeight: weight); // w100–w800
  }
  for (final weight in all.sublist(1, 8)) {
    GoogleFonts.manrope(fontWeight: weight); // w200–w800
  }
  for (final weight in all.sublist(2, 7)) {
    GoogleFonts.spaceGrotesk(fontWeight: weight); // w300–w700
  }
  await GoogleFonts.pendingFonts();
}
