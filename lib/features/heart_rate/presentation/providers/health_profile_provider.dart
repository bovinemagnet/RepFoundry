import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers.dart';
import '../../../clients/domain/models/client.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';
import '../../domain/analytics_events.dart';

class HealthProfileNotifier extends AsyncNotifier<HealthProfile> {
  @override
  Future<HealthProfile> build() async {
    await _migrateLegacyProfileOnce();
    final client = await ref.watch(activeClientProvider.future);
    return ref.watch(healthProfileRepositoryProvider).getForClient(client.id);
  }

  /// One-time migration of the legacy single-profile SharedPreferences data
  /// into the "Me" client's row, guarded by a done-flag key.
  Future<void> _migrateLegacyProfileOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('health_profile_migrated_v1') ?? false) return;
    final legacy = HealthProfile(
      age: prefs.getInt('hr_age') ?? prefs.getInt('user_age'),
      restingHr: prefs.getInt('hr_resting_hr'),
      measuredMaxHr: prefs.getInt('hr_measured_max_hr'),
      clinicianMaxHr: prefs.getInt('hr_clinician_max_hr'),
      betaBlocker: prefs.getBool('hr_beta_blocker') ?? false,
      heartCondition: prefs.getBool('hr_heart_condition') ?? false,
    );
    await ref
        .read(healthProfileRepositoryProvider)
        .saveForClient(kSelfClientId, legacy);
    await prefs.setBool('health_profile_migrated_v1', true);
  }

  HrAnalyticsReporter? get analyticsReporter =>
      ref.watch(hrAnalyticsReporterProvider);

  Future<void> _save(HealthProfile updated) async {
    final clientId = ref.read(activeClientProvider).value?.id ?? kSelfClientId;
    await ref.read(healthProfileRepositoryProvider).saveForClient(
          clientId,
          updated,
        );
    state = AsyncData(updated);
  }

  Future<void> updateAge(int? age) async {
    final current = await future;
    final updated = age != null
        ? current.copyWith(age: age)
        : current.copyWith(clearAge: true);
    await _save(updated);
    if (age != null) {
      analyticsReporter?.trackEvent(
        HrAnalyticsEvent.healthFieldCompleted,
        {'field': 'age'},
      );
    }
  }

  Future<void> updateRestingHeartRate(int? restingHr) async {
    final current = await future;
    final updated = restingHr != null
        ? current.copyWith(restingHr: restingHr)
        : current.copyWith(clearRestingHr: true);
    await _save(updated);
    if (restingHr != null) {
      analyticsReporter?.trackEvent(
        HrAnalyticsEvent.healthFieldCompleted,
        {'field': 'restingHeartRate'},
      );
    }
  }

  Future<void> updateMeasuredMaxHeartRate(int? measuredMax) async {
    final current = await future;
    final updated = measuredMax != null
        ? current.copyWith(measuredMaxHr: measuredMax)
        : current.copyWith(clearMeasuredMaxHr: true);
    await _save(updated);
  }

  Future<void> setTakingBetaBlocker(bool value) async {
    final current = await future;
    final updated = current.copyWith(betaBlocker: value);
    await _save(updated);
    if (updated.isCautionMode) {
      analyticsReporter?.trackEvent(HrAnalyticsEvent.cautionModeActivated);
    }
  }

  Future<void> setHasHeartCondition(bool value) async {
    final current = await future;
    final updated = current.copyWith(heartCondition: value);
    await _save(updated);
    if (updated.isCautionMode) {
      analyticsReporter?.trackEvent(HrAnalyticsEvent.cautionModeActivated);
    }
  }

  Future<void> setClinicianMaxHr(int? maxHr) async {
    final current = await future;
    final updated = maxHr != null
        ? current.copyWith(clinicianMaxHr: maxHr)
        : current.copyWith(clearClinicianMaxHr: true);
    await _save(updated);
    if (maxHr != null) {
      analyticsReporter?.trackEvent(HrAnalyticsEvent.customCapUsed);
    }
  }
}

final healthProfileProvider =
    AsyncNotifierProvider<HealthProfileNotifier, HealthProfile>(
  HealthProfileNotifier.new,
);
