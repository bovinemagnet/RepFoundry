import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entitlements/entitlement.dart';
import '../../../../core/entitlements/entitlement_provider.dart';
import 'trainer_settings_provider.dart';

/// True when the coach will speak its own end-of-rest line.
///
/// The rest-timer chime is suppressed while this holds. On Android the chime
/// takes exclusive audio focus (`AUDIOFOCUS_GAIN`) whereas the coach only asks
/// to duck, so the two firing together cut the coach off mid-sentence. When
/// the coach is speaking the chime is redundant anyway — the spoken line says
/// rest is over.
///
/// The conditions mirror the ones [CoachBridge] applies before speaking, and
/// `countdownsEnabled` is included because the end-of-rest cue carries
/// countdown priority: switching countdowns off silences it, and the chime
/// must come back.
final coachAnnouncesRestEndProvider = Provider<bool>((ref) {
  final settings = ref.watch(trainerSettingsProvider);
  if (!settings.enabled || !settings.disclaimerAccepted) return false;
  if (!settings.countdownsEnabled) return false;

  return ref.watch(entitlementServiceProvider).has(Entitlement.virtualTrainer);
});
