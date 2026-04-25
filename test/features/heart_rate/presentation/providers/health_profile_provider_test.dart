import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/heart_rate/domain/analytics_events.dart';
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
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty profile', () {
      final state = container.read(healthProfileProvider);
      expect(state.age, isNull);
      expect(state.restingHr, isNull);
      expect(state.betaBlocker, isFalse);
      expect(state.heartCondition, isFalse);
    });

    test('updateAge sets age and fires analytics', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.updateAge(49);
      expect(container.read(healthProfileProvider).age, 49);

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
      expect(container.read(healthProfileProvider).age, isNull);
    });

    test('updateRestingHeartRate sets value and fires analytics', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.updateRestingHeartRate(60);
      expect(container.read(healthProfileProvider).restingHr, 60);

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
      expect(container.read(healthProfileProvider).measuredMaxHr, 185);
    });

    test('setTakingBetaBlocker enables caution mode and fires analytics',
        () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.setTakingBetaBlocker(true);
      expect(container.read(healthProfileProvider).betaBlocker, isTrue);
      expect(container.read(healthProfileProvider).isCautionMode, isTrue);

      final cautionEvents = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.cautionModeActivated)
          .toList();
      expect(cautionEvents, hasLength(1));
    });

    test('setHasHeartCondition enables caution mode', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.setHasHeartCondition(true);
      expect(container.read(healthProfileProvider).heartCondition, isTrue);
      expect(container.read(healthProfileProvider).isCautionMode, isTrue);
    });

    test('setClinicianMaxHr sets value and fires customCapUsed', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.setClinicianMaxHr(150);
      expect(container.read(healthProfileProvider).clinicianMaxHr, 150);

      final capEvents = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.customCapUsed)
          .toList();
      expect(capEvents, hasLength(1));
    });

    test('setClinicianMaxHr with null clears value', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.setClinicianMaxHr(150);
      await notifier.setClinicianMaxHr(null);
      expect(container.read(healthProfileProvider).clinicianMaxHr, isNull);
    });

    test('caution mode analytics not fired when disabling flags', () async {
      final notifier = container.read(healthProfileProvider.notifier);
      await notifier.setTakingBetaBlocker(true);
      analytics.events.clear();

      await notifier.setTakingBetaBlocker(false);
      final cautionEvents = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.cautionModeActivated)
          .toList();
      expect(cautionEvents, isEmpty);
    });
  });
}
