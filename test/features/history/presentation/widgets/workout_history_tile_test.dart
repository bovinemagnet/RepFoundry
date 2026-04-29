import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/bar_sparkline_widget.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/history/presentation/widgets/workout_history_tile.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  Widget host(Widget child) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  Workout sampleWorkout({DateTime? startedAt, DateTime? completedAt}) {
    final start = startedAt ?? DateTime.utc(2026, 4, 1, 9);
    return Workout(
      id: 'wo-1',
      startedAt: start,
      completedAt: completedAt ?? start.add(const Duration(minutes: 45)),
      updatedAt: start,
    );
  }

  PersonalRecord samplePr() {
    return PersonalRecord.create(
      exerciseId: 'ex-1',
      recordType: RecordType.maxWeight,
      value: 150,
    );
  }

  group('WorkoutHistoryTile', () {
    testWidgets('renders the fallback workout name when none is supplied',
        (tester) async {
      await tester.pumpWidget(host(WorkoutHistoryTile(
        workout: sampleWorkout(),
        setCount: 6,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Workout'), findsOneWidget);
    });

    testWidgets('renders the explicit workout name when supplied',
        (tester) async {
      await tester.pumpWidget(host(WorkoutHistoryTile(
        workout: sampleWorkout(),
        setCount: 6,
        workoutName: 'Push Day',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Push Day'), findsOneWidget);
    });

    testWidgets('renders set count when no totalVolume is supplied',
        (tester) async {
      await tester.pumpWidget(host(WorkoutHistoryTile(
        workout: sampleWorkout(),
        setCount: 12,
      )));
      await tester.pumpAndSettle();

      expect(find.text('12 sets'), findsOneWidget);
    });

    testWidgets('renders total volume kg when supplied', (tester) async {
      await tester.pumpWidget(host(WorkoutHistoryTile(
        workout: sampleWorkout(),
        setCount: 6,
        totalVolume: 1234.5,
      )));
      await tester.pumpAndSettle();

      expect(find.text('1235 kg'), findsOneWidget);
    });

    testWidgets('renders the PR badge and corner accent when a PR is supplied',
        (tester) async {
      await tester.pumpWidget(host(WorkoutHistoryTile(
        workout: sampleWorkout(),
        setCount: 5,
        personalRecord: samplePr(),
      )));
      await tester.pumpAndSettle();

      expect(find.text('PR!'), findsOneWidget);
    });

    testWidgets('omits the PR badge when no PR is supplied', (tester) async {
      await tester.pumpWidget(host(WorkoutHistoryTile(
        workout: sampleWorkout(),
        setCount: 5,
      )));
      await tester.pumpAndSettle();

      expect(find.text('PR!'), findsNothing);
    });

    testWidgets('renders the embedded sparkline when sparklineData is provided',
        (tester) async {
      await tester.pumpWidget(host(WorkoutHistoryTile(
        workout: sampleWorkout(),
        setCount: 5,
        sparklineData: const [10, 20, 30, 40, 50],
      )));
      await tester.pumpAndSettle();

      expect(find.byType(BarSparklineWidget), findsOneWidget);
      expect(find.text('VOLUME PROGRESS'), findsOneWidget);
    });

    testWidgets('omits the sparkline when sparklineData is empty',
        (tester) async {
      await tester.pumpWidget(host(WorkoutHistoryTile(
        workout: sampleWorkout(),
        setCount: 5,
        sparklineData: const [],
      )));
      await tester.pumpAndSettle();

      expect(find.byType(BarSparklineWidget), findsNothing);
    });

    testWidgets('forwards onTap when the card is tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(WorkoutHistoryTile(
        workout: sampleWorkout(),
        setCount: 5,
        onTap: () => taps++,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(taps, 1);
    });
  });
}
