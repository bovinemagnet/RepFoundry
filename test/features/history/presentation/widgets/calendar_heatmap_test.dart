import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/history/presentation/widgets/calendar_heatmap.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHost(Set<DateTime> workoutDays) {
    return ProviderScope(
      overrides: [
        workoutDaysProvider.overrideWith((ref) async => workoutDays),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: CalendarHeatmap()),
      ),
    );
  }

  group('CalendarHeatmap', () {
    testWidgets('renders nothing when there are no workout days',
        (tester) async {
      await tester.pumpWidget(buildHost({}));
      await tester.pumpAndSettle();

      expect(find.text('Workout Calendar'), findsNothing);
    });

    testWidgets(
        'renders the title and Less/More legend labels when workouts exist',
        (tester) async {
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      final twoDaysAgo = DateTime(today.year, today.month, today.day - 2);
      await tester.pumpWidget(buildHost({yesterday, twoDaysAgo}));
      await tester.pumpAndSettle();

      expect(find.text('Workout Calendar'), findsOneWidget);
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('renders 12 weeks of cells (84 day cells in the heatmap grid)',
        (tester) async {
      final today = DateTime.now();
      final cellDay = DateTime(today.year, today.month, today.day - 1);
      await tester.pumpWidget(buildHost({cellDay}));
      await tester.pumpAndSettle();

      // The heatmap's day cells use Tooltip; legend cells do not. Counting
      // tooltips gives the number of visible day cells. With 12 weeks × 7
      // days the grid is 84 cells.
      final tooltips = find.byType(Tooltip);
      expect(tooltips, findsAtLeastNWidgets(80));
    });
  });
}
