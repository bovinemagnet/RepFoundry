import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_weight_import_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubHealthSyncService extends HealthSyncService {
  _StubHealthSyncService({this.weight, this.shouldThrow = false});

  final double? weight;
  final bool shouldThrow;
  int callCount = 0;

  @override
  Future<double?> readLatestWeight() async {
    callCount++;
    if (shouldThrow) throw Exception('boom');
    return weight;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('healthWeightCheckProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns null when health sync is disabled', () async {
      final stub = _StubHealthSyncService(weight: 82.5);
      final container = ProviderContainer(
        overrides: [
          healthSyncServiceProvider.overrideWithValue(stub),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(healthWeightCheckProvider.future);
      expect(result, isNull);
      expect(stub.callCount, 0);
    });

    test('returns null when readWeight is disabled', () async {
      SharedPreferences.setMockInitialValues({
        'health_sync_enabled': true,
        'health_sync_read_weight': false,
      });
      final stub = _StubHealthSyncService(weight: 82.5);
      final container = ProviderContainer(
        overrides: [
          healthSyncServiceProvider.overrideWithValue(stub),
        ],
      );
      addTearDown(container.dispose);

      // Wait for settings _load() to apply.
      container.read(healthSyncSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = await container.read(healthWeightCheckProvider.future);
      expect(result, isNull);
      expect(stub.callCount, 0);
    });

    test('returns weight when sync is enabled and readWeight is on', () async {
      SharedPreferences.setMockInitialValues({
        'health_sync_enabled': true,
        'health_sync_read_weight': true,
      });
      final stub = _StubHealthSyncService(weight: 82.5);
      final container = ProviderContainer(
        overrides: [
          healthSyncServiceProvider.overrideWithValue(stub),
        ],
      );
      addTearDown(container.dispose);

      container.read(healthSyncSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = await container.read(healthWeightCheckProvider.future);
      expect(result, 82.5);
      expect(stub.callCount, 1);
    });

    test('swallows service errors and returns null', () async {
      SharedPreferences.setMockInitialValues({
        'health_sync_enabled': true,
        'health_sync_read_weight': true,
      });
      final stub = _StubHealthSyncService(shouldThrow: true);
      final container = ProviderContainer(
        overrides: [
          healthSyncServiceProvider.overrideWithValue(stub),
        ],
      );
      addTearDown(container.dispose);

      container.read(healthSyncSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = await container.read(healthWeightCheckProvider.future);
      expect(result, isNull);
      expect(stub.callCount, 1);
    });
  });
}
