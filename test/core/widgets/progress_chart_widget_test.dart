import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/progress_chart_widget.dart';

void main() {
  Widget host(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('ProgressChartWidget', () {
    testWidgets('renders nothing when dataPoints is empty', (tester) async {
      await tester.pumpWidget(host(const ProgressChartWidget(
        dataPoints: [],
        label: 'Estimated 1RM',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Estimated 1RM'), findsNothing);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renders the label and a LineChart when data is present',
        (tester) async {
      final now = DateTime.utc(2026, 4, 1);
      await tester.pumpWidget(host(ProgressChartWidget(
        dataPoints: [
          ProgressDataPoint(date: now, value: 100),
          ProgressDataPoint(
            date: now.add(const Duration(days: 7)),
            value: 105,
          ),
          ProgressDataPoint(
            date: now.add(const Duration(days: 14)),
            value: 110,
          ),
        ],
        label: 'Bench 1RM',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Bench 1RM'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('chart minY/maxY pad around the data range', (tester) async {
      final now = DateTime.utc(2026, 4, 1);
      await tester.pumpWidget(host(ProgressChartWidget(
        dataPoints: [
          ProgressDataPoint(date: now, value: 100),
          ProgressDataPoint(
            date: now.add(const Duration(days: 7)),
            value: 200,
          ),
        ],
        label: 'Volume',
      )));
      await tester.pumpAndSettle();

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      // yRange = 100 → yPadding = 10. minY = 100-10 = 90, maxY = 200+10 = 210.
      expect(chart.data.minY, 90);
      expect(chart.data.maxY, 210);
    });

    testWidgets('a single data point still renders without crashing',
        (tester) async {
      await tester.pumpWidget(host(ProgressChartWidget(
        dataPoints: [
          ProgressDataPoint(date: DateTime.utc(2026, 4, 1), value: 100),
        ],
        label: 'Solo',
      )));
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      // yRange = 0 → fallback yPadding = 10.
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.minY, 90);
      expect(chart.data.maxY, 110);
    });
  });
}
