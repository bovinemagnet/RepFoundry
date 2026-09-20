import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';
import 'package:rep_foundry/core/units/weight_unit_provider.dart';
import 'package:rep_foundry/features/clients/data/drift_client_repository.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:rep_foundry/features/settings/presentation/providers/clear_all_data_provider.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late db.AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('resets the active client to Me after wiping the database', () async {
    final alice = await DriftClientRepository(database)
        .createClient(Client.create(name: 'Alice', colour: 0));
    await container.read(activeClientProvider.notifier).setActive(alice);
    expect((await container.read(activeClientProvider.future)).id, alice.id);

    await container.read(clearAllDataProvider)();

    expect(
        (await container.read(activeClientProvider.future)).id, kSelfClientId);
  });

  test('drops the in-progress workout so a new one can be logged', () async {
    await container.read(activeClientProvider.future);
    final controller = container.read(activeWorkoutControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await controller.startWorkout();
    expect(container.read(activeWorkoutControllerProvider).activeWorkout,
        isNotNull);

    await container.read(clearAllDataProvider)();
    // Let the rebuilt controller finish its own initial load.
    while (container.read(activeWorkoutControllerProvider).isLoading) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(
        container.read(activeWorkoutControllerProvider).activeWorkout, isNull);
  });

  test('restores preference-backed settings to their defaults', () async {
    await container.read(weightUnitProvider.notifier).set(WeightUnit.lbs);
    expect(container.read(weightUnitProvider), WeightUnit.lbs);

    await container.read(clearAllDataProvider)();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(weightUnitProvider), WeightUnit.kg);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });
}
