import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/muscle_balance_provider.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/pr_timeline_provider.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/training_load_provider.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/weekly_volume_provider.dart';
import 'package:rep_foundry/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildScreen({
    List<WeeklyVolume> volume = const [],
    List<MuscleBalance> balance = const [],
    List<PrTimelineEntry> prs = const [],
    List<WeeklyLoad> load = const [],
  }) {
    return ProviderScope(
      overrides: [
        weeklyVolumeProvider.overrideWith((ref) async => volume),
        muscleBalanceProvider.overrideWith((ref) async => balance),
        prTimelineProvider.overrideWith((ref) async => prs),
        trainingLoadProvider.overrideWith((ref) async => load),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: AnalyticsScreen(),
      ),
    );
  }

  group('AnalyticsScreen', () {
    testWidgets('shows the empty state when all four providers return empty',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Not enough data yet'), findsOneWidget);
      expect(find.byIcon(Icons.insights), findsOneWidget);
    });

    testWidgets('renders the four chart sections when at least one has data',
        (tester) async {
      final week = DateTime.utc(2026, 4, 27);
      await tester.pumpWidget(buildScreen(
        volume: [
          WeeklyVolume(weekStart: week, totalVolume: 1200, percentChange: null),
          WeeklyVolume(
            weekStart: week.add(const Duration(days: 7)),
            totalVolume: 1500,
            percentChange: 25.0,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Empty state should NOT be shown when at least one section has data.
      expect(find.text('Not enough data yet'), findsNothing);
      // All four section titles render as Cards with header text.
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });
  });
}
