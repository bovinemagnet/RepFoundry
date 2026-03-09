import 'dart:io' show Platform;
import '../domain/sync_service.dart';
import 'cloudkit_sync_service.dart';
import 'google_drive_sync_service.dart';

/// Returns the platform-appropriate cloud sync service.
CloudSyncService createCloudSyncService() {
  if (Platform.isIOS) {
    return CloudKitSyncService();
  }
  return GoogleDriveSyncService();
}
