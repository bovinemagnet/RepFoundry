import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
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
    });

    final activeZone = panelState.currentHeartRate != null && zoneConfig != null
        ? currentZoneFromConfig(panelState.currentHeartRate!, zoneConfig)
        : null;

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
        padding: const EdgeInsets.all(16),
        children: [
          // Caution badge
          if (profile.isCautionMode) ...[
            CautionBadge(profile: profile),
            const SizedBox(height: 12),
          ],

          // Current HR display
          _buildHrDisplay(context, panelState, activeZone),
          const SizedBox(height: 16),

          // Controls
          _buildControls(context, panelState, controller),
          const SizedBox(height: 24),

          // Recent chart (sliding window)
          if (panelState.readings.isNotEmpty) ...[
            _buildChartHeader(
              context,
              s.recentChart,
              chartWindow,
            ),
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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            HeartRateChart(
              readings: panelState.readings,
              zoneConfig: zoneConfig,
              showZoneBands: showZoneBands,
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

          // Session stats + time-in-zone
          if (panelState.readings.isNotEmpty) ...[
            _buildStats(context, panelState),
            const SizedBox(height: 12),
            if (zoneConfig != null)
              _buildTimeInZone(context, panelState, zoneConfig),
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

  Widget _buildChartHeader(
    BuildContext context,
    String title,
    int windowSeconds,
  ) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        DropdownButton<int>(
          value: windowSeconds,
          underline: const SizedBox.shrink(),
          isDense: true,
          items: ChartWindowNotifier.allowedValues
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(
                      v < 60 ? '${v}s' : '${v ~/ 60}m',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              ref.read(chartWindowProvider.notifier).setWindow(v);
            }
          },
        ),
      ],
    );
  }

  Widget _buildHrDisplay(
    BuildContext context,
    HeartRatePanelState panelState,
    CalculatedZone? zone,
  ) {
    final s = S.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  color: panelState.currentHeartRate != null
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.outline,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Text(
                  panelState.currentHeartRate?.toString() ?? '--',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: panelState.currentHeartRate != null
                        ? Theme.of(context).colorScheme.error
                        : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  s.bpmSuffix,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            if (zone != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(zone.colourValue).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  zone.displayLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Color(zone.colourValue),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
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
                  Text(
                    s.reconnecting,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (panelState.hrDeviceName != null) ...[
              const SizedBox(height: 4),
              Text(
                panelState.hrDeviceName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (panelState.isMonitoring) ...[
              const SizedBox(height: 4),
              Text(
                Duration(seconds: panelState.elapsedSeconds).formatted,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
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

  Widget _buildStats(BuildContext context, HeartRatePanelState panelState) {
    final s = S.of(context)!;
    final bpmValues = panelState.readings.map((r) => r.bpm);
    final avg = (bpmValues.reduce((a, b) => a + b) / bpmValues.length).round();
    final min = bpmValues.reduce((a, b) => a < b ? a : b);
    final max = bpmValues.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatColumn(label: s.statsAvg, value: '$avg'),
            _StatColumn(label: s.statsMin, value: '$min'),
            _StatColumn(label: s.statsMax, value: '$max'),
            _StatColumn(
              label: s.statsReadings,
              value: '${panelState.readings.length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInZone(
    BuildContext context,
    HeartRatePanelState panelState,
    ZoneConfiguration zoneConfig,
  ) {
    final s = S.of(context)!;
    final summary = calculateTimeInZones(panelState.readings, zoneConfig);
    final totalSeconds = panelState.readings.isNotEmpty
        ? panelState.readings.last.elapsed.inSeconds
        : 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.timeInZone,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ReliabilityIndicator(config: zoneConfig),
              ],
            ),
            const SizedBox(height: 8),
            for (final zone in zoneConfig.zones) ...[
              _ZoneTimeBar(
                zone: zone,
                duration: summary.zoneTime[zone.zoneNumber] ?? Duration.zero,
                totalSeconds: totalSeconds,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              s.moderateOrHigher(_formatDuration(summary.moderateOrHigher)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (summary.recoveryHrDrop != null) ...[
              const SizedBox(height: 4),
              Text(
                s.recoveryHrDrop(summary.recoveryHrDrop!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _showDevicePicker(HeartRatePanelController controller) async {
    final heartRateService = ref.read(heartRateServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final permissionOk = await heartRateService.checkAndRequestPermission();
    if (!permissionOk) {
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

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ZoneTimeBar extends StatelessWidget {
  const _ZoneTimeBar({
    required this.zone,
    required this.duration,
    required this.totalSeconds,
  });

  final CalculatedZone zone;
  final Duration duration;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final fraction = totalSeconds > 0 ? duration.inSeconds / totalSeconds : 0.0;
    final mins = duration.inMinutes;
    final secs = duration.inSeconds % 60;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              'Z${zone.zoneNumber}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(Color(zone.colourValue)),
                minHeight: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(
              '$mins:${secs.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
