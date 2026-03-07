import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/heart_rate/data/noop_analytics_reporter.dart';
import 'package:rep_foundry/features/heart_rate/presentation/providers/health_profile_provider.dart';
import 'package:rep_foundry/features/heart_rate/presentation/widgets/health_profile_onboarding.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  group('HealthProfileOnboarding', () {
    Widget buildApp() {
      return ProviderScope(
        overrides: [
          hrAnalyticsReporterProvider
              .overrideWithValue(NoopAnalyticsReporter()),
        ],
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showHealthProfileOnboarding(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows step 1 of 4 with age field', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Set Up Heart Rate Zones'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
    });

    testWidgets('navigates through all 4 steps', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Step 1 → skip to step 2
      expect(find.text('Step 1 of 4'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Step 2
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.text('Resting Heart Rate (optional)'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Step 3
      expect(find.text('Step 3 of 4'), findsOneWidget);
      expect(find.text('Taking beta blocker medication'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Step 4
      expect(find.text('Step 4 of 4'), findsOneWidget);
      expect(find.text('Clinician Max Heart Rate (optional)'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('back button navigates to previous step', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Go to step 2
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 4'), findsOneWidget);

      // Go back to step 1
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 4'), findsOneWidget);
    });

    testWidgets('entering age and pressing next saves value', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hrAnalyticsReporterProvider
                .overrideWithValue(NoopAnalyticsReporter()),
          ],
          child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () => showHealthProfileOnboarding(context),
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter age
      await tester.enterText(find.byType(TextField), '49');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Check step 2 is shown (age was saved)
      expect(find.text('Step 2 of 4'), findsOneWidget);

      // Verify the age was persisted to the notifier
      final profile = container.read(healthProfileProvider);
      expect(profile.age, 49);
    });

    testWidgets('done button closes the bottom sheet', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Skip through to step 4
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
      }

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Bottom sheet should be closed
      expect(find.text('Set Up Heart Rate Zones'), findsNothing);
    });

    testWidgets('step 3 shows medical toggles', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Skip to step 3
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Taking beta blocker medication'), findsOneWidget);
      expect(find.text('Heart condition'), findsOneWidget);

      // Toggle switches should be present
      expect(find.byType(SwitchListTile), findsNWidgets(2));
    });

    testWidgets('step 4 shows emphasis when medical flags set', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Skip to step 3
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Enable beta blocker
      await tester.tap(find.text('Taking beta blocker medication'));
      await tester.pumpAndSettle();

      // Go to step 4
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should show emphasised text
      expect(
        find.textContaining('we strongly recommend'),
        findsOneWidget,
      );
    });
  });
}
