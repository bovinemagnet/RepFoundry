import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/providers.dart';
import '../../../../core/widgets/kinetic.dart';
import '../../../clients/presentation/widgets/client_switcher.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../controllers/cardio_tracking_controller.dart';
import '../controllers/cardio_tracking_state.dart';
import '../widgets/hr_device_picker_dialog.dart';
import '../widgets/hr_setup_guide_dialog.dart';

final _cardioExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.getExercisesByMuscleGroup(MuscleGroup.cardio);
});

class CardioTrackingScreen extends ConsumerStatefulWidget {
  const CardioTrackingScreen({super.key});

  @override
  ConsumerState<CardioTrackingScreen> createState() =>
      _CardioTrackingScreenState();
}

class _CardioTrackingScreenState extends ConsumerState<CardioTrackingScreen> {
  final _distanceController = TextEditingController();
  final _inclineController = TextEditingController();
  final _heartRateController = TextEditingController();

  @override
  void dispose() {
    _distanceController.dispose();
    _inclineController.dispose();
    _heartRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final cardioState = ref.watch(cardioTrackingProvider);
    final controller = ref.read(cardioTrackingProvider.notifier);
    final exercisesAsync = ref.watch(_cardioExercisesProvider);

    ref.listen(cardioTrackingProvider, (prev, next) {
      if (next.savedSuccessfully && !(prev?.savedSuccessfully ?? false)) {
        _distanceController.clear();
        _inclineController.clear();
        _heartRateController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.cardioSessionSaved)),
        );
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      // The Kinetic redesign embeds the app header inside the scroll area.
      // A zero-height AppBar satisfies the shell-route chrome while the
      // KineticAppHeader + screen title below provide the visible heading.
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: cs.surface,
        // Semantics label used by screen readers and kept for test discovery.
        title: Text(s.cardioTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 96),
        children: [
          // ── Kinetic app header ──────────────────────────────
          const KineticAppHeader(),

          // ── Screen title (pagehead eyebrow) ─────────────────
          // Active client badge alongside it — so the coach can't log a
          // session for the wrong client without noticing.
          Row(
            children: [
              KineticEyebrow(s.cardioTitle),
              const Spacer(),
              const ActiveClientIndicator(),
            ],
          ),
          const SizedBox(height: 12),

          // ── Sport segmented control (.seg pill) ────────────
          _ExerciseSegControl(
            exercisesAsync: exercisesAsync,
            selectedId: cardioState.selectedExerciseId,
            onSelected: (id, name) => controller.selectExercise(id, name),
          ),
          const SizedBox(height: 26),

          // ── Hero timer display ──────────────────────────────
          _HeroTimer(
            elapsedSeconds: cardioState.elapsedSeconds,
            isRunning: cardioState.isRunning,
          ),
          const SizedBox(height: 24),

          // ── Avg pace + Distance stat tiles (2-up) ──────────
          _MetricStatRow(cardioState: cardioState),
          const SizedBox(height: 22),

          // ── GPS tracking card ───────────────────────────────
          _GpsCard(
            cardioState: cardioState,
            onToggle: controller.toggleGps,
          ),
          const SizedBox(height: 12),

          // ── Heart rate card ─────────────────────────────────
          _buildHeartRateCard(context, cardioState, controller),
          const SizedBox(height: 12),

          // ── Last session ghost tiles ─────────────────────────
          if (cardioState.lastSession != null) ...[
            _LastSessionCard(session: cardioState.lastSession!),
            const SizedBox(height: 12),
          ],

          // ── Manual input fields ─────────────────────────────
          if (!cardioState.gpsEnabled) ...[
            _KineticInputField(
              controller: _distanceController,
              label: s.distanceMetresLabel,
              icon: Icons.directions_run,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            if (_computedPace != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  s.paceLabel(_computedPace!),
                  style: KineticText.mono(
                    size: 11,
                    weight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],

          _KineticInputField(
            controller: _inclineController,
            label: s.inclineLabel,
            icon: Icons.trending_up,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),

          if (!cardioState.hrConnected) ...[
            _KineticInputField(
              controller: _heartRateController,
              label: s.avgHeartRateLabel,
              icon: Icons.favorite_outline,
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 22),

          // ── Timer controls ──────────────────────────────────
          if (!cardioState.isRunning)
            KineticCta(
              label:
                  cardioState.elapsedSeconds == 0 ? s.startSession : s.resume,
              icon: Icons.play_arrow,
              onPressed: controller.start,
            )
          else
            _SecondaryActionButton(
              onPressed: controller.pause,
              icon: Icons.pause,
              label: s.pause.toUpperCase(),
            ),

          if (cardioState.elapsedSeconds > 0) ...[
            const SizedBox(height: 10),
            _SecondaryActionButton(
              onPressed: controller.reset,
              icon: Icons.stop,
              label: s.reset.toUpperCase(),
            ),
          ],

          // ── Save button ─────────────────────────────────────
          if (cardioState.elapsedSeconds > 0) ...[
            const SizedBox(height: 10),
            KineticCta(
              label: s.saveSession,
              icon: cardioState.isSaving ? null : Icons.save,
              onPressed: cardioState.selectedExerciseId != null &&
                      !cardioState.isSaving
                  ? () => controller.save(
                        distanceMeters:
                            double.tryParse(_distanceController.text),
                        incline: double.tryParse(_inclineController.text),
                        avgHeartRate: int.tryParse(_heartRateController.text),
                      )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeartRateCard(
    BuildContext context,
    CardioTrackingState cardioState,
    CardioTrackingController controller,
  ) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (cardioState.hrConnecting || cardioState.hrReconnecting) {
      // Connecting / reconnecting state
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                cardioState.hrReconnecting
                    ? s.reconnectingTo(cardioState.hrDeviceName ?? 'device')
                    : s.connectingTo(cardioState.hrDeviceName ?? 'device'),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (cardioState.hrConnected) {
      // Connected — live BPM tile (mirrors .route__chip heart in the design)
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.favorite, color: cs.error, size: 28),
            const SizedBox(width: 12),
            Text(
              cardioState.currentHeartRate != null
                  ? '${cardioState.currentHeartRate}'
                  : '--',
              style: KineticText.mono(
                size: 36,
                weight: FontWeight.w800,
                letterSpacing: -1.0,
                color: cs.error,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              s.bpmSuffix,
              style: KineticText.mono(
                size: 13,
                weight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  cardioState.hrDeviceName ?? '',
                  style: KineticText.mono(
                    size: 10,
                    weight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => controller.disconnectHeartRate(),
                  child: Text(
                    s.disconnect.toUpperCase(),
                    style: KineticText.mono(
                      size: 10,
                      letterSpacing: 0.8,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Disconnected — BLE connect prompt
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: _HrConnectPrompt(
        icon: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.bluetooth, color: cs.primary, size: 22),
        ),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.heartRateMonitorCard,
              style: KineticText.display(
                size: 15,
                letterSpacing: -0.2,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              s.heartRateMonitorSubtitle,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        help: IconButton(
          icon: Icon(Icons.help_outline, color: cs.onSurfaceVariant),
          tooltip: s.setupGuide,
          onPressed: () => showHrSetupGuide(context),
        ),
        action: FilledButton.tonal(
          onPressed: cardioState.isSaving
              ? null
              : () => _showHrDevicePicker(controller),
          child: Text(s.connect),
        ),
      ),
    );
  }

  Future<void> _showHrDevicePicker(
    CardioTrackingController controller,
  ) async {
    final s = S.of(context)!;
    final heartRateService = ref.read(heartRateServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    var permissionOk = await heartRateService.checkAndRequestPermission();
    if (!permissionOk) {
      // Offer the system enable-Bluetooth dialog before giving up.
      permissionOk = await heartRateService.turnOnBluetooth();
    }
    if (!permissionOk) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(s.bluetoothNotAvailable),
        ),
      );
      return;
    }

    if (!mounted) return;
    final device = await showHrDevicePicker(
      context: context,
      heartRateService: heartRateService,
    );

    if (device != null) {
      controller.connectHeartRate(device.id, device.name);
    }
  }

  String? get _computedPace {
    final elapsed = ref.read(cardioTrackingProvider).elapsedSeconds;
    final distance = double.tryParse(_distanceController.text);
    if (distance == null || distance <= 0 || elapsed <= 0) return null;
    final paceMinPerKm = (elapsed / 60) / (distance / 1000);
    return _formatPace(paceMinPerKm);
  }

  static String _formatPace(double minutesPerKm) {
    final mins = minutesPerKm.floor();
    final secs = ((minutesPerKm - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')} min/km';
  }
}

// ── Sport Segmented Control (.seg) ──────────────────────────────────────────
// Renders as a pill-shaped row where the active item has an accent fill,
// matching rf.css `.seg` / `.seg__item` / `.seg__item--on`.

class _ExerciseSegControl extends StatelessWidget {
  const _ExerciseSegControl({
    required this.exercisesAsync,
    required this.selectedId,
    required this.onSelected,
  });

  final AsyncValue<List<Exercise>> exercisesAsync;
  final String? selectedId;
  final void Function(String id, String name) onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return exercisesAsync.when(
      data: (exercises) {
        if (exercises.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: exercises.map((ex) {
              final isSelected = ex.id == selectedId;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(ex.id, ex.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_run,
                          size: 17,
                          color:
                              isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            ex.name,
                            overflow: TextOverflow.ellipsis,
                            style: KineticText.mono(
                              size: 12,
                              letterSpacing: 0.4,
                              color: isSelected
                                  ? cs.onPrimary
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: LinearProgressIndicator()),
      ),
      error: (_, __) => const Text('Failed to load exercises'),
    );
  }
}

// ── Hero Timer ───────────────────────────────────────────────────────────────
// Centred display: mono "ACTIVE DURATION" eyebrow, then 64/800 MM:SS with an
// accent-coloured separator colon, and a dim ".00" centisecond stub.

class _HeroTimer extends StatelessWidget {
  const _HeroTimer({
    required this.elapsedSeconds,
    required this.isRunning,
  });

  final int elapsedSeconds;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final duration = Duration(seconds: elapsedSeconds);
    final mins = duration.inMinutes;
    final secs = duration.inSeconds % 60;

    final digitColor = isRunning ? cs.onSurface : cs.onSurfaceVariant;

    return Column(
      children: [
        // Eyebrow label — mono uppercase, accent
        Text(
          s.activeDuration.toUpperCase(),
          style: KineticText.mono(
            size: 10.5,
            weight: FontWeight.w700,
            letterSpacing: 2.2,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 14),
        // Hero numeral row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              mins.toString().padLeft(2, '0'),
              style: KineticText.mono(
                size: 64,
                weight: FontWeight.w800,
                letterSpacing: -2.5,
                color: digitColor,
                height: 0.9,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                ':',
                style: KineticText.mono(
                  size: 64,
                  weight: FontWeight.w800,
                  letterSpacing: 0,
                  color: cs.primary,
                  height: 0.9,
                ),
              ),
            ),
            Text(
              secs.toString().padLeft(2, '0'),
              style: KineticText.mono(
                size: 64,
                weight: FontWeight.w800,
                letterSpacing: -2.5,
                color: digitColor,
                height: 0.9,
              ),
            ),
            const SizedBox(width: 4),
            // Centisecond stub — dim, smaller
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '.00',
                style: KineticText.mono(
                  size: 20,
                  weight: FontWeight.w700,
                  color: cs.primary,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Heart rate connect prompt ────────────────────────────────────────────────

/// Lays out the BLE connect tile: icon + label with the help and Connect
/// actions beside them. On a narrow phone the actions would squeeze the label
/// column to about a third of the width, wrapping "Heart Rate Monitor" over
/// several lines (issue #79 family), so below [_stackBelowWidth] the actions
/// move onto their own line and the label gets the full width.
class _HrConnectPrompt extends StatelessWidget {
  const _HrConnectPrompt({
    required this.icon,
    required this.label,
    required this.help,
    required this.action,
  });

  final Widget icon;
  final Widget label;
  final Widget help;
  final Widget action;

  /// Below this the icon, label and both actions no longer fit on one line
  /// without wrapping the label.
  static const _stackBelowWidth = 420.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelRow = Row(
          children: [
            icon,
            const SizedBox(width: 14),
            Expanded(child: label),
          ],
        );

        if (constraints.maxWidth >= _stackBelowWidth) {
          return Row(
            children: [
              Expanded(child: labelRow),
              help,
              action,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            labelRow,
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [help, action],
            ),
          ],
        );
      },
    );
  }
}

// ── Metric Stat Row (avg pace + distance) ────────────────────────────────────
// Two KineticStatTile widgets side by side, fed from live GPS/manual state.

class _MetricStatRow extends StatelessWidget {
  const _MetricStatRow({required this.cardioState});

  final CardioTrackingState cardioState;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    // Calculate avg pace
    String paceDisplay = '--';
    String? paceUnit;
    if (cardioState.gpsEnabled &&
        cardioState.gpsDistanceMeters > 0 &&
        cardioState.elapsedSeconds > 0) {
      final pace = (cardioState.elapsedSeconds / 60) /
          (cardioState.gpsDistanceMeters / 1000);
      final mins = pace.floor();
      final secs = ((pace - mins) * 60).round();
      paceDisplay = "$mins'${secs.toString().padLeft(2, '0')}\"";
      paceUnit = '/km';
    }

    // Calculate distance
    String distanceDisplay = '--';
    String? distUnit;
    if (cardioState.gpsEnabled && cardioState.gpsDistanceMeters > 0) {
      distanceDisplay =
          (cardioState.gpsDistanceMeters / 1000).toStringAsFixed(2);
      distUnit = 'km';
    }

    return Row(
      children: [
        Expanded(
          child: KineticStatTile(
            label: s.avgPaceLabel,
            value: paceDisplay,
            unit: paceUnit,
            valueSize: 26,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: KineticStatTile(
            label: s.distanceLabel,
            value: distanceDisplay,
            unit: distUnit,
            valueSize: 26,
          ),
        ),
      ],
    );
  }
}

// ── GPS Card ─────────────────────────────────────────────────────────────────
// Uses a custom row inside Material to avoid the ListTile-in-DecoratedBox
// assertion (the root cause of the 4 pre-existing test failures).

class _GpsCard extends StatelessWidget {
  const _GpsCard({
    required this.cardioState,
    required this.onToggle,
  });

  final CardioTrackingState cardioState;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // Subtitle text
    final subtitle = cardioState.gpsAcquiring
        ? s.gpsAcquiring
        : cardioState.gpsEnabled
            ? s.gpsMetresTracked(
                cardioState.gpsDistanceMeters.toStringAsFixed(0))
            : s.gpsSubtitle;

    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: cardioState.isSaving ? null : onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cardioState.gpsEnabled
                      ? cs.primary.withValues(alpha: 0.14)
                      : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.gps_fixed,
                  size: 22,
                  color:
                      cardioState.gpsEnabled ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.gpsDistanceTracking,
                      style: KineticText.display(
                        size: 15,
                        letterSpacing: -0.2,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: cardioState.gpsEnabled,
                onChanged: cardioState.isSaving ? null : (_) => onToggle(),
                activeThumbColor: cs.onPrimary,
                activeTrackColor: cs.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Last Session Card ─────────────────────────────────────────────────────────
// Shows previous session stats as a row of compact mono metric tiles (.mtile).

class _LastSessionCard extends StatelessWidget {
  const _LastSessionCard({required this.session});

  final dynamic session;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KineticSectionLabel(s.lastSession),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricTile(
              value: session.duration.formatted,
              label: 'duration',
            ),
            if (session.distanceMeters != null)
              _MetricTile(
                value: '${session.distanceMeters!.toStringAsFixed(0)} m',
                label: 'distance',
              ),
            if (session.paceMinutesPerKm != null)
              _MetricTile(
                value: _formatPace(session.paceMinutesPerKm!),
                label: 'pace',
              ),
            if (session.avgHeartRate != null)
              _MetricTile(
                value: '${session.avgHeartRate}',
                label: 'avg bpm',
              ),
          ],
        ),
      ],
    );
  }

  static String _formatPace(double minutesPerKm) {
    final mins = minutesPerKm.floor();
    final secs = ((minutesPerKm - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

// ── Compact Metric Tile (.mtile) ─────────────────────────────────────────────
// Matches rf.css `.mtile`: centred big mono value + small uppercase label.

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: KineticText.mono(
              size: 22,
              weight: FontWeight.w700,
              letterSpacing: -0.9,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: KineticText.mono(
              size: 9.5,
              weight: FontWeight.w600,
              letterSpacing: 1.2,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Secondary Action Button ───────────────────────────────────────────────────
// Non-primary controls (Pause, Reset) — surfaceContainer bg, outlined style.

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: cs.onSurface),
              const SizedBox(width: 8),
              Text(
                label,
                style: KineticText.mono(
                  size: 13,
                  letterSpacing: 0.8,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Kinetic Input Field ───────────────────────────────────────────────────────
// Manual entry fields styled with surfaceContainerLow background and
// accent focus ring, matching rf.css `.field--focus`.

class _KineticInputField extends StatelessWidget {
  const _KineticInputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: KineticText.mono(size: 14, color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: cs.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
