import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/domain/analytics_events.dart';
import 'package:rep_foundry/features/heart_rate/domain/models/health_profile.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/health_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAnalyticsReporter implements HrAnalyticsReporter {
  final events = <(HrAnalyticsEvent, Map<String, Object>?)>[];

  @override
  void trackEvent(HrAnalyticsEvent event, [Map<String, Object>? properties]) {
    events.add((event, properties));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthProfileNotifier', () {
    late HealthProfileNotifier notifier;
    late _FakeAnalyticsReporter analytics;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      analytics = _FakeAnalyticsReporter();
      notifier = HealthProfileNotifier(analyticsReporter: analytics);
      // Allow the async _load() from the constructor to complete.
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      notifier.dispose();
    });

    test('initial state is empty profile', () {
      expect(notifier.state.age, isNull);
      expect(notifier.state.restingHeartRate, isNull);
      expect(notifier.state.takingBetaBlocker, isFalse);
      expect(notifier.state.hasHeartCondition, isFalse);
    });

    test('updateAge sets age and fires analytics', () async {
      await notifier.updateAge(49);
      expect(notifier.state.age, 49);
      expect(notifier.state.estimatedMaxHr, 171);

      final ageEvents = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.healthFieldCompleted)
          .toList();
      expect(ageEvents, hasLength(1));
      expect(ageEvents.first.$2?['field'], 'age');
    });

    test('updateAge with null clears age', () async {
      await notifier.updateAge(30);
      await notifier.updateAge(null);
      expect(notifier.state.age, isNull);
    });

    test('updateRestingHeartRate sets value and fires analytics', () async {
      await notifier.updateRestingHeartRate(60);
      expect(notifier.state.restingHeartRate, 60);

      final events = analytics.events
          .where((e) =>
              e.$1 == HrAnalyticsEvent.healthFieldCompleted &&
              e.$2?['field'] == 'restingHeartRate')
          .toList();
      expect(events, hasLength(1));
    });

    test('updateMeasuredMaxHeartRate sets value', () async {
      await notifier.updateMeasuredMaxHeartRate(185);
      expect(notifier.state.measuredMaxHeartRate, 185);
    });

    test('setTakingBetaBlocker enables caution mode and fires analytics',
        () async {
      await notifier.setTakingBetaBlocker(true);
      expect(notifier.state.takingBetaBlocker, isTrue);
      expect(notifier.state.isCautionMode, isTrue);

      final cautionEvents = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.cautionModeActivated)
          .toList();
      expect(cautionEvents, hasLength(1));
    });

    test('setHasHeartCondition enables caution mode', () async {
      await notifier.setHasHeartCondition(true);
      expect(notifier.state.hasHeartCondition, isTrue);
      expect(notifier.state.isCautionMode, isTrue);
    });

    test('setClinicianMaxHr sets value and fires customCapUsed', () async {
      await notifier.setClinicianMaxHr(150);
      expect(notifier.state.clinicianMaxHr, 150);

      final capEvents = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.customCapUsed)
          .toList();
      expect(capEvents, hasLength(1));
    });

    test('setClinicianMaxHr with null clears value', () async {
      await notifier.setClinicianMaxHr(150);
      await notifier.setClinicianMaxHr(null);
      expect(notifier.state.clinicianMaxHr, isNull);
    });

    test('setCustomZones stores and clears custom zones', () async {
      const zones = [
        CustomZoneBoundary(lowerBpm: 60, upperBpm: 100, label: 'Easy'),
        CustomZoneBoundary(lowerBpm: 100, upperBpm: 140, label: 'Hard'),
      ];
      await notifier.setCustomZones(zones);
      expect(notifier.state.customZones, hasLength(2));
      expect(notifier.state.customZones!.first.label, 'Easy');

      await notifier.setCustomZones(null);
      expect(notifier.state.customZones, isNull);
    });

    test('caution mode analytics not fired when disabling flags', () async {
      await notifier.setTakingBetaBlocker(true);
      analytics.events.clear();

      await notifier.setTakingBetaBlocker(false);
      // caution mode is now false, so no event should fire
      final cautionEvents = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.cautionModeActivated)
          .toList();
      expect(cautionEvents, isEmpty);
    });
  });
}
