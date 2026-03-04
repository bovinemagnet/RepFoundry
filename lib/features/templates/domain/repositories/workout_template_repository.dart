import '../models/workout_template.dart';

abstract class WorkoutTemplateRepository {
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template);
  Future<WorkoutTemplate?> getTemplate(String id);
  Future<List<WorkoutTemplate>> getAllTemplates();
  Future<WorkoutTemplate> updateTemplate(WorkoutTemplate template);
  Future<void> deleteTemplate(String id);

  Stream<List<WorkoutTemplate>> watchAllTemplates();
}
