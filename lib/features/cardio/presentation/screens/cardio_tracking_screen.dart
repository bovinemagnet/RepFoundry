import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/providers.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../controllers/cardio_tracking_controller.dart';
import '../controllers/cardio_tracking_state.dart';
import '../widgets/hr_device_picker_dialog.dart';

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
    final cardioState = ref.watch(cardioTrackingProvider);
    final controller = ref.read(cardioTrackingProvider.notifier);
    final exercisesAsync = ref.watch(_cardioExercisesProvider);

    ref.listen(cardioTrackingProvider, (prev, next) {
      if (next.savedSuccessfully && !(prev?.savedSuccessfully ?? false)) {
        _distanceController.clear();
        _inclineController.clear();
        _heartRateController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cardio session saved')),
        );
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Cardio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Exercise selector
          exercisesAsync.when(
            data: (exercises) => DropdownButtonFormField<String>(
              key: ValueKey(cardioState.selectedExerciseId),
              decoration: const InputDecoration(
                labelText: 'Exercise',
                border: OutlineInputBorder(),
              ),
              initialValue: cardioState.selectedExerciseId,
              items: exercises
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                final ex = exercises.firstWhere((e) => e.id == id);
                controller.selectExercise(id, ex.name);
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Failed to load exercises'),
          ),
          const SizedBox(height: 16),

          // Ghost card — last session
          if (cardioState.lastSession != null) ...[
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last session',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _GhostStat(
                          icon: Icons.timer,
                          value: cardioState.lastSession!.duration.formatted,
                        ),
                        if (cardioState.lastSession!.distanceMeters !=
                            null) ...[
                          const SizedBox(width: 16),
                          _GhostStat(
                            icon: Icons.directions_run,
                            value:
                                '${cardioState.lastSession!.distanceMeters!.toStringAsFixed(0)} m',
                          ),
                        ],
                        if (cardioState.lastSession!.paceMinutesPerKm !=
                            null) ...[
                          const SizedBox(width: 16),
                          _GhostStat(
                            icon: Icons.speed,
                            value: _formatPace(
                                cardioState.lastSession!.paceMinutesPerKm!),
                          ),
                        ],
                        if (cardioState.lastSession!.avgHeartRate != null) ...[
                          const SizedBox(width: 16),
                          _GhostStat(
                            icon: Icons.favorite_outline,
                            value:
                                '${cardioState.lastSession!.avgHeartRate} bpm',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Timer display
          Center(
            child: Text(
              Duration(seconds: cardioState.elapsedSeconds).formatted,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cardioState.isRunning
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontFeatures: const [
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Start / Pause / Reset buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!cardioState.isRunning) ...[
                FilledButton.icon(
                  onPressed: controller.start,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                      cardioState.elapsedSeconds == 0 ? 'Start' : 'Resume'),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: controller.pause,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
              ],
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed:
                    cardioState.elapsedSeconds > 0 ? controller.reset : null,
                icon: const Icon(Icons.stop),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // GPS toggle
          Card(
            child: SwitchListTile(
              title: const Text('GPS Distance Tracking'),
              subtitle: cardioState.gpsAcquiring
                  ? const Text('Acquiring signal...')
                  : cardioState.gpsEnabled
                      ? Text(
                          '${cardioState.gpsDistanceMeters.toStringAsFixed(0)} m tracked')
                      : const Text('Track distance via GPS for outdoor runs'),
              secondary: Icon(
                Icons.gps_fixed,
                color: cardioState.gpsEnabled
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              value: cardioState.gpsEnabled,
              onChanged:
                  cardioState.isSaving ? null : (_) => controller.toggleGps(),
            ),
          ),

          // GPS live distance + pace
          if (cardioState.gpsEnabled && cardioState.gpsDistanceMeters > 0) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Row(
                children: [
                  Text(
                    '${(cardioState.gpsDistanceMeters / 1000).toStringAsFixed(2)} km',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  if (cardioState.elapsedSeconds > 0) ...[
                    const SizedBox(width: 16),
                    Text(
                      _formatPace((cardioState.elapsedSeconds / 60) /
                          (cardioState.gpsDistanceMeters / 1000)),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Heart Rate Monitor card
          _buildHeartRateCard(context, cardioState, controller),
          const SizedBox(height: 12),

          // Distance (manual — hidden when GPS is active)
          if (!cardioState.gpsEnabled) ...[
            TextField(
              controller: _distanceController,
              decoration: const InputDecoration(
                labelText: 'Distance (metres)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_run),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),

            // Real-time pace display
            if (_computedPace != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  'Pace: $_computedPace',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],

          // Incline
          TextField(
            controller: _inclineController,
            decoration: const InputDecoration(
              labelText: 'Incline (%)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.trending_up),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          // Heart rate (manual — hidden when HR monitor connected)
          if (!cardioState.hrConnected) ...[
            TextField(
              controller: _heartRateController,
              decoration: const InputDecoration(
                labelText: 'Avg Heart Rate (bpm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.favorite_outline),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: cardioState.elapsedSeconds > 0 &&
                    cardioState.selectedExerciseId != null &&
                    !cardioState.isSaving
                ? () => controller.save(
                      distanceMeters: double.tryParse(_distanceController.text),
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
            label: const Text('Save Session'),
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
    if (cardioState.hrConnecting) {
      return Card(
        child: ListTile(
          leading: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title:
              Text('Connecting to ${cardioState.hrDeviceName ?? "device"}...'),
        ),
      );
    }

    if (cardioState.hrConnected) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Theme.of(context).colorScheme.error,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    cardioState.currentHeartRate != null
                        ? '${cardioState.currentHeartRate}'
                        : '--',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'bpm',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        cardioState.hrDeviceName ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: () => controller.disconnectHeartRate(),
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Disconnected state
    return Card(
      child: ListTile(
        leading: const Icon(Icons.bluetooth),
        title: const Text('Heart Rate Monitor'),
        subtitle: const Text('Connect a BLE heart rate strap'),
        trailing: FilledButton.tonal(
          onPressed: cardioState.isSaving
              ? null
              : () => _showHrDevicePicker(controller),
          child: const Text('Connect'),
        ),
      ),
    );
  }

  Future<void> _showHrDevicePicker(
    CardioTrackingController controller,
  ) async {
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

class _GhostStat extends StatelessWidget {
  const _GhostStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
