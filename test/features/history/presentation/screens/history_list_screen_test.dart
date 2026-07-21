import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/history/presentation/screens/history_list_screen.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// An [AsyncNotifier] override that resolves the active client to the fixed
/// "Me" client, without touching the database.
class _FixedActiveClientNotifier extends ActiveClientNotifier {
  _FixedActiveClientNotifier(this._client);

  final Client _client;

  @override
  Future<Client> build() async => _client;
}

final _meClient = Client(
  id: kSelfClientId,
  name: 'Me',
  colour: 0xFF4CAF50,
  notes: null,
  isSelf: true,
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
  deletedAt: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Every History/Progress provider derives from workoutRepositoryProvider, so a
  // single in-memory override drives the whole screen.
  Widget buildScreen(InMemoryWorkoutRepository repo) {
    return ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repo),
        activeClientProvider.overrideWith(
          () => _FixedActiveClientNotifier(_meClient),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: HistoryListScreen(),
      ),
    );
  }

  group('HistoryListScreen', () {
    testWidgets(
        'renders the two-tab shell and the empty state with no workouts',
        (tester) async {
      await tester.pumpWidget(buildScreen(InMemoryWorkoutRepository()));
      await tester.pumpAndSettle();

      // The History / Progress tab shell is always present.
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(2));

      // With no completed workouts, the History tab shows the empty state.
      expect(find.text('No workouts yet'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets(
        'renders the redesigned pagehead and a session card once a workout '
        'is completed', (tester) async {
      final repo = InMemoryWorkoutRepository();
      final now = DateTime.utc(2026, 6, 1, 9);
      await repo.createWorkout(
        Workout(
          id: 'w1',
          startedAt: now,
          completedAt: now.add(const Duration(minutes: 45)),
          clientId: kSelfClientId,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      // The pagehead title appears only when there is data; the empty state
      // must be gone and the screen must build cleanly.
      expect(find.text('Training History'), findsOneWidget);
      expect(find.text('No workouts yet'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
