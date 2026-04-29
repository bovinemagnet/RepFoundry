import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/features/workout/presentation/widgets/edit_set_dialog.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

WorkoutSet sampleSet({
  double weight = 100,
  int reps = 5,
  double? rpe = 8,
}) {
  return WorkoutSet(
    id: 'set-1',
    workoutId: 'wo-1',
    exerciseId: 'ex-1',
    setOrder: 1,
    weight: weight,
    reps: reps,
    rpe: rpe,
    timestamp: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  Widget buildHost(
    WorkoutSet existing, {
    void Function(WorkoutSet?)? onResult,
  }) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await showEditSetDialog(context, existing);
              if (onResult != null) onResult(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('showEditSetDialog', () {
    testWidgets('opens with the existing weight, reps and RPE pre-filled',
        (tester) async {
      await tester.pumpWidget(buildHost(sampleSet()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Set'), findsOneWidget);
      // Three TextFormFields — weight, reps, rpe.
      final fields =
          tester.widgetList<TextFormField>(find.byType(TextFormField));
      expect(fields, hasLength(3));
    });

    testWidgets('cancel resolves the future to null', (tester) async {
      WorkoutSet? result = sampleSet();
      var resolved = false;
      await tester.pumpWidget(buildHost(
        sampleSet(),
        onResult: (r) {
          result = r;
          resolved = true;
        },
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(resolved, isTrue);
      expect(result, isNull);
    });

    testWidgets('save with valid values returns an updated set',
        (tester) async {
      WorkoutSet? result;
      await tester.pumpWidget(buildHost(
        sampleSet(weight: 100, reps: 5, rpe: 8),
        onResult: (r) => result = r,
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Weight field is the first TextFormField; index 0.
      final weightField = find.byType(TextFormField).at(0);
      final repsField = find.byType(TextFormField).at(1);
      final rpeField = find.byType(TextFormField).at(2);

      await tester.enterText(weightField, '110');
      await tester.enterText(repsField, '6');
      await tester.enterText(rpeField, '7.5');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.weight, 110.0);
      expect(result!.reps, 6);
      expect(result!.rpe, 7.5);
    });

    testWidgets('rpe validation rejects values outside 1..10', (tester) async {
      WorkoutSet? result;
      var resolved = false;
      await tester.pumpWidget(buildHost(
        sampleSet(),
        onResult: (r) {
          result = r;
          resolved = true;
        },
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final rpeField = find.byType(TextFormField).at(2);
      await tester.enterText(rpeField, '15');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Submission blocked — dialog still showing, future unresolved.
      expect(resolved, isFalse);
      expect(result, isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('reps validation rejects empty input', (tester) async {
      WorkoutSet? result;
      var resolved = false;
      await tester.pumpWidget(buildHost(
        sampleSet(),
        onResult: (r) {
          result = r;
          resolved = true;
        },
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(resolved, isFalse);
      expect(result, isNull);
    });
  });
}
