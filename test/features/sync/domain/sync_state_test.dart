import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/sync/domain/models/sync_state.dart';

void main() {
  group('SyncStatus', () {
    test('enum contains idle value', () {
      expect(SyncStatus.values, contains(SyncStatus.idle));
    });

    test('enum contains syncing value', () {
      expect(SyncStatus.values, contains(SyncStatus.syncing));
    });

    test('enum contains success value', () {
      expect(SyncStatus.values, contains(SyncStatus.success));
    });

    test('enum contains error value', () {
      expect(SyncStatus.values, contains(SyncStatus.error));
    });

    test('enum has exactly four values', () {
      expect(SyncStatus.values, hasLength(4));
    });
  });

  group('SyncState', () {
    group('default construction', () {
      test('default status is idle', () {
        const state = SyncState();
        expect(state.status, SyncStatus.idle);
      });

      test('default lastSyncAt is null', () {
        const state = SyncState();
        expect(state.lastSyncAt, isNull);
      });

      test('default errorMessage is null', () {
        const state = SyncState();
        expect(state.errorMessage, isNull);
      });
    });

    group('explicit construction', () {
      test('stores provided status', () {
        const state = SyncState(status: SyncStatus.syncing);
        expect(state.status, SyncStatus.syncing);
      });

      test('stores provided lastSyncAt', () {
        final syncTime = DateTime.utc(2024, 5, 20, 8, 0);
        final state = SyncState(lastSyncAt: syncTime);
        expect(state.lastSyncAt, syncTime);
      });

      test('stores provided errorMessage', () {
        const state = SyncState(
          status: SyncStatus.error,
          errorMessage: 'Connection refused',
        );
        expect(state.errorMessage, 'Connection refused');
      });
    });

    group('copyWith updates status', () {
      test('copyWith updates status to syncing', () {
        const original = SyncState(status: SyncStatus.idle);
        final updated = original.copyWith(status: SyncStatus.syncing);
        expect(updated.status, SyncStatus.syncing);
      });

      test('copyWith updates status to success and preserves other fields', () {
        final lastSync = DateTime.utc(2024, 1, 1);
        final original = SyncState(
          status: SyncStatus.syncing,
          lastSyncAt: lastSync,
        );
        final updated = original.copyWith(status: SyncStatus.success);

        expect(updated.status, SyncStatus.success);
        expect(updated.lastSyncAt, lastSync);
        expect(updated.errorMessage, isNull);
      });

      test('copyWith updates status to error and preserves other fields', () {
        const original = SyncState(status: SyncStatus.idle);
        final updated = original.copyWith(
          status: SyncStatus.error,
          errorMessage: 'Timeout',
        );

        expect(updated.status, SyncStatus.error);
        expect(updated.errorMessage, 'Timeout');
      });
    });

    group('copyWith updates lastSyncAt', () {
      test('copyWith updates lastSyncAt and preserves other fields', () {
        const original = SyncState(status: SyncStatus.success);
        final syncTime = DateTime.utc(2024, 9, 15, 14, 0);
        final updated = original.copyWith(lastSyncAt: syncTime);

        expect(updated.lastSyncAt, syncTime);
        expect(updated.status, SyncStatus.success);
        expect(updated.errorMessage, isNull);
      });
    });

    group('copyWith with clearError flag', () {
      test('clearError=true sets errorMessage to null regardless of other args',
          () {
        const original = SyncState(
          status: SyncStatus.error,
          errorMessage: 'Something failed',
        );
        final updated = original.copyWith(clearError: true);

        expect(updated.errorMessage, isNull);
      });

      test('clearError=true with new errorMessage provided still clears it',
          () {
        // clearError takes precedence over the errorMessage parameter
        const original = SyncState(
          status: SyncStatus.error,
          errorMessage: 'Old error',
        );
        final updated = original.copyWith(
          clearError: true,
          errorMessage: 'New error',
        );

        expect(updated.errorMessage, isNull);
      });

      test('clearError=true preserves status and lastSyncAt', () {
        final lastSync = DateTime.utc(2024, 3, 1);
        final original = SyncState(
          status: SyncStatus.error,
          lastSyncAt: lastSync,
          errorMessage: 'Auth failure',
        );
        final updated = original.copyWith(
          clearError: true,
          status: SyncStatus.idle,
        );

        expect(updated.status, SyncStatus.idle);
        expect(updated.lastSyncAt, lastSync);
        expect(updated.errorMessage, isNull);
      });

      test('clearError=false (default) preserves existing errorMessage', () {
        const original = SyncState(
          status: SyncStatus.error,
          errorMessage: 'Existing error',
        );
        final updated = original.copyWith();

        expect(updated.errorMessage, 'Existing error');
      });

      test('clearError=false with new errorMessage updates it', () {
        const original = SyncState(
          status: SyncStatus.error,
          errorMessage: 'Old error',
        );
        final updated = original.copyWith(errorMessage: 'New error');

        expect(updated.errorMessage, 'New error');
      });
    });

    group('copyWith with no arguments', () {
      test('returns equivalent state', () {
        final lastSync = DateTime.utc(2024, 7, 4);
        final original = SyncState(
          status: SyncStatus.success,
          lastSyncAt: lastSync,
          errorMessage: null,
        );
        final copy = original.copyWith();

        expect(copy.status, original.status);
        expect(copy.lastSyncAt, original.lastSyncAt);
        expect(copy.errorMessage, original.errorMessage);
      });
    });
  });
}
