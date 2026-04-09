import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rep_foundry/app/app.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/core/providers.dart';

import 'fake_health_sync_service.dart';
import 'fakes.dart';

/// Creates a fully-wired test app with an in-memory database and faked
/// platform services. Returns the widget to pump and the database handle
/// for pre-seeding data or asserting at the data layer.
Future<({Widget app, AppDatabase database})> createTestApp({
  FakeHeartRateService? heartRateService,
  FakeLocationService? locationService,
}) async {
  SharedPreferences.setMockInitialValues({});

  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final hrService = heartRateService ?? FakeHeartRateService();
  final locService = locationService ?? FakeLocationService();

  final app = ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      heartRateServiceProvider.overrideWithValue(hrService),
      locationServiceProvider.overrideWithValue(locService),
      healthSyncServiceProvider.overrideWithValue(FakeHealthSyncService()),
    ],
    child: const RepFoundryApp(),
  );

  return (app: app, database: database);
}

/// Repeatedly pumps until the [finder] matches at least one widget,
/// or times out after [timeout].
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (tester.any(finder)) return;
  }
  // One final pump and settle attempt.
  await tester.pumpAndSettle();
}
