import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/providers.dart';
import '../../../cardio/presentation/controllers/cardio_tracking_controller.dart';
import '../../../cardio/presentation/widgets/hr_device_picker_dialog.dart';
import '../../../cardio/presentation/widgets/hr_setup_guide_dialog.dart';
import '../../domain/time_in_zone_calculator.dart';
import '../../domain/zone_calculator.dart';
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

    final maxBpm = zoneConfig.zones.last.upperBpm;
    if (currentHr < maxBpm) return;

    // Cooldown check
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // Caution badge
          if (profile.isCautionMode) ...[
            CautionBadge(profile: profile),
            const SizedBox(height: 12),
          ],

          // ── Hero BPM section ───────────────────────────────────
          _HeroBpmSection(
            panelState: panelState,
            activeZone: activeZone,
          ),
          const SizedBox(height: 16),

          // Controls
          _buildControls(context, panelState, controller),
          const SizedBox(height: 24),

          // ── Bento metric grid ──────────────────────────────────
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

          // ── Workout Intensity Zones ────────────────────────────
          if (zoneConfig != null && panelState.readings.isNotEmpty) ...[
            _ZonesSection(
              panelState: panelState,
              zoneConfig: zoneConfig,
            ),
            const SizedBox(height: 24),
          ],

          // ── Heart Rate Trend chart ─────────────────────────────
          if (panelState.readings.isNotEmpty) ...[
            _TrendChartSection(
              panelState: panelState,
              zoneConfig: zoneConfig,
              chartWindow: chartWindow,
              showZoneBands: showZoneBands,
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

          // Symptom report button during active monitoring
          if (panelState.isMonitoring) ...[
            SymptomReportButton(
              onStopRequested: controller.stopMonitoring,
              analytics: ref.read(hrAnalyticsReporterProvider),
            ),
            const SizedBox(height: 16),
          ],

          // Zone legend
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

    final permissionOk = await heartRateService.checkAndRequestPermission();
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

// ── Hero BPM Section ─────────────────────────────────────────────────────

class _HeroBpmSection extends StatelessWidget {
  const _HeroBpmSection({
    required this.panelState,
    required this.activeZone,
  });

  final HeartRatePanelState panelState;
  final CalculatedZone? activeZone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasHr = panelState.currentHeartRate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live sensor badge
        if (hasHr)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, size: 12, color: cs.error),
                const SizedBox(width: 6),
                Text(
                  s.liveSensor.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    color: cs.error,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),

        // Large BPM display
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              panelState.currentHeartRate?.toString() ?? '--',
              style: tt.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 72,
                height: 1.0,
                color: hasHr ? cs.onSurface : cs.outline,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s.bpmSuffix.toUpperCase(),
              style: tt.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Zone description
        if (activeZone != null) ...[
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              children: [
                const TextSpan(text: 'Currently in the '),
                TextSpan(
                  text: activeZone!.displayLabel,
                  style: TextStyle(
                    color: Color(activeZone!.colourValue),
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const TextSpan(text: ' zone.'),
              ],
            ),
          ),
        ],

        // Reconnecting indicator
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

        // Device name
        if (panelState.hrDeviceName != null) ...[
          const SizedBox(height: 4),
          Text(
            panelState.hrDeviceName!,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],

        // Elapsed time
        if (panelState.isMonitoring) ...[
          const SizedBox(height: 2),
          Text(
            Duration(seconds: panelState.elapsedSeconds).formatted,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Bento Metric Grid ────────────────────────────────────────────────────

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
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _BentoCard(
          icon: Icons.air,
          iconColor: cs.primary,
          label: s.statsAvg.toUpperCase(),
          value: '$avgBpm',
          subtitle: s.bpmSuffix,
        ),
        _BentoCard(
          icon: Icons.bolt,
          iconColor: cs.tertiary,
          label: s.statsMax.toUpperCase(),
          value: '$maxBpm',
          subtitle: s.reachedAgo,
        ),
        _BentoCard(
          icon: Icons.timer,
          iconColor: cs.secondary,
          label: s.statsMin.toUpperCase(),
          value: '$minBpm',
          subtitle: s.bpmSuffix,
        ),
        _BentoCard(
          icon: Icons.waves,
          iconColor: const Color(0xFF8354F4),
          label: s.statsReadings.toUpperCase(),
          value: '$readingCount',
          subtitle: '',
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
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
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: iconColor),
          const Spacer(),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty)
            Text(
              subtitle!,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Zones Section ────────────────────────────────────────────────────────

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

    // Map zone number to theme-appropriate colours (Z5→Z1).
    final zoneThemeColours = {
      5: cs.error,
      4: cs.tertiary,
      3: cs.primary,
      2: cs.secondary,
      1: cs.outline,
    };

    final zoneIcons = {
      5: Icons.local_fire_department,
      4: Icons.speed,
      3: Icons.directions_run,
      2: Icons.fitness_center,
      1: Icons.self_improvement,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                s.workoutIntensityZones,
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              s.sessionDuration(elapsed).toUpperCase(),
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Reliability indicator
        Row(
          children: [
            const Spacer(),
            ReliabilityIndicator(config: zoneConfig),
          ],
        ),
        const SizedBox(height: 8),

        // Zone cards (Z5 → Z1, highest first)
        for (final zone in zoneConfig.zones.reversed) ...[
          _ZoneCard(
            zone: zone,
            duration: summary.zoneTime[zone.zoneNumber] ?? Duration.zero,
            accentColour:
                zoneThemeColours[zone.zoneNumber] ?? Color(zone.colourValue),
            backgroundIcon: zoneIcons[zone.zoneNumber] ?? Icons.favorite,
          ),
          const SizedBox(height: 8),
        ],

        // Summary stats
        const SizedBox(height: 4),
        Text(
          s.moderateOrHigher(_formatDuration(summary.moderateOrHigher)),
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

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.duration,
    required this.accentColour,
    required this.backgroundIcon,
  });

  final CalculatedZone zone;
  final Duration duration;
  final Color accentColour;
  final IconData backgroundIcon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mins = duration.inMinutes;
    final secs = duration.inSeconds % 60;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColour, width: 4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background icon
          Positioned(
            right: -4,
            bottom: -4,
            child: Icon(
              backgroundIcon,
              size: 56,
              color: cs.onSurface.withValues(alpha: 0.05),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zone ${zone.zoneNumber}: ${zone.descriptiveLabel}'
                      .toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    color: accentColour,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$mins:${secs.toString().padLeft(2, '0')}',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${zone.lowerBpm}–${zone.upperBpm} BPM',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trend Chart Section ──────────────────────────────────────────────────

class _TrendChartSection extends StatelessWidget {
  const _TrendChartSection({
    required this.panelState,
    required this.zoneConfig,
    required this.chartWindow,
    required this.showZoneBands,
    required this.onWindowChanged,
  });

  final HeartRatePanelState panelState;
  final ZoneConfiguration? zoneConfig;
  final int chartWindow;
  final bool showZoneBands;
  final ValueChanged<int> onWindowChanged;

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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.heartRateTrend,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
              // Window selector
              DropdownButton<int>(
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
            ],
          ),
          const SizedBox(height: 16),

          // Recent chart (windowed)
          Text(
            s.recentChart,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          HeartRateChart(
            readings: panelState.readings,
            zoneConfig: zoneConfig,
            windowSeconds: chartWindow,
            showZoneBands: showZoneBands,
          ),
          const SizedBox(height: 20),

          // Full session chart
          Text(
            s.fullSessionChart,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
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
