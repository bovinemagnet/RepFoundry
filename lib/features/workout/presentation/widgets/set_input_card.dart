import 'package:flutter/material.dart';

/// A card widget for entering a new set's weight and reps.
class SetInputCard extends StatefulWidget {
  const SetInputCard({super.key, required this.onLogSet});

  final void Function({
    required double weight,
    required int reps,
    double? rpe,
  }) onLogSet;

  @override
  State<SetInputCard> createState() => _SetInputCardState();
}

class _SetInputCardState extends State<SetInputCard> {
  final _weightController = TextEditingController(text: '0');
  final _repsController = TextEditingController(text: '0');
  final _rpeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showRpe = false;

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
    final rpe = _showRpe ? double.tryParse(_rpeController.text) : null;

    widget.onLogSet(weight: weight, reps: reps, rpe: rpe);

    _repsController.text = '0';
    _rpeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: _weightController,
                  label: 'Weight (kg)',
                  isDouble: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  controller: _repsController,
                  label: 'Reps',
                  isDouble: false,
                ),
              ),
              if (_showRpe) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: _NumberField(
                    controller: _rpeController,
                    label: 'RPE',
                    isDouble: true,
                    isRequired: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final d = double.tryParse(value);
                      if (d == null || d < 1 || d > 10) {
                        return '1–10';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _showRpe = !_showRpe),
                icon: Icon(
                  _showRpe ? Icons.remove : Icons.add,
                  size: 16,
                ),
                label: Text(_showRpe ? 'Hide RPE' : 'Add RPE'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Set'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.isDouble,
    this.isRequired = true,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool isDouble;
  final bool isRequired;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
      textAlign: TextAlign.center,
      validator: validator ??
          (value) {
            if (!isRequired && (value == null || value.isEmpty)) return null;
            if (value == null || value.isEmpty) return 'Required';
            final n = isDouble
                ? double.tryParse(value)
                : int.tryParse(value)?.toDouble();
            if (n == null) return 'Invalid';
            if (isRequired && n < 0) return '≥ 0';
            return null;
          },
    );
  }
}
