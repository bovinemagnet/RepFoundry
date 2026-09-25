import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../workout/presentation/controllers/active_workout_controller.dart';
import '../../domain/trainer_event.dart';
import '../providers/trainer_event_bus.dart';

/// Shows the one-tap "Start workout" offer that accompanies the coach's
/// spoken invitation when sustained effort is noticed (phase 3). Mounted
/// around the app shell so it works from any tab.
class ActivityNudgeListener extends ConsumerStatefulWidget {
  const ActivityNudgeListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ActivityNudgeListener> createState() =>
      _ActivityNudgeListenerState();
}

class _ActivityNudgeListenerState extends ConsumerState<ActivityNudgeListener> {
  late final StreamSubscription<TrainerEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref
        .read(trainerEventBusProvider)
        .events
        .where((e) => e is ActivityDetected)
        .listen((_) => _offerWorkout());
  }

  void _offerWorkout() {
    if (!mounted) return;
    final s = S.of(context)!;
    // Resolved now: the snackbar can outlive this context.
    final router = GoRouter.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.activityNudgeMessage),
        duration: const Duration(seconds: 10),
        // A snackbar with an action persists by default; keep the timeout.
        persist: false,
        action: SnackBarAction(
          label: s.activityNudgeStart,
          onPressed: () {
            unawaited(
              ref.read(activeWorkoutControllerProvider.notifier).startWorkout(),
            );
            router.go('/workout');
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
