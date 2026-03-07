import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/presentation/widgets/pr_celebration_overlay.dart';

void main() {
  group('PRCelebrationOverlay', () {
    testWidgets('renders exercise name and e1RM value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PRCelebrationOverlay(
              exerciseName: 'Bench Press',
              value: 120.5,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('New Personal Record!'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('e1RM: 120.5 kg'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('calls onDismiss on tap', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PRCelebrationOverlay(
              exerciseName: 'Squat',
              value: 200.0,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Let the entrance animation complete.
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PRCelebrationOverlay));
      // Let the reverse animation complete.
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('auto-dismisses after 3 seconds', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PRCelebrationOverlay(
              exerciseName: 'Deadlift',
              value: 180.0,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Advance past the 3-second auto-dismiss delay.
      await tester.pump(const Duration(seconds: 3));
      // Let the reverse animation complete.
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });
  });
}
