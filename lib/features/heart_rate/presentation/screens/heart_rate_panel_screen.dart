import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/kinetic.dart';
import '../../../../core/widgets/sparkline_widget.dart';
import '../../../cardio/presentation/controllers/cardio_tracking_controller.dart';
import '../../../cardio/presentation/widgets/hr_device_picker_dialog.dart';
import '../../../cardio/presentation/widgets/hr_setup_guide_dialog.dart';
import 'package:hr_zones/hr_zones.dart';
import '../controllers/heart_rate_panel_controller.dart';
import '../controllers/heart_rate_panel_state.dart';
import '../providers/chart_window_provider.dart';
import '../providers/health_profile_provider.dart';
import '../providers/max_hr_alert_provider.dart';
import '../providers/zone_bands_provider.dart';
import '../providers/zone_configuration_provider.dart';
import '../widgets/caution_badge.dart';
import '../widgets/disclaimer_dialog.dart';
import '../widgets/health_profile_onboarding.dart';
import '../widgets/heart_rate_chart.dart';
import '../widgets/heart_rate_zones.dart';
import '../widgets/reliability_indicator.dart';
import '../widgets/symptom_report_button.dart';

class HeartRatePanelScreen extends ConsumerStatefulWidget {
  const HeartRatePanelScreen({super.key});

  @override
  ConsumerState<HeartRatePanelScreen> createState() =>
      _HeartRatePanelScreenState();
}

class _HeartRatePanelScreenState extends ConsumerState<HeartRatePanelScreen> {
  bool _initialised = false;
  AudioPlayer? _alertPlayer;
  DateTime? _lastMaxHrAlert;

