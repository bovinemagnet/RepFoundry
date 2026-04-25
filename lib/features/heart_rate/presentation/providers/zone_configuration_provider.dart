import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_zones/hr_zones.dart';

import '../../../../core/providers.dart';
import '../../domain/analytics_events.dart';
import 'health_profile_provider.dart';

/// Derived provider that recalculates zones whenever the health profile changes.
final zoneConfigurationProvider = Provider<ZoneConfiguration?>((ref) {
  final profile = ref.watch(healthProfileProvider);
  final config = calculateZones(profile);
  if (config != null) {
    ref.read(hrAnalyticsReporterProvider).trackEvent(
      HrAnalyticsEvent.zoneMethodSelected,
      {'method': config.method.name},
    );
  }
  return config;
});

/// Whether caution mode is active.
final cautionModeProvider = Provider<bool>((ref) {
  return ref.watch(healthProfileProvider).isCautionMode;
});
