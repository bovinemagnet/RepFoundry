import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/presentation/models/ghost_set.dart';
import 'package:rep_foundry/features/workout/presentation/widgets/set_input_card.dart';

void main() {
  group('SetInputCard', () {
    Widget buildCard({GhostSet? suggestion, Key? key}) {
      return MaterialApp(
        home: Scaffold(
          body: SetInputCard(
            key: key,
            onLogSet: (
                {required double weight, required int reps, double? rpe}) {},
            suggestion: suggestion,
          ),
        ),
      );
    }

    testWidgets('defaults to 0/0 when no suggestion', (tester) async {
      await tester.pumpWidget(buildCard());

      final weightField = find.widgetWithText(TextFormField, '0').first;
      expect(weightField, findsOneWidget);
    });

    testWidgets('pre-populates fields from suggestion', (tester) async {
      const suggestion = GhostSet(weight: 80, reps: 5, setOrder: 1);
      await tester.pumpWidget(buildCard(suggestion: suggestion));

      // Check weight field contains '80'.
      final weightFields = find.byType(TextFormField);
      expect(weightFields, findsAtLeast(2));

      // Extract controller text from the TextFormField widgets.
      final weightField = tester.widget<TextFormField>(weightFields.at(0));
      expect(weightField.controller?.text, '80');

      final repsField = tester.widget<TextFormField>(weightFields.at(1));
      expect(repsField.controller?.text, '5');
    });

    testWidgets('pre-populates RPE when suggestion has it', (tester) async {
      const suggestion = GhostSet(weight: 100, reps: 3, rpe: 9, setOrder: 1);
      await tester.pumpWidget(buildCard(suggestion: suggestion));

      // RPE should be shown since suggestion has rpe.
      final fields = find.byType(TextFormField);
      expect(fields, findsAtLeast(3));

      final rpeField = tester.widget<TextFormField>(fields.at(2));
      expect(rpeField.controller?.text, '9');
    });

    testWidgets('updates fields when suggestion changes', (tester) async {
      const suggestion1 = GhostSet(weight: 80, reps: 5, setOrder: 1);
      const suggestion2 = GhostSet(weight: 85, reps: 5, setOrder: 2);

      // Build with first suggestion using a ValueKey to keep state.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetInputCard(
              onLogSet: ({
                required double weight,
                required int reps,
                double? rpe,
              }) {},
              suggestion: suggestion1,
            ),
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      var weightField = tester.widget<TextFormField>(fields.at(0));
      expect(weightField.controller?.text, '80');

      // Rebuild with second suggestion.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetInputCard(
              onLogSet: ({
                required double weight,
                required int reps,
                double? rpe,
              }) {},
              suggestion: suggestion2,
            ),
          ),
        ),
      );

      weightField = tester.widget<TextFormField>(fields.at(0));
      expect(weightField.controller?.text, '85');
    });

    testWidgets('reverts to 0 when suggestion becomes null', (tester) async {
      const suggestion = GhostSet(weight: 80, reps: 5, setOrder: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetInputCard(
              onLogSet: ({
                required double weight,
                required int reps,
                double? rpe,
              }) {},
              suggestion: suggestion,
            ),
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      var weightField = tester.widget<TextFormField>(fields.at(0));
      expect(weightField.controller?.text, '80');

      // Rebuild without suggestion.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetInputCard(
              onLogSet: ({
                required double weight,
                required int reps,
                double? rpe,
              }) {},
              suggestion: null,
            ),
          ),
        ),
      );

      weightField = tester.widget<TextFormField>(fields.at(0));
      expect(weightField.controller?.text, '0');
    });
  });
}
