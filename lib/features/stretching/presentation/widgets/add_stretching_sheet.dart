import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../domain/models/stretching_session.dart';
import '../controllers/stretching_timer_controller.dart';
import 'stretch_preset_localiser.dart';

/// Bottom sheet for adding a stretching entry (timer or manual). Owns its
/// own internal mode toggle but delegates state to [StretchingTimerController]
/// so timer state survives sheet dismiss.
class AddStretchingSheet extends ConsumerStatefulWidget {
  const AddStretchingSheet({super.key, required this.workoutId});

  final String workoutId;

  static Future<bool?> show(BuildContext context, String workoutId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddStretchingSheet(workoutId: workoutId),
    );
  }

  @override
  ConsumerState<AddStretchingSheet> createState() => _AddStretchingSheetState();
}

enum _Mode { timer, manual }

class _AddStretchingSheetState extends ConsumerState<AddStretchingSheet> {
  _Mode _mode = _Mode.manual;
  final _customNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final controller = ref.read(stretchingTimerProvider.notifier);
    final state = ref.read(stretchingTimerProvider);
    controller.setWorkoutId(widget.workoutId);
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
    final ok = await controller.save();
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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.addStretchingTitle,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(s.stretchTypeLabel, style: tt.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in defaultStretches)
                    ChoiceChip(
                      label: Text(localiseStretch(s, preset.key)),
                      selected: state.selectedType == preset.key,
                      onSelected: (_) {
                        ref.read(stretchingTimerProvider.notifier).selectType(
                              type: preset.key,
                              bodyArea: preset.bodyArea,
                            );
                      },
                    ),
                  ChoiceChip(
                    label: Text(s.customStretchLabel),
                    selected: state.selectedType ==
                        StretchingSession.customStretchType,
                    onSelected: (_) {
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
              const SizedBox(height: 20),
              Text(s.recordTimeLabel, style: tt.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<_Mode>(
                segments: [
                  ButtonSegment(
                    value: _Mode.manual,
                    label: Text(s.recordManual),
                    icon: const Icon(Icons.edit_note),
                  ),
                  ButtonSegment(
                    value: _Mode.timer,
                    label: Text(s.recordTimer),
                    icon: const Icon(Icons.timer_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (sel) => setState(() => _mode = sel.first),
              ),
              const SizedBox(height: 16),
              if (_mode == _Mode.manual)
                _ManualEntry(
                  minutesController: _minutesController,
                  secondsController: _secondsController,
                  onChanged: _applyManualDuration,
                  onQuickAdd: _applyQuickAdd,
                )
              else
                _TimerEntry(
                  elapsedSeconds: state.elapsedSeconds,
                  isRunning: state.isRunning,
                  onStart: () =>
                      ref.read(stretchingTimerProvider.notifier).start(),
                  onPause: () =>
                      ref.read(stretchingTimerProvider.notifier).pause(),
                  onReset: () =>
                      ref.read(stretchingTimerProvider.notifier).reset(),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _notesController,
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: s.notesLabel,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) =>
                    ref.read(stretchingTimerProvider.notifier).setNotes(v),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  style: tt.bodySmall?.copyWith(color: cs.error),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleDiscard,
                      child: Text(s.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: state.isSaving ? null : _handleSave,
                      child: Text(s.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualEntry extends StatelessWidget {
  const _ManualEntry({
    required this.minutesController,
    required this.secondsController,
    required this.onChanged,
    required this.onQuickAdd,
  });

  final TextEditingController minutesController;
  final TextEditingController secondsController;
  final VoidCallback onChanged;
  final void Function(int minutes) onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: s.minutesAbbrev,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: secondsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: s.secondsAbbrev,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(s.quickAddDurations,
            style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in [1, 2, 5, 10, 15])
              ActionChip(
                label: Text('$m ${s.minutesAbbrev}'),
                onPressed: () => onQuickAdd(m),
              ),
          ],
        ),
      ],
    );
  }
}

class _TimerEntry extends StatelessWidget {
  const _TimerEntry({
    required this.elapsedSeconds,
    required this.isRunning,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  final int elapsedSeconds;
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            _format(elapsedSeconds),
            style: tt.displayMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.bold,
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
                label: Text(s.reset),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: isRunning ? onPause : onStart,
                icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(isRunning ? s.pause : s.start),
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
