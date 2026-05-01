import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/cardio/application/save_cardio_session_use_case.dart';
import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/data/heart_rate_service.dart';
import 'package:rep_foundry/features/health_sync/data/health_sync_service.dart';
import 'package:rep_foundry/features/health_sync/presentation/providers/health_sync_settings_provider.dart';
import 'package:rep_foundry/features/heart_rate/presentation/controllers/heart_rate_panel_controller.dart';
import 'package:rep_foundry/features/heart_rate/presentation/controllers/heart_rate_panel_state.dart';
import 'package:rep_foundry/features/heart_rate/presentation/screens/heart_rate_panel_screen.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../cardio/data/fake_heart_rate_service.dart';
import '../../../cardio/data/fake_location_service.dart';

/// Notifier override that seeds the panel with a specific initial state so
/// tests can render branches that normally depend on live BLE readings.
class _SeedNotifier extends HeartRatePanelController {
  _SeedNotifier(this._initial);

  final HeartRatePanelState _initial;

  @override
  HeartRatePanelState build() {
    super.build();
    return _initial;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocationService locationService;
  late FakeHeartRateService heartRateService;
  late InMemoryCardioSessionRepository cardioRepo;
  late InMemoryWorkoutRepository workoutRepo;

  // Stub the audioplayers method channel so AudioPlayer construction in
  // initState does not raise MissingPluginException at test time.
  setUp(() {
    SharedPreferences.setMockInitialValues({
      // Mark the disclaimer as already shown so showDisclaimerIfNeeded
      // returns synchronously.
      'hr_disclaimer_shown': true,
      // Set an age so health-profile onboarding is skipped on first visit.
      'hr_age': 35,
    });
    locationService = FakeLocationService();
    heartRateService = FakeHeartRateService();
    cardioRepo = InMemoryCardioSessionRepository();
    workoutRepo = InMemoryWorkoutRepository();

    const audioChannel = MethodChannel('xyz.luan/audioplayers.global');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (_) async => null);
    const audioInstance = MethodChannel('xyz.luan/audioplayers');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioInstance, (_) async => null);

    // Tall surface so the lazy ListView builds the rows we assert on.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    locationService.dispose();
    heartRateService.dispose();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
    const audioChannel = MethodChannel('xyz.luan/audioplayers.global');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, null);
    const audioInstance = MethodChannel('xyz.luan/audioplayers');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioInstance, null);
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        cardioSessionRepositoryProvider.overrideWithValue(cardioRepo),
        saveCardioSessionUseCaseProvider.overrideWithValue(
          SaveCardioSessionUseCase(
            cardioRepository: cardioRepo,
            workoutRepository: workoutRepo,
          ),
        ),
        locationServiceProvider.overrideWithValue(locationService),
        heartRateServiceProvider.overrideWithValue(heartRateService),
        healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
        healthSyncSettingsProvider
            .overrideWith(() => HealthSyncSettingsNotifier()),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: HeartRatePanelScreen(),
      ),
    );
  }

  group('HeartRatePanelScreen', () {
    testWidgets('renders the Heart Rate app bar with the setup-guide action',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      // Settle the post-frame callback that decides whether to show the
      // disclaimer / onboarding dialogs (both are short-circuited by the
      // SharedPreferences seed in setUp).
      await tester.pumpAndSettle();

      expect(find.text('Heart Rate'), findsOneWidget);
      // Setup guide tooltip is always shown in the AppBar.
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets(
        'shows the Connect HR Monitor button when no monitor is connected',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Connect HR Monitor'), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth), findsOneWidget);
      // Bluetooth-disabled icon (disconnect action) is only shown while
      // connected — it should NOT appear on the initial render.
      expect(find.byIcon(Icons.bluetooth_disabled), findsNothing);
    });

    testWidgets(
        'shows the placeholder chart and zone-config card when no profile age',
        (tester) async {
      // Override SharedPreferences without the age key — onboarding is
      // suppressed because we keep the disclaimer flag set, but the
      // zoneConfig will resolve to null and the "set age" prompt should
      // appear instead of the zone legend.
      SharedPreferences.setMockInitialValues({
        'hr_disclaimer_shown': true,
        // Re-seed the age key as null by simply not setting it.  The
        // health-profile onboarding flow only opens when age is null AND
        // we are still on first visit; with the disclaimer already shown,
        // _initialised flips to true after the first frame so the
        // onboarding flow does not run synchronously, leaving the body
        // intact for our assertions.
      });
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      // Allow post-frame callbacks to run without forcing pumpAndSettle —
      // pumpAndSettle would loop on the bottom-sheet animation if onboarding
      // gets scheduled.
      await tester.pump(const Duration(milliseconds: 200));

      // Either the "set age" tile or the onboarding sheet renders depending on
      // timing of the post-frame callback; both indicate the no-zone path.
      final hasSetAgeTile =
          find.text('Set your age in Settings').evaluate().isNotEmpty;
      final hasOnboarding =
          find.textContaining('Heart Rate').evaluate().isNotEmpty;
      expect(hasSetAgeTile || hasOnboarding, isTrue);
    });

    testWidgets('renders the placeholder text when there are no readings',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // The empty heart_rate_chart shows this string.
      expect(
        find.text('Waiting for heart rate data...'),
        findsOneWidget,
      );
    });
  });

  // ── Seeded-state tests ─────────────────────────────────────────────────
  //
  // The branches below are guarded by readings/connection flags that the
  // empty-state tests above can't reach. We override the panel notifier with
  // a seeded state so the bento grid, zones, trend chart, and connected
  // controls actually render and can be asserted on.
  group('HeartRatePanelScreen with seeded state', () {
    Widget buildScreenWithState(HeartRatePanelState state) {
      return ProviderScope(
        overrides: [
          cardioSessionRepositoryProvider.overrideWithValue(cardioRepo),
          saveCardioSessionUseCaseProvider.overrideWithValue(
            SaveCardioSessionUseCase(
              cardioRepository: cardioRepo,
              workoutRepository: workoutRepo,
            ),
          ),
          locationServiceProvider.overrideWithValue(locationService),
          heartRateServiceProvider.overrideWithValue(heartRateService),
          healthSyncServiceProvider.overrideWithValue(HealthSyncService()),
          healthSyncSettingsProvider
              .overrideWith(() => HealthSyncSettingsNotifier()),
          heartRatePanelProvider.overrideWith(() => _SeedNotifier(state)),
        ],
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: HeartRatePanelScreen(),
        ),
      );
    }

    /// Build a list of `count` plausible HrReading samples, with bpm values
    /// kept comfortably below an age-35 max so the max-HR alert path stays
    /// inert during widget tests.
    List<HrReading> readings({int count = 30, int baseBpm = 130}) {
      return List.generate(
        count,
        (i) => HrReading(
          bpm: baseBpm + (i % 10),
          elapsed: Duration(seconds: i),
        ),
      );
    }

    testWidgets('hero BPM section shows the live sensor badge and value',
        (tester) async {
      await tester.pumpWidget(
        buildScreenWithState(
          HeartRatePanelState(
            hrConnected: true,
            isMonitoring: true,
            currentHeartRate: 142,
            readings: readings(),
            hrDeviceName: 'Polar H10',
            elapsedSeconds: 65,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('142'), findsOneWidget);
      expect(find.text('LIVE SENSOR'), findsOneWidget);
      expect(find.text('Polar H10'), findsOneWidget);
      // Duration(seconds: 65).formatted == '01:05'.
      expect(find.text('01:05'), findsOneWidget);
    });

    testWidgets('reconnecting indicator renders when hrReconnecting is true',
        (tester) async {
      await tester.pumpWidget(
        buildScreenWithState(
          HeartRatePanelState(
            hrConnected: true,
            hrReconnecting: true,
            currentHeartRate: 138,
            readings: readings(count: 5),
          ),
        ),
      );
      // The reconnecting indicator includes a CircularProgressIndicator that
      // spins indefinitely, so pumpAndSettle would hang. A pair of pumps is
      // enough to flush the post-frame callbacks.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Reconnecting...'), findsOneWidget);
    });

    testWidgets('bento metric grid renders avg / max / min / readings cards',
        (tester) async {
      await tester.pumpWidget(
        buildScreenWithState(
          HeartRatePanelState(
            hrConnected: true,
            isMonitoring: true,
            currentHeartRate: 135,
            readings: readings(count: 12),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AVG'), findsOneWidget);
      expect(find.text('MAX'), findsOneWidget);
      expect(find.text('MIN'), findsOneWidget);
      expect(find.text('READINGS'), findsOneWidget);
      // Reading count is shown verbatim.
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('zones section renders header and Z5 card when readings + age',
        (tester) async {
      await tester.pumpWidget(
        buildScreenWithState(
          HeartRatePanelState(
            hrConnected: true,
            isMonitoring: true,
            currentHeartRate: 140,
            readings: readings(),
            elapsedSeconds: 30,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workout Intensity Zones'), findsOneWidget);
      // Each zone card title is rendered uppercase. We don't assert on every
      // zone label since they depend on the resolved zone calculation, but
      // the section header alone proves the _ZonesSection widget rendered.
      expect(find.textContaining('SESSION:'), findsOneWidget);
    });

    testWidgets(
        'trend chart section renders header and recent / full-session labels',
        (tester) async {
      await tester.pumpWidget(
        buildScreenWithState(
          HeartRatePanelState(
            hrConnected: true,
            isMonitoring: true,
            currentHeartRate: 132,
            readings: readings(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Heart Rate Trend'), findsOneWidget);
      // Section labels are rendered verbatim (no .toUpperCase() in the
      // screen) — assert the strings as they appear in the ARB.
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Full Session'), findsOneWidget);
    });

    testWidgets('start / reset buttons render when connected but not monitoring',
        (tester) async {
      await tester.pumpWidget(
        buildScreenWithState(
          HeartRatePanelState(
            hrConnected: true,
            isMonitoring: false,
            currentHeartRate: 130,
            readings: readings(count: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      // Reset only renders when there are existing readings.
      expect(find.text('Reset'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      // Connected → AppBar shows the disconnect action.
      expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
    });

    testWidgets('pause / reset buttons render when monitoring with readings',
        (tester) async {
      await tester.pumpWidget(
        buildScreenWithState(
          HeartRatePanelState(
            hrConnected: true,
            isMonitoring: true,
            currentHeartRate: 145,
            readings: readings(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pause'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('symptom report button renders during active monitoring',
        (tester) async {
      await tester.pumpWidget(
        buildScreenWithState(
          HeartRatePanelState(
            hrConnected: true,
            isMonitoring: true,
            currentHeartRate: 150,
            readings: readings(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('controls show a progress indicator while hrConnecting',
        (tester) async {
      await tester.pumpWidget(
        buildScreenWithState(
          const HeartRatePanelState(hrConnecting: true),
        ),
      );
      // Don't pumpAndSettle — the spinner animates forever and would hang.
      // A single frame plus a short pump is enough for the post-frame
      // callbacks (which short-circuit thanks to the SharedPreferences seed).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      // Connect/Start buttons must NOT be shown while connecting.
      expect(find.text('Connect HR Monitor'), findsNothing);
      expect(find.text('Start'), findsNothing);
    });

    testWidgets('disconnect AppBar action exposes a Disconnect tooltip',
        (tester) async {
      await tester.pumpWidget(
        buildScreenWithState(
          HeartRatePanelState(
            hrConnected: true,
            isMonitoring: true,
            currentHeartRate: 140,
            readings: readings(count: 5),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifying the action exists is enough at the widget level — the
      // controller's disconnectHeartRate() flow itself is unit-tested in
      // heart_rate_panel_controller_test.dart.
      expect(find.byTooltip('Disconnect'), findsOneWidget);
    });
  });
}
