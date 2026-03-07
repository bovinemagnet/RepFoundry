import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../settings/presentation/providers/rest_timer_settings_provider.dart';

/// Provider that holds the current rest timer state in seconds remaining.
/// A value of null means the timer is not running.
final restTimerProvider = StateNotifierProvider<RestTimerNotifier, int?>((ref) {
  return RestTimerNotifier();
});

class RestTimerNotifier extends StateNotifier<int?> {
  Timer? _timer;

  RestTimerNotifier() : super(null);

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
class RestTimerWidget extends ConsumerStatefulWidget {
  const RestTimerWidget({super.key});

  @override
  ConsumerState<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends ConsumerState<RestTimerWidget> {
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _onTimerComplete() {
    final settings = ref.read(restTimerSettingsProvider);
    if (settings.vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (settings.soundEnabled) {
      _audioPlayer?.play(AssetSource('sounds/timer_complete.wav'));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(restTimerProvider, (previous, next) {
      if (previous != null && next == null) {
        _onTimerComplete();
      }
    });

    final secondsLeft = ref.watch(restTimerProvider);
    final notifier = ref.read(restTimerProvider.notifier);
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
              tooltip: S.of(context)!.stopTimer,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ] else
            Text(
              S.of(context)!.restTimer,
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
