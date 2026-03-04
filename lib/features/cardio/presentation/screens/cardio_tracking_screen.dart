import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cardio_session.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../../core/providers.dart';
import '../../../../core/extensions/datetime_extensions.dart';

class _CardioState {
  final bool isRunning;
  final int elapsedSeconds;
  final String? selectedExerciseId;
  final String? selectedExerciseName;

  const _CardioState({
    this.isRunning = false,
    this.elapsedSeconds = 0,
    this.selectedExerciseId,
    this.selectedExerciseName,
  });

  _CardioState copyWith({
    bool? isRunning,
    int? elapsedSeconds,
    String? selectedExerciseId,
    String? selectedExerciseName,
  }) {
    return _CardioState(
      isRunning: isRunning ?? this.isRunning,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      selectedExerciseId:
          selectedExerciseId ?? this.selectedExerciseId,
      selectedExerciseName:
          selectedExerciseName ?? this.selectedExerciseName,
    );
  }
}

class _CardioNotifier extends StateNotifier<_CardioState> {
  Timer? _timer;

  _CardioNotifier() : super(const _CardioState());

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state =
          state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    state = const _CardioState();
  }

  void selectExercise(String id, String name) {
    state = state.copyWith(
      selectedExerciseId: id,
      selectedExerciseName: name,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final _cardioProvider =
    StateNotifierProvider.autoDispose<_CardioNotifier, _CardioState>(
  (ref) => _CardioNotifier(),
);

final _cardioExercisesProvider =
    FutureProvider.autoDispose<List<Exercise>>((ref) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.getExercisesByMuscleGroup(MuscleGroup.cardio);
});

class CardioTrackingScreen extends ConsumerStatefulWidget {
  const CardioTrackingScreen({super.key});

  @override
  ConsumerState<CardioTrackingScreen> createState() =>
      _CardioTrackingScreenState();
}

class _CardioTrackingScreenState
    extends ConsumerState<CardioTrackingScreen> {
  final _distanceController = TextEditingController();
  final _heartRateController = TextEditingController();

  @override
  void dispose() {
    _distanceController.dispose();
    _heartRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardioState = ref.watch(_cardioProvider);
    final notifier = ref.read(_cardioProvider.notifier);
    final exercisesAsync = ref.watch(_cardioExercisesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cardio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Exercise selector
          exercisesAsync.when(
            data: (exercises) => DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Exercise',
                border: OutlineInputBorder(),
              ),
              value: cardioState.selectedExerciseId,
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
                notifier.selectExercise(id, ex.name);
              },
            ),
            loading: () =>
                const LinearProgressIndicator(),
            error: (_, __) => const Text('Failed to load exercises'),
          ),
          const SizedBox(height: 24),

          // Timer display
          Center(
            child: Text(
              Duration(seconds: cardioState.elapsedSeconds)
                  .formatted,
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(
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
                  onPressed: notifier.start,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(cardioState.elapsedSeconds == 0
                      ? 'Start'
                      : 'Resume'),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: notifier.pause,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
              ],
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: cardioState.elapsedSeconds > 0
                    ? notifier.reset
                    : null,
                icon: const Icon(Icons.stop),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Optional stats
          TextField(
            controller: _distanceController,
            decoration: const InputDecoration(
              labelText: 'Distance (meters)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions_run),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _heartRateController,
            decoration: const InputDecoration(
              labelText: 'Avg Heart Rate (bpm)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.favorite_outline),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: cardioState.elapsedSeconds > 0 &&
                    cardioState.selectedExerciseId != null
                ? () => _saveSession(context, cardioState)
                : null,
            icon: const Icon(Icons.save),
            label: const Text('Save Session'),
          ),
        ],
      ),
    );
  }

  void _saveSession(
    BuildContext context,
    _CardioState cardioState,
  ) {
    final session = CardioSession.create(
      workoutId: 'standalone',
      exerciseId: cardioState.selectedExerciseId!,
      durationSeconds: cardioState.elapsedSeconds,
      distanceMeters:
          double.tryParse(_distanceController.text),
      avgHeartRate:
          int.tryParse(_heartRateController.text),
    );

    ref.read(_cardioProvider.notifier).reset();
    _distanceController.clear();
    _heartRateController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cardio session saved: ${Duration(seconds: session.durationSeconds).formatted}',
        ),
      ),
    );
  }
}
