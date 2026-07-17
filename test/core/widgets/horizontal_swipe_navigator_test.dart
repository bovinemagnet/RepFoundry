import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/horizontal_swipe_navigator.dart';

void main() {
  Widget build({
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    Widget? child,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HorizontalSwipeNavigator(
          onSwipeLeft: onSwipeLeft,
          onSwipeRight: onSwipeRight,
          child: child ?? const SizedBox.expand(),
        ),
      ),
    );
  }

  group('HorizontalSwipeNavigator', () {
    testWidgets('leftward fling calls onSwipeLeft', (tester) async {
      var leftCalls = 0;
      var rightCalls = 0;
      await tester.pumpWidget(build(
        onSwipeLeft: () => leftCalls++,
        onSwipeRight: () => rightCalls++,
      ));

      await tester.fling(
        find.byType(HorizontalSwipeNavigator),
        const Offset(-300, 0),
        1200,
      );
      await tester.pumpAndSettle();

      expect(leftCalls, 1);
      expect(rightCalls, 0);
    });

    testWidgets('rightward fling calls onSwipeRight', (tester) async {
      var leftCalls = 0;
      var rightCalls = 0;
      await tester.pumpWidget(build(
        onSwipeLeft: () => leftCalls++,
        onSwipeRight: () => rightCalls++,
      ));

      await tester.fling(
        find.byType(HorizontalSwipeNavigator),
        const Offset(300, 0),
        1200,
      );
      await tester.pumpAndSettle();

      expect(leftCalls, 0);
      expect(rightCalls, 1);
    });

    testWidgets('slow horizontal drag below the fling threshold is ignored',
        (tester) async {
      var leftCalls = 0;
      var rightCalls = 0;
      await tester.pumpWidget(build(
        onSwipeLeft: () => leftCalls++,
        onSwipeRight: () => rightCalls++,
      ));

      await tester.timedDrag(
        find.byType(HorizontalSwipeNavigator),
        const Offset(-100, 0),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();

      expect(leftCalls, 0);
      expect(rightCalls, 0);
    });

    testWidgets('vertical scrolling inside the child still works',
        (tester) async {
      var leftCalls = 0;
      var rightCalls = 0;
      await tester.pumpWidget(build(
        onSwipeLeft: () => leftCalls++,
        onSwipeRight: () => rightCalls++,
        child: ListView(
          children: [
            for (var i = 0; i < 40; i++)
              SizedBox(height: 50, child: Text('row $i')),
          ],
        ),
      ));

      expect(find.text('row 0'), findsOneWidget);
      await tester.fling(find.byType(ListView), const Offset(0, -400), 1200);
      await tester.pumpAndSettle();

      expect(find.text('row 0'), findsNothing);
      expect(leftCalls, 0);
      expect(rightCalls, 0);
    });

    testWidgets('missing callbacks are a no-op rather than an error',
        (tester) async {
      await tester.pumpWidget(build());

      await tester.fling(
        find.byType(HorizontalSwipeNavigator),
        const Offset(-300, 0),
        1200,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
