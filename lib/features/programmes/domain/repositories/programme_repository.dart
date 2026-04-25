import '../models/programme.dart';

abstract class ProgrammeRepository {
  Future<Programme> createProgramme(Programme programme);
  Future<Programme?> getProgramme(String id);
  Future<List<Programme>> getAllProgrammes();
  Future<Programme> updateProgramme(Programme programme);

  /// Marks [programmeId] as started at [startedAt] (defaults to now). Used
  /// to anchor the per-week template lookup in the active workout controller.
  Future<void> markProgrammeStarted(String programmeId, {DateTime? startedAt});

  Future<void> deleteProgramme(String id);
  Stream<List<Programme>> watchAllProgrammes();

  Future<void> addDay(ProgrammeDay day);
  Future<void> removeDay(String dayId);
  Future<List<ProgrammeDay>> getDaysForProgramme(String programmeId);

  Future<void> addRule(ProgressionRule rule);
  Future<void> removeRule(String ruleId);
  Future<List<ProgressionRule>> getRulesForProgramme(String programmeId);
}
