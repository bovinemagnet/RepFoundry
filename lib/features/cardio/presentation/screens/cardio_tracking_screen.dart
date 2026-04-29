import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/providers.dart';
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
    final tt = Theme.of(context).textTheme;
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
      appBar: AppBar(title: Text(s.cardioTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // ── Exercise selector chips ──────────────────────────
          _ExerciseChipSelector(
            exercisesAsync: exercisesAsync,
            selectedId: cardioState.selectedExerciseId,
            onSelected: (id, name) => controller.selectExercise(id, name),
          ),
          const SizedBox(height: 24),

          // ── Hero timer display ──────────────────────────────
          _HeroTimer(
            elapsedSeconds: cardioState.elapsedSeconds,
            isRunning: cardioState.isRunning,
          ),
          const SizedBox(height: 20),

          // ── Kinetic metric bento ────────────────────────────
          _MetricBento(cardioState: cardioState),
          const SizedBox(height: 24),

          // ── GPS tracking card ───────────────────────────────
          _GpsCard(
            cardioState: cardioState,
            onToggle: controller.toggleGps,
          ),
          const SizedBox(height: 12),

          // ── Heart rate card ─────────────────────────────────
          _buildHeartRateCard(context, cardioState, controller),
          const SizedBox(height: 12),

          // ── Last session ghost card ─────────────────────────
          if (cardioState.lastSession != null) ...[
            _LastSessionCard(session: cardioState.lastSession!),
            const SizedBox(height: 12),
          ],

          // ── Manual input fields ─────────────────────────────
          if (!cardioState.gpsEnabled) ...[
            TextField(
              controller: _distanceController,
              decoration: InputDecoration(
                labelText: s.distanceMetresLabel,
                prefixIcon: const Icon(Icons.directions_run),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            if (_computedPace != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 16),
                child: Text(
                  s.paceLabel(_computedPace!),
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],

          TextField(
            controller: _inclineController,
            decoration: InputDecoration(
              labelText: s.inclineLabel,
              prefixIcon: const Icon(Icons.trending_up),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          if (!cardioState.hrConnected) ...[
            TextField(
              controller: _heartRateController,
              decoration: InputDecoration(
                labelText: s.avgHeartRateLabel,
                prefixIcon: const Icon(Icons.favorite_outline),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 24),

          // ── Save / Start controls ───────────────────────────
          Row(
            children: [
              // Timer controls
              if (!cardioState.isRunning)
                Expanded(
                  child: _ActionButton(
                    onPressed: controller.start,
                    icon: Icons.play_arrow,
                    label: cardioState.elapsedSeconds == 0
                        ? s.startSession.toUpperCase()
                        : s.resume.toUpperCase(),
                    isPrimary: true,
                  ),
                )
              else
                Expanded(
                  child: _ActionButton(
                    onPressed: controller.pause,
                    icon: Icons.pause,
                    label: s.pause.toUpperCase(),
                    isPrimary: false,
                  ),
                ),
              if (cardioState.elapsedSeconds > 0) ...[
                const SizedBox(width: 12),
                _ActionButton(
                  onPressed: controller.reset,
                  icon: Icons.stop,
                  label: s.reset.toUpperCase(),
                  isPrimary: false,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Save button
          if (cardioState.elapsedSeconds > 0)
            FilledButton.icon(
              onPressed: cardioState.selectedExerciseId != null &&
                      !cardioState.isSaving
                  ? () => controller.save(
                        distanceMeters:
                            double.tryParse(_distanceController.text),
                        incline: double.tryParse(_inclineController.text),
                        avgHeartRate: int.tryParse(_heartRateController.text),
                      )
                  : null,
              icon: cardioState.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(s.saveSession),
            ),
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
    final tt = Theme.of(context).textTheme;

    if (cardioState.hrConnecting || cardioState.hrReconnecting) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
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
                style: tt.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    if (cardioState.hrConnected) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.favorite, color: cs.error, size: 32),
            const SizedBox(width: 12),
            Text(
              cardioState.currentHeartRate != null
                  ? '${cardioState.currentHeartRate}'
                  : '--',
              style: tt.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.error,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              s.bpmSuffix,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  cardioState.hrDeviceName ?? '',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => controller.disconnectHeartRate(),
                  child: Text(
                    s.disconnect,
                    style: tt.labelSmall?.copyWith(
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

    // Disconnected state
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.bluetooth, color: cs.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.heartRateMonitorCard,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  s.heartRateMonitorSubtitle,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: s.setupGuide,
            onPressed: () => showHrSetupGuide(context),
          ),
          FilledButton.tonal(
            onPressed: cardioState.isSaving
                ? null
                : () => _showHrDevicePicker(controller),
            child: Text(s.connect),
          ),
        ],
      ),
    );
  }

  Future<void> _showHrDevicePicker(
    CardioTrackingController controller,
  ) async {
    final s = S.of(context)!;
    final heartRateService = ref.read(heartRateServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final permissionOk = await heartRateService.checkAndRequestPermission();
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

// ── Exercise Chip Selector ───────────────────────────────────────────────

class _ExerciseChipSelector extends StatelessWidget {
  const _ExerciseChipSelector({
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
    final tt = Theme.of(context).textTheme;

    return exercisesAsync.when(
      data: (exercises) => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: exercises.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final ex = exercises[index];
            final isSelected = ex.id == selectedId;

            return GestureDetector(
              onTap: () => onSelected(ex.id, ex.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.surfaceContainerHighest
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(100),
                  border: isSelected
                      ? Border.all(
                          color: cs.primary.withValues(alpha: 0.2),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_run,
                      size: 16,
                      color: isSelected ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ex.name,
                      style: tt.labelMedium?.copyWith(
                        color: isSelected ? cs.primary : cs.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      loading: () => const SizedBox(
        height: 42,
        child: Center(child: LinearProgressIndicator()),
      ),
      error: (_, __) => const Text('Failed to load exercises'),
    );
  }
}

// ── Hero Timer ───────────────────────────────────────────────────────────

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
    final tt = Theme.of(context).textTheme;
    final duration = Duration(seconds: elapsedSeconds);
    final mins = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    final centis = 0; // No centiseconds in current timer

    return Column(
      children: [
        Text(
          s.activeDuration.toUpperCase(),
          style: tt.labelSmall?.copyWith(
            color: cs.primary.withValues(alpha: 0.6),
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              mins.toString().padLeft(2, '0'),
              style: tt.displayLarge?.copyWith(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                height: 1.0,
                color: isRunning ? cs.onSurface : cs.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              ':',
              style: tt.displayLarge?.copyWith(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                height: 1.0,
                color: const Color(0xFF8354F4), // primary-dim
              ),
            ),
            Text(
              secs.toString().padLeft(2, '0'),
              style: tt.displayLarge?.copyWith(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                height: 1.0,
                color: isRunning ? cs.onSurface : cs.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '.${centis.toString().padLeft(2, '0')}',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w300,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Kinetic Metric Bento ─────────────────────────────────────────────────

class _MetricBento extends StatelessWidget {
  const _MetricBento({required this.cardioState});

  final CardioTrackingState cardioState;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Calculate pace
    String paceDisplay = '--';
    if (cardioState.gpsEnabled &&
        cardioState.gpsDistanceMeters > 0 &&
        cardioState.elapsedSeconds > 0) {
      final pace = (cardioState.elapsedSeconds / 60) /
          (cardioState.gpsDistanceMeters / 1000);
      final mins = pace.floor();
      final secs = ((pace - mins) * 60).round();
      paceDisplay = "$mins'${secs.toString().padLeft(2, '0')}\"";
    }

    // Calculate distance
    String distanceDisplay = '--';
    if (cardioState.gpsEnabled && cardioState.gpsDistanceMeters > 0) {
      distanceDisplay =
          (cardioState.gpsDistanceMeters / 1000).toStringAsFixed(2);
    }

    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.speed, color: cs.tertiary),
                  const Spacer(),
                  Text(
                    paceDisplay,
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    S.of(context)!.avgPaceLabel.toUpperCase(),
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.8,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.straighten, color: cs.primary),
                  const Spacer(),
                  Text(
                    distanceDisplay,
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    S.of(context)!.distanceLabel.toUpperCase(),
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.8,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── GPS Card ─────────────────────────────────────────────────────────────

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
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          s.gpsDistanceTracking,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: cardioState.gpsAcquiring
            ? Text(s.gpsAcquiring)
            : cardioState.gpsEnabled
                ? Text(s.gpsMetresTracked(
                    cardioState.gpsDistanceMeters.toStringAsFixed(0)))
                : Text(s.gpsSubtitle),
        secondary: Icon(
          Icons.gps_fixed,
          color: cardioState.gpsEnabled ? cs.primary : cs.outline,
        ),
        value: cardioState.gpsEnabled,
        onChanged: cardioState.isSaving ? null : (_) => onToggle(),
      ),
    );
  }
}

// ── Last Session Card ────────────────────────────────────────────────────

class _LastSessionCard extends StatelessWidget {
  const _LastSessionCard({required this.session});

  final dynamic session;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.lastSession.toUpperCase(),
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _GhostStat(
                icon: Icons.timer,
                value: session.duration.formatted,
              ),
              if (session.distanceMeters != null)
                _GhostStat(
                  icon: Icons.directions_run,
                  value: '${session.distanceMeters!.toStringAsFixed(0)} m',
                ),
              if (session.paceMinutesPerKm != null)
                _GhostStat(
                  icon: Icons.speed,
                  value: _formatPace(session.paceMinutesPerKm!),
                ),
              if (session.avgHeartRate != null)
                _GhostStat(
                  icon: Icons.favorite_outline,
                  value: '${session.avgHeartRate} bpm',
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatPace(double minutesPerKm) {
    final mins = minutesPerKm.floor();
    final secs = ((minutesPerKm - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')} min/km';
  }
}

// ── Action Button ────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? cs.primaryContainer : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? cs.onPrimaryContainer : cs.onSurface,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: tt.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: isPrimary ? cs.onPrimaryContainer : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ghost Stat ───────────────────────────────────────────────────────────

class _GhostStat extends StatelessWidget {
  const _GhostStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.outline),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
