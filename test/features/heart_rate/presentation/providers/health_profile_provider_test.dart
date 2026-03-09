import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/domain/analytics_events.dart';
import 'package:rep_foundry/features/heart_rate/domain/models/health_profile.dart';
import 'package:rep_foundry/core/providers.dart';
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
    late ProviderContainer container;
    late _FakeAnalyticsReporter analytics;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      analytics = _FakeAnalyticsReporter();
      container = ProviderContainer(
        overrides: [
          hrAnalyticsReporterProvider.overrideWithValue(analytics),
        ],
      );
      // Allow the async _load() to complete.
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty profile', () {
      final state = container.read(healthProfileProvider);
      expect(state.age, isNull);
      expect(state.restingHeartRate, isNull);
      expect(state.takingBetaBlocker, isFalse);
      expect(state.hasHeartCondition, isFalse);
    });

    test('updateAge sets age and fires analytics', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.updateAge(49);
      final state = container.read(healthProfileProvider);
      expect(state.age, 49);
      expect(state.estimatedMaxHr, 171);

      final ageEvents = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.healthFieldCompleted)
          .toList();
      expect(ageEvents, hasLength(1));
      expect(ageEvents.first.$2?['field'], 'age');
    });

    test('updateAge with null clears age', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.updateAge(30);
      await notifier.updateAge(null);
      final state = container.read(healthProfileProvider);
      expect(state.age, isNull);
    });

    test('updateRestingHeartRate sets value and fires analytics', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.updateRestingHeartRate(60);
      final state = container.read(healthProfileProvider);
      expect(state.restingHeartRate, 60);

      final events = analytics.events
          .where((e) =>
              e.$1 == HrAnalyticsEvent.healthFieldCompleted &&
              e.$2?['field'] == 'restingHeartRate')
          .toList();
      expect(events, hasLength(1));
    });

    test('updateMeasuredMaxHeartRate sets value', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.updateMeasuredMaxHeartRate(185);
      final state = container.read(healthProfileProvider);
      expect(state.measuredMaxHeartRate, 185);
    });

    test('setTakingBetaBlocker enables caution mode and fires analytics',
        () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.setTakingBetaBlocker(true);
      final state = container.read(healthProfileProvider);
      expect(state.takingBetaBlocker, isTrue);
      expect(state.isCautionMode, isTrue);

      final cautionEvents = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.cautionModeActivated)
          .toList();
      expect(cautionEvents, hasLength(1));
    });

    test('setHasHeartCondition enables caution mode', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.setHasHeartCondition(true);
      final state = container.read(healthProfileProvider);
      expect(state.hasHeartCondition, isTrue);
      expect(state.isCautionMode, isTrue);
    });

    test('setClinicianMaxHr sets value and fires customCapUsed', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.setClinicianMaxHr(150);
      final state = container.read(healthProfileProvider);
      expect(state.clinicianMaxHr, 150);

      final capEvents = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.customCapUsed)
          .toList();
      expect(capEvents, hasLength(1));
    });

    test('setClinicianMaxHr with null clears value', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.setClinicianMaxHr(150);
      await notifier.setClinicianMaxHr(null);
      final state = container.read(healthProfileProvider);
      expect(state.clinicianMaxHr, isNull);
    });

    test('setCustomZones stores and clears custom zones', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      const zones = [
        CustomZoneBoundary(lowerBpm: 60, upperBpm: 100, label: 'Easy'),
        CustomZoneBoundary(lowerBpm: 100, upperBpm: 140, label: 'Hard'),
      ];
      await notifier.setCustomZones(zones);
      var state = container.read(healthProfileProvider);
      expect(state.customZones, hasLength(2));
      expect(state.customZones!.first.label, 'Easy');

      await notifier.setCustomZones(null);
      state = container.read(healthProfileProvider);
      expect(state.customZones, isNull);
    });

    test('caution mode analytics not fired when disabling flags', () async {
      final notifier = container.read(healthProfileProvider.notifier);
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
