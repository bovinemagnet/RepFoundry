import 'package:flutter/material.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';
import 'package:rep_foundry/core/units/weight_unit_provider.dart';
import 'package:rep_foundry/core/widgets/kinetic.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../models/ghost_set.dart';

/// A card widget for entering a new set's weight and reps.
///
/// Styled to the "Kinetic Green" redesign: `.fieldrow` / `.field` /
/// `.field--focus` tiles from rf.css, with the Kinetic action row below.
class SetInputCard extends StatefulWidget {
  const SetInputCard({
    super.key,
    required this.onLogSet,
    this.suggestion,
    this.autofocusWeight = false,
    this.unit = WeightUnit.kg,
  });

  final void Function({
    required double weight,
    required int reps,
    double? rpe,
    bool isWarmUp,
  }) onLogSet;

  final GhostSet? suggestion;

  /// When true, the Weight field grabs keyboard focus on first build.
  /// Used so a freshly added exercise becomes the active input target
  /// instead of leaving focus on the previously edited exercise.
  final bool autofocusWeight;

  /// Display unit for the Weight field. The value passed to [onLogSet]
  /// is always kg, whatever the display unit.
  final WeightUnit unit;

  @override
  State<SetInputCard> createState() => _SetInputCardState();
}

class _SetInputCardState extends State<SetInputCard> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  final _rpeController = TextEditingController();
  final _weightFocusNode = FocusNode();
  final _repsFocusNode = FocusNode();
  final _rpeFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _showRpe = false;
  bool _isWarmUp = false;

  // Tracked locally so the field tiles can react to focus changes.
  bool _weightFocused = false;
  bool _repsFocused = false;
  bool _rpeFocused = false;

  @override
  void initState() {
    super.initState();
    final s = widget.suggestion;
    _weightController = TextEditingController(
      text: s != null ? widget.unit.formatFromKg(s.weight) : '0',
    );
    _repsController = TextEditingController(
      text: s != null ? '${s.reps}' : '0',
    );
    if (s?.rpe != null) {
      _rpeController.text = _formatWeight(s!.rpe!);
      _showRpe = true;
    }

    _weightFocusNode.addListener(_onFocusChange);
    _repsFocusNode.addListener(_onFocusChange);
    _rpeFocusNode.addListener(_onFocusChange);

    if (widget.autofocusWeight) {
      // Defer until after the picker route's pop transition completes
      // (~300 ms Material route default); requesting earlier loses the
      // focus race against the route transition and the keyboard never
      // appears.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          _weightFocusNode.requestFocus();
          // Select all text so the user can immediately overwrite the
          // pre-filled ghost-set value (or the default "0").
          _weightController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _weightController.text.length,
          );
        });
      });
    }
  }

  void _onFocusChange() {
    setState(() {
      _weightFocused = _weightFocusNode.hasFocus;
      _repsFocused = _repsFocusNode.hasFocus;
      _rpeFocused = _rpeFocusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(covariant SetInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suggestion != oldWidget.suggestion) {
      final s = widget.suggestion;
      _weightController.text =
          s != null ? widget.unit.formatFromKg(s.weight) : '0';
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
    _weightFocusNode.dispose();
    _repsFocusNode.dispose();
    _rpeFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final weight =
        widget.unit.toKg(double.tryParse(_weightController.text) ?? 0);
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
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Field row: Weight / Reps (/ optional RPE) ──────────────
          // Mirrors rf.css `.fieldrow` — a 2-col (or 3-col) grid of
          // `.field` tiles; the focused tile gets a 1.5px accent inset ring.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _KineticField(
                  controller: _weightController,
                  focusNode: _weightFocusNode,
                  label: s.weightFieldLabel(widget.unit.label(s)),
                  isDouble: true,
                  isFocused: _weightFocused,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KineticField(
                  controller: _repsController,
                  focusNode: _repsFocusNode,
                  label: s.repsLabel,
                  isDouble: false,
                  isFocused: _repsFocused,
                  // Domain rule: reps > 0. Surface it inline instead of
                  // letting LogSetUseCase reject the set via a snackbar.
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return s.validationRequired;
                    }
                    final n = int.tryParse(value);
                    if (n == null) return s.validationInvalid;
                    if (n < 1) return s.validationMinOne;
                    return null;
                  },
                ),
              ),
              if (_showRpe) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 88,
                  child: _KineticField(
                    controller: _rpeController,
                    focusNode: _rpeFocusNode,
                    label: s.rpeLabel,
                    isDouble: true,
                    isRequired: false,
                    isFocused: _rpeFocused,
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
          const SizedBox(height: 16),
          // ── Action row ─────────────────────────────────────────────
          // "+ Add RPE" (accent mono text), "Warm-up" ghost pill toggle,
          // and "+ Log Set" KineticCta pushed to the trailing edge.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // "+ Add RPE" affordance — accent mono, matches rf.css
              // inline style: color:var(--accent-line), JetBrains Mono 700 12px.
              GestureDetector(
                onTap: () => setState(() => _showRpe = !_showRpe),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showRpe ? Icons.remove : Icons.add,
                      size: 16,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      (_showRpe ? s.hideRpe : s.addRpe).toUpperCase(),
                      style: KineticText.mono(
                        size: 12,
                        letterSpacing: 0.5,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // "Warm-up" ghost pill toggle
              GestureDetector(
                onTap: () => setState(() => _isWarmUp = !_isWarmUp),
                child: KineticPill(
                  s.warmUpLabel,
                  variant: _isWarmUp
                      ? KineticPillVariant.accent
                      : KineticPillVariant.ghost,
                ),
              ),
              const Spacer(),
              // "+ Log Set" CTA — auto width, 46px height
              KineticCta(
                label: s.logSet,
                icon: Icons.add,
                onPressed: _submit,
                height: 46,
                borderRadius: 13,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single Kinetic field tile mirroring rf.css `.field` / `.field--focus`.
///
/// The tile has:
/// - A mono uppercase label at the top (`.field__k`)
/// - A large mono value in the centre (`.field__v`)
/// - An accent 1.5px inset ring when focused (`.field--focus`)
///
/// The underlying [TextFormField] is kept (but visually hidden via
/// `InputDecoration` with zero-height borders and zero padding) so that
/// widget-test finders using `find.byType(TextFormField)` and controller
/// inspection continue to work.
class _KineticField extends StatelessWidget {
  const _KineticField({
    required this.controller,
    required this.label,
    required this.isDouble,
    required this.isFocused,
    this.isRequired = true,
    this.validator,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final bool isDouble;
  final bool isFocused;
  final bool isRequired;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // Field tile background: uses surfaceContainer (--s2 in dark, --s2 in light).
    // Focused: 1.5px accent inset ring per `.field--focus`.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused ? cs.primary : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.18),
                  blurRadius: 0,
                  spreadRadius: 0,
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `.field__k` — mono uppercase dim label
          Text(
            label.toUpperCase(),
            style: KineticText.mono(
              size: 10,
              weight: FontWeight.w600,
              letterSpacing: 1.0,
              color: cs.onSurfaceVariant,
            ),
          ),
          // The TextFormField itself — styled to look like `.field__v`:
          // large mono value, no visible borders or decoration chrome.
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: KineticText.mono(
              size: 22,
              letterSpacing: -0.5,
              color: cs.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 9, bottom: 11),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorStyle: TextStyle(
                fontSize: 10,
                color: cs.error,
                height: 1.2,
              ),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
            textAlign: TextAlign.left,
            validator: validator ??
                (value) {
                  if (!isRequired && (value == null || value.isEmpty)) {
                    return null;
                  }
                  if (value == null || value.isEmpty) {
                    return s.validationRequired;
                  }
                  final n = isDouble
                      ? double.tryParse(value)
                      : int.tryParse(value)?.toDouble();
                  if (n == null) return s.validationInvalid;
                  if (isRequired && n < 0) return s.validationMinZero;
                  return null;
                },
          ),
        ],
      ),
    );
  }
}
