abstract class CloudSyncService {
  /// Whether this host has a real cloud backend at all. False only for the
  /// placeholder used on platforms without one; distinct from [isAvailable],
  /// which is also false while a real backend is awaiting sign-in.
  bool get isSupported => true;

  /// Whether the cloud storage is available and authenticated.
  Future<bool> isAvailable();

  /// Upload a serialised snapshot to cloud storage.
  ///
  /// [interactive] should be true only from an explicit user action where the
  /// platform is allowed to show authentication/authorization UI.
  Future<void> uploadSnapshot(String jsonData, {bool interactive = false});

  /// Download the latest snapshot from cloud storage.
  /// Returns null if no snapshot exists (first sync).
  ///
  /// [interactive] should be true only from an explicit user action where the
  /// platform is allowed to show authentication/authorization UI.
  Future<String?> downloadSnapshot({bool interactive = false});

  /// Delete all cloud data and sign out.
  Future<void> deleteCloudData({bool interactive = false});
}
