// Driver-enabled entry point for live MCP / Flutter Driver testing.
//
// Mirrors lib/main.dart but calls [enableFlutterDriverExtension] so the running
// app can be inspected and driven via the Dart/Flutter MCP tools. Run with:
//   flutter run -t integration_test/live_driver.dart -d <device>
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/app/app.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/features/notifications/data/notification_service.dart';

Future<void> main() async {
  enableFlutterDriverExtension();
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  try {
    await NotificationService().init();
  } catch (_) {
    // Notification init is best-effort in the test harness.
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const RepFoundryApp(),
    ),
  );
}
