import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entitlements/entitlement.dart';
import '../../../../core/entitlements/entitlement_provider.dart';
import '../../../../core/foreground/foreground_keep_alive.dart';
import '../../../workout/presentation/controllers/active_workout_controller.dart';
import 'trainer_settings_provider.dart';

/// Whether the coach needs the app kept alive with the screen off: it is
/// switched on, allowed to speak in the background, and a workout is running.
final coachNeedsBackgroundProvider = Provider<bool>((ref) {
  final settings = ref.watch(trainerSettingsProvider);
  final entitled =
      ref.watch(entitlementServiceProvider).has(Entitlement.virtualTrainer);
  final inWorkout = ref.watch(
    activeWorkoutControllerProvider.select((s) => s.hasActiveWorkout),
  );
  return entitled &&
      settings.enabled &&
      settings.disclaimerAccepted &&
      settings.speakInBackground &&
      inWorkout;
});

/// Reports [coachNeedsBackgroundProvider] to the shared
/// [ForegroundKeepAlive], and switches the coach off when its notification
/// button is tapped. Mounted for the life of the app shell, like the
/// coach bridge.
///
/// Subscribed through the container rather than with `ref.listen`, for the
/// reason `CoachBridge` gives: a provider-internal listener on a derived
/// provider is lazy, so an entitlement being revoked would never reach it.
final coachKeepAliveProvider = Provider<void>((ref) {
  final keepAlive = ref.watch(foregroundKeepAliveProvider);
  final subscription = ref.container.listen<bool>(
    coachNeedsBackgroundProvider,
    (_, active) => unawaited(keepAlive.setCoach(active: active)),
    fireImmediately: true,
  );
  // The notification's "Turn coach off" button: switching the coach off
  // silences it (see CoachBridge) and, through the subscription above,
  // releases the keep-alive and its notification.
  final stopRequests = keepAlive.coachStopRequests.listen(
    (_) =>
        unawaited(ref.read(trainerSettingsProvider.notifier).setEnabled(false)),
  );
  ref.onDispose(() {
    unawaited(stopRequests.cancel());
    subscription.close();
    unawaited(keepAlive.setCoach(active: false));
  });
});
