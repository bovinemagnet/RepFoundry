import '../models/body_metric.dart';

abstract class BodyMetricRepository {
  Future<BodyMetric> create(BodyMetric metric);
  Future<BodyMetric> update(BodyMetric metric);
  Future<void> delete(String id);
  Future<List<BodyMetric>> getAll({required String clientId, int limit = 100});
  Future<BodyMetric?> getLatest(String clientId);
  Stream<List<BodyMetric>> watchAll(String clientId);
}
