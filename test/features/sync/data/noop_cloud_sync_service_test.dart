import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/sync/data/noop_cloud_sync_service.dart';

void main() {
  late NoopCloudSyncService service;

  setUp(() {
    service = const NoopCloudSyncService();
  });

  group('NoopCloudSyncService', () {
    test('isAvailable is false so callers can short-circuit', () async {
      expect(await service.isAvailable(), isFalse);
    });

    test('downloadSnapshot returns null (no remote state)', () async {
      expect(await service.downloadSnapshot(), isNull);
    });

    test('uploadSnapshot succeeds silently and discards the payload', () async {
      // Must not throw, regardless of payload contents.
      await service.uploadSnapshot('{"some":"data"}');
      // Subsequent download still returns null — the upload was discarded.
      expect(await service.downloadSnapshot(), isNull);
    });

    test('deleteCloudData succeeds silently', () async {
      await service.deleteCloudData();
    });

    test('orchestrator-style sequence runs to completion without throwing',
        () async {
      // The orchestrator does: download → (merge) → upload → (apply
      // local). Verify the cloud-facing calls all succeed against the
      // Noop without throwing, which is the reason the service exists.
      final remote = await service.downloadSnapshot();
      expect(remote, isNull);

      await service.uploadSnapshot('{"merged":"snapshot"}');

      // No state retained.
      expect(await service.downloadSnapshot(), isNull);
    });
  });
}
