import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers.dart';
import '../../domain/analytics_events.dart';

class HealthProfileNotifier extends Notifier<HealthProfile> {
  @override
  HealthProfile build() {
    _load();
    return const HealthProfile();
  }

  HrAnalyticsReporter? get analyticsReporter =>
      ref.watch(hrAnalyticsReporterProvider);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    int? age = prefs.getInt('hr_age');
    if (age == null) {
      final legacyAge = prefs.getInt('user_age');
      if (legacyAge != null) {
        age = legacyAge;
        await prefs.setInt('hr_age', legacyAge);
      }
    }

    state = HealthProfile(
      age: age,
      restingHr: prefs.getInt('hr_resting_hr'),
      measuredMaxHr: prefs.getInt('hr_measured_max_hr'),
      clinicianMaxHr: prefs.getInt('hr_clinician_max_hr'),
      betaBlocker: prefs.getBool('hr_beta_blocker') ?? false,
      heartCondition: prefs.getBool('hr_heart_condition') ?? false,
    );
  }

  Future<void> updateAge(int? age) async {
    state =
        age != null ? state.copyWith(age: age) : state.copyWith(clearAge: true);
    final prefs = await SharedPreferences.getInstance();
    if (age != null) {
      await prefs.setInt('hr_age', age);
      await prefs.setInt('user_age', age);
      analyticsReporter?.trackEvent(
        HrAnalyticsEvent.healthFieldCompleted,
        {'field': 'age'},
      );
    } else {
      await prefs.remove('hr_age');
      await prefs.remove('user_age');
    }
  }

  Future<void> updateRestingHeartRate(int? restingHr) async {
    state = restingHr != null
        ? state.copyWith(restingHr: restingHr)
        : state.copyWith(clearRestingHr: true);
    final prefs = await SharedPreferences.getInstance();
    if (restingHr != null) {
      await prefs.setInt('hr_resting_hr', restingHr);
      analyticsReporter?.trackEvent(
        HrAnalyticsEvent.healthFieldCompleted,
        {'field': 'restingHeartRate'},
      );
    } else {
      await prefs.remove('hr_resting_hr');
    }
  }

  Future<void> updateMeasuredMaxHeartRate(int? measuredMax) async {
    state = measuredMax != null
        ? state.copyWith(measuredMaxHr: measuredMax)
        : state.copyWith(clearMeasuredMaxHr: true);
    final prefs = await SharedPreferences.getInstance();
    if (measuredMax != null) {
      await prefs.setInt('hr_measured_max_hr', measuredMax);
    } else {
      await prefs.remove('hr_measured_max_hr');
    }
  }

  Future<void> setTakingBetaBlocker(bool value) async {
    state = state.copyWith(betaBlocker: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hr_beta_blocker', value);
    if (state.isCautionMode) {
      analyticsReporter?.trackEvent(HrAnalyticsEvent.cautionModeActivated);
    }
  }

  Future<void> setHasHeartCondition(bool value) async {
    state = state.copyWith(heartCondition: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hr_heart_condition', value);
    if (state.isCautionMode) {
      analyticsReporter?.trackEvent(HrAnalyticsEvent.cautionModeActivated);
    }
  }

  Future<void> setClinicianMaxHr(int? maxHr) async {
    state = maxHr != null
        ? state.copyWith(clinicianMaxHr: maxHr)
        : state.copyWith(clearClinicianMaxHr: true);
    final prefs = await SharedPreferences.getInstance();
    if (maxHr != null) {
      await prefs.setInt('hr_clinician_max_hr', maxHr);
      analyticsReporter?.trackEvent(HrAnalyticsEvent.customCapUsed);
    } else {
      await prefs.remove('hr_clinician_max_hr');
    }
  }
}

final healthProfileProvider =
    NotifierProvider<HealthProfileNotifier, HealthProfile>(
  HealthProfileNotifier.new,
);
