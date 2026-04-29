import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/history/presentation/widgets/date_group_header.dart';

void main() {
  group('DateGroupHeader', () {
    testWidgets('renders the supplied label uppercased', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DateGroupHeader(label: 'this week'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('this week'), findsNothing);
    });

    testWidgets('renders a separator line beside the label', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DateGroupHeader(label: 'last month'),
        ),
      ));
      await tester.pumpAndSettle();

      // The separator is built from a Container inside an Expanded.
      expect(find.byType(Expanded), findsOneWidget);
    });
  });
}
