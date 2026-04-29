import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/features/heart_rate/presentation/widgets/heart_rate_chart.dart';

ZoneConfiguration _config() {
  return const ZoneConfiguration(
    zones: [
      CalculatedZone(
        zoneNumber: 1,
        label: 'Z1',
        effortLabel: 'Easy',
        descriptiveLabel: 'Recovery',
        lowerBound: 90,
        upperBound: 108,
        color: 0xFF4FC3F7,
        lowerPercent: 0.5,
        upperPercent: 0.6,
      ),
      CalculatedZone(
        zoneNumber: 2,
        label: 'Z2',
        effortLabel: 'Light',
        descriptiveLabel: 'Aerobic',
        lowerBound: 108,
        upperBound: 126,
        color: 0xFF81C784,
        lowerPercent: 0.6,
        upperPercent: 0.7,
      ),
    ],
    method: ZoneMethod.percentOfEstimatedMax,
    reliability: ZoneReliability.medium,
    maxHr: 180,
    reason: 'Estimated',
  );
}

List<HrReading> _readings(
  int count, {
  int startBpm = 100,
  int stepBpm = 1,
}) {
  return [
    for (var i = 0; i < count; i++)
      HrReading(
        bpm: startBpm + i * stepBpm,
        elapsed: Duration(seconds: i * 5),
      ),
  ];
}

// Readings that span enough of the BPM range for zone boundaries
// (90 / 108) to fall inside the chart's chartMinY..chartMaxY window.
List<HrReading> _spanningReadings() => _readings(10, startBpm: 95, stepBpm: 4);

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('HeartRateChart', () {
    testWidgets('shows the placeholder when no readings are provided',
        (tester) async {
      await tester.pumpWidget(host(const HeartRateChart(readings: [])));
      await tester.pumpAndSettle();

      expect(find.text('Waiting for heart rate data...'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renders a LineChart when readings are present',
        (tester) async {
      await tester.pumpWidget(host(HeartRateChart(readings: _readings(5))));
      await tester.pumpAndSettle();

      expect(find.text('Waiting for heart rate data...'), findsNothing);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets(
        'renders zone bands as range annotations when zoneConfig is set'
        ' and showZoneBands is true', (tester) async {
      await tester.pumpWidget(host(HeartRateChart(
        readings: _spanningReadings(),
        zoneConfig: _config(),
      )));
      await tester.pumpAndSettle();

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(
        chart.data.rangeAnnotations.horizontalRangeAnnotations,
        isNotEmpty,
      );
      expect(chart.data.extraLinesData.horizontalLines, isNotEmpty);
    });

    testWidgets(
        'omits range annotations when showZoneBands is false but keeps lines',
        (tester) async {
      await tester.pumpWidget(host(HeartRateChart(
        readings: _spanningReadings(),
        zoneConfig: _config(),
        showZoneBands: false,
      )));
      await tester.pumpAndSettle();

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.rangeAnnotations.horizontalRangeAnnotations, isEmpty);
      expect(chart.data.extraLinesData.horizontalLines, isNotEmpty);
    });

    testWidgets('omits zone overlays entirely when zoneConfig is null',
        (tester) async {
      await tester.pumpWidget(host(HeartRateChart(readings: _readings(5))));
      await tester.pumpAndSettle();

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.rangeAnnotations.horizontalRangeAnnotations, isEmpty);
      expect(chart.data.extraLinesData.horizontalLines, isEmpty);
    });

    testWidgets(
        'sliding window restricts the rendered range when windowSeconds is set',
        (tester) async {
      // 10 readings at 5s intervals → 0..45s range. With windowSeconds=20
      // the rendered window should start at elapsed=25s.
      final readings = _readings(10);
      await tester.pumpWidget(host(HeartRateChart(
        readings: readings,
        windowSeconds: 20,
      )));
      await tester.pumpAndSettle();

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      // minX is the start of the window (last.elapsed.inSeconds - 20).
      expect(chart.data.minX, 25.0);
    });
  });
}
