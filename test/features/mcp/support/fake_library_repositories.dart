import 'package:rep_foundry/features/body_metrics/domain/models/body_metric.dart';
import 'package:rep_foundry/features/body_metrics/domain/repositories/body_metric_repository.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';
import 'package:rep_foundry/features/programmes/domain/repositories/programme_repository.dart';

/// Read-only body metrics seeded up front; every write throws.
class FakeBodyMetricRepository implements BodyMetricRepository {
  FakeBodyMetricRepository([this.metrics = const []]);

  final List<BodyMetric> metrics;

  @override
  Future<List<BodyMetric>> getAll(
      {required String clientId, int limit = 100}) async {
    final rows = metrics.where((m) => m.clientId == clientId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return rows.take(limit).toList();
  }

  @override
  Future<BodyMetric?> getLatest(String clientId) async =>
      (await getAll(clientId: clientId)).firstOrNull;

  @override
  Stream<List<BodyMetric>> watchAll(String clientId) =>
      Stream.fromFuture(getAll(clientId: clientId));

  @override
  Future<BodyMetric> create(BodyMetric metric) => throw StateError('write');

  @override
  Future<BodyMetric> update(BodyMetric metric) => throw StateError('write');

  @override
  Future<void> delete(String id) => throw StateError('write');
}

/// Read-only programmes seeded up front; every write throws.
class FakeProgrammeRepository implements ProgrammeRepository {
  FakeProgrammeRepository({
    this.programmes = const [],
    this.days = const [],
    this.rules = const [],
  });

  final List<Programme> programmes;
  final List<ProgrammeDay> days;
  final List<ProgressionRule> rules;

  @override
  Future<List<Programme>> getAllProgrammes() async => programmes;

  @override
  Future<Programme?> getProgramme(String id) async =>
      programmes.where((p) => p.id == id).firstOrNull;

  @override
  Stream<List<Programme>> watchAllProgrammes() => Stream.value(programmes);

  @override
  Future<List<ProgrammeDay>> getDaysForProgramme(String programmeId) async =>
      days.where((d) => d.programmeId == programmeId).toList();

  @override
  Future<List<ProgressionRule>> getRulesForProgramme(
          String programmeId) async =>
      rules.where((r) => r.programmeId == programmeId).toList();

  @override
  Future<Programme> createProgramme(Programme programme) =>
      throw StateError('write');
  @override
  Future<Programme> updateProgramme(Programme programme) =>
      throw StateError('write');
  @override
  Future<void> markProgrammeStarted(String programmeId,
          {DateTime? startedAt}) =>
      throw StateError('write');
  @override
  Future<void> deleteProgramme(String id) => throw StateError('write');
  @override
  Future<void> addDay(ProgrammeDay day) => throw StateError('write');
  @override
  Future<void> removeDay(String dayId) => throw StateError('write');
  @override
  Future<void> addRule(ProgressionRule rule) => throw StateError('write');
  @override
  Future<void> removeRule(String ruleId) => throw StateError('write');
}
