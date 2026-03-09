import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../domain/models/workout_template.dart';
import '../../../../core/providers.dart';

class TemplateEditScreen extends ConsumerStatefulWidget {
  const TemplateEditScreen({super.key, required this.templateId});

  final String templateId;

  @override
  ConsumerState<TemplateEditScreen> createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends ConsumerState<TemplateEditScreen> {
  late final TextEditingController _nameController;
  WorkoutTemplate? _template;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final repo = ref.read(workoutTemplateRepositoryProvider);
    final template = await repo.getTemplate(widget.templateId);
    if (mounted) {
      setState(() {
        _template = template;
        _nameController.text = template?.name ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    final template = _template;
    if (template == null) return;

    final updated = template.copyWith(
      name: _nameController.text.trim(),
      updatedAt: DateTime.now().toUtc(),
    );

    await ref.read(workoutTemplateRepositoryProvider).updateTemplate(updated);

    if (mounted) {
      final s = S.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.templateSaved)),
      );
      context.pop();
    }
  }

  Future<void> _addExercise() async {
    final exercise = await context.push<Exercise>('/exercises');
    if (exercise == null || !mounted) return;

    final template = _template;
    if (template == null) return;

    final newExercise = TemplateExercise(
      id: const Uuid().v4(),
      templateId: template.id,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      targetSets: 3,
      targetReps: 10,
      orderIndex: template.exercises.length,
      updatedAt: DateTime.now().toUtc(),
    );

    setState(() {
      _template = template.copyWith(
        exercises: [...template.exercises, newExercise],
      );
    });
  }

  void _removeExercise(int index) {
    final template = _template;
    if (template == null) return;

    final updatedExercises = List<TemplateExercise>.from(template.exercises)
      ..removeAt(index);

    // Re-index
    final reindexed = [
      for (var i = 0; i < updatedExercises.length; i++)
        TemplateExercise(
          id: updatedExercises[i].id,
          templateId: updatedExercises[i].templateId,
          exerciseId: updatedExercises[i].exerciseId,
          exerciseName: updatedExercises[i].exerciseName,
          targetSets: updatedExercises[i].targetSets,
          targetReps: updatedExercises[i].targetReps,
          orderIndex: i,
          updatedAt: DateTime.now().toUtc(),
        ),
    ];

    setState(() {
      _template = template.copyWith(exercises: reindexed);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    final template = _template;
    if (template == null) return;

    final exercises = List<TemplateExercise>.from(template.exercises);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, item);

    // Re-index
    final reindexed = [
      for (var i = 0; i < exercises.length; i++)
        TemplateExercise(
          id: exercises[i].id,
          templateId: exercises[i].templateId,
          exerciseId: exercises[i].exerciseId,
          exerciseName: exercises[i].exerciseName,
          targetSets: exercises[i].targetSets,
          targetReps: exercises[i].targetReps,
          orderIndex: i,
          updatedAt: DateTime.now().toUtc(),
        ),
    ];

    setState(() {
      _template = template.copyWith(exercises: reindexed);
    });
  }

  void _updateExercise(int index, {int? targetSets, int? targetReps}) {
    final template = _template;
    if (template == null) return;

    final exercises = List<TemplateExercise>.from(template.exercises);
    final current = exercises[index];
    exercises[index] = TemplateExercise(
      id: current.id,
      templateId: current.templateId,
      exerciseId: current.exerciseId,
      exerciseName: current.exerciseName,
      targetSets: targetSets ?? current.targetSets,
      targetReps: targetReps ?? current.targetReps,
      orderIndex: current.orderIndex,
      updatedAt: DateTime.now().toUtc(),
    );

    setState(() {
      _template = template.copyWith(exercises: exercises);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(s.editTemplate)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final template = _template;
    if (template == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.editTemplate)),
        body: const Center(child: Icon(Icons.error_outline, size: 48)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.editTemplate),
        actions: [
          TextButton(
            onPressed: _saveTemplate,
            child: Text(s.saveTemplate),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: s.templateNameLabel,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          if (template.exercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                s.reorderHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          Expanded(
            child: template.exercises.isEmpty
                ? Center(
                    child: Text(
                      s.addExerciseToTemplate,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: template.exercises.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final exercise = template.exercises[index];
                      return _TemplateExerciseTile(
                        key: ValueKey(exercise.id),
                        exercise: exercise,
                        index: index,
                        onTargetSetsChanged: (value) =>
                            _updateExercise(index, targetSets: value),
                        onTargetRepsChanged: (value) =>
                            _updateExercise(index, targetReps: value),
                        onDelete: () => _removeExercise(index),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExercise,
        icon: const Icon(Icons.add),
        label: Text(s.addExerciseToTemplate),
      ),
    );
  }
}

class _TemplateExerciseTile extends StatelessWidget {
  const _TemplateExerciseTile({
    super.key,
    required this.exercise,
    required this.index,
    required this.onTargetSetsChanged,
    required this.onTargetRepsChanged,
    required this.onDelete,
  });

  final TemplateExercise exercise;
  final int index;
  final ValueChanged<int> onTargetSetsChanged;
  final ValueChanged<int> onTargetRepsChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.exerciseName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: s.targetSets,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                            text: exercise.targetSets.toString(),
                          ),
                          onChanged: (value) {
                            final parsed = int.tryParse(value);
                            if (parsed != null && parsed > 0) {
                              onTargetSetsChanged(parsed);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 72,
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: s.targetReps,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                            text: exercise.targetReps.toString(),
                          ),
                          onChanged: (value) {
                            final parsed = int.tryParse(value);
                            if (parsed != null && parsed > 0) {
                              onTargetRepsChanged(parsed);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: s.removeExercise,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
