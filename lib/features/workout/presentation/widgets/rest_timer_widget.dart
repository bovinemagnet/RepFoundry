import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/datetime_extensions.dart';

/// Provider that holds the current rest timer state in seconds remaining.
/// A value of null means the timer is not running.
final _restTimerProvider =
    StateNotifierProvider<_RestTimerNotifier, int?>((ref) {
  return _RestTimerNotifier();
});

class _RestTimerNotifier extends StateNotifier<int?> {
  Timer? _timer;

  _RestTimerNotifier() : super(null);

  void start(int seconds) {
    _timer?.cancel();
    state = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state == null || state! <= 0) {
        t.cancel();
        state = null;
      } else {
        state = state! - 1;
      }
    });
  }

  void stop() {
    _timer?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Displays a rest timer with quick-start buttons.
class RestTimerWidget extends ConsumerWidget {
  const RestTimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secondsLeft = ref.watch(_restTimerProvider);
    final notifier = ref.read(_restTimerProvider.notifier);
    final isRunning = secondsLeft != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: isRunning
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          if (isRunning) ...[
            Text(
              Duration(seconds: secondsLeft).formatted,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontFeatures: const [
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: notifier.stop,
              tooltip: 'Stop timer',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ] else
            Text(
              'Rest Timer',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          const Spacer(),
          for (final seconds in const [60, 90, 120, 180])
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: ActionChip(
                label: Text(
                    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'),
                onPressed: () => notifier.start(seconds),
                padding: EdgeInsets.zero,
                labelStyle: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }
}
