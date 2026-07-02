import 'package:flutter/material.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';
import 'package:rep_foundry/core/units/weight_unit_provider.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../domain/models/workout_set.dart';

/// Shows a dialog to edit an existing [WorkoutSet].
/// Returns the updated set (weight always in kg), or `null` if cancelled.
Future<WorkoutSet?> showEditSetDialog(
  BuildContext context,
  WorkoutSet existingSet, {
  WeightUnit unit = WeightUnit.kg,
}) {
  return showDialog<WorkoutSet>(
    context: context,
    builder: (ctx) => _EditSetDialog(existingSet: existingSet, unit: unit),
  );
}

class _EditSetDialog extends StatefulWidget {
  const _EditSetDialog({required this.existingSet, required this.unit});

  final WorkoutSet existingSet;
  final WeightUnit unit;

  @override
  State<_EditSetDialog> createState() => _EditSetDialogState();
}

class _EditSetDialogState extends State<_EditSetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _rpeController;
  late final String _initialWeightText;

  @override
  void initState() {
    super.initState();
    _initialWeightText = widget.unit.formatFromKg(widget.existingSet.weight);
    _weightController = TextEditingController(text: _initialWeightText);
    _repsController = TextEditingController(text: '${widget.existingSet.reps}');
    _rpeController = TextEditingController(
      text: widget.existingSet.rpe != null
          ? _formatNum(widget.existingSet.rpe!)
          : '',
    );
  }

  String _formatNum(double value) {
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _rpeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Keep the stored kg weight untouched when the field was not edited, so
    // repeated open/save cycles in lbs cannot drift the value via rounding.
    final weightText = _weightController.text;
    final weight = weightText == _initialWeightText
        ? widget.existingSet.weight
        : widget.unit.toKg(double.tryParse(weightText) ?? 0);
    final reps = int.tryParse(_repsController.text) ?? 0;
    final rpeText = _rpeController.text.trim();
    final rpe = rpeText.isEmpty ? null : double.tryParse(rpeText);

    final updated = widget.existingSet.copyWith(
      weight: weight,
      reps: reps,
      rpe: rpe,
      updatedAt: DateTime.now().toUtc(),
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return AlertDialog(
      title: Text(s.editSet),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: s.weightFieldLabel(widget.unit.label(s)),
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return s.validationRequired;
                final n = double.tryParse(value);
                if (n == null) return s.validationInvalid;
                if (n < 0) return s.validationMinZero;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _repsController,
              decoration: InputDecoration(
                labelText: s.repsLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return s.validationRequired;
                final n = int.tryParse(value);
                if (n == null || n <= 0) return s.validationInvalid;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rpeController,
              decoration: InputDecoration(
                labelText: s.rpeLabel,
                border: const OutlineInputBorder(),
                hintText: '1–10',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final d = double.tryParse(value);
                if (d == null || d < 1 || d > 10) return s.validationRpeRange;
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(s.save),
        ),
      ],
    );
  }
}
