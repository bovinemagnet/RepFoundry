import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/database/database_provider.dart';
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

  late db.AppDatabase database;

  ProviderContainer buildContainer(HrAnalyticsReporter analytics) {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    return ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        hrAnalyticsReporterProvider.overrideWithValue(analytics),
      ],
    );
  }

  group('zoneConfigurationProvider', () {
    late _RecordingAnalyticsReporter analytics;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      analytics = _RecordingAnalyticsReporter();
    });

    tearDown(() => database.close());

    test('returns null when health profile lacks data to compute zones',
        () async {
      final container = buildContainer(analytics);
      addTearDown(container.dispose);
      await container.read(healthProfileProvider.future);

      // Empty profile has no age, no measured max, no clinician cap
      // → calculateZones cannot anchor any method.
      final config = container.read(zoneConfigurationProvider);
      expect(config, isNull);
      expect(analytics.events, isEmpty);
    });

    test('returns a configuration when age is set and fires analytics',
        () async {
      final container = buildContainer(analytics);
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
      final container = buildContainer(analytics);
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

    tearDown(() => database.close());

    test('is false for an empty profile', () async {
      final container = buildContainer(_RecordingAnalyticsReporter());
      addTearDown(container.dispose);
      await container.read(healthProfileProvider.future);

      expect(container.read(cautionModeProvider), isFalse);
    });

    test('becomes true when beta blocker flag is set', () async {
      final container = buildContainer(_RecordingAnalyticsReporter());
      addTearDown(container.dispose);

      await container
          .read(healthProfileProvider.notifier)
          .setTakingBetaBlocker(true);

      expect(container.read(cautionModeProvider), isTrue);
    });

    test('becomes true when heart condition flag is set', () async {
      final container = buildContainer(_RecordingAnalyticsReporter());
      addTearDown(container.dispose);

      await container
          .read(healthProfileProvider.notifier)
          .setHasHeartCondition(true);

      expect(container.read(cautionModeProvider), isTrue);
    });
  });
}
