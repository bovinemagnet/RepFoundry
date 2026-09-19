import '../domain/sync_service.dart';

/// A no-op [CloudSyncService] used on platforms that have no real cloud
/// backend wired up (Linux, Windows, macOS, Flutter web without the
/// Google Sign-In plugin). Letting these hosts fall through to a real
/// service throws `UnimplementedError` from the platform-interface
/// placeholder when sync runs.
///
/// [isSupported] and [isAvailable] both return false so the orchestrator
/// refuses to sync and the settings UI can disable the toggle, rather than
/// reporting a success whose upload was silently discarded.
class NoopCloudSyncService implements CloudSyncService {
  const NoopCloudSyncService();

  @override
  bool get isSupported => false;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> uploadSnapshot(
    String jsonData, {
    bool interactive = false,
  }) async {
    // Discard.
  }

  @override
  Future<String?> downloadSnapshot({bool interactive = false}) async => null;

  @override
  Future<void> deleteCloudData({bool interactive = false}) async {
    // Nothing to delete.
  }
}
