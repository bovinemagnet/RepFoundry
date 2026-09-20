import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/notifications/data/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('init completes on Windows even though the plugin is not configured',
      () async {
    // main() awaits init() before runApp, so a throw here blocks startup.
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    await expectLater(NotificationService().init(), completes);
  });
}
