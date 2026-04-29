import 'package:flutter/material.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../domain/models/workout_set.dart';

/// Shows a dialog to edit an existing [WorkoutSet].
/// Returns the updated set, or `null` if cancelled.
Future<WorkoutSet?> showEditSetDialog(
  BuildContext context,
  WorkoutSet existingSet,
) {
  return showDialog<WorkoutSet>(
    context: context,
    builder: (ctx) => _EditSetDialog(existingSet: existingSet),
  );
}

class _EditSetDialog extends StatefulWidget {
  const _EditSetDialog({required this.existingSet});

  final WorkoutSet existingSet;

  @override
  State<_EditSetDialog> createState() => _EditSetDialogState();
}

class _EditSetDialogState extends State<_EditSetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _rpeController;

  @override
  void initState() {
    super.initState();
    _weightController =
        TextEditingController(text: _formatNum(widget.existingSet.weight));
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

    final weight = double.tryParse(_weightController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    final rpeText = _rpeController.text.trim();
    final rpe = rpeText.isEmpty ? null : double.tryParse(rpeText);

    final updated = widget.existingSet.copyWith(
      weight: weight,
      reps: reps,
      rpe: rpe,
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
                labelText: s.weightKgLabel,
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
