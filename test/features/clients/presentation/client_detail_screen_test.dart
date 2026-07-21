import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/domain/models/client_plan_assignment.dart';
import 'package:rep_foundry/features/clients/domain/repositories/health_profile_repository.dart';
import 'package:rep_foundry/features/clients/presentation/screens/client_detail_screen.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// In-memory double for [HealthProfileRepository] keyed by client id, so
/// tests can both seed initial values and assert what got saved for a
/// specific client without touching Drift.
class _FakeHealthProfileRepository implements HealthProfileRepository {
  final Map<String, HealthProfile> _store = {};

  @override
  Future<HealthProfile> getForClient(String clientId) async {
    return _store[clientId] ?? const HealthProfile();
  }

  @override
  Future<void> saveForClient(String clientId, HealthProfile profile) async {
    _store[clientId] = profile;
  }
}

Client _client({required String id, required String name}) {
  final t = DateTime.utc(2024, 1, 1);
  return Client(
    id: id,
    name: name,
    colour: 0xFF4C6EF5,
    notes: null,
    isSelf: false,
    createdAt: t,
    updatedAt: t,
    deletedAt: null,
  );
}

void main() {
  // Every Drift-backed provider the screen reaches is overridden with an
  // in-memory double (mirroring client_switcher_test.dart), so plain
  // pumpAndSettle() is safe: none of these streams stay open indefinitely
  // the way a real Drift watch query does.
  testWidgets('detail shows the client and an assign-plan affordance',
      (tester) async {
    final sarah = _client(id: 'sarah', name: 'Sarah');
    final container = ProviderContainer(
      overrides: [
        clientsProvider.overrideWith((ref) => Stream.value([sarah])),
        clientAssignmentsProvider.overrideWith(
          (ref, clientId) => Stream.value(const <ClientPlanAssignment>[]),
        ),
        clientDetailTemplatesProvider.overrideWith(
          (ref) => Stream.value(const <WorkoutTemplate>[]),
        ),
        clientDetailProgrammesProvider.overrideWith(
          (ref) => Stream.value(const <Programme>[]),
        ),
        healthProfileRepositoryProvider
            .overrideWithValue(_FakeHealthProfileRepository()),
      ],
    );
    addTearDown(container.dispose);

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

  testWidgets(
      'saving the health profile form persists it for this client via '
      'healthProfileRepositoryProvider', (tester) async {
    final sarah = _client(id: 'sarah', name: 'Sarah');
    final healthRepo = _FakeHealthProfileRepository();
    final container = ProviderContainer(
      overrides: [
        clientsProvider.overrideWith((ref) => Stream.value([sarah])),
        clientAssignmentsProvider.overrideWith(
          (ref, clientId) => Stream.value(const <ClientPlanAssignment>[]),
        ),
        clientDetailTemplatesProvider.overrideWith(
          (ref) => Stream.value(const <WorkoutTemplate>[]),
        ),
        clientDetailProgrammesProvider.overrideWith(
          (ref) => Stream.value(const <Programme>[]),
        ),
        healthProfileRepositoryProvider.overrideWithValue(healthRepo),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: ClientDetailScreen(clientId: sarah.id),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Age'),
      '34',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Resting Heart Rate'),
      '52',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Measured Max Heart Rate'),
      '188',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Clinician Max Heart Rate'),
      '170',
    );
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Beta Blocker Medication'),
    );
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Heart Condition'),
    );
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Health profile saved'), findsOneWidget);

    final saved = await healthRepo.getForClient(sarah.id);
    expect(saved.age, 34);
    expect(saved.restingHr, 52);
    expect(saved.measuredMaxHr, 188);
    expect(saved.clinicianMaxHr, 170);
    expect(saved.betaBlocker, isTrue);
    expect(saved.heartCondition, isTrue);
  });
}
