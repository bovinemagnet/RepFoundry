import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../domain/sync_service.dart';
import 'cloudkit_sync_service.dart';
import 'google_drive_sync_service.dart';
import 'noop_cloud_sync_service.dart';

/// Returns the platform-appropriate cloud sync service.
///
/// iOS uses CloudKit; Android uses Google Drive. Every other host —
/// Linux, Windows, macOS desktop, Flutter web without the Google
/// Sign-In plugin — gets a [NoopCloudSyncService] so the orchestrator
/// runs to completion without throwing `UnimplementedError` from the
/// Google Sign-In platform-interface placeholder.
CloudSyncService createCloudSyncService() {
  // dart:io's Platform getters throw on web, so decide that first.
  if (kIsWeb) return pickCloudSyncService(isWeb: true);
  return pickCloudSyncService(
    isIOS: Platform.isIOS,
    isAndroid: Platform.isAndroid,
  );
}

/// Pure routing decision for [createCloudSyncService], extracted so
/// tests can drive the platform booleans directly without stubbing
/// `dart:io`.
CloudSyncService pickCloudSyncService({
  bool isWeb = false,
  bool isIOS = false,
  bool isAndroid = false,
}) {
  if (isWeb) return const NoopCloudSyncService();
  if (isIOS) return CloudKitSyncService();
  if (isAndroid) return GoogleDriveSyncService();
  return const NoopCloudSyncService();
}
