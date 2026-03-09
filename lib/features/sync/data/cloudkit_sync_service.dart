import 'package:flutter/services.dart';
import '../domain/sync_service.dart';

/// CloudKit-based sync service for iOS, communicating via platform channel.
class CloudKitSyncService implements CloudSyncService {
  static const _channel = MethodChannel('com.repfoundry.app/cloudkit_sync');

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> uploadSnapshot(String jsonSnapshot) async {
    await _channel.invokeMethod<bool>(
      'uploadSnapshot',
      {'json': jsonSnapshot},
    );
  }

  @override
  Future<String?> downloadSnapshot() async {
    final result = await _channel.invokeMethod<String>('downloadSnapshot');
    return result;
  }

  @override
  Future<void> deleteCloudData() async {
    await _channel.invokeMethod<bool>('deleteCloudData');
  }
}
