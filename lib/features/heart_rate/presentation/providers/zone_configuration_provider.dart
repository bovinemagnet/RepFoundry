import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/zone_calculator.dart';
import 'health_profile_provider.dart';

/// Derived provider that recalculates zones whenever the health profile changes.
final zoneConfigurationProvider = Provider<ZoneConfiguration?>((ref) {
  final profile = ref.watch(healthProfileProvider);
  return calculateZones(profile);
});

/// Whether caution mode is active.
final cautionModeProvider = Provider<bool>((ref) {
  return ref.watch(healthProfileProvider).isCautionMode;
});
