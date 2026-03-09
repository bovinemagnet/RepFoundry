import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers.dart';
import '../../domain/analytics_events.dart';
import '../../domain/models/health_profile.dart';

class HealthProfileNotifier extends Notifier<HealthProfile> {
  late final HrAnalyticsReporter? analyticsReporter;

  @override
  HealthProfile build() {
    analyticsReporter = ref.watch(hrAnalyticsReporterProvider);
    _load();
    return const HealthProfile();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Migrate legacy user_age key if present
    int? age = prefs.getInt('hr_age');
    if (age == null) {
      final legacyAge = prefs.getInt('user_age');
      if (legacyAge != null) {
        age = legacyAge;
        await prefs.setInt('hr_age', legacyAge);
      }
    }

    List<CustomZoneBoundary>? customZones;
    final zonesJson = prefs.getString('hr_custom_zones');
    if (zonesJson != null) {
      final list = jsonDecode(zonesJson) as List;
      customZones = list
          .map((e) => CustomZoneBoundary(
                lowerBpm: e['lowerBpm'] as int,
                upperBpm: e['upperBpm'] as int,
                label: e['label'] as String,
              ))
          .toList();
    }

    state = HealthProfile(
      age: age,
      restingHeartRate: prefs.getInt('hr_resting_hr'),
      measuredMaxHeartRate: prefs.getInt('hr_measured_max_hr'),
      clinicianMaxHr: prefs.getInt('hr_clinician_max_hr'),
      takingBetaBlocker: prefs.getBool('hr_beta_blocker') ?? false,
      hasHeartCondition: prefs.getBool('hr_heart_condition') ?? false,
      customZones: customZones,
    );
  }

  Future<void> updateAge(int? age) async {
    state =
        age != null ? state.copyWith(age: age) : state.copyWith(clearAge: true);
    final prefs = await SharedPreferences.getInstance();
    if (age != null) {
      await prefs.setInt('hr_age', age);
      // Keep legacy key in sync
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
        ? state.copyWith(restingHeartRate: restingHr)
        : state.copyWith(clearRestingHeartRate: true);
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
        ? state.copyWith(measuredMaxHeartRate: measuredMax)
        : state.copyWith(clearMeasuredMaxHeartRate: true);
    final prefs = await SharedPreferences.getInstance();
    if (measuredMax != null) {
      await prefs.setInt('hr_measured_max_hr', measuredMax);
    } else {
      await prefs.remove('hr_measured_max_hr');
    }
  }

  Future<void> setTakingBetaBlocker(bool value) async {
    state = state.copyWith(takingBetaBlocker: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hr_beta_blocker', value);
    if (state.isCautionMode) {
      analyticsReporter?.trackEvent(HrAnalyticsEvent.cautionModeActivated);
    }
  }

  Future<void> setHasHeartCondition(bool value) async {
    state = state.copyWith(hasHeartCondition: value);
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

  Future<void> setCustomZones(List<CustomZoneBoundary>? zones) async {
    state = zones != null
        ? state.copyWith(customZones: zones)
        : state.copyWith(clearCustomZones: true);
    final prefs = await SharedPreferences.getInstance();
    if (zones != null) {
      final json = jsonEncode(zones
          .map((z) => {
                'lowerBpm': z.lowerBpm,
                'upperBpm': z.upperBpm,
                'label': z.label,
              })
          .toList());
      await prefs.setString('hr_custom_zones', json);
    } else {
      await prefs.remove('hr_custom_zones');
    }
  }
}

final healthProfileProvider =
    NotifierProvider<HealthProfileNotifier, HealthProfile>(
  HealthProfileNotifier.new,
);
