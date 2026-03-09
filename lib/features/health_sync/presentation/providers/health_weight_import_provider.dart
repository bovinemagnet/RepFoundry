import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import 'health_sync_settings_provider.dart';

/// Checks the health store for a newer body weight reading.
/// Returns the weight in kg if found, null otherwise.
final healthWeightCheckProvider =
    FutureProvider.autoDispose<double?>((ref) async {
  final settings = ref.watch(healthSyncSettingsProvider);
  if (!settings.enabled || !settings.readWeight) return null;

  final healthService = ref.watch(healthSyncServiceProvider);
  try {
    return await healthService.readLatestWeight();
  } catch (_) {
    return null;
  }
});
