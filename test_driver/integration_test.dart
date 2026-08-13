import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver entry point for the documentation screenshot captures.
///
/// Each `binding.takeScreenshot(name)` in a capture test arrives here; the
/// name is the image's final filename without its extension.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (
      String name,
      List<int> bytes, [
      Map<String, Object?>? args,
    ]) async {
      final file = File('build/screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
