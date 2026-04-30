import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/body_metrics/data/drift_body_metric_repository.dart';
import 'package:rep_foundry/features/body_metrics/domain/models/body_metric.dart';
import 'package:drift/drift.dart' show Value;

void main() {
  late db.AppDatabase database;
  late DriftBodyMetricRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftBodyMetricRepository(database);
  });

  tearDown(() => database.close());

  BodyMetric newMetric({
    double weight = 80.0,
    DateTime? date,
    double? bodyFatPercent,
    String? notes,
  }) {
    return BodyMetric.create(
      weight: weight,
      date: date,
      bodyFatPercent: bodyFatPercent,
      notes: notes,
    );
  }

  group('DriftBodyMetricRepository', () {
    group('create & getAll', () {
      test('persists and retrieves a metric', () async {
        final metric = newMetric();
        await repo.create(metric);

        final results = await repo.getAll();
        expect(results, hasLength(1));
        expect(results.first.id, metric.id);
        expect(results.first.weight, 80.0);
        expect(results.first.date.isUtc, isTrue);
      });

      test('create returns the metric', () async {
        final metric = newMetric(weight: 75.5);
        final returned = await repo.create(metric);

        expect(returned.id, metric.id);
        expect(returned.weight, 75.5);
      });

      test('persists optional fields', () async {
        final metric = newMetric(
          weight: 82.0,
          bodyFatPercent: 15.5,
          notes: 'Morning weigh-in',
        );
        await repo.create(metric);

        final results = await repo.getAll();
        expect(results.first.bodyFatPercent, 15.5);
        expect(results.first.notes, 'Morning weigh-in');
      });
    });

    group('update', () {
      test('updates weight without changing id', () async {
        final metric = newMetric(weight: 80.0);
        await repo.create(metric);

        final updated = metric.copyWith(weight: 85.0);
        await repo.update(updated);

        final results = await repo.getAll();
        expect(results, hasLength(1));
        expect(results.first.id, metric.id);
        expect(results.first.weight, 85.0);
      });
    });

    group('delete', () {
      test('removes the metric from public reads', () async {
        final metric = newMetric();
        await repo.create(metric);

        await repo.delete(metric.id);

        final results = await repo.getAll();
        expect(results, isEmpty);
      });

      test('soft-deletes: row remains in DB with deletedAt set', () async {
        // The soft-delete must keep the tombstone around so a subsequent
        // sync can propagate the delete. A hard-delete here would silently
        // resurrect the row on the next sync from another device.
        final metric = newMetric();
        await repo.create(metric);

        await repo.delete(metric.id);

        // Query the table directly, bypassing the repo's deletedAt filter.
        final raw = await database.select(database.bodyMetrics).get();
        expect(raw, hasLength(1));
        expect(raw.single.id, metric.id);
        expect(raw.single.deletedAt, isNotNull);
      });

      test('subsequent reads filter the tombstoned row', () async {
        final metric = newMetric();
        await repo.create(metric);
        await repo.delete(metric.id);

        expect(await repo.getAll(), isEmpty);
        expect(await repo.getLatest(), isNull);
      });

      test('manually-tombstoned row (sync-applied) is filtered from reads',
          () async {
        // Simulate a tombstone arriving via cloud sync rather than via
        // repo.delete(): apply a deletedAt directly. Public reads must
        // still hide it.
        final metric = newMetric();
        await repo.create(metric);

        await (database.update(database.bodyMetrics)
              ..where((t) => t.id.equals(metric.id)))
            .write(
          db.BodyMetricsCompanion(
            deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

        expect(await repo.getAll(), isEmpty);
      });
    });

    group('getAll', () {
      test('respects limit parameter', () async {
        for (var i = 0; i < 5; i++) {
          await repo.create(newMetric(
            weight: 80.0 + i,
            date: DateTime.utc(2025, 1, 1 + i),
          ));
        }

        final results = await repo.getAll(limit: 3);
        expect(results, hasLength(3));
      });

      test('orders by date descending', () async {
        final older = newMetric(
          weight: 80.0,
          date: DateTime.utc(2025, 1, 1),
        );
        final newer = newMetric(
          weight: 82.0,
          date: DateTime.utc(2025, 6, 1),
        );
        await repo.create(older);
        await repo.create(newer);

        final results = await repo.getAll();
        expect(results.first.weight, 82.0);
        expect(results.last.weight, 80.0);
      });
    });

    group('getLatest', () {
      test('returns null when no metrics exist', () async {
        final latest = await repo.getLatest();
        expect(latest, isNull);
      });

      test('returns the most recent metric by date', () async {
        await repo.create(newMetric(
          weight: 80.0,
          date: DateTime.utc(2025, 1, 1),
        ));
        await repo.create(newMetric(
          weight: 82.0,
          date: DateTime.utc(2025, 6, 1),
        ));

        final latest = await repo.getLatest();
        expect(latest, isNotNull);
        expect(latest!.weight, 82.0);
      });
    });

    group('watchAll', () {
      test('emits when a metric is created', () async {
        final emissions = <List<BodyMetric>>[];
        final sub = repo.watchAll().listen(emissions.add);
        addTearDown(sub.cancel);

        await pumpEventQueue();
        expect(emissions, hasLength(1));
        expect(emissions.first, isEmpty);

        await repo.create(newMetric());
        await pumpEventQueue();

        expect(emissions.last, hasLength(1));
      });

      test('emits when a metric is deleted', () async {
        final metric = newMetric();
        await repo.create(metric);

        final emissions = <List<BodyMetric>>[];
        final sub = repo.watchAll().listen(emissions.add);
        addTearDown(sub.cancel);

        await pumpEventQueue();
        expect(emissions.last, hasLength(1));

        await repo.delete(metric.id);
        await pumpEventQueue();

        expect(emissions.last, isEmpty);
      });
    });
  });
}
