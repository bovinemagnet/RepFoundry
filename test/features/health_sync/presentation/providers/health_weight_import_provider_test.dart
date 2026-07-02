import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/body_metrics/domain/models/body_metric.dart';
import 'package:rep_foundry/features/body_metrics/domain/repositories/body_metric_repository.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_weight_import_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubHealthSyncService extends HealthSyncService {
  _StubHealthSyncService({this.sample, this.shouldThrow = false});

  final WeightSample? sample;
  final bool shouldThrow;
  int callCount = 0;

  @override
  Future<WeightSample?> readLatestWeight() async {
    callCount++;
    if (shouldThrow) throw Exception('boom');
    return sample;
  }
}

class _StubBodyMetricRepository implements BodyMetricRepository {
  _StubBodyMetricRepository({this.latest});

  final BodyMetric? latest;

  @override
  Future<BodyMetric?> getLatest() async => latest;

  @override
  Future<BodyMetric> create(BodyMetric metric) async => metric;

  @override
  Future<BodyMetric> update(BodyMetric metric) async => metric;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<BodyMetric>> getAll({int limit = 100}) async =>
      [if (latest != null) latest!];

  @override
  Stream<List<BodyMetric>> watchAll() =>
      Stream.value([if (latest != null) latest!]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WeightSample sample({double kg = 82.5, DateTime? date}) =>
      (weightKg: kg, date: date ?? DateTime.utc(2026, 6, 30));

  ProviderContainer makeContainer(
    _StubHealthSyncService stub, {
    BodyMetric? latestMetric,
  }) {
    final container = ProviderContainer(
      overrides: [
        healthSyncServiceProvider.overrideWithValue(stub),
        bodyMetricRepositoryProvider
            .overrideWithValue(_StubBodyMetricRepository(latest: latestMetric)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('healthWeightCheckProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns null when health sync is disabled', () async {
      final stub = _StubHealthSyncService(sample: sample());
      final container = makeContainer(stub);

      final result = await container.read(healthWeightCheckProvider.future);
      expect(result, isNull);
      expect(stub.callCount, 0);
    });

    test('returns null when readWeight is disabled', () async {
      SharedPreferences.setMockInitialValues({
        'health_sync_enabled': true,
        'health_sync_read_weight': false,
      });
      final stub = _StubHealthSyncService(sample: sample());
      final container = makeContainer(stub);

      // Wait for settings _load() to apply.
      container.read(healthSyncSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = await container.read(healthWeightCheckProvider.future);
      expect(result, isNull);
      expect(stub.callCount, 0);
    });

    test('returns the sample when sync is enabled and readWeight is on',
        () async {
      SharedPreferences.setMockInitialValues({
        'health_sync_enabled': true,
        'health_sync_read_weight': true,
      });
      final stub = _StubHealthSyncService(sample: sample());
      final container = makeContainer(stub);

      container.read(healthSyncSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = await container.read(healthWeightCheckProvider.future);
      expect(result?.weightKg, 82.5);
      expect(stub.callCount, 1);
    });

    test('returns null when the sample is not newer than the latest metric',
        () async {
      SharedPreferences.setMockInitialValues({
        'health_sync_enabled': true,
        'health_sync_read_weight': true,
      });
      final sampleDate = DateTime.utc(2026, 6, 30);
      final stub = _StubHealthSyncService(sample: sample(date: sampleDate));
      final container = makeContainer(
        stub,
        // Already imported: metric recorded with the sample's own date.
        latestMetric: BodyMetric.create(weight: 82.5, date: sampleDate),
      );

      container.read(healthSyncSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = await container.read(healthWeightCheckProvider.future);
      expect(result, isNull);
    });

    test('swallows service errors and returns null', () async {
      SharedPreferences.setMockInitialValues({
        'health_sync_enabled': true,
        'health_sync_read_weight': true,
      });
      final stub = _StubHealthSyncService(shouldThrow: true);
      final container = makeContainer(stub);

      container.read(healthSyncSettingsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final result = await container.read(healthWeightCheckProvider.future);
      expect(result, isNull);
      expect(stub.callCount, 1);
    });
  });
}
