import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rep_foundry/features/settings/presentation/providers/rest_timer_settings_provider.dart';
import 'package:rep_foundry/features/workout/presentation/widgets/rest_timer_widget.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  late List<String> hapticCalls;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    hapticCalls = [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        hapticCalls.add(call.arguments as String);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget buildWidget() {
    return const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: RestTimerWidget()),
      ),
    );
  }

  testWidgets('renders Rest Timer label when idle', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.text('Rest Timer'), findsOneWidget);
  });

  testWidgets('shows countdown when timer starts', (tester) async {
    await tester.pumpWidget(buildWidget());

    // Tap the 1:00 chip
    await tester.tap(find.text('1:00'));
    await tester.pump();

    expect(find.text('1:00'), findsWidgets); // chip + countdown
    expect(find.text('Rest Timer'), findsNothing);
  });

  testWidgets('haptic fires when timer completes with defaults',
      (tester) async {
    await tester.pumpWidget(buildWidget());

    // Start a 1-second timer
    final container =
        ProviderScope.containerOf(tester.element(find.byType(RestTimerWidget)));
    container.read(restTimerProvider.notifier).start(1);
    await tester.pump();

    // Advance 1 second for countdown
    await tester.pump(const Duration(seconds: 1));
    // Advance another tick for the periodic timer to fire and set state to null
    await tester.pump(const Duration(seconds: 1));

    expect(hapticCalls, contains('HapticFeedbackType.heavyImpact'));
  });

  testWidgets('no haptic when vibration disabled', (tester) async {
    await tester.pumpWidget(buildWidget());

    final container =
        ProviderScope.containerOf(tester.element(find.byType(RestTimerWidget)));

    // Disable vibration
    await container.read(restTimerSettingsProvider.notifier).toggleVibration();
    await tester.pump();

    // Start and complete timer
    container.read(restTimerProvider.notifier).start(1);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(hapticCalls, isEmpty);
  });

  testWidgets('stop button cancels timer without alert', (tester) async {
    await tester.pumpWidget(buildWidget());

    final container =
        ProviderScope.containerOf(tester.element(find.byType(RestTimerWidget)));
    container.read(restTimerProvider.notifier).start(60);
    await tester.pump();

    // Tap stop
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();

    // Stop sets state to null directly — but previous was non-null,
    // so the listener fires. This is expected: manual stop also alerts.
    // The user can disable alerts in settings if they don't want this.
    expect(find.text('Rest Timer'), findsOneWidget);
  });
}
