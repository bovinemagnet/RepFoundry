import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/history/presentation/providers/workout_history_provider.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('workout history reflects the active client', () async {
    SharedPreferences.setMockInitialValues({});
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final repo = container.read(workoutRepositoryProvider);
    final sarah = Client.create(name: 'Sarah', colour: 0);
    await container.read(clientRepositoryProvider).createClient(sarah);

    final mine = Workout.create();
    await repo.createWorkout(mine);
    await (database.update(database.workouts)
          ..where((t) => t.id.equals(mine.id)))
        .write(const db.WorkoutsCompanion(completedAt: Value(0)));

    await container.read(activeClientProvider.future);
    // Active = Me → sees the Me workout.
    final asMe = await container.read(workoutHistoryWithSetsProvider.future);
    expect(asMe.map((e) => e.workout.id), contains(mine.id));

    // Switch to Sarah → empty.
    await container.read(activeClientProvider.notifier).setActive(sarah);
    container.invalidate(workoutHistoryWithSetsProvider);
    final asSarah = await container.read(workoutHistoryWithSetsProvider.future);
    expect(asSarah, isEmpty);
  });
}
