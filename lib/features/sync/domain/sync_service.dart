abstract class CloudSyncService {
  /// Whether the cloud storage is available and authenticated.
  Future<bool> isAvailable();

  /// Upload a serialised snapshot to cloud storage.
  Future<void> uploadSnapshot(String jsonData);

  /// Download the latest snapshot from cloud storage.
  /// Returns null if no snapshot exists (first sync).
  Future<String?> downloadSnapshot();

  /// Delete all cloud data and sign out.
  Future<void> deleteCloudData();
}
