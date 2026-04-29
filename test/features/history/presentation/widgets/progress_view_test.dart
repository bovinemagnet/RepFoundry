import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/core/widgets/progress_chart_widget.dart';
import 'package:rep_foundry/features/history/presentation/providers/muscle_group_distribution_provider.dart';
import 'package:rep_foundry/features/history/presentation/providers/streak_provider.dart';
import 'package:rep_foundry/features/history/presentation/providers/trained_exercises_provider.dart';
import 'package:rep_foundry/features/history/presentation/providers/workout_duration_chart_provider.dart';
import 'package:rep_foundry/features/history/presentation/providers/workout_frequency_provider.dart';
import 'package:rep_foundry/features/history/presentation/providers/workout_volume_chart_provider.dart';
import 'package:rep_foundry/features/history/presentation/widgets/calendar_heatmap.dart';
import 'package:rep_foundry/features/history/presentation/widgets/progress_view.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ({Widget app, List<String> visited}) buildHost({
    List<ProgressDataPoint> volume = const [],
    List<ProgressDataPoint> duration = const [],
    List<WeeklyFrequency> frequency = const [],
  }) {
    final visited = <String>[];
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: ProgressView()),
        ),
        GoRoute(
          path: '/analytics',
          builder: (_, state) {
            visited.add(state.uri.toString());
            return const Scaffold(body: Text('Analytics'));
          },
        ),
      ],
    );

    return (
      app: ProviderScope(
        overrides: [
          // Streak / heatmap / muscle group / trained exercises all empty so
          // they render SizedBox.shrink and don't add unrelated items.
          streakProvider.overrideWith(
            (ref) async => const StreakData(currentStreak: 0, longestStreak: 0),
          ),
          workoutDaysProvider.overrideWith((ref) async => <DateTime>{}),
          muscleGroupDistributionProvider
              .overrideWith((ref) async => <MuscleGroupVolume>[]),
          trainedExercisesProvider
              .overrideWith((ref) async => <TrainedExercise>[]),
          workoutVolumeChartProvider.overrideWith((ref) async => volume),
          workoutDurationChartProvider.overrideWith((ref) async => duration),
          workoutFrequencyProvider.overrideWith((ref) async => frequency),
        ],
        child: MaterialApp.router(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          routerConfig: router,
        ),
      ),
      visited: visited,
    );
  }

  group('ProgressView', () {
    testWidgets('always renders the advanced-analytics link tile',
        (tester) async {
      await tester.pumpWidget(buildHost().app);
      await tester.pumpAndSettle();

      expect(find.text('View Advanced Analytics'), findsOneWidget);
      expect(find.byIcon(Icons.insights), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('volume chart appears when volume data is present',
        (tester) async {
      final now = DateTime.utc(2026, 4, 1);
      await tester.pumpWidget(buildHost(volume: [
        ProgressDataPoint(date: now, value: 1000),
        ProgressDataPoint(
          date: now.add(const Duration(days: 7)),
          value: 1200,
        ),
      ]).app);
      await tester.pumpAndSettle();

      expect(find.text('Volume Trend'), findsOneWidget);
    });

    testWidgets('frequency chart appears when frequency data is present',
        (tester) async {
      await tester.pumpWidget(buildHost(frequency: [
        WeeklyFrequency(weekStart: DateTime.utc(2026, 4, 6), count: 3),
        WeeklyFrequency(weekStart: DateTime.utc(2026, 4, 13), count: 4),
      ]).app);
      await tester.pumpAndSettle();

      expect(find.text('Workouts per Week'), findsOneWidget);
    });

    testWidgets(
        'tapping the advanced-analytics tile pushes the /analytics route',
        (tester) async {
      final scaffolding = buildHost();
      await tester.pumpWidget(scaffolding.app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Advanced Analytics'));
      await tester.pumpAndSettle();

      expect(scaffolding.visited, contains('/analytics'));
    });
  });
}
