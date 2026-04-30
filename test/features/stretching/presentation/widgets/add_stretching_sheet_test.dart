import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/stretching/application/save_stretching_session_use_case.dart';
import 'package:rep_foundry/features/stretching/data/in_memory_stretching_session_repository.dart';
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
}
