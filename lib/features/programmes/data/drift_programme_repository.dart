import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../domain/models/programme.dart';
import '../domain/repositories/programme_repository.dart';

class DriftProgrammeRepository implements ProgrammeRepository {
  final db.AppDatabase _db;

  DriftProgrammeRepository(this._db);

  @override
  Future<Programme> createProgramme(Programme programme) async {
    await _db.into(_db.programmes).insert(
          db.ProgrammesCompanion.insert(
            id: programme.id,
            name: programme.name,
            durationWeeks: programme.durationWeeks,
            createdAt: dateTimeToEpochMs(programme.createdAt),
            updatedAt: dateTimeToEpochMs(programme.updatedAt),
          ),
        );
    return programme;
  }

  @override
  Future<Programme?> getProgramme(String id) async {
    final q = _db.select(_db.programmes)..where((t) => t.id.equals(id));
    final row = await q.getSingleOrNull();
    if (row == null) return null;

    final days = await _getDaysForProgrammeRow(id);
    final rules = await _getRulesForProgrammeRow(id);
    return _toDomain(row, days, rules);
  }

  @override
  Future<List<Programme>> getAllProgrammes() async {
    final q = _db.select(_db.programmes)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await q.get();
    return Future.wait(rows.map((row) async {
      final days = await _getDaysForProgrammeRow(row.id);
      final rules = await _getRulesForProgrammeRow(row.id);
      return _toDomain(row, days, rules);
    }));
  }

  @override
  Future<Programme> updateProgramme(Programme programme) async {
    await (_db.update(_db.programmes)
          ..where((t) => t.id.equals(programme.id)))
        .write(
      db.ProgrammesCompanion(
        name: Value(programme.name),
        durationWeeks: Value(programme.durationWeeks),
        updatedAt: Value(dateTimeToEpochMs(programme.updatedAt)),
      ),
    );
    return programme;
  }

  @override
  Future<void> deleteProgramme(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.programmeDays)
            ..where((t) => t.programmeId.equals(id)))
          .go();
      await (_db.delete(_db.progressionRules)
            ..where((t) => t.programmeId.equals(id)))
          .go();
      await (_db.delete(_db.programmes)..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Stream<List<Programme>> watchAllProgrammes() {
    final q = _db.select(_db.programmes)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch().asyncMap((rows) async {
      return Future.wait(rows.map((row) async {
        final days = await _getDaysForProgrammeRow(row.id);
        final rules = await _getRulesForProgrammeRow(row.id);
        return _toDomain(row, days, rules);
      }));
    });
  }

  @override
  Future<void> addDay(ProgrammeDay day) async {
    await _db.into(_db.programmeDays).insert(
          db.ProgrammeDaysCompanion.insert(
            id: day.id,
            programmeId: day.programmeId,
            weekNumber: day.weekNumber,
            dayOfWeek: day.dayOfWeek,
            templateId: day.templateId,
            templateName: day.templateName,
          ),
        );
  }

  @override
  Future<void> removeDay(String dayId) async {
    await (_db.delete(_db.programmeDays)..where((t) => t.id.equals(dayId)))
        .go();
  }

  @override
  Future<List<ProgrammeDay>> getDaysForProgramme(String programmeId) async {
    return _getDaysForProgrammeRow(programmeId);
  }

  @override
  Future<void> addRule(ProgressionRule rule) async {
    await _db.into(_db.progressionRules).insert(
          db.ProgressionRulesCompanion.insert(
            id: rule.id,
            programmeId: rule.programmeId,
            exerciseId: rule.exerciseId,
            type: rule.type.name,
            value: rule.value,
            frequencyWeeks: Value(rule.frequencyWeeks),
          ),
        );
  }

  @override
  Future<void> removeRule(String ruleId) async {
    await (_db.delete(_db.progressionRules)..where((t) => t.id.equals(ruleId)))
        .go();
  }

  @override
  Future<List<ProgressionRule>> getRulesForProgramme(
    String programmeId,
  ) async {
    return _getRulesForProgrammeRow(programmeId);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<List<ProgrammeDay>> _getDaysForProgrammeRow(
    String programmeId,
  ) async {
    final q = _db.select(_db.programmeDays)
      ..where((t) => t.programmeId.equals(programmeId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.weekNumber),
        (t) => OrderingTerm.asc(t.dayOfWeek),
      ]);
    final rows = await q.get();
    return rows.map(_dayToDomain).toList();
  }

  Future<List<ProgressionRule>> _getRulesForProgrammeRow(
    String programmeId,
  ) async {
    final q = _db.select(_db.progressionRules)
      ..where((t) => t.programmeId.equals(programmeId));
    final rows = await q.get();
    return rows.map(_ruleToDomain).toList();
  }

  Programme _toDomain(
    db.Programme row,
    List<ProgrammeDay> days,
    List<ProgressionRule> rules,
  ) {
    return Programme(
      id: row.id,
      name: row.name,
      durationWeeks: row.durationWeeks,
      createdAt: dateTimeFromEpochMs(row.createdAt),
      updatedAt: dateTimeFromEpochMs(row.updatedAt),
      days: days,
      rules: rules,
    );
  }

  ProgrammeDay _dayToDomain(db.ProgrammeDay row) {
    return ProgrammeDay(
      id: row.id,
      programmeId: row.programmeId,
      weekNumber: row.weekNumber,
      dayOfWeek: row.dayOfWeek,
      templateId: row.templateId,
      templateName: row.templateName,
    );
  }

  ProgressionRule _ruleToDomain(db.ProgressionRule row) {
    return ProgressionRule(
      id: row.id,
      programmeId: row.programmeId,
      exerciseId: row.exerciseId,
      type: ProgressionType.values.byName(row.type),
      value: row.value,
      frequencyWeeks: row.frequencyWeeks,
    );
  }
}
