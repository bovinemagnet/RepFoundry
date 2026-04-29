import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/bar_sparkline_widget.dart';

void main() {
  group('BarSparklineWidget', () {
    testWidgets('renders SizedBox.shrink when data is empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: BarSparklineWidget(data: []),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(BarSparklineWidget), findsOneWidget);
      final renderBox =
          tester.renderObject<RenderBox>(find.byType(BarSparklineWidget));
      // Empty data → SizedBox.shrink → zero-sized render box.
      expect(renderBox.size, Size.zero);
    });

    testWidgets('renders a CustomPaint when data is non-empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 40,
            child: BarSparklineWidget(data: [10, 20, 30, 25, 40]),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // BarSparklineWidget itself is a CustomPaint subtree — look for one
      // whose painter is non-null.
      final paints = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((cp) => cp.painter != null);
      expect(paints, isNotEmpty);
    });
  });
}
