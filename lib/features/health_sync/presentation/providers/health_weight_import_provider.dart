import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../clients/domain/models/client.dart';
import '../../data/health_sync_service.dart';
import 'health_sync_settings_provider.dart';

/// Checks the health store for a body weight reading newer than anything
/// already recorded. Returns the sample if found, null otherwise — so an
/// imported value doesn't re-prompt on every visit.
final healthWeightCheckProvider =
    FutureProvider.autoDispose<WeightSample?>((ref) async {
  final settings = ref.watch(healthSyncSettingsProvider);
  if (!settings.enabled || !settings.readWeight) return null;

  final healthService = ref.watch(healthSyncServiceProvider);
  try {
    final sample = await healthService.readLatestWeight();
    if (sample == null) return null;

    final latest =
        await ref.watch(bodyMetricRepositoryProvider).getLatest(kSelfClientId);
    if (latest != null && !sample.date.isAfter(latest.date)) return null;

    return sample;
  } catch (_) {
    return null;
  }
});
