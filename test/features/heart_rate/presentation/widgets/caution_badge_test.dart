import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/features/heart_rate/presentation/widgets/caution_badge.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  group('CautionBadge', () {
    Widget buildHost(HealthProfile profile) {
      return MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: CautionBadge(profile: profile)),
      );
    }

    testWidgets('renders nothing when caution mode is off', (tester) async {
      await tester.pumpWidget(buildHost(const HealthProfile(age: 35)));
      await tester.pumpAndSettle();

      expect(find.text('Caution Mode'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('renders beta-blocker warning when only that flag is set',
        (tester) async {
      await tester.pumpWidget(
        buildHost(const HealthProfile(age: 35, betaBlocker: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Caution Mode'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('Beta blocker'), findsOneWidget);
      expect(find.textContaining('heart condition'), findsNothing);
    });

    testWidgets('renders heart-condition warning when only that flag is set',
        (tester) async {
      await tester.pumpWidget(
        buildHost(const HealthProfile(age: 35, heartCondition: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Caution Mode'), findsOneWidget);
      expect(find.textContaining('heart condition'), findsOneWidget);
      expect(find.textContaining('Beta blocker'), findsNothing);
    });

    testWidgets('renders combined warning when both flags are set',
        (tester) async {
      await tester.pumpWidget(
        buildHost(const HealthProfile(
          age: 35,
          betaBlocker: true,
          heartCondition: true,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Caution Mode'), findsOneWidget);
      expect(find.textContaining('Beta blocker'), findsOneWidget);
      expect(find.textContaining('heart condition'), findsOneWidget);
    });
  });
}