  @override
  void initState() {
    super.initState();
    _alertPlayer = AudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onFirstVisit();

      // If cardio already has HR connected, sync it.
      final cardioState = ref.read(cardioTrackingProvider);
      final panelController = ref.read(heartRatePanelProvider.notifier);
      if (cardioState.hrConnected &&
          !ref.read(heartRatePanelProvider).hrConnected) {
        panelController.syncFromService();
        if (!ref.read(heartRatePanelProvider).isMonitoring) {
          panelController.startMonitoring();
        }
      }
    });
  }

  Future<void> _onFirstVisit() async {
    if (_initialised || !mounted) return;
    _initialised = true;

    final analytics = ref.read(hrAnalyticsReporterProvider);
    await showDisclaimerIfNeeded(context, analytics: analytics);

    if (!mounted) return;
    final profile = ref.read(healthProfileProvider);
    if (profile.age == null) {
      await showHealthProfileOnboarding(context);
    }
  }

  @override
  void dispose() {
    _alertPlayer?.dispose();
    super.dispose();
  }

  void _checkMaxHrAlert(HeartRatePanelState panelState) {
    final alertSettings = ref.read(maxHrAlertProvider);
    if (!alertSettings.isEnabled) return;
    if (!panelState.isMonitoring) return;

    final currentHr = panelState.currentHeartRate;
    if (currentHr == null) return;

    final zoneConfig = ref.read(zoneConfigurationProvider);
    if (zoneConfig == null || zoneConfig.zones.isEmpty) return;

    final maxBpm = zoneConfig.maxHr;
    if (currentHr < maxBpm) return;

    // Cooldown check.
    final now = DateTime.now();
    if (_lastMaxHrAlert != null &&
        now.difference(_lastMaxHrAlert!).inSeconds <
            alertSettings.cooldownSeconds) {
      return;
    }
    _lastMaxHrAlert = now;

    if (alertSettings.vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (alertSettings.soundEnabled) {
      _alertPlayer?.play(AssetSource('sounds/timer_complete.wav'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final panelState = ref.watch(heartRatePanelProvider);
    final controller = ref.read(heartRatePanelProvider.notifier);
    final profile = ref.watch(healthProfileProvider);
    final zoneConfig = ref.watch(zoneConfigurationProvider);
    final chartWindow = ref.watch(chartWindowProvider);
    final showZoneBands = ref.watch(zoneBandsProvider);

    ref.listen(heartRatePanelProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
      _checkMaxHrAlert(next);
    });

    final activeZone = panelState.currentHeartRate != null && zoneConfig != null
        ? currentZoneFromConfig(panelState.currentHeartRate!, zoneConfig)
        : null;

    final bpmStats = _calculateStats(panelState);

    // Determine the "peak" zone colour for HR trace — use zone 5 colour if
    // available, otherwise fall back to the theme error colour.
    final peakZoneColor = zoneConfig != null && zoneConfig.zones.isNotEmpty
        ? Color(zoneConfig.zones.last.color)
        : Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.heartRateTitle),
        actions: [
          if (panelState.hrConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              tooltip: s.disconnect,
              onPressed: () => controller.disconnectHeartRate(),
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: s.setupGuide,
            onPressed: () => showHrSetupGuide(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 96),
        children: [
          // Kinetic app header.
          const KineticAppHeader(),

          // Caution badge.
          if (profile.isCautionMode) ...[
            CautionBadge(profile: profile),
            const SizedBox(height: 12),
          ],

          // ── Hero BPM section ──────────────────────────────────────
          _HeroBpmSection(
            panelState: panelState,
            activeZone: activeZone,
            peakZoneColor: peakZoneColor,
          ),
          const SizedBox(height: 16),

          // Controls.
          _buildControls(context, panelState, controller),
          const SizedBox(height: 24),

          // ── EKG trace sparkline ───────────────────────────────────
          if (panelState.readings.isNotEmpty) ...[
            _EkgTrace(
              readings: panelState.readings,
              peakZoneColor: peakZoneColor,
            ),
            const SizedBox(height: 20),
          ],

          // ── Vitals bento grid ─────────────────────────────────────
          if (panelState.readings.isNotEmpty) ...[
            _MetricBentoGrid(
              avgBpm: bpmStats.avg,
              maxBpm: bpmStats.max,
              minBpm: bpmStats.min,
              readingCount: panelState.readings.length,
              profile: profile,
            ),
            const SizedBox(height: 24),
          ],

          // ── Workout Intensity Zones ───────────────────────────────
          if (zoneConfig != null && panelState.readings.isNotEmpty) ...[
            _ZonesSection(
              panelState: panelState,
              zoneConfig: zoneConfig,
            ),
            const SizedBox(height: 24),
          ],

          // ── HR Trend card with SparklineWidget ────────────────────
          if (panelState.readings.isNotEmpty) ...[
            _TrendChartSection(
              panelState: panelState,
              zoneConfig: zoneConfig,
              chartWindow: chartWindow,
              showZoneBands: showZoneBands,
              peakZoneColor: peakZoneColor,
              onWindowChanged: (v) =>
                  ref.read(chartWindowProvider.notifier).setWindow(v),
            ),
            const SizedBox(height: 16),
          ] else ...[
            HeartRateChart(
              readings: panelState.readings,
              zoneConfig: zoneConfig,
              showZoneBands: showZoneBands,
            ),
            const SizedBox(height: 16),
          ],

          // Symptom report button during active monitoring.
          if (panelState.isMonitoring) ...[
            SymptomReportButton(
              onStopRequested: controller.stopMonitoring,
              analytics: ref.read(hrAnalyticsReporterProvider),
            ),
            const SizedBox(height: 16),
          ],

          // ── Full Weekly Heart Report row (.srow style) ────────────
          if (panelState.readings.isNotEmpty) ...[
            _WeeklyReportRow(peakZoneColor: peakZoneColor),
            const SizedBox(height: 16),
          ],

          // Zone legend / no-profile prompt.
          if (zoneConfig != null) ...[
            HeartRateZoneLegend(
              config: zoneConfig,
              currentBpm: panelState.currentHeartRate,
            ),
          ] else ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(s.setAgeInSettings),
                subtitle: Text(s.setAgeInSettingsSubtitle),
                onTap: () => showHealthProfileOnboarding(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    HeartRatePanelState panelState,
    HeartRatePanelController controller,
  ) {
    final s = S.of(context)!;
    if (panelState.hrConnecting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!panelState.hrConnected) {
      return Center(
        child: FilledButton.icon(
          onPressed: () => _showDevicePicker(controller),
          icon: const Icon(Icons.bluetooth),
          label: Text(s.connectHrMonitor),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!panelState.isMonitoring)
          FilledButton.icon(
            onPressed: controller.startMonitoring,
            icon: const Icon(Icons.play_arrow),
            label: Text(s.start),
          )
        else
          OutlinedButton.icon(
            onPressed: controller.stopMonitoring,
            icon: const Icon(Icons.pause),
            label: Text(s.pause),
          ),
        if (panelState.readings.isNotEmpty) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: controller.resetReadings,
            icon: const Icon(Icons.refresh),
            label: Text(s.reset),
          ),
        ],
      ],
    );
  }

  _BpmStats _calculateStats(HeartRatePanelState panelState) {
    if (panelState.readings.isEmpty) {
      return const _BpmStats(avg: 0, min: 0, max: 0);
    }
    final bpmValues = panelState.readings.map((r) => r.bpm);
    return _BpmStats(
      avg: (bpmValues.reduce((a, b) => a + b) / bpmValues.length).round(),
      min: bpmValues.reduce((a, b) => a < b ? a : b),
      max: bpmValues.reduce((a, b) => a > b ? a : b),
    );
  }

  Future<void> _showDevicePicker(HeartRatePanelController controller) async {
    final heartRateService = ref.read(heartRateServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    var permissionOk = await heartRateService.checkAndRequestPermission();
    if (!permissionOk) {
      // Offer the system enable-Bluetooth dialog before giving up.
      permissionOk = await heartRateService.turnOnBluetooth();
    }
    if (!permissionOk) {
      if (!mounted) return;
      final s = S.of(context)!;
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
      await controller.connectAndStart(device.id, device.name);
    }
  }
}

class _BpmStats {
  final int avg;
  final int min;
  final int max;

  const _BpmStats({required this.avg, required this.min, required this.max});
}

// ── EKG Trace ────────────────────────────────────────────────────────────────

/// Renders the HR readings as a Kinetic-style sparkline trace — mirrors the
/// `ekg()` SVG function from screens.js (peak zone colour, 64 px tall).
class _EkgTrace extends StatelessWidget {
  const _EkgTrace({
    required this.readings,
    required this.peakZoneColor,
  });

  final List<HrReading> readings;
  final Color peakZoneColor;

  @override
  Widget build(BuildContext context) {
    final data = readings.map((r) => r.bpm.toDouble()).toList();
    return SizedBox(
      height: 64,
      child: SparklineWidget(
        data: data,
        lineColor: peakZoneColor,
        fillColor: peakZoneColor.withValues(alpha: 0.14),
        strokeWidth: 2.5,
      ),
    );
  }
}

// ── Hero BPM Section ──────────────────────────────────────────────────────────

class _HeroBpmSection extends StatelessWidget {
  const _HeroBpmSection({
    required this.panelState,
    required this.activeZone,
    required this.peakZoneColor,
  });

  final HeartRatePanelState panelState;
  final CalculatedZone? activeZone;
  final Color peakZoneColor;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasHr = panelState.currentHeartRate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Live Sensor" pill — peak-coloured when connected, per design spec.
        if (hasHr) ...[
          KineticPill(
            s.liveSensor,
            icon: Icons.sensors,
            variant: KineticPillVariant.ghost,
          ),
          const SizedBox(height: 14),
        ],

        // Large mono BPM hero — 64/800, tight tracking (-0.04em).
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              panelState.currentHeartRate?.toString() ?? '--',
              style: KineticText.mono(
                size: 64,
                weight: FontWeight.w800,
                letterSpacing: -2.56, // approx -0.04em at 64px
                color: hasHr ? cs.onSurface : cs.outline,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                s.bpmSuffix.toUpperCase(),
                style: KineticText.mono(
                  size: 16,
                  weight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),

        // Zone description — zone name rendered in its own colour.
        if (activeZone != null) ...[
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Currently in the '),
                TextSpan(
                  text: activeZone!.displayLabel,
                  style: TextStyle(
                    color: Color(activeZone!.color),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' zone.'),
              ],
            ),
          ),
        ],

        // Reconnecting indicator.
        if (panelState.hrReconnecting) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(s.reconnecting, style: tt.bodySmall),
            ],
          ),
        ],

        // Device name.
        if (panelState.hrDeviceName != null) ...[
          const SizedBox(height: 4),
          Text(
            panelState.hrDeviceName!,
            style: KineticText.mono(
              size: 11,
              weight: FontWeight.w600,
              letterSpacing: 0.5,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],

        // Elapsed time.
        if (panelState.isMonitoring) ...[
          const SizedBox(height: 2),
          Text(
            Duration(seconds: panelState.elapsedSeconds).formatted,
            style: KineticText.mono(
              size: 11,
              weight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Vitals Bento Grid ─────────────────────────────────────────────────────────

class _MetricBentoGrid extends StatelessWidget {
  const _MetricBentoGrid({
    required this.avgBpm,
    required this.maxBpm,
    required this.minBpm,
    required this.readingCount,
    required this.profile,
  });

  final int avgBpm;
  final int maxBpm;
  final int minBpm;
  final int readingCount;
  final dynamic profile;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      children: [
        KineticStatTile(
          label: s.statsAvg,
          value: '$avgBpm',
          unit: s.bpmSuffix,
        ),
        _VitalTile(
          icon: Icons.bolt,
          iconColor: cs.tertiary,
          label: s.statsMax,
          value: '$maxBpm',
          subtitle: s.reachedAgo,
        ),
        _VitalTile(
          icon: Icons.timer,
          iconColor: cs.secondary,
          label: s.statsMin,
          value: '$minBpm',
          subtitle: s.bpmSuffix,
        ),
        _VitalTile(
          icon: Icons.waves,
          iconColor: cs.onSurfaceVariant,
          label: s.statsReadings,
          value: '$readingCount',
          subtitle: '',
        ),
      ],
    );
  }
}

/// A single vitals tile — icon + uppercase mono label + big mono value.
/// Mirrors the `.stat` component from rf.css.
class _VitalTile extends StatelessWidget {
  const _VitalTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: KineticText.mono(
                  size: 10.5,
                  weight: FontWeight.w600,
                  letterSpacing: 1.7,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: KineticText.mono(
              size: 26,
              weight: FontWeight.w700,
              letterSpacing: -0.8,
              color: cs.onSurface,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Workout Intensity Zones ───────────────────────────────────────────────────

class _ZonesSection extends StatelessWidget {
  const _ZonesSection({
    required this.panelState,
    required this.zoneConfig,
  });

  final HeartRatePanelState panelState;
  final ZoneConfiguration zoneConfig;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final summary = calculateTimeInZones(panelState.readings, zoneConfig);
    final elapsed = Duration(seconds: panelState.elapsedSeconds).formatted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header — display style preserves mixed-case localised string.
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                s.workoutIntensityZones,
                style: KineticText.display(
                  size: 16,
                  weight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            Text(
              s.sessionDuration(elapsed).toUpperCase(),
              style: KineticText.mono(
                size: 9,
                weight: FontWeight.w600,
                letterSpacing: 0.5,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Reliability indicator.
        Row(
          children: [
            const Spacer(),
            ReliabilityIndicator(config: zoneConfig),
          ],
        ),
        const SizedBox(height: 8),

        // Zone rows card — mirrors rf.css .card + .zone structure.
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            children: [
              for (final zone in zoneConfig.zones.reversed)
                _ZoneRow(
                  zone: zone,
                  duration: summary.durationInZone(zone.zoneNumber),
                ),
            ],
          ),
        ),

        // Summary stats.
        const SizedBox(height: 8),
        Text(
          s.moderateOrHigher(_formatDuration(summary.moderateOrHigherDuration)),
          style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (summary.recoveryHrDrop != null) ...[
          const SizedBox(height: 4),
          Text(
            s.recoveryHrDrop(summary.recoveryHrDrop!),
            style: tt.bodySmall,
          ),
        ],
      ],
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

/// A single zone row inside the zones card.
/// Renders: name (mono, zone colour) + time | proportional fill bar + bpm range.
/// Mirrors rf.css `.zone`, `.zone__top`, `.zone__track`, `.zone__fill`, `.zone__bpm`.
class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.zone,
    required this.duration,
  });

  final CalculatedZone zone;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final zoneColor = Color(zone.color);
    final mins = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    final timeLabel = '$mins:${secs.toString().padLeft(2, '0')}';

    // Compute fill fraction: cap at 100% of elapsed for proportional rendering.
    final totalSecs = duration.inSeconds;
    // Use a relative fill based on the time displayed. We normalise against a
    // nominal maximum (e.g. the largest zone time in the session is not known
    // here, so we use the raw seconds capped at 30 minutes as the scale).
    final fillFraction = (totalSecs / 1800).clamp(0.0, 1.0);

    final bpmRange = zone.upperBound != null
        ? '${zone.lowerBound}–${zone.upperBound} BPM'
        : '${zone.lowerBound}+ BPM';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: zone name + time.
          Row(
            children: [
              Expanded(
                child: Text(
                  'Zone ${zone.zoneNumber} · ${zone.descriptiveLabel}'
                      .toUpperCase(),
                  style: KineticText.mono(
                    size: 10.5,
                    weight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: zoneColor,
                  ),
                ),
              ),
              Text(
                timeLabel,
                style: KineticText.mono(
                  size: 10.5,
                  weight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Proportional fill bar — track = surfaceContainer, fill = zone colour.
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Container(color: cs.surfaceContainer),
                  FractionallySizedBox(
                    widthFactor: fillFraction,
                    child: Container(color: zoneColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // BPM range.
          Text(
            bpmRange,
            style: KineticText.mono(
              size: 10,
              weight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── HR Trend Chart Section ────────────────────────────────────────────────────

class _TrendChartSection extends StatelessWidget {
  const _TrendChartSection({
    required this.panelState,
    required this.zoneConfig,
    required this.chartWindow,
    required this.showZoneBands,
    required this.peakZoneColor,
    required this.onWindowChanged,
  });

  final HeartRatePanelState panelState;
  final ZoneConfiguration? zoneConfig;
  final int chartWindow;
  final bool showZoneBands;
  final Color peakZoneColor;
  final ValueChanged<int> onWindowChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Derive sparkline data from all readings for the full-session trace.
    final sparkData = panelState.readings.map((r) => r.bpm.toDouble()).toList();
    final maxBpm =
        sparkData.isNotEmpty ? sparkData.reduce((a, b) => a > b ? a : b) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + "Max NNN" ghost pill.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.heartRateTrend,
                      style: KineticText.display(
                        size: 15,
                        weight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.heartRateTrendSubtitle,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (maxBpm > 0)
                KineticPill(
                  'Max ${maxBpm.toInt()}',
                  variant: KineticPillVariant.ghost,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Recent windowed chart.
          Text(
            s.recentChart,
            style: KineticText.mono(
              size: 10,
              weight: FontWeight.w600,
              letterSpacing: 1.7,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          // Window selector inline.
          Align(
            alignment: Alignment.centerRight,
            child: DropdownButton<int>(
              value: chartWindow,
              underline: const SizedBox.shrink(),
              isDense: true,
              items: ChartWindowNotifier.allowedValues
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(
                          v < 60 ? '${v}s' : '${v ~/ 60}m',
                          style: tt.bodySmall,
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onWindowChanged(v);
              },
            ),
          ),
          HeartRateChart(
            readings: panelState.readings,
            zoneConfig: zoneConfig,
            windowSeconds: chartWindow,
            showZoneBands: showZoneBands,
          ),
          const SizedBox(height: 16),

          // Full-session sparkline (Kinetic style: peak-coloured).
          Text(
            s.fullSessionChart,
            style: KineticText.mono(
              size: 10,
              weight: FontWeight.w600,
              letterSpacing: 1.7,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (sparkData.length >= 2)
            SizedBox(
              height: 80,
              child: SparklineWidget(
                data: sparkData,
                lineColor: peakZoneColor,
                fillColor: peakZoneColor.withValues(alpha: 0.18),
                strokeWidth: 2.5,
              ),
            )
          else
            HeartRateChart(
              readings: panelState.readings,
              zoneConfig: zoneConfig,
              showZoneBands: showZoneBands,
            ),
        ],
      ),
    );
  }
}

// ── Full Weekly Heart Report Row ──────────────────────────────────────────────

/// .srow-style list row that links to the full weekly heart report.
/// Uses a peak-tinted icon tile with the `monitor_heart` icon.
class _WeeklyReportRow extends StatelessWidget {
  const _WeeklyReportRow({required this.peakZoneColor});

  final Color peakZoneColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: peakZoneColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.monitor_heart, size: 22, color: peakZoneColor),
        ),
        title: Text(
          'Full Weekly Heart Report',
          style: KineticText.display(
            size: 14,
            weight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          'Cardiovascular adaptation, last 7 days',
          style: GoogleFonts.manrope(
            fontSize: 11.5,
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: cs.onSurfaceVariant,
        ),
        onTap: () {
          // Navigation to weekly report — not yet implemented in this release.
        },
      ),
    );
  }
}
