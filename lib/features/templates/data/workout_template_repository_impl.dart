import 'dart:async';

import '../domain/models/workout_template.dart';
import '../domain/repositories/workout_template_repository.dart';

/// In-memory implementation for use-case tests.
class InMemoryWorkoutTemplateRepository implements WorkoutTemplateRepository {
  final List<WorkoutTemplate> _templates = [];
  final _controller = StreamController<void>.broadcast();

  @override
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    _templates.add(template);
    _controller.add(null);
    return template;
  }

  @override
  Future<WorkoutTemplate?> getTemplate(String id) async {
    return _templates.where((t) => t.id == id).firstOrNull;
  }

  @override
  Future<List<WorkoutTemplate>> getAllTemplates() async {
    return List.unmodifiable(_templates);
  }

  @override
  Future<WorkoutTemplate> updateTemplate(WorkoutTemplate template) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _templates[index] = template;
    }
    _controller.add(null);
    return template;
  }

  @override
  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    _controller.add(null);
  }

  @override
  Stream<List<WorkoutTemplate>> watchAllTemplates() {
    return _controller.stream.map((_) => List.unmodifiable(_templates));
  }
}
