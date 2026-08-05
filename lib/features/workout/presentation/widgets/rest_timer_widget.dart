import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../settings/presentation/providers/rest_timer_settings_provider.dart';
import '../../../trainer/domain/trainer_event.dart';
import '../../../trainer/presentation/providers/coach_announcements.dart';
import '../../../trainer/presentation/providers/trainer_event_bus.dart';

/// Provider that holds the current rest timer state in seconds remaining.
/// A value of null means the timer is not running.
final restTimerProvider = NotifierProvider<RestTimerNotifier, int?>(
  RestTimerNotifier.new,
);

class RestTimerNotifier extends Notifier<int?> {
  Timer? _timer;
  bool _completedNaturally = false;
  Duration? _lastRestDuration;

  /// True when the most recent transition to null was the timer running out
  /// rather than a manual stop — only then should the alert fire.
  bool get completedNaturally => _completedNaturally;

  /// What the most recent rest was set to run for, so the chime-suppression
  /// rule and the coach's quote rule read the same number.
  Duration? get lastRestDuration => _lastRestDuration;

  @override
  int? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void start(int seconds) {
    _timer?.cancel();
    _lastRestDuration = Duration(seconds: seconds);
    state = seconds;
    ref
        .read(trainerEventBusProvider)
        .emit(RestStarted(duration: Duration(seconds: seconds)));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state == null || state! <= 0) {
        t.cancel();
        _completedNaturally = true;
        state = null;
        ref
            .read(trainerEventBusProvider)
            .emit(RestFinished(restDuration: _lastRestDuration));
      } else {
        state = state! - 1;
        final remaining = state!;
        if (remaining >= 1 && remaining <= 3) {
          ref
              .read(trainerEventBusProvider)
              .emit(RestCountdown(secondsLeft: remaining));
        }
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _completedNaturally = false;
    state = null;
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
    // The chime takes exclusive audio focus and would cut the coach off
    // mid-sentence, so it stands down whenever the coach announces rest end
    // itself. Vibration is unaffected — it does not contend for audio.
    final restDuration =
        ref.read(restTimerProvider.notifier).lastRestDuration ?? Duration.zero;
    if (settings.soundEnabled &&
        !ref.read(coachAnnouncesRestEndProvider(restDuration))) {
      _audioPlayer?.play(AssetSource('sounds/timer_complete.wav'));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(restTimerProvider, (previous, next) {
      if (previous != null &&
          next == null &&
          ref.read(restTimerProvider.notifier).completedNaturally) {
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
          const SizedBox(width: 8),
          // Right-aligned when there is room, but horizontally scrollable so the
          // preset chips never overflow on narrow screens (issue #42).
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
