import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../../core/providers.dart';
import '../../domain/models/exercise.dart';
import '../helpers/exercise_labels.dart';

class CreateExerciseScreen extends ConsumerStatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  ConsumerState<CreateExerciseScreen> createState() =>
      _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  ExerciseCategory _category = ExerciseCategory.strength;
  MuscleGroup _muscleGroup = MuscleGroup.chest;
  EquipmentType _equipmentType = EquipmentType.barbell;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final exercise = Exercise.create(
      name: _nameController.text.trim(),
      category: _category,
      muscleGroup: _muscleGroup,
      equipmentType: _equipmentType,
      isCustom: true,
    );

    final created =
        await ref.read(exerciseRepositoryProvider).createExercise(exercise);

    if (mounted) {
      Navigator.of(context).pop(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.newExerciseTitle),
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
                  : Text(s.create),
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
