import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/stretching/application/save_stretching_session_use_case.dart';
import 'package:rep_foundry/features/stretching/data/in_memory_stretching_session_repository.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';
import 'package:rep_foundry/features/stretching/presentation/widgets/add_stretching_sheet.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHost(InMemoryStretchingSessionRepository repo) {
    return ProviderScope(
      overrides: [
        stretchingSessionRepositoryProvider.overrideWithValue(repo),
        saveStretchingSessionUseCaseProvider.overrideWithValue(
          SaveStretchingSessionUseCase(repository: repo),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddStretchingSheet.show(context, 'w1'),
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
    );
  }

  group('AddStretchingSheet', () {
    testWidgets('opens without throwing a Riverpod lifecycle error',
        (tester) async {
      final repo = InMemoryStretchingSessionRepository();
      await tester.pumpWidget(buildHost(repo));

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      // Title visible, mode toggle present, no exceptions.
      expect(find.text('Add Stretching'), findsWidgets);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Timer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('untimed mode: pick preset, save persists with zero duration',
        (tester) async {
      final repo = InMemoryStretchingSessionRepository();
      await tester.pumpWidget(buildHost(repo));

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      // Pick Cobra Stretch.
      final cobra = find.widgetWithText(ChoiceChip, 'Cobra Stretch');
      await tester.ensureVisible(cobra);
      await tester.pumpAndSettle();
      await tester.tap(cobra);
      await tester.pumpAndSettle();

      // Tap the Untimed segment. SegmentedButton renders each segment as a
      // tappable region around its label, so tapping the text by itself can
      // miss — use ensureVisible + warnIfMissed=false to be robust.
      final untimedLabel = find.text('Untimed');
      await tester.ensureVisible(untimedLabel);
      await tester.pumpAndSettle();
      await tester.tap(untimedLabel, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Save.
      final saveButton = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final stored = await repo.getSessionsForWorkout('w1');
      expect(stored, hasLength(1));
      expect(stored.first.type, 'cobra');
      expect(stored.first.durationSeconds, 0);
      expect(stored.first.entryMethod, StretchingEntryMethod.untimed);
    });

    testWidgets('shows the Front Splits and Side Splits preset chips',
        (tester) async {
      final repo = InMemoryStretchingSessionRepository();
      await tester.pumpWidget(buildHost(repo));

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Front Splits'), findsOneWidget);
      expect(find.text('Side Splits (Middle Splits)'), findsOneWidget);
    });

    testWidgets(
        'manual entry: pick preset, set duration via quick chip, save persists',
        (tester) async {
      final repo = InMemoryStretchingSessionRepository();
      await tester.pumpWidget(buildHost(repo));

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      // Pick Pigeon Pose chip — find via the ChoiceChip ancestor so the tap
      // lands on the chip's gesture detector, not the inner Text.
      final pigeonChip = find.widgetWithText(ChoiceChip, 'Pigeon Pose');
      await tester.ensureVisible(pigeonChip);
      await tester.pumpAndSettle();
      await tester.tap(pigeonChip);
      await tester.pumpAndSettle();

      // Tap the 5-min quick-add chip.
      final fiveMinChip = find.widgetWithText(ActionChip, '5 min');
      await tester.ensureVisible(fiveMinChip);
      await tester.pumpAndSettle();
      await tester.tap(fiveMinChip);
      await tester.pumpAndSettle();

      // Save.
      final saveButton = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final stored = await repo.getSessionsForWorkout('w1');
      expect(stored, hasLength(1));
      expect(stored.first.type, 'pigeon');
      expect(stored.first.durationSeconds, 300);
    });
  });

  group('AddStretchingSheet search (#69)', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.pumpWidget(buildHost(InMemoryStretchingSessionRepository()));
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
    }

    Future<void> search(WidgetTester tester, String query) async {
      await tester.enterText(find.byKey(const Key('stretch-search')), query);
      await tester.pumpAndSettle();
    }

    Finder chip(String label) => find.widgetWithText(ChoiceChip, label);

    testWidgets('narrows the stretches to names that match', (tester) async {
      await openSheet(tester);
      expect(chip('Cobra Stretch'), findsOneWidget);

      await search(tester, 'split');

      expect(chip('Front Splits'), findsOneWidget);
      expect(chip('Side Splits (Middle Splits)'), findsOneWidget);
      expect(chip('Cobra Stretch'), findsNothing);
      expect(chip('Pigeon Pose'), findsNothing);
    });

    testWidgets('ignores case', (tester) async {
      await openSheet(tester);

      await search(tester, 'COBRA');

      expect(chip('Cobra Stretch'), findsOneWidget);
      expect(chip('Frog Pose'), findsNothing);
    });

    testWidgets('keeps Custom available while searching', (tester) async {
      await openSheet(tester);

      await search(tester, 'split');

      expect(chip('Custom\u2026'), findsOneWidget);
    });

    testWidgets('keeps the chosen stretch visible when it stops matching',
        (tester) async {
      await openSheet(tester);
      await tester.ensureVisible(chip('Cobra Stretch'));
      await tester.pumpAndSettle();
      await tester.tap(chip('Cobra Stretch'));
      await tester.pumpAndSettle();

      await search(tester, 'split');

      expect(chip('Cobra Stretch'), findsOneWidget);
      expect(chip('Frog Pose'), findsNothing);
    });

    testWidgets('clearing the search shows every stretch again',
        (tester) async {
      await openSheet(tester);
      await search(tester, 'split');

      await search(tester, '');

      expect(chip('Cobra Stretch'), findsOneWidget);
      expect(chip('Frog Pose'), findsOneWidget);
    });

    testWidgets('the clear button empties the search', (tester) async {
      await openSheet(tester);
      await search(tester, 'split');

      await tester.tap(find.descendant(
        of: find.byKey(const Key('stretch-search')),
        matching: find.byIcon(Icons.clear),
      ));
      await tester.pumpAndSettle();

      expect(chip('Cobra Stretch'), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('no match points to Custom, which takes the searched name',
        (tester) async {
      await openSheet(tester);
      expect(find.textContaining('No stretches match'), findsNothing);

      await search(tester, 'Thread the needle');

      expect(find.textContaining('No stretches match'), findsOneWidget);
      await tester.ensureVisible(chip('Custom\u2026'));
      await tester.pumpAndSettle();
      await tester.tap(chip('Custom\u2026'));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, 'Stretch name');
      expect(nameField, findsOneWidget);
      expect(
        tester.widget<TextField>(nameField).controller?.text,
        'Thread the needle',
      );
    });
  });
}
