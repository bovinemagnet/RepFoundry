import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/widgets/kinetic.dart';
import '../../domain/models/stretching_session.dart';
import '../controllers/stretching_timer_controller.dart';
import 'stretch_preset_localiser.dart';

/// Bottom sheet for adding a stretching entry (timer or manual). Owns its
/// own internal mode toggle but delegates state to [StretchingTimerController]
/// so timer state survives sheet dismiss.
///
/// Styled to the "Kinetic Green" redesign spec (rf.css `.sheet`, `.schip`,
/// `.segsm`, `.field`, `.qchip`, `.notes`, `.sheetbtns`).
class AddStretchingSheet extends ConsumerStatefulWidget {
  const AddStretchingSheet({super.key, required this.workoutId});

  final String workoutId;

  static Future<bool?> show(BuildContext context, String workoutId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddStretchingSheet(workoutId: workoutId),
    );
  }

  @override
  ConsumerState<AddStretchingSheet> createState() => _AddStretchingSheetState();
}

enum _Mode { timer, manual, untimed }

StretchingEntryMethod _entryMethodFor(_Mode mode) {
  switch (mode) {
    case _Mode.timer:
      return StretchingEntryMethod.timer;
    case _Mode.manual:
      return StretchingEntryMethod.manual;
    case _Mode.untimed:
      return StretchingEntryMethod.untimed;
  }
}

