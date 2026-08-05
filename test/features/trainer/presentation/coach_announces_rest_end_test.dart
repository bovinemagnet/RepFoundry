import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/coach_announcements.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Entitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

class _NotEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => false;
}

const _short = Duration(seconds: 60);
const _long = Duration(minutes: 2);

ProviderContainer _container({
  bool entitled = true,
  bool enabled = true,
  bool disclaimerAccepted = true,
  bool countdownsEnabled = true,
  bool quotesEnabled = true,
}) {
  final container = ProviderContainer(
    overrides: [
      entitlementServiceProvider
          .overrideWithValue(entitled ? _Entitled() : _NotEntitled()),
    ],
  );
  addTearDown(container.dispose);

  // Seeded synchronously: the notifier's async load would otherwise land
  // after the assertion and mask the state under test.
  container.read(trainerSettingsProvider.notifier).state = TrainerSettings(
    enabled: enabled,
    disclaimerAccepted: disclaimerAccepted,
    countdownsEnabled: countdownsEnabled,
    quotesEnabled: quotesEnabled,
  );
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('coachAnnouncesRestEndProvider', () {
    test(
        'true when the coach is entitled, enabled, consented, and counting '
        'down', () {
      expect(_container().read(coachAnnouncesRestEndProvider(_short)), isTrue);
    });

    test('false without the entitlement', () {
      expect(
        _container(entitled: false).read(coachAnnouncesRestEndProvider(_short)),
        isFalse,
      );
    });

    test('false when the coach is switched off', () {
      expect(
        _container(enabled: false).read(coachAnnouncesRestEndProvider(_short)),
        isFalse,
      );
    });

    test('false when the safety disclaimer has not been accepted', () {
      expect(
        _container(disclaimerAccepted: false)
            .read(coachAnnouncesRestEndProvider(_short)),
        isFalse,
      );
    });

    test('false when rest countdowns are switched off', () {
      // RestFinished is a countdown-priority cue, so this toggle silences it
      // and the chime must come back.
      expect(
        _container(countdownsEnabled: false)
            .read(coachAnnouncesRestEndProvider(_short)),
        isFalse,
      );
    });

    test('follows the settings as they change', () {
      final container = _container();
      expect(container.read(coachAnnouncesRestEndProvider(_short)), isTrue);

      container.read(trainerSettingsProvider.notifier).state =
          const TrainerSettings(
        enabled: true,
        disclaimerAccepted: true,
        countdownsEnabled: false,
      );

      expect(container.read(coachAnnouncesRestEndProvider(_short)), isFalse);
    });

    test(
        'with countdowns off, a long rest still silences the chime — the '
        'coach speaks a standalone quote there', () {
      final container = _container(countdownsEnabled: false);

      expect(container.read(coachAnnouncesRestEndProvider(_long)), isTrue);
    });

    test('with countdowns off, a short rest lets the chime through', () {
      final container = _container(countdownsEnabled: false);

      expect(container.read(coachAnnouncesRestEndProvider(_short)), isFalse);
    });

    test('with countdowns and quotes both off, the chime always plays', () {
      final container =
          _container(countdownsEnabled: false, quotesEnabled: false);

      expect(container.read(coachAnnouncesRestEndProvider(_long)), isFalse);
    });
  });
}
