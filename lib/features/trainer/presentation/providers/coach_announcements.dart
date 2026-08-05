import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entitlements/entitlement.dart';
import '../../../../core/entitlements/entitlement_provider.dart';
import '../../application/coaching_engine.dart';
import 'trainer_settings_provider.dart';

/// True when the coach will speak its own line at the end of a rest of
/// [restDuration], so the rest-timer chime must stand down.
///
/// On Android the chime takes exclusive audio focus (`AUDIOFOCUS_GAIN`)
/// whereas the coach only asks to duck, so the two firing together cut the
/// coach off mid-sentence. When the coach speaks, the chime is redundant
/// anyway.
///
/// Keyed on the rest's length because the answer now depends on it. With
/// countdowns on, the coach always speaks the end-of-rest line. With
/// countdowns off it still speaks a standalone quote, but only after a rest
/// of [CoachingEngine.longRestThreshold] or more.
///
/// This cannot see the engine's above-cap/caution/zone-5 suppression, so with
/// countdowns off and quotes on a long rest ending above the safety cap
/// silences the chime for a quote the engine then withholds — vibration, and
/// no sound. That is the right way to be wrong: above the cap a
/// safety-priority warning is the likeliest thing playing, and a chime seizing
/// exclusive audio focus is exactly what must not happen then.
final coachAnnouncesRestEndProvider =
    Provider.family<bool, Duration>((ref, restDuration) {
  final settings = ref.watch(trainerSettingsProvider);
  if (!settings.enabled || !settings.disclaimerAccepted) return false;
  if (!ref.watch(entitlementServiceProvider).has(Entitlement.virtualTrainer)) {
    return false;
  }

  if (settings.countdownsEnabled) return true;
  return settings.quotesEnabled &&
      restDuration >= CoachingEngine.longRestThreshold;
});