class _AddStretchingSheetState extends ConsumerState<AddStretchingSheet> {
  _Mode _mode = _Mode.manual;
  final _customNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Read-only access in initState is fine; mutating the Riverpod provider
    // here would throw because the widget tree is still building. The
    // workoutId is passed to save() at submit time, so no mutation needed.
    final state = ref.read(stretchingTimerProvider);
    _customNameController.text = state.customName ?? '';
    _notesController.text = state.notes;
    if (state.manualSeconds > 0) {
      _minutesController.text = (state.manualSeconds ~/ 60).toString();
      _secondsController.text = (state.manualSeconds % 60).toString();
    }
    if (state.isRunning) {
      _mode = _Mode.timer;
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _notesController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _applyManualDuration() {
    final mins = int.tryParse(_minutesController.text.trim()) ?? 0;
    final secs = int.tryParse(_secondsController.text.trim()) ?? 0;
    ref
        .read(stretchingTimerProvider.notifier)
        .setManualDuration((mins * 60) + secs);
  }

  void _applyQuickAdd(int minutes) {
    _minutesController.text = minutes.toString();
    _secondsController.text = '0';
    ref.read(stretchingTimerProvider.notifier).setManualDuration(minutes * 60);
  }

  Future<void> _handleSave() async {
    final controller = ref.read(stretchingTimerProvider.notifier);
    if (_mode == _Mode.manual) _applyManualDuration();
    controller.setNotes(_notesController.text.trim());
    final ok = await controller.save(
      workoutId: widget.workoutId,
      entryMethod: _entryMethodFor(_mode),
    );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  void _handleDiscard() {
    ref.read(stretchingTimerProvider.notifier).discard();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final state = ref.watch(stretchingTimerProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      // Top-rounded sheet container — rf.css `.sheet`: radius 28 28 0 0,
      // surface background, top shadow.
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 50,
              offset: Offset(0, -20),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grip handle — rf.css `.sheet__grip`: 42×5 px, outline-variant.
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.outline,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                // Sheet title — rf.css `.sheet__title`: Space Grotesk 21/700.
                Text(
                  s.addStretchingTitle,
                  style: KineticText.display(size: 21, letterSpacing: -0.21),
                ),
                // Section label — rf.css `.sheet__lbl`: mono 11, 0.14em spacing.
                _SheetLabel(s.stretchTypeLabel),
                // Stretch-type chips — rf.css `.schip` / `.schip--on`.
                // ChoiceChip is used so the test can locate chips by type and text.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in defaultStretches)
                      _StretchChip(
                        label: localiseStretch(s, preset.key),
                        selected: state.selectedType == preset.key,
                        onSelected: () {
                          ref.read(stretchingTimerProvider.notifier).selectType(
                                type: preset.key,
                                bodyArea: preset.bodyArea,
                              );
                        },
                      ),
                    _StretchChip(
                      label: s.customStretchLabel,
                      selected: state.selectedType ==
                          StretchingSession.customStretchType,
                      onSelected: () {
                        ref.read(stretchingTimerProvider.notifier).selectType(
                              type: StretchingSession.customStretchType,
                              customName: _customNameController.text,
                            );
                      },
                    ),
                  ],
                ),
                if (state.selectedType ==
                    StretchingSession.customStretchType) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customNameController,
                    maxLength: 60,
                    decoration: InputDecoration(
                      labelText: s.customStretchHint,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => ref
                        .read(stretchingTimerProvider.notifier)
                        .setCustomName(v),
                  ),
                ],
                // Section label for "Record time".
                _SheetLabel(s.recordTimeLabel),
                // Compact segmented control — rf.css `.segsm` / `.segsm__i--on`.
                // SegmentedButton retains the widget type the test depends on.
                _KineticSegmented(
                  mode: _mode,
                  onChanged: (m) => setState(() => _mode = m),
                  manualLabel: s.recordManual,
                  timerLabel: s.recordTimer,
                  untimedLabel: s.recordUntimed,
                ),
                const SizedBox(height: 12),
                if (_mode == _Mode.manual)
                  _ManualEntry(
                    minutesController: _minutesController,
                    secondsController: _secondsController,
                    onChanged: _applyManualDuration,
                    onQuickAdd: _applyQuickAdd,
                    quickAddLabel: s.quickAddDurations,
                    minutesAbbrev: s.minutesAbbrev,
                    secondsAbbrev: s.secondsAbbrev,
                  )
                else if (_mode == _Mode.timer)
                  _TimerEntry(
                    elapsedSeconds: state.elapsedSeconds,
                    isRunning: state.isRunning,
                    onStart: () =>
                        ref.read(stretchingTimerProvider.notifier).start(),
                    onPause: () =>
                        ref.read(stretchingTimerProvider.notifier).pause(),
                    onReset: () =>
                        ref.read(stretchingTimerProvider.notifier).reset(),
                    resetLabel: s.reset,
                    pauseLabel: s.pause,
                    startLabel: s.start,
                  )
                else
                  _UntimedEntry(hint: s.untimedEntryHint),
                // Section label for notes.
                _SheetLabel(s.notesLabel),
                // Notes textarea — rf.css `.notes`: surfaceContainer bg, radius 14.
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  maxLength: 200,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: s.notesLabel,
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onChanged: (v) =>
                      ref.read(stretchingTimerProvider.notifier).setNotes(v),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.error!,
                    style: tt.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                // Button row — rf.css `.sheetbtns`: grid 1 : 1.4, gap 10.
                // Cancel = `.btn-ghost` (surfaceContainer fill, text colour).
                // Save = `.cta` via KineticCta / FilledButton (test finds FilledButton).
                const SizedBox(height: 18),
                Row(
                  children: [
                    // Cancel ghost button.
                    Expanded(
                      flex: 10,
                      child: _GhostButton(
                        label: s.cancel,
                        onPressed: _handleDiscard,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Save — FilledButton so the test locates it by type.
                    Expanded(
                      flex: 14,
                      child: SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: state.isSaving ? null : _handleSave,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            s.save,
                            style: KineticText.mono(
                              size: 13,
                              letterSpacing: 0.8,
                              color: cs.onPrimary,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────  Local helpers  ────────────────────────────────────

/// Section label inside the sheet — rf.css `.sheet__lbl`:
/// JetBrains Mono 11/700, 0.14em letter-spacing, uppercase, dim colour.
class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 11),
      child: Text(
        text.toUpperCase(),
        style: KineticText.mono(
          size: 11,
          letterSpacing: 1.4,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Stretch-type chip — wraps [ChoiceChip] with Kinetic Green styling.
/// Tests locate these as [ChoiceChip] widgets, so the type is preserved.
/// rf.css `.schip` (outlined default) / `.schip--on` (accent fill).
class _StretchChip extends StatelessWidget {
  const _StretchChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: selected
          ? GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: cs.onPrimary,
            )
          : GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
      backgroundColor: Colors.transparent,
      selectedColor: cs.primary,
      side: selected
          ? BorderSide.none
          : BorderSide(color: cs.outline, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      showCheckmark: false,
    );
  }
}

/// Full-width compact segmented control — rf.css `.segsm` / `.segsm__i--on`.
/// Uses [SegmentedButton] so the test can still find it via [SegmentedButton]
/// and tap segment labels by text.
class _KineticSegmented extends StatelessWidget {
  const _KineticSegmented({
    required this.mode,
    required this.onChanged,
    required this.manualLabel,
    required this.timerLabel,
    required this.untimedLabel,
  });

  final _Mode mode;
  final ValueChanged<_Mode> onChanged;
  final String manualLabel;
  final String timerLabel;
  final String untimedLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme(
      // Override the segmented button theme to match `.segsm` styling:
      // surfaceContainer track, accent fill for active item, radius 12.
      data: Theme.of(context).copyWith(
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return cs.primary;
              }
              return cs.surfaceContainer;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return cs.onPrimary;
              }
              return cs.onSurfaceVariant;
            }),
            textStyle: WidgetStatePropertyAll(
              KineticText.mono(size: 12, letterSpacing: 0.4),
            ),
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            side: const WidgetStatePropertyAll(BorderSide.none),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 7, horizontal: 12),
            ),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(3),
        child: SegmentedButton<_Mode>(
          expandedInsets: EdgeInsets.zero,
          segments: [
            ButtonSegment(
              value: _Mode.manual,
              label: Text(manualLabel),
              icon: const Icon(Icons.check, size: 15),
            ),
            ButtonSegment(
              value: _Mode.timer,
              label: Text(timerLabel),
              icon: const Icon(Icons.timer_outlined, size: 15),
            ),
            ButtonSegment(
              value: _Mode.untimed,
              label: Text(untimedLabel),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (sel) => onChanged(sel.first),
          showSelectedIcon: false,
        ),
      ),
    );
  }
}

/// Ghost cancel button — rf.css `.btn-ghost`:
/// surfaceContainer bg, text colour, Space Grotesk 13/700, height 52, radius 15.
class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: cs.surfaceContainer,
          foregroundColor: cs.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: KineticText.display(
            size: 13,
            letterSpacing: -0.1,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Untimed-mode placeholder tile — rf.css surface tile with centred icon + hint.
class _UntimedEntry extends StatelessWidget {
  const _UntimedEntry({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.remove, size: 32, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            hint,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Manual-entry section: 2-column field tiles + quick-add chips.
/// rf.css `.field` tiles (surfaceContainerLowest bg, radius 14) and
/// `.qchip` chips (surfaceContainer bg, mono font, radius 11).
class _ManualEntry extends StatelessWidget {
  const _ManualEntry({
    required this.minutesController,
    required this.secondsController,
    required this.onChanged,
    required this.onQuickAdd,
    required this.quickAddLabel,
    required this.minutesAbbrev,
    required this.secondsAbbrev,
  });

  final TextEditingController minutesController;
  final TextEditingController secondsController;
  final VoidCallback onChanged;
  final void Function(int minutes) onQuickAdd;
  final String quickAddLabel;
  final String minutesAbbrev;
  final String secondsAbbrev;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2-column field row — rf.css `.fieldrow` / `.field`.
        Row(
          children: [
            Expanded(
              child: _FieldTile(
                controller: minutesController,
                label: minutesAbbrev,
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FieldTile(
                controller: secondsController,
                label: secondsAbbrev,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Quick-add label.
        Text(
          quickAddLabel.toUpperCase(),
          style: KineticText.mono(
            size: 11,
            letterSpacing: 1.4,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        // Quick-add chips — rf.css `.qchip`: mono 12/700, surfaceContainer bg,
        // radius 11. ActionChip is used so the test can locate them by type.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in [1, 2, 5, 10, 15])
              ActionChip(
                label: Text('$m $minutesAbbrev'),
                onPressed: () => onQuickAdd(m),
                labelStyle: KineticText.mono(
                  size: 12,
                  color: cs.onSurface,
                ),
                backgroundColor: cs.surfaceContainer,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Single numeric input tile — rf.css `.field`:
/// surfaceContainerLowest bg, radius 14, mono label + value.
class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: KineticText.mono(
              size: 10,
              weight: FontWeight.w600,
              letterSpacing: 1.0,
              color: cs.onSurfaceVariant,
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: KineticText.mono(
              size: 22,
              letterSpacing: -0.02,
              color: cs.onSurface,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: KineticText.mono(
                size: 22,
                letterSpacing: -0.02,
                color: cs.onSurfaceVariant,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 9),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Timer-mode section: elapsed display + start/pause/reset controls.
class _TimerEntry extends StatelessWidget {
  const _TimerEntry({
    required this.elapsedSeconds,
    required this.isRunning,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.resetLabel,
    required this.pauseLabel,
    required this.startLabel,
  });

  final int elapsedSeconds;
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final String resetLabel;
  final String pauseLabel;
  final String startLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            _format(elapsedSeconds),
            style: KineticText.mono(
              size: 48,
              weight: FontWeight.w800,
              letterSpacing: -1.5,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt),
                label: Text(resetLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: isRunning ? onPause : onStart,
                icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(isRunning ? pauseLabel : startLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _format(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final ss = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }
}
