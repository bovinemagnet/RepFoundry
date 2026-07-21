import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/screens/client_detail_screen.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('detail shows the client and an assign-plan affordance',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final sarah = Client.create(name: 'Sarah', colour: 0xFF4C6EF5);
    await container.read(clientRepositoryProvider).createClient(sarah);
    await container
        .read(workoutTemplateRepositoryProvider)
        .createTemplate(WorkoutTemplate.create(name: 'Push Day'));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: ClientDetailScreen(clientId: sarah.id),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sarah'), findsOneWidget);
    expect(find.text('Assigned plans'), findsOneWidget);
    expect(find.text('Assign plan'), findsOneWidget);
  });
}
