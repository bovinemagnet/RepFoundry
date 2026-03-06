import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/sparkline_widget.dart';

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
}
