import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/sync/data/cloudkit_sync_service.dart';
import 'package:rep_foundry/features/sync/data/google_drive_sync_service.dart';
import 'package:rep_foundry/features/sync/data/noop_cloud_sync_service.dart';
import 'package:rep_foundry/features/sync/data/sync_service_factory.dart';

void main() {
  group('pickCloudSyncService', () {
    test('iOS routes to CloudKit', () {
      final service = pickCloudSyncService(isIOS: true, isAndroid: false);
      expect(service, isA<CloudKitSyncService>());
    });

    test('Android routes to Google Drive', () {
      final service = pickCloudSyncService(isIOS: false, isAndroid: true);
      expect(service, isA<GoogleDriveSyncService>());
    });

    test('Linux / Windows / macOS / unknown route to Noop', () {
      // Both flags false simulates a desktop or web host without a
      // platform-specific cloud backend wired up. The previous routing
      // returned GoogleDriveSyncService, which threw UnimplementedError
      // from the Google Sign-In platform-interface placeholder during
      // the post-workout sync.
      final service = pickCloudSyncService(isIOS: false, isAndroid: false);
      expect(service, isA<NoopCloudSyncService>());
    });

    test('iOS takes precedence over Android (defensive)', () {
      // Both flags can never be true on a real device, but the routing
      // must be deterministic if a test forces both.
      final service = pickCloudSyncService(isIOS: true, isAndroid: true);
      expect(service, isA<CloudKitSyncService>());
    });
  });
}
