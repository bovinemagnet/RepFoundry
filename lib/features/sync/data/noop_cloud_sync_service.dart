import '../domain/sync_service.dart';

/// A no-op [CloudSyncService] used on platforms that have no real cloud
/// backend wired up (Linux, Windows, macOS, Flutter web without the
/// Google Sign-In plugin). Letting these hosts fall through to a real
/// service throws `UnimplementedError` from the platform-interface
/// placeholder when sync runs.
///
/// All methods succeed silently. [isAvailable] returns false so any
/// caller that gates on it short-circuits cleanly. [downloadSnapshot]
/// returns null so the orchestrator merges against an empty remote and
/// produces a no-op upload that this service then discards.
class NoopCloudSyncService implements CloudSyncService {
  const NoopCloudSyncService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> uploadSnapshot(String jsonData) async {
    // Discard.
  }

  @override
  Future<String?> downloadSnapshot() async => null;

  @override
  Future<void> deleteCloudData() async {
    // Nothing to delete.
  }
}
