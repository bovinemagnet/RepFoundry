import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/presentation/widgets/rest_timer_widget.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});

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
  });
}
