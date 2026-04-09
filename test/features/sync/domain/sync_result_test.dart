import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_result.dart';

void main() {
  group('SyncResult', () {
    group('SyncResult.success()', () {
      test('sets success to true', () {
        final result = SyncResult.success(entitiesMerged: 5);
        expect(result.success, isTrue);
      });

      test('sets errorMessage to null', () {
        final result = SyncResult.success(entitiesMerged: 5);
        expect(result.errorMessage, isNull);
      });

      test('stores the provided entitiesMerged count', () {
        final result = SyncResult.success(entitiesMerged: 12);
        expect(result.entitiesMerged, 12);
      });

      test('sets entitiesMerged to zero when zero is provided', () {
        final result = SyncResult.success(entitiesMerged: 0);
        expect(result.entitiesMerged, 0);
      });

      test('sets syncedAt to a UTC DateTime', () {
        final before = DateTime.now().toUtc();
        final result = SyncResult.success(entitiesMerged: 0);
        final after = DateTime.now().toUtc();

        expect(result.syncedAt.isUtc, isTrue);
        expect(
          result.syncedAt.isAfter(before) ||
              result.syncedAt.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          result.syncedAt.isBefore(after) ||
              result.syncedAt.isAtSameMomentAs(after),
          isTrue,
        );
      });
    });

    group('SyncResult.error()', () {
      test('sets success to false', () {
        final result = SyncResult.error('Network timeout');
        expect(result.success, isFalse);
      });

      test('stores the provided error message', () {
        final result = SyncResult.error('Network timeout');
        expect(result.errorMessage, 'Network timeout');
      });

      test('sets entitiesMerged to default of zero', () {
        final result = SyncResult.error('Something went wrong');
        expect(result.entitiesMerged, 0);
      });

      test('sets syncedAt to a UTC DateTime', () {
        final before = DateTime.now().toUtc();
        final result = SyncResult.error('Failure');
        final after = DateTime.now().toUtc();

        expect(result.syncedAt.isUtc, isTrue);
        expect(
          result.syncedAt.isAfter(before) ||
              result.syncedAt.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          result.syncedAt.isBefore(after) ||
              result.syncedAt.isAtSameMomentAs(after),
          isTrue,
        );
      });

      test('stores an empty string error message when provided', () {
        final result = SyncResult.error('');
        expect(result.errorMessage, '');
      });
    });

    group('direct construction', () {
      test('can construct with explicit success=true and no error message', () {
        final syncedAt = DateTime.utc(2024, 6, 1);
        final result = SyncResult(
          success: true,
          syncedAt: syncedAt,
          entitiesMerged: 3,
        );

        expect(result.success, isTrue);
        expect(result.errorMessage, isNull);
        expect(result.entitiesMerged, 3);
        expect(result.syncedAt, syncedAt);
      });

      test('can construct with explicit success=false and error message', () {
        final syncedAt = DateTime.utc(2024, 6, 1);
        final result = SyncResult(
          success: false,
          errorMessage: 'Auth failed',
          syncedAt: syncedAt,
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, 'Auth failed');
        expect(result.entitiesMerged, 0);
      });
    });
  });
}
