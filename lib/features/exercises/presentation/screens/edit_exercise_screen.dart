import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../../core/providers.dart';
import '../../domain/models/exercise.dart';
import '../helpers/exercise_labels.dart';

class EditExerciseScreen extends ConsumerStatefulWidget {
  const EditExerciseScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  ConsumerState<EditExerciseScreen> createState() => _EditExerciseScreenState();
}

class _EditExerciseScreenState extends ConsumerState<EditExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late ExerciseCategory _category;
  late MuscleGroup _muscleGroup;
  late EquipmentType _equipmentType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise.name);
    _category = widget.exercise.category;
    _muscleGroup = widget.exercise.muscleGroup;
    _equipmentType = widget.exercise.equipmentType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final updated = widget.exercise.copyWith(
      name: _nameController.text.trim(),
      category: _category,
      muscleGroup: _muscleGroup,
      equipmentType: _equipmentType,
    );

    await ref.read(exerciseRepositoryProvider).updateExercise(updated);

    if (mounted) {
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.editExerciseTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.save),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: s.exerciseNameLabel,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return s.exerciseNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExerciseCategory>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: s.categoryLabel,
                border: const OutlineInputBorder(),
              ),
              items: ExerciseCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(labelForCategory(c)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MuscleGroup>(
              initialValue: _muscleGroup,
              decoration: InputDecoration(
                labelText: s.muscleGroupLabel,
                border: const OutlineInputBorder(),
              ),
              items: MuscleGroup.values
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(labelForMuscleGroup(g)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _muscleGroup = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EquipmentType>(
              initialValue: _equipmentType,
              decoration: InputDecoration(
                labelText: s.equipmentLabel,
                border: const OutlineInputBorder(),
              ),
              items: EquipmentType.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(labelForEquipment(e)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _equipmentType = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
