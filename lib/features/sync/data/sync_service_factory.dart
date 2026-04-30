import 'dart:io' show Platform;
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
  return pickCloudSyncService(
    isIOS: Platform.isIOS,
    isAndroid: Platform.isAndroid,
  );
}

/// Pure routing decision for [createCloudSyncService], extracted so
/// tests can drive the platform booleans directly without stubbing
/// `dart:io`.
CloudSyncService pickCloudSyncService({
  required bool isIOS,
  required bool isAndroid,
}) {
  if (isIOS) return CloudKitSyncService();
  if (isAndroid) return GoogleDriveSyncService();
  return const NoopCloudSyncService();
}
