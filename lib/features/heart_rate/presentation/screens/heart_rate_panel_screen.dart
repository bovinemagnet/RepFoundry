import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/providers.dart';
import '../../../cardio/presentation/controllers/cardio_tracking_controller.dart';
import '../../../cardio/presentation/widgets/hr_device_picker_dialog.dart';
import '../../../cardio/presentation/widgets/hr_setup_guide_dialog.dart';
import '../../../settings/presentation/providers/user_age_provider.dart';
import '../controllers/heart_rate_panel_controller.dart';
import '../controllers/heart_rate_panel_state.dart';
import '../widgets/heart_rate_chart.dart';
import '../widgets/heart_rate_zones.dart';

class HeartRatePanelScreen extends ConsumerStatefulWidget {
  const HeartRatePanelScreen({super.key});

  @override
  ConsumerState<HeartRatePanelScreen> createState() =>
      _HeartRatePanelScreenState();
}

class _HeartRatePanelScreenState extends ConsumerState<HeartRatePanelScreen> {
  @override
  void initState() {
    super.initState();
    // If cardio already has HR connected, sync it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  @override
  Widget build(BuildContext context) {
    final panelState = ref.watch(heartRatePanelProvider);
    final controller = ref.read(heartRatePanelProvider.notifier);
    final userAge = ref.watch(userAgeProvider);
    final maxHr = userAge != null ? estimateMaxHeartRate(userAge) : null;

    ref.listen(heartRatePanelProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate'),
        actions: [
          if (panelState.hrConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              tooltip: 'Disconnect',
              onPressed: () => controller.disconnectHeartRate(),
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Setup guide',
            onPressed: () => showHrSetupGuide(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current HR display
          _buildHrDisplay(context, panelState, maxHr),
          const SizedBox(height: 16),

          // Controls
          _buildControls(context, panelState, controller),
          const SizedBox(height: 24),

          // HR chart
          HeartRateChart(
            readings: panelState.readings,
            maxHr: maxHr,
          ),
          const SizedBox(height: 16),

          // Session stats
          if (panelState.readings.isNotEmpty) ...[
            _buildStats(context, panelState),
            const SizedBox(height: 16),
          ],

          // Zone legend
          if (maxHr != null) ...[
            HeartRateZoneLegend(
              maxHr: maxHr,
              currentBpm: panelState.currentHeartRate,
            ),
          ] else ...[
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Set your age in Settings'),
                subtitle: Text(
                  'Heart rate training zones will appear when your age is configured.',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHrDisplay(
    BuildContext context,
    HeartRatePanelState panelState,
    int? maxHr,
  ) {
    final zone = panelState.currentHeartRate != null && maxHr != null
        ? currentZone(panelState.currentHeartRate!, maxHr)
        : null;

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
                  'bpm',
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
                  color: zone.colour.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  zone.name,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: zone.colour,
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
                    'Reconnecting...',
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
    if (panelState.hrConnecting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!panelState.hrConnected) {
      return Center(
        child: FilledButton.icon(
          onPressed: () => _showDevicePicker(controller),
          icon: const Icon(Icons.bluetooth),
          label: const Text('Connect HR Monitor'),
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
            label: const Text('Start'),
          )
        else
          OutlinedButton.icon(
            onPressed: controller.stopMonitoring,
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          ),
        if (panelState.readings.isNotEmpty) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: controller.resetReadings,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
        ],
      ],
    );
  }

  Widget _buildStats(BuildContext context, HeartRatePanelState panelState) {
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
            _StatColumn(label: 'Avg', value: '$avg'),
            _StatColumn(label: 'Min', value: '$min'),
            _StatColumn(label: 'Max', value: '$max'),
            _StatColumn(
              label: 'Readings',
              value: '${panelState.readings.length}',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDevicePicker(HeartRatePanelController controller) async {
    final heartRateService = ref.read(heartRateServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final permissionOk = await heartRateService.checkAndRequestPermission();
    if (!permissionOk) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Bluetooth is not available. Ensure Bluetooth is turned on.',
          ),
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
