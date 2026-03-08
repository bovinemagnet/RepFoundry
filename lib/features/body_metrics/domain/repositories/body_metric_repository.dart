import '../models/body_metric.dart';

abstract class BodyMetricRepository {
  Future<BodyMetric> create(BodyMetric metric);
  Future<BodyMetric> update(BodyMetric metric);
  Future<void> delete(String id);
  Future<List<BodyMetric>> getAll({int limit = 100});
  Future<BodyMetric?> getLatest();
  Stream<List<BodyMetric>> watchAll();
}
