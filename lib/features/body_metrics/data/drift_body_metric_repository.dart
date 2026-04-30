import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../domain/models/body_metric.dart';
import '../domain/repositories/body_metric_repository.dart';

class DriftBodyMetricRepository implements BodyMetricRepository {
  final db.AppDatabase _db;

  DriftBodyMetricRepository(this._db);

  @override
  Future<BodyMetric> create(BodyMetric metric) async {
    await _db.into(_db.bodyMetrics).insert(
          db.BodyMetricsCompanion.insert(
            id: metric.id,
            date: dateTimeToEpochMs(metric.date),
            weight: metric.weight,
            bodyFatPercent: Value(metric.bodyFatPercent),
            notes: Value(metric.notes),
            updatedAt: Value(dateTimeToEpochMs(metric.updatedAt)),
          ),
        );
    return metric;
  }

  @override
  Future<BodyMetric> update(BodyMetric metric) async {
    await (_db.update(_db.bodyMetrics)..where((t) => t.id.equals(metric.id)))
        .write(
      db.BodyMetricsCompanion(
        date: Value(dateTimeToEpochMs(metric.date)),
        weight: Value(metric.weight),
        bodyFatPercent: Value(metric.bodyFatPercent),
        notes: Value(metric.notes),
        updatedAt: Value(dateTimeToEpochMs(metric.updatedAt)),
        deletedAt: Value(nullableDateTimeToEpochMs(metric.deletedAt)),
      ),
    );
    return metric;
  }

  @override
  Future<void> delete(String id) async {
    final now = dateTimeToEpochMs(DateTime.now().toUtc());
    await (_db.update(_db.bodyMetrics)..where((t) => t.id.equals(id))).write(
      db.BodyMetricsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<List<BodyMetric>> getAll({int limit = 100}) async {
    final q = _db.select(_db.bodyMetrics)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(limit);
    final rows = await q.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<BodyMetric?> getLatest() async {
    final q = _db.select(_db.bodyMetrics)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(1);
    final row = await q.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Stream<List<BodyMetric>> watchAll() {
    final q = _db.select(_db.bodyMetrics)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  BodyMetric _toDomain(db.BodyMetric row) {
    return BodyMetric(
      id: row.id,
      date: dateTimeFromEpochMs(row.date),
      weight: row.weight,
      bodyFatPercent: row.bodyFatPercent,
      notes: row.notes,
      updatedAt: dateTimeFromEpochMs(row.updatedAt),
      deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
    );
  }
}
