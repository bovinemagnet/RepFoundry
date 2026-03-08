import 'package:flutter/material.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../models/ghost_set.dart';

/// A card widget for entering a new set's weight and reps.
class SetInputCard extends StatefulWidget {
  const SetInputCard({super.key, required this.onLogSet, this.suggestion});

  final void Function({
    required double weight,
    required int reps,
    double? rpe,
    bool isWarmUp,
  }) onLogSet;

  final GhostSet? suggestion;

  @override
  State<SetInputCard> createState() => _SetInputCardState();
}

class _SetInputCardState extends State<SetInputCard> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  final _rpeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showRpe = false;
  bool _isWarmUp = false;

  @override
  void initState() {
    super.initState();
    final s = widget.suggestion;
    _weightController = TextEditingController(
      text: s != null ? _formatWeight(s.weight) : '0',
    );
    _repsController = TextEditingController(
      text: s != null ? '${s.reps}' : '0',
    );
    if (s?.rpe != null) {
      _rpeController.text = _formatWeight(s!.rpe!);
      _showRpe = true;
    }
  }

  @override
  void didUpdateWidget(covariant SetInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suggestion != oldWidget.suggestion) {
      final s = widget.suggestion;
      _weightController.text = s != null ? _formatWeight(s.weight) : '0';
      _repsController.text = s != null ? '${s.reps}' : '0';
      if (s?.rpe != null) {
        _rpeController.text = _formatWeight(s!.rpe!);
        if (!_showRpe) setState(() => _showRpe = true);
      }
    }
  }

  String _formatWeight(double value) {
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
    final rpe = _showRpe ? double.tryParse(_rpeController.text) : null;

    widget.onLogSet(weight: weight, reps: reps, rpe: rpe, isWarmUp: _isWarmUp);

    _repsController.text = '0';
    _rpeController.clear();
    if (_isWarmUp) setState(() => _isWarmUp = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
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
                  label: s.weightKgLabel,
                  isDouble: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  controller: _repsController,
                  label: s.repsLabel,
                  isDouble: false,
                ),
              ),
              if (_showRpe) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: _NumberField(
                    controller: _rpeController,
                    label: s.rpeLabel,
                    isDouble: true,
                    isRequired: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final d = double.tryParse(value);
                      if (d == null || d < 1 || d > 10) {
                        return s.validationRpeRange;
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
                label: Text(_showRpe ? s.hideRpe : s.addRpe),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              FilterChip(
                label: Text(s.warmUpLabel),
                selected: _isWarmUp,
                onSelected: (v) => setState(() => _isWarmUp = v),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add, size: 18),
                label: Text(s.logSet),
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
    final s = S.of(context)!;
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
            if (value == null || value.isEmpty) return s.validationRequired;
            final n = isDouble
                ? double.tryParse(value)
                : int.tryParse(value)?.toDouble();
            if (n == null) return s.validationInvalid;
            if (isRequired && n < 0) return s.validationMinZero;
            return null;
          },
    );
  }
}
