import 'package:audioplayers/audioplayers.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_settings_provider.dart';
import 'package:rep_foundry/features/workout/presentation/widgets/rest_timer_widget.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records every asset `AudioPlayer.play()` tries to load, then throws.
///
/// The real loading chain (`rootBundle` + `path_provider`, then a native
/// "prepared" event) is not wired up in a widget test, so letting `play()`
/// run further would hang or crash on unrelated native plumbing this test
/// has no way to supply. `loadPath` is the first thing `play()` reaches on
/// its way to sounding the chime, so recording the call — before throwing to
/// keep the rest of that chain from ever running — is the closest
/// observable, and only reliable, proxy for "the chime was told to play".
class _FakeAudioCache extends AudioCache {
  final List<String> loadedFileNames = [];

  @override
  Future<String> loadPath(String fileName) async {
    loadedFileNames.add(fileName);
    throw StateError('no native audio backend in widget tests');
  }
}

class _Entitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

/// Pushes a fixed [TrainerSettings] synchronously, bypassing the real
/// notifier's `SharedPreferences` load entirely — same pattern as
/// coach_bridge_test.dart's `_SeededTrainerSettingsNotifier`. Overriding
/// `.state` on the real notifier after the fact is not enough: its own
/// pending async load still lands on a later `pump()` and clobbers the seed
/// back to defaults.
class _SeededTrainerSettingsNotifier extends TrainerSettingsNotifier {
  _SeededTrainerSettingsNotifier(this._seed);

  final TrainerSettings _seed;

  @override
  TrainerSettings build() => _seed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAudioCache fakeAudioCache;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeAudioCache = _FakeAudioCache();
    AudioCache.instance = fakeAudioCache;

    // Stub audioplayers so AudioPlayer construction does not raise
    // MissingPluginException at test time.
    const audioGlobal = MethodChannel('xyz.luan/audioplayers.global');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobal, (_) async => null);
    const audioInstance = MethodChannel('xyz.luan/audioplayers');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioInstance, (_) async => null);
  });

  tearDown(() {
    const audioGlobal = MethodChannel('xyz.luan/audioplayers.global');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioGlobal, null);
    const audioInstance = MethodChannel('xyz.luan/audioplayers');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioInstance, null);
  });

  Widget buildHost() {
    return const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: RestTimerWidget()),
      ),
    );
  }

  group('RestTimerNotifier', () {
    test('start sets state to the supplied seconds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(restTimerProvider.notifier).start(60);
      expect(container.read(restTimerProvider), 60);
    });

    test('stop returns state to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(restTimerProvider.notifier).start(60);
      container.read(restTimerProvider.notifier).stop();
      expect(container.read(restTimerProvider), isNull);
    });

    testWidgets('timer counts down each second and self-completes',
        (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ));

      container.read(restTimerProvider.notifier).start(2);
      expect(container.read(restTimerProvider), 2);

      // Two ticks should drain the timer.
      await tester.pump(const Duration(seconds: 1));
      expect(container.read(restTimerProvider), 1);

      await tester.pump(const Duration(seconds: 1));
      expect(container.read(restTimerProvider), 0);

      await tester.pump(const Duration(seconds: 1));
      expect(container.read(restTimerProvider), isNull);
    });

    test('RestFinished carries the duration the timer ran for', () async {
      final bus = TrainerEventBus(() => true);
      final events = <TrainerEvent>[];
      final sub = bus.events.listen(events.add);
      addTearDown(sub.cancel);

      final container = ProviderContainer(
        overrides: [trainerEventBusProvider.overrideWithValue(bus)],
      );
      addTearDown(container.dispose);

      fakeAsync((async) {
        container.read(restTimerProvider.notifier).start(2);
        async.elapse(const Duration(seconds: 4));
      });
      await Future<void>.delayed(Duration.zero);

      final finished = events.whereType<RestFinished>().single;
      expect(finished.restDuration, const Duration(seconds: 2));
    });
  });

  group('RestTimerWidget rendering', () {
    testWidgets('renders the idle "Rest Timer" label and four quick chips',
        (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.pumpAndSettle();

      expect(find.text('Rest Timer'), findsOneWidget);
      expect(find.byType(ActionChip), findsNWidgets(4));
      expect(find.text('1:00'), findsOneWidget);
      expect(find.text('1:30'), findsOneWidget);
      expect(find.text('2:00'), findsOneWidget);
      expect(find.text('3:00'), findsOneWidget);
      // Stop button should not appear while idle.
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('tapping a chip starts the timer and reveals the Stop button',
        (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.pumpAndSettle();

      await tester.tap(find.text('1:00'));
      // Pump once — do NOT pumpAndSettle, the per-second Timer never settles.
      await tester.pump();

      // Initial render shows 01:00 in the running state.
      expect(find.text('01:00'), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);
      // Idle label is hidden while running.
      expect(find.text('Rest Timer'), findsNothing);

      // Stop the timer to keep the test deterministic.
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();
    });

    testWidgets('tapping Stop returns the widget to the idle state',
        (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.pumpAndSettle();

      await tester.tap(find.text('2:00'));
      await tester.pump();
      expect(find.byIcon(Icons.stop), findsOneWidget);

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();

      expect(find.text('Rest Timer'), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('does not overflow horizontally on a narrow screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHost());
      await tester.pumpAndSettle();

      // All four presets remain reachable and no RenderFlex overflows.
      expect(find.byType(ActionChip), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  });

  group('chime suppression when the coach will speak', () {
    testWidgets(
        'does not tell the chime to play when a long rest ends with '
        'countdowns off and the coach entitled to speak', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            entitlementServiceProvider.overrideWithValue(_Entitled()),
            trainerSettingsProvider.overrideWith(
              () => _SeededTrainerSettingsNotifier(
                const TrainerSettings(
                  enabled: true,
                  disclaimerAccepted: true,
                  countdownsEnabled: false,
                  quotesEnabled: true,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(body: RestTimerWidget()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RestTimerWidget)),
      );

      // A rest at CoachingEngine.longRestThreshold (two minutes) earns the
      // standalone quote the coach speaks with countdowns off — the real
      // rest duration flowing through RestTimerNotifier and into
      // coachAnnouncesRestEndProvider that rest_timer_widget.dart:104-107
      // exists to join.
      container.read(restTimerProvider.notifier).start(120);
      await tester.pump();
      // The periodic timer needs one tick beyond the started duration to
      // reach zero and complete (see the "self-completes" test above).
      await tester.pump(const Duration(seconds: 121));
      await tester.pump();

      // The chime must never have been told to load, which is the closest
      // observable proxy this test has for "the chime did not sound" — see
      // the doc comment on _FakeAudioCache for why nothing further down the
      // real playback chain is observable here.
      expect(fakeAudioCache.loadedFileNames, isEmpty);
    });
  });
}
