import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/workout/presentation/widgets/pr_celebration_overlay.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  group('PRCelebrationOverlay', () {
    testWidgets('renders exercise name and e1RM value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: PRCelebrationOverlay(
              exerciseName: 'Bench Press',
              value: 120.5,
              recordType: RecordType.estimatedOneRepMax,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('New e1RM PR!'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('120.5 kg e1RM'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('shows correct text for weight PR', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: PRCelebrationOverlay(
              exerciseName: 'Squat',
              value: 150.0,
              recordType: RecordType.maxWeight,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('New Weight PR!'), findsOneWidget);
      expect(find.text('150.0 kg'), findsOneWidget);
    });

    testWidgets('shows correct text for reps PR', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: PRCelebrationOverlay(
              exerciseName: 'Pull-ups',
              value: 15.0,
              recordType: RecordType.maxReps,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('New Rep PR!'), findsOneWidget);
      expect(find.text('15 reps'), findsOneWidget);
    });

    testWidgets('shows correct text for volume PR', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: PRCelebrationOverlay(
              exerciseName: 'Deadlift',
              value: 1200.0,
              recordType: RecordType.maxVolume,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('New Volume PR!'), findsOneWidget);
      expect(find.text('1200.0 kg volume'), findsOneWidget);
    });

    testWidgets('calls onDismiss on tap', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: PRCelebrationOverlay(
              exerciseName: 'Squat',
              value: 200.0,
              recordType: RecordType.estimatedOneRepMax,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(PRCelebrationOverlay));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('auto-dismisses after 3 seconds', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: PRCelebrationOverlay(
              exerciseName: 'Deadlift',
              value: 180.0,
              recordType: RecordType.estimatedOneRepMax,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });
  });
}
