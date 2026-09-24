import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/features/heart_rate/presentation/widgets/heart_rate_chart.dart';
import 'package:rep_foundry/features/heart_rate/presentation/widgets/zone_line_gradient.dart';

import '../../../../helpers/pixel_probe.dart';

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
        'renders without crashing when all readings exceed the zone maxHr',
        (tester) async {
      // A clinician-capped user (maxHr 180 here) whose readings all sit
      // above the cap must still get a chart, not an ArgumentError.
      await tester.pumpWidget(host(HeartRateChart(
        readings: _readings(5, startBpm: 205, stepBpm: 2),
        zoneConfig: _config(),
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LineChart), findsOneWidget);
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

  group('HeartRateChart zone-coloured line (#131)', () {
    const zone1 = Color(0xFF4FC3F7);
    const zone2 = Color(0xFF81C784);
    const probeKey = Key('probe');

    // 95..125 bpm: zone 1 (90–108) then zone 2 (108–126).
    List<HrReading> rising() => _readings(7, startBpm: 95, stepBpm: 5);

    LineChartBarData bar(WidgetTester tester) => tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .lineBarsData
        .single;

    testWidgets(
        'the line gradient spans the whole chart, so its zone edges sit on '
        'the threshold lines', (tester) async {
      await tester.pumpWidget(host(HeartRateChart(
        readings: rising(),
        zoneConfig: _config(),
      )));
      await tester.pumpAndSettle();

      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      final line = data.lineBarsData.single;
      final neutral = Theme.of(tester.element(find.byType(LineChart)))
          .colorScheme
          .onSurfaceVariant;

      expect(line.gradientArea, LineChartGradientArea.wholeChart);
      expect(
        line.gradient,
        zoneLineGradient(
          _config(),
          topBpm: data.maxY,
          bottomBpm: data.minY,
          belowZonesColour: neutral,
        ),
      );
    });

    testWidgets(
        'the fill gradient runs from the highest reading down to the chart '
        'floor, where fl_chart paints the area', (tester) async {
      await tester.pumpWidget(host(HeartRateChart(
        readings: rising(),
        zoneConfig: _config(),
      )));
      await tester.pumpAndSettle();

      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      final neutral = Theme.of(tester.element(find.byType(LineChart)))
          .colorScheme
          .onSurfaceVariant;

      expect(
        bar(tester).belowBarData.gradient,
        zoneLineGradient(
          _config(),
          topBpm: 125,
          bottomBpm: data.minY,
          belowZonesColour: neutral,
          opacity: 0.1,
        ),
      );
    });

    testWidgets('with zoneColouredLine off the line is a single colour',
        (tester) async {
      await tester.pumpWidget(host(HeartRateChart(
        readings: rising(),
        zoneConfig: _config(),
        zoneColouredLine: false,
      )));
      await tester.pumpAndSettle();

      final error =
          Theme.of(tester.element(find.byType(LineChart))).colorScheme.error;
      expect(bar(tester).gradient, isNull);
      expect(bar(tester).color, error);
      expect(bar(tester).belowBarData.gradient, isNull);
    });

    testWidgets('without zones the line is a single colour', (tester) async {
      await tester.pumpWidget(host(HeartRateChart(readings: rising())));
      await tester.pumpAndSettle();

      expect(bar(tester).gradient, isNull);
    });

    Future<PixelProbe> render(WidgetTester tester, bool zoneColoured) async {
      await tester.pumpWidget(host(Center(
        child: RepaintBoundary(
          key: probeKey,
          child: SizedBox(
            width: 336,
            child: HeartRateChart(
              readings: rising(),
              zoneConfig: _config(),
              showZoneBands: false,
              zoneColouredLine: zoneColoured,
            ),
          ),
        ),
      )));
      await tester.pumpAndSettle();
      return PixelProbe.capture(tester, find.byKey(probeKey));
    }

    bool anyIn(PixelProbe probe, Color colour, int fromX, int toX) {
      for (var x = fromX; x < toX; x++) {
        if (probe.columnContains(x, colour)) return true;
      }
      return false;
    }

    testWidgets('the painted line turns from zone 1 to zone 2 as BPM rises',
        (tester) async {
      final probe = await render(tester, true);

      // Plot area starts after the 36 px left axis. Low readings on the
      // left are in zone 1; high readings on the right are in zone 2.
      expect(anyIn(probe, zone1, 40, 90), isTrue);
      expect(anyIn(probe, zone2, 40, 90), isFalse);
      expect(anyIn(probe, zone2, 280, 330), isTrue);
      expect(anyIn(probe, zone1, 280, 330), isFalse);
    });

    testWidgets('positive control: a single-colour line paints no zone colours',
        (tester) async {
      final probe = await render(tester, false);

      expect(anyIn(probe, zone1, 36, 336), isFalse);
      expect(anyIn(probe, zone2, 36, 336), isFalse);
    });
  });
}
