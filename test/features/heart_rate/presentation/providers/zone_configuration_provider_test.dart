import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/heart_rate/domain/analytics_events.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/health_profile_provider.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/zone_configuration_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAnalyticsReporter implements HrAnalyticsReporter {
  final events = <(HrAnalyticsEvent, Map<String, Object>?)>[];

  @override
  void trackEvent(HrAnalyticsEvent event, [Map<String, Object>? properties]) {
    events.add((event, properties));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('zoneConfigurationProvider', () {
    late _RecordingAnalyticsReporter analytics;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      analytics = _RecordingAnalyticsReporter();
    });

    test('returns null when health profile lacks data to compute zones', () {
      final container = ProviderContainer(
        overrides: [
          hrAnalyticsReporterProvider.overrideWithValue(analytics),
        ],
      );
      addTearDown(container.dispose);

      // Empty profile has no age, no measured max, no clinician cap
      // → calculateZones cannot anchor any method.
      final config = container.read(zoneConfigurationProvider);
      expect(config, isNull);
      expect(analytics.events, isEmpty);
    });

    test('returns a configuration when age is set and fires analytics',
        () async {
      final container = ProviderContainer(
        overrides: [
          hrAnalyticsReporterProvider.overrideWithValue(analytics),
        ],
      );
      addTearDown(container.dispose);

      await container.read(healthProfileProvider.notifier).updateAge(35);

      final config = container.read(zoneConfigurationProvider);
      expect(config, isNotNull);
      expect(config!.zones, hasLength(5));
      expect(config.maxHr, greaterThan(0));

      final methodEvents = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.zoneMethodSelected)
          .toList();
      expect(methodEvents, isNotEmpty);
      expect(methodEvents.last.$2?['method'], isA<String>());
    });

    test('clinician cap drives high reliability', () async {
      final container = ProviderContainer(
        overrides: [
          hrAnalyticsReporterProvider.overrideWithValue(analytics),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(healthProfileProvider.notifier)
          .setClinicianMaxHr(160);

      final config = container.read(zoneConfigurationProvider);
      expect(config, isNotNull);
      expect(config!.method, ZoneMethod.clinicianCap);
      expect(config.reliability, ZoneReliability.high);
      expect(config.maxHr, 160);
    });
  });

  group('cautionModeProvider', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('is false for an empty profile', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(cautionModeProvider), isFalse);
    });

    test('becomes true when beta blocker flag is set', () async {
      final container = ProviderContainer(
        overrides: [
          hrAnalyticsReporterProvider
              .overrideWithValue(_RecordingAnalyticsReporter()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(healthProfileProvider.notifier)
          .setTakingBetaBlocker(true);

      expect(container.read(cautionModeProvider), isTrue);
    });

    test('becomes true when heart condition flag is set', () async {
      final container = ProviderContainer(
        overrides: [
          hrAnalyticsReporterProvider
              .overrideWithValue(_RecordingAnalyticsReporter()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(healthProfileProvider.notifier)
          .setHasHeartCondition(true);

      expect(container.read(cautionModeProvider), isTrue);
    });
  });
}
