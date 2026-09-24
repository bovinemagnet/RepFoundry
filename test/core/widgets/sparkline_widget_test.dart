import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/sparkline_widget.dart';

import '../../helpers/pixel_probe.dart';

void main() {
  Widget buildTestWidget(List<double> data) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 100,
          height: 40,
          child: SparklineWidget(data: data),
        ),
      ),
    );
  }

  group('SparklineWidget', () {
    testWidgets('renders without error with sample data', (tester) async {
      await tester.pumpWidget(buildTestWidget([10, 20, 15, 30, 25]));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders nothing for empty data', (tester) async {
      await tester.pumpWidget(buildTestWidget([]));

      // Should render a SizedBox.shrink instead of CustomPaint
      expect(find.byType(SparklineWidget), findsOneWidget);
      final sparkline = tester.widget<SparklineWidget>(
        find.byType(SparklineWidget),
      );
      expect(sparkline.data, isEmpty);
    });

    testWidgets('renders correctly with single data point', (tester) async {
      await tester.pumpWidget(buildTestWidget([42.0]));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly with flat data', (tester) async {
      await tester.pumpWidget(buildTestWidget([50, 50, 50, 50]));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts custom colours', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 40,
              child: SparklineWidget(
                data: const [1, 2, 3],
                lineColor: Colors.red,
                fillColor: Colors.red.withValues(alpha: 0.2),
                strokeWidth: 2.0,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('SparklineWidget gradients (#131)', () {
    const red = Color(0xFFFF0000);
    const blue = Color(0xFF0000FF);
    const green = Color(0xFF00FF00);
    const white = Color(0xFFFFFFFF);
    const probeKey = Key('probe');

    // Top half red, bottom half blue, with a hard edge in the middle.
    const splitGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [red, red, blue, blue],
      stops: [0, 0.5, 0.5, 1],
    );

    // A diagonal from bottom-left (0) to top-right (100) on a black square.
    Future<PixelProbe> paint(
      WidgetTester tester, {
      Gradient? lineGradient,
      Gradient? fillGradient,
    }) async {
      await tester.pumpWidget(
        Center(
          child: RepaintBoundary(
            key: probeKey,
            child: Container(
              width: 100,
              height: 100,
              color: const Color(0xFF000000),
              child: SparklineWidget(
                data: const [0, 25, 50, 75, 100],
                lineColor: white,
                fillColor: const Color(0x00000000),
                lineGradient: lineGradient,
                fillGradient: fillGradient,
                strokeWidth: 4,
              ),
            ),
          ),
        ),
      );
      return PixelProbe.capture(tester, find.byKey(probeKey));
    }

    testWidgets('without a gradient the line uses lineColor', (tester) async {
      final probe = await paint(tester);

      expect(probe.columnContains(90, white, toY: 50), isTrue);
      expect(probe.columnContains(10, white, fromY: 50), isTrue);
    });

    testWidgets('a line gradient colours the line by height', (tester) async {
      final probe = await paint(tester, lineGradient: splitGradient);

      // Near the top-right the line is high, so red; near the bottom-left
      // it is low, so blue.
      expect(probe.columnContains(90, red, toY: 50), isTrue);
      expect(probe.columnContains(90, blue), isFalse);
      expect(probe.columnContains(10, blue, fromY: 50), isTrue);
      expect(probe.columnContains(10, red), isFalse);
      expect(probe.columnContains(10, white), isFalse);
    });

    testWidgets('a fill gradient replaces the faded fillColor', (tester) async {
      const solidGreen = LinearGradient(colors: [green, green]);
      final probe = await paint(tester, fillGradient: solidGreen);

      // Well below the line at the right-hand side.
      expect(PixelProbe.isClose(probe.at(90, 80), green), isTrue);
      // Above the line stays the black background.
      expect(PixelProbe.isClose(probe.at(10, 20), const Color(0xFF000000)),
          isTrue);
    });
  });
}
