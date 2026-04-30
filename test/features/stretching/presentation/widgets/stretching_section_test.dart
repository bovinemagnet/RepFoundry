import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/stretching/application/save_stretching_session_use_case.dart';
import 'package:rep_foundry/features/stretching/data/in_memory_stretching_session_repository.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';
import 'package:rep_foundry/features/stretching/presentation/widgets/stretching_section.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHost({
    required InMemoryStretchingSessionRepository repo,
    required String workoutId,
  }) {
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
          body: StretchingSection(workoutId: workoutId),
        ),
      ),
    );
  }

  group('StretchingSection', () {
    testWidgets('shows empty subtitle and Add Stretching CTA when empty',
        (tester) async {
      final repo = InMemoryStretchingSessionRepository();
      await tester.pumpWidget(buildHost(repo: repo, workoutId: 'w1'));
      await tester.pump();

      expect(find.text('Stretching'), findsOneWidget);
      expect(
        find.text('Add mobility, warm-up, or cool-down stretching.'),
        findsOneWidget,
      );
      expect(find.text('Add Stretching'), findsOneWidget);
    });

    testWidgets('shows entries and total when sessions exist', (tester) async {
      final repo = InMemoryStretchingSessionRepository();
      await repo.createSession(
        StretchingSession.create(
          workoutId: 'w1',
          type: 'pigeon',
          durationSeconds: 180,
          entryMethod: StretchingEntryMethod.manual,
        ),
      );
      await repo.createSession(
        StretchingSession.create(
          workoutId: 'w1',
          type: 'frontSplits',
          durationSeconds: 60,
          entryMethod: StretchingEntryMethod.manual,
        ),
      );

      await tester.pumpWidget(buildHost(repo: repo, workoutId: 'w1'));
      // Pump twice — once for the initial frame, once for the stream emission.
      await tester.pump();
      await tester.pump();

      expect(find.text('Pigeon Pose'), findsOneWidget);
      expect(find.text('Front Splits'), findsOneWidget);
      // Total: (180 + 60) / 60 = 4 minutes
      expect(find.textContaining('4 min total'), findsOneWidget);
      // Two entries shown.
      expect(find.text('2 entries'), findsNothing); // not the exact format
      expect(find.textContaining('entries'), findsOneWidget);
      // Compact CTA when populated.
      expect(find.text('Add'), findsOneWidget);
    });
  });
}
