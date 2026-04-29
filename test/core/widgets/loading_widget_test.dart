import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/loading_widget.dart';

void main() {
  group('LoadingWidget', () {
    testWidgets('shows only the spinner when no message is provided',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: LoadingWidget()),
      ));
      // pumpAndSettle would hang on the spinner's indefinite animation.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders the supplied message under the spinner',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: LoadingWidget(message: 'Loading workouts')),
      ));
      // pumpAndSettle would hang on the spinner's indefinite animation.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading workouts'), findsOneWidget);
    });
  });
}
