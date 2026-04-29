import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/history/presentation/providers/streak_provider.dart';
import 'package:rep_foundry/features/history/presentation/widgets/streak_card.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHost(StreakData? data) {
    return ProviderScope(
      overrides: [
        if (data != null)
          streakProvider.overrideWith((ref) async => data)
        else
          streakProvider.overrideWith((ref) async => const StreakData(
                currentStreak: 0,
                longestStreak: 0,
              )),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: StreakCard()),
      ),
    );
  }

  group('StreakCard', () {
    testWidgets('renders nothing when both streaks are zero', (tester) async {
      await tester.pumpWidget(buildHost(null));
      await tester.pumpAndSettle();

      // The card body is hidden — fire icon and Card should not be present.
      expect(find.byIcon(Icons.local_fire_department), findsNothing);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders fire icon and current streak label when active',
        (tester) async {
      await tester.pumpWidget(buildHost(
        const StreakData(currentStreak: 5, longestStreak: 12),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      // The "5 day streak" copy and the trailing big-number "5".
      expect(find.text('5 day streak'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Longest: 12 days'), findsOneWidget);
    });

    testWidgets('hides the trailing big-number when current streak is zero',
        (tester) async {
      // longestStreak > 0 so the body still renders — but currentStreak == 0
      // means the trailing headline number must be omitted.
      await tester.pumpWidget(buildHost(
        const StreakData(currentStreak: 0, longestStreak: 7),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.text('No current streak'), findsOneWidget);
      // Big trailing number should not be rendered.
      expect(find.text('0'), findsNothing);
    });
  });
}
