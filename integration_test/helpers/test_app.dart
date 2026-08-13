import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rep_foundry/app/app.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/notifications/presentation/providers/reminder_settings_provider.dart';

import 'fake_health_sync_service.dart';
import 'fake_notification_service.dart';
import 'fakes.dart';

/// Creates a fully-wired test app with an in-memory database and faked
/// platform services. Returns the widget to pump and the database handle
/// for pre-seeding data or asserting at the data layer.
Future<({Widget app, AppDatabase database})> createTestApp({
  FakeHeartRateService? heartRateService,
  FakeLocationService? locationService,
  Map<String, Object>? initialPrefs,
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs ?? {});

  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final hrService = heartRateService ?? FakeHeartRateService();
  final locService = locationService ?? FakeLocationService();

  final app = ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      heartRateServiceProvider.overrideWithValue(hrService),
      locationServiceProvider.overrideWithValue(locService),
      healthSyncServiceProvider.overrideWithValue(FakeHealthSyncService()),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
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

/// Navigates the running app to [location] and settles.
///
/// The screenshot captures photograph screens several taps deep; driving the
/// router directly keeps them independent of how a screen happens to be
/// reachable today, and avoids scrolling long menus to find an entry point.
Future<void> goTo(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(Navigator).first);
  GoRouter.of(context).go(location);
  await tester.pumpAndSettle();
}

/// Settles the tree, then gives the device a moment to composite it.
///
/// `takeScreenshot` photographs what the device last put on screen, which can
/// lag a settled widget tree: a route transition that has finished animating
/// in the tree may still be sliding in the captured frame, leaving the
/// previous screen peeking at the edge of the image.
Future<void> settleForCapture(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Jumps the scroll view that contains [anchor] back to its top.
///
/// Used instead of a drag because dragging downwards at the top of a list
/// arms the pull-to-refresh indicator, which then appears in the capture.
Future<void> scrollToTop(WidgetTester tester, Finder anchor) async {
  final scrollable =
      find.ancestor(of: anchor, matching: find.byType(Scrollable)).first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pumpAndSettle();
}
