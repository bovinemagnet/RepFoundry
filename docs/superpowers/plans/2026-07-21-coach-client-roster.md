# Coach Client Roster (Local v1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let one coach manage several people from a single install — pick a client, then log and review that client's workouts, cardio, PRs, body metrics, and heart-rate zones — all locally, with existing single-user data migrated into a default "Me" client.

**Architecture:** Add a `clients` table (+ a fixed "Me" self-client), a `client_plan_assignments` join table, and a per-client `health_profiles` table. Add a `clientId` column to the four client-owned tables (`workouts`, `cardio_sessions`, `personal_records`, `body_metrics`) with a **DB-level default of the Me id**, so migration backfill and sync-inserts both resolve to "Me" for free. An `activeClientProvider` drives client-scoped repository queries and stamps writes. Roster/switcher UI sits on the existing responsive nav shell.

**Tech Stack:** Flutter, Riverpod 3, Drift/SQLite (drift_flutter), go_router 17, `hr_zones` package (HealthProfile), flutter_test + Drift `NativeDatabase.memory()`.

## Global Constraints

- British spelling in all user-facing copy, comments, and docs (e.g. "colour", "behaviour").
- All user-facing strings go in `lib/l10n/app_en.arb`; run `flutter gen-l10n` after edits; access via `S.of(context)!`. Widget tests set `localizationsDelegates: S.localizationsDelegates` and `supportedLocales: S.supportedLocales`.
- `dart analyze` must report zero issues; `dart format --set-exit-if-changed .` must pass.
- Missing return types are lint errors; prefer `const`/`final`.
- Regenerate Drift after table changes: `dart run build_runner build --delete-conflicting-outputs`.
- Author: Paul Snow. Version/`@since`: 0.0.0 where a tag is needed.
- Commit messages: no Claude/Anthropic mentions, no co-author lines.
- TDD: write the failing test before implementation in every code task.
- Follow existing patterns: immutable domain models with `const` ctors + `create` factories; Drift repos take `db.AppDatabase` via `import '../../../core/database/app_database.dart' as db;`; epoch-ms storage via `converters.dart`; enums stored as `.name`.

## Key Interfaces (shared across tasks)

Defined in Task 1 / Task 2, consumed everywhere after:

- **Self-client id constant** — `const String kSelfClientId = '00000000-0000-4000-8000-000000000001';` (top-level in `lib/features/clients/domain/models/client.dart`).
- **`Client`** — `{ String id, String name, int colour, String? notes, bool isSelf, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt }`; `const` ctor, `Client.create({required String name, required int colour, String? notes})`, `copyWith(...)`.
- **`PlanType`** — `enum PlanType { template, programme }`.
- **`ClientPlanAssignment`** — `{ String id, String clientId, PlanType planType, String planId, DateTime? startedAt, DateTime createdAt, DateTime updatedAt }`; `const` ctor, `ClientPlanAssignment.create({required String clientId, required PlanType planType, required String planId, DateTime? startedAt})`.
- **`clientId` on the four scoped models** — `String clientId` (non-null; defaults to `kSelfClientId` in each `create` factory).
- **Scoped repo methods** — each grows a required `String clientId` (exact signatures in Task 6).
- **Providers** — `clientRepositoryProvider`, `clientPlanAssignmentRepositoryProvider`, `clientsProvider` (`StreamProvider<List<Client>>`), `activeClientProvider` (`NotifierProvider<ActiveClientNotifier, Client>`).

---

## Phase A — Data foundation

### Task 1: Client and ClientPlanAssignment domain models

**Files:**
- Create: `lib/features/clients/domain/models/client.dart`
- Create: `lib/features/clients/domain/models/client_plan_assignment.dart`
- Test: `test/features/clients/domain/client_test.dart`
- Test: `test/features/clients/domain/client_plan_assignment_test.dart`

**Interfaces:**
- Produces: `kSelfClientId`, `Client`, `PlanType`, `ClientPlanAssignment` as in Key Interfaces.

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/clients/domain/client_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';

void main() {
  test('create sets a non-empty id and the given fields', () {
    final c = Client.create(name: 'Sarah', colour: 0xFF2196F3, notes: 'knee');
    expect(c.id, isNotEmpty);
    expect(c.name, 'Sarah');
    expect(c.colour, 0xFF2196F3);
    expect(c.notes, 'knee');
    expect(c.isSelf, isFalse);
  });

  test('copyWith replaces only named fields', () {
    final c = Client.create(name: 'Sarah', colour: 0xFF000000);
    final renamed = c.copyWith(name: 'Sarah J');
    expect(renamed.name, 'Sarah J');
    expect(renamed.id, c.id);
    expect(renamed.colour, c.colour);
  });

  test('self client id constant is stable', () {
    expect(kSelfClientId, '00000000-0000-4000-8000-000000000001');
  });
}
```

```dart
// test/features/clients/domain/client_plan_assignment_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/clients/domain/models/client_plan_assignment.dart';

void main() {
  test('create builds a template assignment with an id', () {
    final a = ClientPlanAssignment.create(
      clientId: 'c1',
      planType: PlanType.template,
      planId: 't1',
    );
    expect(a.id, isNotEmpty);
    expect(a.clientId, 'c1');
    expect(a.planType, PlanType.template);
    expect(a.planId, 't1');
    expect(a.startedAt, isNull);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/clients/domain/`
Expected: FAIL — model files don't exist (compile error).

- [ ] **Step 3: Implement the models**

```dart
// lib/features/clients/domain/models/client.dart
import 'package:uuid/uuid.dart';

/// Fixed id of the always-present "Me" client. The coach's own training data
/// lives here, and every pre-coach-mode row migrates into it.
const String kSelfClientId = '00000000-0000-4000-8000-000000000001';

/// A person the coach trains. Coach-owned; clients never log in.
class Client {
  const Client({
    required this.id,
    required this.name,
    required this.colour,
    required this.notes,
    required this.isSelf,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;
  final String name;

  /// ARGB accent colour used on the roster and switcher.
  final int colour;
  final String? notes;

  /// True for the single undeletable "Me" client.
  final bool isSelf;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory Client.create({
    required String name,
    required int colour,
    String? notes,
  }) {
    final now = DateTime.now().toUtc();
    return Client(
      id: const Uuid().v4(),
      name: name,
      colour: colour,
      notes: notes,
      isSelf: false,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    );
  }

  Client copyWith({
    String? name,
    int? colour,
    String? notes,
    bool clearNotes = false,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      colour: colour ?? this.colour,
      notes: clearNotes ? null : (notes ?? this.notes),
      isSelf: isSelf,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  bool operator ==(Object other) => other is Client && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
```

```dart
// lib/features/clients/domain/models/client_plan_assignment.dart
import 'package:uuid/uuid.dart';

/// Which library entity an assignment points at.
enum PlanType { template, programme }

/// A live-reference link from a client to a shared library template or
/// programme. Editing the library plan changes it for every assigned client.
class ClientPlanAssignment {
  const ClientPlanAssignment({
    required this.id,
    required this.clientId,
    required this.planType,
    required this.planId,
    required this.startedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clientId;
  final PlanType planType;
  final String planId;

  /// Anchors this client's programme week for a shared programme; null for
  /// templates or an unstarted programme.
  final DateTime? startedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ClientPlanAssignment.create({
    required String clientId,
    required PlanType planType,
    required String planId,
    DateTime? startedAt,
  }) {
    final now = DateTime.now().toUtc();
    return ClientPlanAssignment(
      id: const Uuid().v4(),
      clientId: clientId,
      planType: planType,
      planId: planId,
      startedAt: startedAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClientPlanAssignment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/clients/domain/`
Expected: PASS

- [ ] **Step 5: Analyse, format, commit**

```bash
dart analyze && dart format lib/features/clients test/features/clients
git add lib/features/clients test/features/clients
git commit -m "feat: client and plan-assignment domain models"
```

---

### Task 2: Drift tables, schema bump, and migration

**Files:**
- Create: `lib/core/database/tables/clients_table.dart`
- Create: `lib/core/database/tables/client_plan_assignments_table.dart`
- Create: `lib/core/database/tables/health_profiles_table.dart`
- Modify: `lib/core/database/tables/workouts_table.dart`, `cardio_sessions_table.dart`, `personal_records_table.dart`, `body_metrics_table.dart` (add `clientId`)
- Modify: `lib/core/database/app_database.dart` (register tables, bump `schemaVersionConst` 12→13, add migration, seed Me in `onCreate`)
- Test: `test/core/database/client_migration_test.dart`

**Interfaces:**
- Consumes: `kSelfClientId` (Task 1).
- Produces: generated Drift getters `database.clients`, `database.clientPlanAssignments`, `database.healthProfiles`; a `client_id` column (default `kSelfClientId`) on the four scoped tables; `schemaVersion == 13`; a "Me" client row created on both fresh installs and upgrades.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/database/client_migration_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/domain/models/client.dart';

void main() {
  test('fresh database has a Me self-client and scoped tables default to it',
      () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    // Me client exists and is self.
    final clients = await database.select(database.clients).get();
    expect(clients, hasLength(1));
    expect(clients.single.id, kSelfClientId);
    expect(clients.single.isSelf, isTrue);

    // A workout inserted without a client_id defaults to Me.
    await database.customStatement(
      "INSERT INTO workouts (id, started_at, updated_at) VALUES ('w1', 0, 0)",
    );
    final row = await database.customSelect(
      "SELECT client_id FROM workouts WHERE id = 'w1'",
    ).getSingle();
    expect(row.read<String>('client_id'), kSelfClientId);

    expect(database.schemaVersion, 13);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/database/client_migration_test.dart`
Expected: FAIL — tables/columns don't exist yet (compile or runtime error).

- [ ] **Step 3: Create the three new table files**

```dart
// lib/core/database/tables/clients_table.dart
import 'package:drift/drift.dart';

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get colour => integer()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSelf => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// lib/core/database/tables/client_plan_assignments_table.dart
import 'package:drift/drift.dart';

import 'clients_table.dart';

@TableIndex(
  name: 'idx_client_plan_assignments_unique',
  columns: {#clientId, #planType, #planId},
  unique: true,
)
class ClientPlanAssignments extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text().references(Clients, #id)();
  TextColumn get planType => text()();
  TextColumn get planId => text()();
  IntColumn get startedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// lib/core/database/tables/health_profiles_table.dart
import 'package:drift/drift.dart';

import 'clients_table.dart';

class HealthProfiles extends Table {
  TextColumn get clientId => text().references(Clients, #id)();
  IntColumn get age => integer().nullable()();
  IntColumn get restingHr => integer().nullable()();
  IntColumn get measuredMaxHr => integer().nullable()();
  IntColumn get clinicianMaxHr => integer().nullable()();
  BoolColumn get betaBlocker => boolean().withDefault(const Constant(false))();
  BoolColumn get heartCondition =>
      boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {clientId};
}
```

- [ ] **Step 4: Add `clientId` to the four scoped tables**

In each of `workouts_table.dart`, `cardio_sessions_table.dart`, `personal_records_table.dart`, `body_metrics_table.dart`, add the import and the column. Example for `workouts_table.dart` (do the identical edit in all four):

```dart
import 'package:drift/drift.dart';

import 'clients_table.dart';

class Workouts extends Table {
  TextColumn get id => text()();
  // ... existing columns unchanged ...
  TextColumn get clientId =>
      text().references(Clients, #id).withDefault(const Constant(kSelfClientIdConst))();
  @override
  Set<Column> get primaryKey => {id};
}
```

Because Drift table DSL needs a compile-time const, add this const to `clients_table.dart` and import it:

```dart
// at top of clients_table.dart, after imports
const String kSelfClientIdConst = '00000000-0000-4000-8000-000000000001';
```

Use `kSelfClientIdConst` in the four `withDefault` clauses (each table file imports `clients_table.dart`). It must equal `kSelfClientId` from Task 1 — a test in Task 3 asserts they match.

- [ ] **Step 5: Register tables, bump version, add migration, seed Me on create**

In `lib/core/database/app_database.dart`:

Add the three tables to the `@DriftDatabase(tables: [...])` list: `Clients, ClientPlanAssignments, HealthProfiles`.

Add the import for the self-client constant near the other imports:

```dart
import 'tables/clients_table.dart';
```

Bump the version:

```dart
static const int schemaVersionConst = 13;
```

In `onCreate`, seed the Me client alongside the exercises (Me must exist before any FK-referencing insert). Replace the existing `onCreate` body with:

```dart
onCreate: (m) async {
  await m.createAll();
  await batch((b) {
    b.insertAll(exercises, _defaultExercises);
    b.insert(clients, _selfClientCompanion());
  });
},
```

Add the migration step at the end of `onUpgrade`'s `if` chain:

```dart
if (from < 13) {
  await m.createTable(clients);
  await m.createTable(clientPlanAssignments);
  await m.createTable(healthProfiles);
  await into(clients).insert(_selfClientCompanion());
  for (final table in ['workouts', 'cardio_sessions', 'personal_records', 'body_metrics']) {
    await customStatement(
      'ALTER TABLE $table ADD COLUMN client_id TEXT NOT NULL '
      "DEFAULT '$kSelfClientIdConst' REFERENCES clients(id)",
    );
  }
  await m.createIndex(idxClientPlanAssignmentsUnique);
}
```

Add a private helper (near `_defaultExercises`):

```dart
ClientsCompanion _selfClientCompanion() => ClientsCompanion.insert(
      id: kSelfClientIdConst,
      name: 'Me',
      colour: 0xFF4CAF50,
      isSelf: const Value(true),
      createdAt: 0,
      updatedAt: const Value(0),
    );
```

(`idxClientPlanAssignmentsUnique` is the generated `@TableIndex` constant; confirm its generated name after codegen and adjust if the generator names it differently.)

- [ ] **Step 6: Regenerate Drift**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `app_database.g.dart` regenerates with the new tables/columns and no errors.

- [ ] **Step 7: Run the migration test**

Run: `flutter test test/core/database/client_migration_test.dart`
Expected: PASS

- [ ] **Step 8: Analyse, format, commit**

```bash
dart analyze && dart format lib/core/database test/core/database/client_migration_test.dart
git add lib/core/database test/core/database/client_migration_test.dart
git commit -m "feat: clients schema, Me self-client, and clientId columns"
```

---

### Task 3: clientId on the four scoped domain models and their repository mappers

**Files:**
- Modify: `lib/features/workout/domain/models/workout.dart`
- Modify: `lib/features/cardio/domain/models/cardio_session.dart`
- Modify: `lib/features/history/domain/models/personal_record.dart`
- Modify: `lib/features/body_metrics/domain/models/body_metric.dart`
- Modify: `lib/features/workout/data/drift_workout_repository.dart`, `lib/features/cardio/data/drift_cardio_session_repository.dart`, `lib/features/history/data/drift_personal_record_repository.dart`, `lib/features/body_metrics/data/drift_body_metric_repository.dart` (mappers + companions)
- Test: `test/features/clients/domain/self_client_const_test.dart`
- Test: extend an existing repo test, e.g. `test/features/workout/data/drift_workout_repository_test.dart`

**Interfaces:**
- Consumes: `kSelfClientId` (Task 1), `clientId` column (Task 2).
- Produces: `String clientId` on `Workout`, `CardioSession`, `PersonalRecord`, `BodyMetric`; each `create` factory gains `String clientId = kSelfClientId`; repo mappers read `row.clientId`; companions set `clientId`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/clients/domain/self_client_const_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/tables/clients_table.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';

void main() {
  test('domain and table self-client ids match', () {
    expect(kSelfClientId, kSelfClientIdConst);
  });
}
```

Add to `test/features/workout/data/drift_workout_repository_test.dart` (inside `main`):

```dart
  test('createWorkout persists and reads back clientId', () async {
    final w = Workout.create(clientId: 'client-42');
    await repo.createWorkout(w);
    final history = await repo.getWorkoutHistory(clientId: 'client-42');
    // Not yet completed, so history is empty; read the row directly instead.
    final row = await (database.select(database.workouts)
          ..where((t) => t.id.equals(w.id)))
        .getSingle();
    expect(row.clientId, 'client-42');
  });
```

(If `getWorkoutHistory(clientId:)` isn't available until Task 6, keep only the direct-row assertion above and drop the `history` line.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/clients/domain/self_client_const_test.dart`
Expected: FAIL — `kSelfClientIdConst` referenced but models/repos not yet updated / signature mismatch.

- [ ] **Step 3: Add `clientId` to each model**

For each model, add `final String clientId;` to the fields, the `const` constructor (as `required this.clientId`), the `create` factory (as `String clientId = kSelfClientId`), and `copyWith` where it exists (Workout, BodyMetric — add `String? clientId` and `clientId: clientId ?? this.clientId`). Import the constant: `import '../../../clients/domain/models/client.dart';` (adjust relative depth per file). Example for `Workout.create`:

```dart
factory Workout.create({String? templateId, String? notes, String clientId = kSelfClientId}) {
  final now = DateTime.now().toUtc();
  return Workout(
    id: const Uuid().v4(),
    startedAt: now,
    completedAt: null,
    templateId: templateId,
    notes: notes,
    clientId: clientId,
    updatedAt: now,
    deletedAt: null,
  );
}
```

`CardioSession` and `PersonalRecord` have no `copyWith`; just add the field, ctor param, and factory param.

- [ ] **Step 4: Update each repository mapper and companion**

In each Drift repo, add `clientId: Value(model.clientId)` to the `Companion.insert(...)` calls that write these entities, and `clientId: row.clientId` to the row→domain mapper. Example in `drift_workout_repository.dart` `_workoutToDomain`:

```dart
Workout _workoutToDomain(db.Workout row) => Workout(
      id: row.id,
      startedAt: dateTimeFromEpochMs(row.startedAt),
      completedAt: nullableDateTimeFromEpochMs(row.completedAt),
      templateId: row.templateId,
      notes: row.notes,
      clientId: row.clientId,
      updatedAt: dateTimeFromEpochMs(row.updatedAt),
      deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
    );
```

And in `createWorkout`'s companion: `clientId: Value(workout.clientId),`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/clients/domain/self_client_const_test.dart test/features/workout/data/drift_workout_repository_test.dart`
Expected: PASS. Then `flutter test` to confirm the model changes didn't break other suites.

- [ ] **Step 6: Analyse, format, commit**

```bash
dart analyze && dart format lib test
git add lib/features/workout lib/features/cardio lib/features/history lib/features/body_metrics test/features/clients test/features/workout
git commit -m "feat: add clientId to scoped domain models and repository mappers"
```

---

### Task 4: ClientRepository

**Files:**
- Create: `lib/features/clients/domain/repositories/client_repository.dart`
- Create: `lib/features/clients/data/drift_client_repository.dart`
- Modify: `lib/core/providers.dart` (add `clientRepositoryProvider`)
- Test: `test/features/clients/data/drift_client_repository_test.dart`

**Interfaces:**
- Consumes: `Client`, `kSelfClientId`; `databaseProvider`.
- Produces: `ClientRepository` (`watchClients()`, `getClient(String id)`, `getSelfClient()`, `createClient(Client)`, `updateClient(Client)`, `softDeleteClient(String id)`); `clientRepositoryProvider`. `softDeleteClient` throws `StateError` for the self client.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/clients/data/drift_client_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/data/drift_client_repository.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';

void main() {
  late db.AppDatabase database;
  late DriftClientRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftClientRepository(database);
  });
  tearDown(() => database.close());

  test('seeded Me client is returned and marked self', () async {
    final self = await repo.getSelfClient();
    expect(self.id, kSelfClientId);
    expect(self.isSelf, isTrue);
  });

  test('create then watch excludes soft-deleted', () async {
    final sarah = Client.create(name: 'Sarah', colour: 0xFF000000);
    await repo.createClient(sarah);
    expect((await repo.watchClients().first).map((c) => c.name), contains('Sarah'));

    await repo.softDeleteClient(sarah.id);
    expect((await repo.watchClients().first).map((c) => c.name),
        isNot(contains('Sarah')));
  });

  test('cannot soft-delete the self client', () async {
    expect(() => repo.softDeleteClient(kSelfClientId), throwsStateError);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/clients/data/drift_client_repository_test.dart`
Expected: FAIL — repository doesn't exist.

- [ ] **Step 3: Implement the interface and Drift repository**

```dart
// lib/features/clients/domain/repositories/client_repository.dart
import '../models/client.dart';

abstract class ClientRepository {
  Stream<List<Client>> watchClients();
  Future<Client?> getClient(String id);
  Future<Client> getSelfClient();
  Future<Client> createClient(Client client);
  Future<Client> updateClient(Client client);

  /// Soft-deletes a client. Throws [StateError] for the self client.
  Future<void> softDeleteClient(String id);
}
```

```dart
// lib/features/clients/data/drift_client_repository.dart
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/converters.dart';
import '../../domain/models/client.dart';
import '../../domain/repositories/client_repository.dart';

class DriftClientRepository implements ClientRepository {
  DriftClientRepository(this._db);

  final db.AppDatabase _db;

  @override
  Stream<List<Client>> watchClients() {
    final q = _db.select(_db.clients)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Client?> getClient(String id) async {
    final row = await (_db.select(_db.clients)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Client> getSelfClient() async {
    final row = await (_db.select(_db.clients)
          ..where((t) => t.id.equals(kSelfClientId)))
        .getSingle();
    return _toDomain(row);
  }

  @override
  Future<Client> createClient(Client client) async {
    await _db.into(_db.clients).insert(_toCompanion(client));
    return client;
  }

  @override
  Future<Client> updateClient(Client client) async {
    await (_db.update(_db.clients)..where((t) => t.id.equals(client.id)))
        .write(_toCompanion(client));
    return client;
  }

  @override
  Future<void> softDeleteClient(String id) async {
    if (id == kSelfClientId) {
      throw StateError('The self client cannot be deleted.');
    }
    await (_db.update(_db.clients)..where((t) => t.id.equals(id))).write(
      db.ClientsCompanion(
        deletedAt: Value(dateTimeToEpochMs(DateTime.now().toUtc())),
        updatedAt: Value(dateTimeToEpochMs(DateTime.now().toUtc())),
      ),
    );
  }

  Client _toDomain(db.Client row) => Client(
        id: row.id,
        name: row.name,
        colour: row.colour,
        notes: row.notes,
        isSelf: row.isSelf,
        createdAt: dateTimeFromEpochMs(row.createdAt),
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
        deletedAt: nullableDateTimeFromEpochMs(row.deletedAt),
      );

  db.ClientsCompanion _toCompanion(Client c) => db.ClientsCompanion.insert(
        id: c.id,
        name: c.name,
        colour: c.colour,
        notes: Value(c.notes),
        isSelf: Value(c.isSelf),
        createdAt: dateTimeToEpochMs(c.createdAt),
        updatedAt: Value(dateTimeToEpochMs(c.updatedAt)),
        deletedAt: Value(nullableDateTimeToEpochMs(c.deletedAt)),
      );
}
```

- [ ] **Step 4: Add the provider**

In `lib/core/providers.dart`, add the import and provider (near the other repository providers):

```dart
import '../features/clients/data/drift_client_repository.dart';
import '../features/clients/domain/repositories/client_repository.dart';
```

```dart
final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return DriftClientRepository(ref.watch(databaseProvider));
});
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/clients/data/drift_client_repository_test.dart`
Expected: PASS

- [ ] **Step 6: Analyse, format, commit**

```bash
dart analyze && dart format lib/features/clients lib/core/providers.dart test/features/clients/data
git add lib/features/clients lib/core/providers.dart test/features/clients/data
git commit -m "feat: ClientRepository with self-client delete guard"
```

---

### Task 5: ClientPlanAssignmentRepository

**Files:**
- Create: `lib/features/clients/domain/repositories/client_plan_assignment_repository.dart`
- Create: `lib/features/clients/data/drift_client_plan_assignment_repository.dart`
- Modify: `lib/core/providers.dart`
- Test: `test/features/clients/data/drift_client_plan_assignment_repository_test.dart`

**Interfaces:**
- Consumes: `ClientPlanAssignment`, `PlanType`; `databaseProvider`.
- Produces: `ClientPlanAssignmentRepository` (`watchAssignments(String clientId)`, `assign(String clientId, PlanType planType, String planId)`, `unassign(String assignmentId)`, `watchClientsForPlan(PlanType planType, String planId)`); `clientPlanAssignmentRepositoryProvider`. `assign` is idempotent (unique index).

- [ ] **Step 1: Write the failing test**

```dart
// test/features/clients/data/drift_client_plan_assignment_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/data/drift_client_plan_assignment_repository.dart';
import 'package:rep_foundry/features/clients/domain/models/client_plan_assignment.dart';

void main() {
  late db.AppDatabase database;
  late DriftClientPlanAssignmentRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftClientPlanAssignmentRepository(database);
  });
  tearDown(() => database.close());

  test('assign then watch by client', () async {
    await repo.assign('c1', PlanType.template, 't1');
    final list = await repo.watchAssignments('c1').first;
    expect(list, hasLength(1));
    expect(list.single.planId, 't1');
  });

  test('assign is idempotent', () async {
    await repo.assign('c1', PlanType.programme, 'p1');
    await repo.assign('c1', PlanType.programme, 'p1');
    expect(await repo.watchAssignments('c1').first, hasLength(1));
  });

  test('watchClientsForPlan is the reverse lookup', () async {
    await repo.assign('c1', PlanType.template, 't1');
    await repo.assign('c2', PlanType.template, 't1');
    expect(await repo.watchClientsForPlan(PlanType.template, 't1'),
        containsAll(['c1', 'c2']));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/clients/data/drift_client_plan_assignment_repository_test.dart`
Expected: FAIL — repository doesn't exist.

- [ ] **Step 3: Implement**

```dart
// lib/features/clients/domain/repositories/client_plan_assignment_repository.dart
import '../models/client_plan_assignment.dart';

abstract class ClientPlanAssignmentRepository {
  Stream<List<ClientPlanAssignment>> watchAssignments(String clientId);
  Future<void> assign(String clientId, PlanType planType, String planId);
  Future<void> unassign(String assignmentId);
  Future<List<String>> watchClientsForPlan(PlanType planType, String planId);
}
```

```dart
// lib/features/clients/data/drift_client_plan_assignment_repository.dart
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/converters.dart';
import '../../domain/models/client_plan_assignment.dart';
import '../../domain/repositories/client_plan_assignment_repository.dart';

class DriftClientPlanAssignmentRepository
    implements ClientPlanAssignmentRepository {
  DriftClientPlanAssignmentRepository(this._db);

  final db.AppDatabase _db;

  @override
  Stream<List<ClientPlanAssignment>> watchAssignments(String clientId) {
    final q = _db.select(_db.clientPlanAssignments)
      ..where((t) => t.clientId.equals(clientId));
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> assign(String clientId, PlanType planType, String planId) async {
    final assignment = ClientPlanAssignment.create(
      clientId: clientId,
      planType: planType,
      planId: planId,
    );
    await _db.into(_db.clientPlanAssignments).insert(
          db.ClientPlanAssignmentsCompanion.insert(
            id: assignment.id,
            clientId: assignment.clientId,
            planType: assignment.planType.name,
            planId: assignment.planId,
            startedAt: Value(nullableDateTimeToEpochMs(assignment.startedAt)),
            createdAt: dateTimeToEpochMs(assignment.createdAt),
            updatedAt: Value(dateTimeToEpochMs(assignment.updatedAt)),
          ),
          mode: InsertMode.insertOrIgnore, // idempotent on the unique index
        );
  }

  @override
  Future<void> unassign(String assignmentId) async {
    await (_db.delete(_db.clientPlanAssignments)
          ..where((t) => t.id.equals(assignmentId)))
        .go();
  }

  @override
  Future<List<String>> watchClientsForPlan(
    PlanType planType,
    String planId,
  ) async {
    final q = _db.select(_db.clientPlanAssignments)
      ..where((t) =>
          t.planType.equals(planType.name) & t.planId.equals(planId));
    final rows = await q.get();
    return rows.map((r) => r.clientId).toList();
  }

  ClientPlanAssignment _toDomain(db.ClientPlanAssignment row) =>
      ClientPlanAssignment(
        id: row.id,
        clientId: row.clientId,
        planType: enumFromString(PlanType.values, row.planType),
        planId: row.planId,
        startedAt: nullableDateTimeFromEpochMs(row.startedAt),
        createdAt: dateTimeFromEpochMs(row.createdAt),
        updatedAt: dateTimeFromEpochMs(row.updatedAt),
      );
}
```

- [ ] **Step 4: Add the provider**

In `lib/core/providers.dart`:

```dart
import '../features/clients/data/drift_client_plan_assignment_repository.dart';
import '../features/clients/domain/repositories/client_plan_assignment_repository.dart';
```

```dart
final clientPlanAssignmentRepositoryProvider =
    Provider<ClientPlanAssignmentRepository>((ref) {
  return DriftClientPlanAssignmentRepository(ref.watch(databaseProvider));
});
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/clients/data/drift_client_plan_assignment_repository_test.dart`
Expected: PASS

- [ ] **Step 6: Analyse, format, commit**

```bash
dart analyze && dart format lib/features/clients lib/core/providers.dart test/features/clients/data
git add lib/features/clients lib/core/providers.dart test/features/clients/data
git commit -m "feat: client plan-assignment repository"
```

---

### Task 6: Client-scoped query methods on the four existing repositories

Add a required `String clientId` to the read/query methods that back the scoped screens, filtering in SQL, and update all direct callers to pass the active client (callers that are Riverpod providers are rewired in Task 9; here, update non-provider callers and use-case call sites so the app compiles).

**Files:**
- Modify: `lib/features/workout/domain/repositories/workout_repository.dart` + `data/drift_workout_repository.dart`
- Modify: `lib/features/cardio/domain/repositories/cardio_session_repository.dart` + `data/drift_cardio_session_repository.dart`
- Modify: `lib/features/history/domain/repositories/personal_record_repository.dart` + `data/drift_personal_record_repository.dart`
- Modify: `lib/features/body_metrics/domain/repositories/body_metric_repository.dart` + `data/drift_body_metric_repository.dart`
- Test: extend each repo's existing test file with an isolation test.

**Interfaces:**
- Produces (exact new signatures):
  - Workout: `Future<List<Workout>> getWorkoutHistory({required String clientId, int limit = 20, DateTime? before})`; `Stream<List<Workout>> watchWorkoutHistory(String clientId)`; `Future<List<WorkoutSet>> getSetsFromLastSession(String exerciseId, String clientId)`.
  - Cardio: `Future<List<CardioSession>> getAllSessions(String clientId)`; `Future<List<CardioSession>> getSessionsForExercise(String exerciseId, String clientId)`; `Future<CardioSession?> getLastSessionForExercise(String exerciseId, String clientId)`.
  - PR: `Future<List<PersonalRecord>> getAllRecords({required String clientId, int limit = 50})`; `Future<List<PersonalRecord>> getRecordsForExercise(String exerciseId, String clientId)`; `Future<PersonalRecord?> getBestRecord(String exerciseId, RecordType type, String clientId)`.
  - Body metric: `Stream<List<BodyMetric>> watchAll(String clientId)`; `Future<List<BodyMetric>> getAll({required String clientId, int limit = 100})`; `Future<BodyMetric?> getLatest(String clientId)`.

- [ ] **Step 1: Write a failing isolation test (per repo — workout shown; mirror for the others)**

Add to `test/features/workout/data/drift_workout_repository_test.dart`:

```dart
  test('getWorkoutHistory is scoped to the client', () async {
    final a = Workout.create(clientId: 'A').copyWith(
      completedAt: DateTime.now().toUtc(),
    );
    final b = Workout.create(clientId: 'B').copyWith(
      completedAt: DateTime.now().toUtc(),
    );
    await repo.createWorkout(a);
    await repo.createWorkout(b);
    // Mark them completed so history includes them.
    await (database.update(database.workouts)..where((t) => t.id.equals(a.id)))
        .write(db.WorkoutsCompanion(completedAt: Value(0)));
    await (database.update(database.workouts)..where((t) => t.id.equals(b.id)))
        .write(db.WorkoutsCompanion(completedAt: Value(0)));

    final onlyA = await repo.getWorkoutHistory(clientId: 'A');
    expect(onlyA.map((w) => w.id), [a.id]);
  });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/workout/data/drift_workout_repository_test.dart`
Expected: FAIL — `getWorkoutHistory` doesn't accept `clientId`.

- [ ] **Step 3: Add `clientId` to each interface method and its Drift implementation**

Workout `getWorkoutHistory` (add the `clientId` filter to the existing `where`):

```dart
@override
Future<List<Workout>> getWorkoutHistory({
  required String clientId,
  int limit = 20,
  DateTime? before,
}) async {
  final q = _db.select(_db.workouts)
    ..where((t) =>
        t.clientId.equals(clientId) &
        t.completedAt.isNotNull() &
        t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
    ..limit(limit);
  if (before != null) {
    q.where((t) => t.startedAt.isSmallerThanValue(dateTimeToEpochMs(before)));
  }
  final rows = await q.get();
  return rows.map(_workoutToDomain).toList();
}
```

`watchWorkoutHistory(String clientId)` — add `t.clientId.equals(clientId) &` to its `where`.

`getSetsFromLastSession(String exerciseId, String clientId)` — add the client clause to the raw SQL and bind it:

```dart
final workoutIdResult = await _db.customSelect(
  'SELECT w.id FROM workouts w '
  'INNER JOIN workout_sets ws ON ws.workout_id = w.id '
  'WHERE ws.exercise_id = ? '
  'AND w.client_id = ? '
  'AND w.completed_at IS NOT NULL '
  'AND w.deleted_at IS NULL '
  'ORDER BY w.started_at DESC '
  'LIMIT 1',
  variables: [Variable.withString(exerciseId), Variable.withString(clientId)],
).getSingleOrNull();
```

Apply the equivalent `clientId` filter to the cardio, PR, and body-metric methods listed in Interfaces (each adds `t.clientId.equals(clientId)` to its `where`, or `AND client_id = ?` to raw SQL).

- [ ] **Step 4: Update non-provider callers so the app compiles**

Search for direct callers of the changed methods and pass a client id. The active-workout ghost-set calls in `active_workout_controller.dart` (`getSetsFromLastSession(exercise.id)` at the two sites) become `getSetsFromLastSession(exercise.id, ref.read(activeClientProvider).id)` — but `activeClientProvider` lands in Task 7. To keep this task self-contained and compiling, temporarily pass `kSelfClientId` at these call sites and add a `// TODO(coach): active client — Task 8` marker; Task 8 replaces them. (This is the one permitted interim constant, removed in Task 8.)

Run to find all callers:

```bash
grep -rn "getWorkoutHistory(\|watchWorkoutHistory(\|getSetsFromLastSession(\|getAllSessions(\|getSessionsForExercise(\|getLastSessionForExercise(\|getAllRecords(\|getRecordsForExercise(\|getBestRecord(\|\.watchAll(\|\.getAll(\|getLatest(" lib/ | grep -v "_test.dart"
```

Provider call sites are rewired in Task 9; for now pass `clientId: kSelfClientId` (named) or `kSelfClientId` (positional) so everything compiles.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test`
Expected: PASS (all suites; the isolation tests you added are green).

- [ ] **Step 6: Analyse, format, commit**

```bash
dart analyze && dart format lib test
git add lib test
git commit -m "feat: client-scoped query methods on scoped repositories"
```

---

## Phase B — State and write path

### Task 7: clientsProvider and activeClientProvider

**Files:**
- Create: `lib/features/clients/presentation/providers/active_client_provider.dart`
- Modify: `lib/core/providers.dart` (add `clientsProvider`)
- Test: `test/features/clients/presentation/active_client_provider_test.dart`

**Interfaces:**
- Consumes: `clientRepositoryProvider`, `Client`, `kSelfClientId`.
- Produces: `clientsProvider` (`StreamProvider<List<Client>>`); `activeClientProvider` (`NotifierProvider<ActiveClientNotifier, Client>`), which defaults to the self client, persists the last-active id under SharedPreferences key `active_client_id`, and exposes `setActive(Client)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/clients/presentation/active_client_provider_test.dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/providers/active_client_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to the self client', () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final client = await container.read(activeClientProvider.future);
    expect(client.id, kSelfClientId);
  });

  test('setActive persists and updates the active client', () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    await container.read(activeClientProvider.future);
    final sarah = Client.create(name: 'Sarah', colour: 0xFF000000);
    await container.read(clientRepositoryProvider).createClient(sarah);
    await container.read(activeClientProvider.notifier).setActive(sarah);

    expect(container.read(activeClientProvider).value?.id, sarah.id);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('active_client_id'), sarah.id);
  });
}
```

(If an async `Notifier` complicates the container reads, implement `activeClientProvider` as an `AsyncNotifierProvider<ActiveClientNotifier, Client>` — the test above uses `.future`/`.value` accordingly.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/clients/presentation/active_client_provider_test.dart`
Expected: FAIL — provider file doesn't exist.

- [ ] **Step 3: Implement**

```dart
// lib/features/clients/presentation/providers/active_client_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers.dart';
import '../../domain/models/client.dart';

const _activeClientKey = 'active_client_id';

class ActiveClientNotifier extends AsyncNotifier<Client> {
  @override
  Future<Client> build() async {
    final repo = ref.watch(clientRepositoryProvider);
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_activeClientKey);
    if (savedId != null) {
      final saved = await repo.getClient(savedId);
      if (saved != null && saved.deletedAt == null) return saved;
    }
    return repo.getSelfClient();
  }

  Future<void> setActive(Client client) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeClientKey, client.id);
    state = AsyncData(client);
  }
}

final activeClientProvider =
    AsyncNotifierProvider<ActiveClientNotifier, Client>(
        ActiveClientNotifier.new);
```

In `lib/core/providers.dart`, add:

```dart
final clientsProvider = StreamProvider<List<Client>>((ref) {
  return ref.watch(clientRepositoryProvider).watchClients();
});
```

(with `import '../features/clients/domain/models/client.dart';`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/clients/presentation/active_client_provider_test.dart`
Expected: PASS

- [ ] **Step 5: Analyse, format, commit**

```bash
dart analyze && dart format lib/features/clients lib/core/providers.dart test/features/clients/presentation
git add lib/features/clients lib/core/providers.dart test/features/clients/presentation
git commit -m "feat: clients and active-client providers"
```

---

### Task 8: Thread the active client into the write path

Stamp the active client on every new workout, cardio session, PR, and body metric, and scope ghost-set lookups. Replace the interim `kSelfClientId` placeholders from Task 6.

**Files:**
- Modify: `lib/features/workout/application/start_workout_use_case.dart` (accept `clientId`)
- Modify: `lib/features/workout/presentation/controllers/active_workout_controller.dart` (pass active client to start + ghost lookups)
- Modify: `lib/features/workout/application/log_set_use_case.dart` (stamp `clientId` on created PRs)
- Modify: cardio session creation call site + `lib/features/body_metrics/...` create call site
- Test: `test/features/workout/application/start_workout_use_case_test.dart` (extend)

**Interfaces:**
- Consumes: `activeClientProvider` (Task 7), `Workout.create(clientId:)`, `PersonalRecord.create(clientId:)`, `CardioSession.create(clientId:)`, `BodyMetric.create(clientId:)`.

- [ ] **Step 1: Write the failing test**

```dart
// add to test/features/workout/application/start_workout_use_case_test.dart
  test('execute stamps the given clientId on the new workout', () async {
    final useCase = StartWorkoutUseCase(fakeRepo);
    final workout = await useCase.execute(clientId: 'client-9');
    expect(workout.clientId, 'client-9');
  });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/workout/application/start_workout_use_case_test.dart`
Expected: FAIL — `execute` doesn't accept `clientId`.

- [ ] **Step 3: Thread `clientId` through the use case and controller**

`StartWorkoutUseCase.execute` — add `required String clientId` (or `String clientId = kSelfClientId`) and pass to `Workout.create(templateId: templateId, clientId: clientId)`.

In `active_workout_controller.dart`, resolve the active client and pass it:

```dart
final clientId = ref.read(activeClientProvider).value?.id ?? kSelfClientId;
final workout = await ref
    .read(startWorkoutUseCaseProvider)
    .execute(clientId: clientId); // and templateId/programme variants
```

Replace the two ghost-set calls (from Task 6) with the real active client:

```dart
await _workoutRepository.getSetsFromLastSession(exercise.id, clientId);
```

resolving `clientId` from `activeClientProvider` at each call site. Remove the Task-6 `// TODO(coach)` markers.

`LogSetUseCase` — when it creates a `PersonalRecord`, stamp the workout's `clientId`. The use case already has the workout (or its id); pass `clientId` into `PersonalRecord.create(..., clientId: clientId)`. If the use case only has `workoutId`, add a `clientId` parameter to `execute(...)` and have the controller pass the active client.

Cardio and body-metric create call sites — pass the active client id into `CardioSession.create(..., clientId: clientId)` and `BodyMetric.create(..., clientId: clientId)`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test`
Expected: PASS. Grep to confirm no interim placeholder remains in write paths:

```bash
grep -rn "TODO(coach)" lib/ && echo "FIX REMAINING" || echo "clean"
```

- [ ] **Step 5: Analyse, format, commit**

```bash
dart analyze && dart format lib test
git add lib test
git commit -m "feat: stamp active client on workouts, PRs, cardio, and body metrics"
```

---

### Task 9: Scope the read providers to the active client

Rewire every unscoped read provider to watch `activeClientProvider` and pass its id to the now-scoped repository methods.

**Files:**
- Modify: `lib/features/history/presentation/providers/workout_history_provider.dart`
- Modify: `lib/features/analytics/presentation/providers/weekly_volume_provider.dart`, `muscle_balance_provider.dart`, `pr_timeline_provider.dart`, `training_load_provider.dart`
- Modify: `lib/features/history/presentation/screens/pr_history_screen.dart` (`_prHistoryProvider`)
- Modify: `lib/core/providers.dart` (`bodyMetricsStreamProvider`)
- Modify: `lib/features/history/presentation/providers/` — `muscle_group_distribution_provider.dart`, `streak_provider.dart`, `trained_exercises_provider.dart`, `volume_sparkline_provider.dart`, `workout_duration_chart_provider.dart`, `workout_frequency_provider.dart`, `workout_volume_chart_provider.dart`
- Modify: cardio history read sites (`cardio_tracking_screen.dart` and any `getAllSessions`/`getSessionsForExercise` callers)
- Test: `test/features/history/presentation/workout_history_scoping_test.dart`

**Interfaces:**
- Consumes: `activeClientProvider`, the Task-6 scoped repo methods.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/history/presentation/workout_history_scoping_test.dart
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
    await (database.update(database.workouts)..where((t) => t.id.equals(mine.id)))
        .write(db.WorkoutsCompanion(completedAt: Value(0)));

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
```

(Adjust the record type of `workoutHistoryWithSetsProvider`'s elements to match the existing provider — `.workout.id` if it returns a record/class with a `workout` field.)

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/history/presentation/workout_history_scoping_test.dart`
Expected: FAIL — the provider ignores the active client.

- [ ] **Step 3: Rewire each provider**

The uniform change per provider: read the active client and pass its id. Example for `workout_history_provider.dart`:

```dart
final workoutHistoryWithSetsProvider =
    FutureProvider.autoDispose<List<WorkoutWithSets>>((ref) async {
  final clientId = (await ref.watch(activeClientProvider.future)).id;
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(clientId: clientId, limit: 50);
  // ... unchanged set-fetching logic ...
});
```

Apply the same pattern (`final clientId = (await ref.watch(activeClientProvider.future)).id;` then pass to the scoped repo call) to every provider in Files. For `bodyMetricsStreamProvider` (a `StreamProvider`), switch to watching the active client then the scoped stream:

```dart
final bodyMetricsStreamProvider =
    StreamProvider.autoDispose<List<BodyMetric>>((ref) {
  final clientAsync = ref.watch(activeClientProvider);
  final client = clientAsync.valueOrNull;
  if (client == null) return const Stream.empty();
  return ref.watch(bodyMetricRepositoryProvider).watchAll(client.id);
});
```

For cardio read sites, pass the active client id into `getAllSessions(clientId)` / `getSessionsForExercise(exerciseId, clientId)`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test`
Expected: PASS. Confirm no unscoped call remains:

```bash
grep -rn "getWorkoutHistory(limit\|\.watchAll()\|getAllRecords(limit\|getAllSessions()" lib/ && echo "UNSCOPED LEFT" || echo "all scoped"
```

- [ ] **Step 5: Analyse, format, commit**

```bash
dart analyze && dart format lib test
git add lib test
git commit -m "feat: scope history, analytics, and body-metric providers to active client"
```

---

### Task 10: Per-client health profile

Back `HealthProfileNotifier` with the `health_profiles` table keyed by the active client, and migrate the existing SharedPreferences profile into the Me row once.

**Files:**
- Create: `lib/features/clients/domain/repositories/health_profile_repository.dart`
- Create: `lib/features/clients/data/drift_health_profile_repository.dart`
- Modify: `lib/features/heart_rate/presentation/providers/health_profile_provider.dart` (load/save per active client + one-time SharedPreferences→Me migration)
- Modify: `lib/core/providers.dart` (add `healthProfileRepositoryProvider`)
- Test: `test/features/clients/data/drift_health_profile_repository_test.dart`
- Test: `test/features/heart_rate/presentation/per_client_health_profile_test.dart`

**Interfaces:**
- Consumes: `HealthProfile` (from `package:hr_zones/hr_zones.dart`), `activeClientProvider`, `databaseProvider`.
- Produces: `HealthProfileRepository` (`getForClient(String clientId) → HealthProfile`, `saveForClient(String clientId, HealthProfile)`); `healthProfileRepositoryProvider`. `healthProfileProvider` now reflects the active client.

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/clients/data/drift_health_profile_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/data/drift_health_profile_repository.dart';

void main() {
  late db.AppDatabase database;
  late DriftHealthProfileRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftHealthProfileRepository(database);
  });
  tearDown(() => database.close());

  test('missing profile returns a default HealthProfile', () async {
    final p = await repo.getForClient('nobody');
    expect(p.age, isNull);
  });

  test('save then read round-trips per client', () async {
    await repo.saveForClient('c1', const HealthProfile(age: 40, restingHr: 55));
    await repo.saveForClient('c2', const HealthProfile(age: 25));
    expect((await repo.getForClient('c1')).age, 40);
    expect((await repo.getForClient('c1')).restingHr, 55);
    expect((await repo.getForClient('c2')).age, 25);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/clients/data/drift_health_profile_repository_test.dart`
Expected: FAIL — repository doesn't exist.

- [ ] **Step 3: Implement the repository**

```dart
// lib/features/clients/domain/repositories/health_profile_repository.dart
import 'package:hr_zones/hr_zones.dart';

abstract class HealthProfileRepository {
  Future<HealthProfile> getForClient(String clientId);
  Future<void> saveForClient(String clientId, HealthProfile profile);
}
```

```dart
// lib/features/clients/data/drift_health_profile_repository.dart
import 'package:drift/drift.dart';
import 'package:hr_zones/hr_zones.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/repositories/health_profile_repository.dart';

class DriftHealthProfileRepository implements HealthProfileRepository {
  DriftHealthProfileRepository(this._db);

  final db.AppDatabase _db;

  @override
  Future<HealthProfile> getForClient(String clientId) async {
    final row = await (_db.select(_db.healthProfiles)
          ..where((t) => t.clientId.equals(clientId)))
        .getSingleOrNull();
    if (row == null) return const HealthProfile();
    return HealthProfile(
      age: row.age,
      restingHr: row.restingHr,
      measuredMaxHr: row.measuredMaxHr,
      clinicianMaxHr: row.clinicianMaxHr,
      betaBlocker: row.betaBlocker,
      heartCondition: row.heartCondition,
    );
  }

  @override
  Future<void> saveForClient(String clientId, HealthProfile p) async {
    await _db.into(_db.healthProfiles).insertOnConflictUpdate(
          db.HealthProfilesCompanion.insert(
            clientId: clientId,
            age: Value(p.age),
            restingHr: Value(p.restingHr),
            measuredMaxHr: Value(p.measuredMaxHr),
            clinicianMaxHr: Value(p.clinicianMaxHr),
            betaBlocker: Value(p.betaBlocker),
            heartCondition: Value(p.heartCondition),
            updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          ),
        );
  }
}
```

- [ ] **Step 4: Rewire `HealthProfileNotifier` to the active client, with one-time migration**

Change `HealthProfileNotifier` so `build()` watches `activeClientProvider`, reads that client's profile from `healthProfileRepositoryProvider`, and its mutators (`updateAge`, etc.) write back via the repository for the active client id. On first run, migrate the existing SharedPreferences fields into the Me client's row and set a done-flag key `health_profile_migrated_v1`:

```dart
@override
Future<HealthProfile> build() async {
  await _migrateLegacyProfileOnce();
  final client = await ref.watch(activeClientProvider.future);
  return ref.watch(healthProfileRepositoryProvider).getForClient(client.id);
}

Future<void> _migrateLegacyProfileOnce() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('health_profile_migrated_v1') ?? false) return;
  final legacy = HealthProfile(
    age: prefs.getInt('hr_age') ?? prefs.getInt('user_age'),
    restingHr: prefs.getInt('hr_resting_hr'),
    measuredMaxHr: prefs.getInt('hr_measured_max_hr'),
    clinicianMaxHr: prefs.getInt('hr_clinician_max_hr'),
    betaBlocker: prefs.getBool('hr_beta_blocker') ?? false,
    heartCondition: prefs.getBool('hr_heart_condition') ?? false,
  );
  await ref.read(healthProfileRepositoryProvider)
      .saveForClient(kSelfClientId, legacy);
  await prefs.setBool('health_profile_migrated_v1', true);
}
```

Each mutator (e.g. `updateAge`) now does: read active client id, `saveForClient(id, current.copyWith(age: value))`, then `state = AsyncData(updated)`. (Convert the notifier to `AsyncNotifier<HealthProfile>` if it isn't already; update `userAgeProvider`'s `select` to read from the async value.) Add `healthProfileRepositoryProvider` to `lib/core/providers.dart`.

- [ ] **Step 5: Write and run the per-client switch test**

```dart
// test/features/heart_rate/presentation/per_client_health_profile_test.dart
// Build a ProviderContainer with an in-memory db, create two clients with
// different ages via healthProfileRepositoryProvider, switch activeClient,
// and assert healthProfileProvider's age changes accordingly.
```

Run: `flutter test test/features/clients/data/drift_health_profile_repository_test.dart test/features/heart_rate/presentation/per_client_health_profile_test.dart`
Expected: PASS

- [ ] **Step 6: Analyse, format, commit**

```bash
dart analyze && dart format lib test
git add lib/features/clients lib/features/heart_rate lib/core/providers.dart test/features/clients test/features/heart_rate
git commit -m "feat: per-client health profile with legacy migration"
```

---

## Phase C — UI

### Task 11: Clients nav destination, route, and roster screen

**Files:**
- Create: `lib/features/clients/presentation/screens/client_roster_screen.dart`
- Modify: `lib/app/router.dart` (add `/clients` route in the ShellRoute)
- Modify: `lib/core/widgets/desktop_nav_rail.dart` (add a "Clients" `RailDestination`)
- Modify: `lib/core/widgets/scaffold_with_nav_bar.dart` (`_railIndexForLocation`, `_onRailDestinationSelected`, `_railShortcutKeys` — extend to a 9th destination; add `/clients` handling)
- Modify: `lib/l10n/app_en.arb` (new strings) + `flutter gen-l10n`
- Test: `test/features/clients/presentation/client_roster_screen_test.dart`

**Interfaces:**
- Consumes: `clientsProvider`, `clientRepositoryProvider`, `Client`.

- [ ] **Step 1: Add l10n strings**

In `lib/l10n/app_en.arb` add: `"clientsTitle": "Clients"`, `"newClient": "New client"`, `"newClientTitle": "New client"`, `"clientNameLabel": "Name"`, `"deleteClientTitle": "Delete client?"`, `"deleteClientContent": "Delete {name}? Their logged data is kept but hidden.", "@deleteClientContent": {"placeholders": {"name": {"type": "String"}}}`, `"noClientsYet": "No clients yet"`, `"selfClientBadge": "You"`. Run `flutter gen-l10n`.

- [ ] **Step 2: Write the failing widget test**

```dart
// test/features/clients/presentation/client_roster_screen_test.dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/presentation/screens/client_roster_screen.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('roster lists clients including Me', (tester) async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: ClientRosterScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Me'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run to verify it fails**

Run: `flutter test test/features/clients/presentation/client_roster_screen_test.dart`
Expected: FAIL — screen doesn't exist.

- [ ] **Step 4: Implement the roster screen**

Build `ClientRosterScreen` (a `ConsumerWidget`) that watches `clientsProvider` and shows a `ListView` of clients — each a `ListTile` with a `CircleAvatar` tinted `Color(client.colour)`, the name, a "You" badge when `isSelf`, and a `PopupMenuButton` with Edit and (for non-self) Delete. A `FloatingActionButton.extended` opens a create dialog (name field + a small colour picker row) that calls `clientRepositoryProvider.createClient(Client.create(name:, colour:))`. Delete calls `softDeleteClient` after a confirm dialog; the self client shows no delete. Follow the exact structure of `programme_list_screen.dart` (Task 5 of the desktop work) for dialogs and tiles, but bind to clients. Tapping a client navigates to `/clients/${client.id}` (the detail screen from Task 13).

- [ ] **Step 5: Register the route and nav destination**

In `router.dart`, add inside the ShellRoute `routes:` list:

```dart
GoRoute(
  path: '/clients',
  builder: (context, state) => const ClientRosterScreen(),
  routes: [
    GoRoute(
      path: ':id',
      builder: (context, state) =>
          ClientDetailScreen(clientId: state.pathParameters['id']!),
    ),
  ],
),
```

(`ClientDetailScreen` is created in Task 13; if executing Task 11 before 13, register only the `/clients` route and add the `:id` sub-route in Task 13.)

In `desktop_nav_rail.dart`, add a "Clients" `RailDestination` (icon `Icons.groups_outlined`, label from `s.clientsTitle`) — put it in a new leading position or the "Review" group; keep the flat build order deliberate. In `scaffold_with_nav_bar.dart`, extend `_railIndexForLocation` and `_onRailDestinationSelected` with a `/clients` case at the matching flat index, and add a 9th key to `_railShortcutKeys` (`LogicalKeyboardKey.digit9`) so the Ctrl-shortcut list stays aligned with the rail order. Keep the rail's build order and the flat-index switch in lock-step (a comment in both files already documents the order — update it).

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/features/clients test/core/widgets`
Expected: PASS. Then `flutter test` for the whole suite.

- [ ] **Step 7: Analyse, format, commit**

```bash
dart analyze && dart format lib test
git add lib test
git commit -m "feat: clients roster screen, route, and nav destination"
```

---

### Task 12: Client switcher and active-client indicator

**Files:**
- Create: `lib/features/clients/presentation/widgets/client_switcher.dart`
- Modify: `lib/core/widgets/desktop_nav_rail.dart` (host the switcher in the footer)
- Modify: `lib/core/widgets/scaffold_with_nav_bar.dart` (mobile app-bar/indicator hook)
- Modify: `lib/l10n/app_en.arb` (add `"switchClient": "Switch client"`, `"viewingClient": "Viewing {name}", "@viewingClient": {"placeholders": {"name": {"type": "String"}}}`) + `flutter gen-l10n`
- Test: `test/features/clients/presentation/client_switcher_test.dart`

**Interfaces:**
- Consumes: `clientsProvider`, `activeClientProvider`, `Client`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/clients/presentation/client_switcher_test.dart
// Pump ClientSwitcher in a ProviderScope with an in-memory db + two clients.
// Assert the active client's name shows; tap it, pick the other client from
// the sheet/menu, and assert activeClientProvider updated (read the container).
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/clients/presentation/client_switcher_test.dart`
Expected: FAIL — widget doesn't exist.

- [ ] **Step 3: Implement the switcher and indicator**

`ClientSwitcher` (a `ConsumerWidget`): shows the active client (coloured dot + name; "You" if self) as a tappable chip. Tapping opens a menu/bottom sheet listing `clientsProvider` entries; selecting one calls `ref.read(activeClientProvider.notifier).setActive(client)`. Host it in the `DesktopNavRail` footer (above the pinned Settings). For mobile, expose the same active-client name as a compact chip in the relevant screens' app bars via a small `ActiveClientIndicator` widget in the same file (reads `activeClientProvider`, renders the coloured dot + name; on tap opens the same sheet). Place the indicator on the logging surfaces (active workout, cardio) so the coach always sees whose data they're recording.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/clients`
Expected: PASS

- [ ] **Step 5: Analyse, format, commit**

```bash
dart analyze && dart format lib test
git add lib test
git commit -m "feat: client switcher and active-client indicator"
```

---

### Task 13: Client detail — plan assignment and per-client health profile

**Files:**
- Create: `lib/features/clients/presentation/screens/client_detail_screen.dart`
- Modify: `lib/app/router.dart` (ensure the `/clients/:id` sub-route points here)
- Modify: `lib/l10n/app_en.arb` (`"assignedPlans": "Assigned plans"`, `"assignPlan": "Assign plan"`, `"clientHealthProfile": "Health profile"`) + `flutter gen-l10n`
- Test: `test/features/clients/presentation/client_detail_screen_test.dart`

**Interfaces:**
- Consumes: `clientRepositoryProvider`, `clientPlanAssignmentRepositoryProvider`, `workoutTemplateRepositoryProvider`, `programmeRepositoryProvider`, `healthProfileRepositoryProvider`, `Client`, `PlanType`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/clients/presentation/client_detail_screen_test.dart
// Pump ClientDetailScreen(clientId: sarah.id) with an in-memory db seeded with
// a client and a library template. Assert the client name renders and an
// "Assign plan" affordance is present.
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/clients/presentation/client_detail_screen_test.dart`
Expected: FAIL — screen doesn't exist.

- [ ] **Step 3: Implement the detail screen**

`ClientDetailScreen({required String clientId})` (a `ConsumerWidget`): header with the client's name/colour and an edit action; an "Assigned plans" section watching `clientPlanAssignmentRepositoryProvider.watchAssignments(clientId)` (resolve each `planId` to its template/programme name via the respective repo) with unassign buttons and an "Assign plan" action that opens a picker of library templates + programmes and calls `assign(clientId, planType, planId)`; and a "Health profile" section that opens the existing health-profile editor scoped to this client (reads/writes `healthProfileRepositoryProvider` for `clientId`). Reuse existing health-profile editing widgets from `lib/features/heart_rate/` where possible rather than duplicating fields.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/clients`
Expected: PASS. Then `flutter test`.

- [ ] **Step 5: Analyse, format, commit**

```bash
dart analyze && dart format lib test
git add lib test
git commit -m "feat: client detail with plan assignment and health profile"
```

---

## Phase D — Sync-safety

### Task 14: Prove and lock in sync-safety

The `clientId` column default (`kSelfClientIdConst`) plus the sync serialiser's `DoUpdate((_) => row)` (which omits `clientId`, so an existing row's client is untouched on conflict) already deliver sync-safety. This task adds tests that lock the guarantee in and a guard comment so no one adds `clientId` to the sync companions.

**Files:**
- Modify: `lib/features/sync/data/sync_snapshot_serialiser.dart` (comment only — document why `clientId` is deliberately omitted)
- Test: `test/features/sync/sync_client_safety_test.dart`

**Interfaces:**
- Consumes: `SyncSnapshotSerialiser.applyToDatabase`, the four scoped tables, `kSelfClientId`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/sync/sync_client_safety_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/domain/models/client.dart';
// import the serialiser + a SyncSnapshot builder as used by existing sync tests

void main() {
  test('applying a snapshot preserves an existing row clientId', () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    // Local workout owned by a non-Me client, newer than the incoming one.
    await database.customStatement(
      "INSERT INTO workouts (id, started_at, updated_at, client_id) "
      "VALUES ('w1', 0, 100, 'client-X')",
    );

    // Build a snapshot containing workout w1 with an OLDER updatedAt so the
    // guarded upsert's `excluded.updated_at > updated_at` does not overwrite,
    // and a NEW workout w2 (not present locally).
    // ... construct SyncSnapshot with w1(updatedAt<100) and w2 ...
    // await serialiser.applyToDatabase(database, snapshot);

    final w1 = await database.customSelect(
      "SELECT client_id FROM workouts WHERE id = 'w1'",
    ).getSingle();
    expect(w1.read<String>('client_id'), 'client-X'); // preserved

    final w2 = await database.customSelect(
      "SELECT client_id FROM workouts WHERE id = 'w2'",
    ).getSingle();
    expect(w2.read<String>('client_id'), kSelfClientId); // new → Me via default
  });
}
```

(Fill in the `SyncSnapshot` construction using the same builder helpers the existing sync tests under `test/features/sync/` use; match the domain `Workout` shape.)

- [ ] **Step 2: Run to verify it fails or drives the assertion**

Run: `flutter test test/features/sync/sync_client_safety_test.dart`
Expected: initially FAIL where the snapshot builder isn't wired; once wired, both assertions must hold. If either fails, the sync path is not safe — do not weaken the test; investigate the serialiser.

- [ ] **Step 3: Add the guard comment**

In `sync_snapshot_serialiser.dart`, above the `workouts`/`cardioSessions`/`personalRecords`/`bodyMetrics` companions, add:

```dart
// Do NOT add clientId here. Omitting it preserves each row's existing
// client on conflict (DoUpdate copies only present columns), and new rows
// default to the Me client via the column default. Adding clientId would be
// a v2 sync change (roster + per-entity clientId in the snapshot).
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/sync/`
Expected: PASS (existing sync tests still green, new safety test green).

- [ ] **Step 5: Analyse, format, commit**

```bash
dart analyze && dart format lib/features/sync test/features/sync
git add lib/features/sync test/features/sync
git commit -m "test: lock in clientId sync-safety and document the guarantee"
```

---

## Final verification (after all tasks)

- [ ] `flutter test` — full suite passes.
- [ ] `dart analyze` — zero issues.
- [ ] `dart format --set-exit-if-changed .` — clean.
- [ ] Smoke test (`flutter run -d linux`): create a client, switch to them (indicator updates), log a workout, confirm it appears under that client and not under "Me", assign a library template, set the client's health profile and confirm HR zones use their age, delete a client (Me shows no delete), restart and confirm the last-active client is restored.

## Self-review notes (traceability to spec)

- Spec "clients table + Me migration" → Tasks 1, 2. "clientId scoping on four tables" → Tasks 2, 3, 6. "per-client health profiles" → Task 10. "client_plan_assignments" → Tasks 1, 5. "active-client state + filtering" → Tasks 7, 8, 9. "roster CRUD + assignment UI" → Tasks 11, 13. "switcher + indicator" → Task 12. "sync-safety" → Tasks 2 (column default), 14. Deferred sync/reporting explicitly out of scope.
- Column-default refinement (Me id as DB default) is within the spec's stated intent ("preserve existing local clientId; new incoming → Me") and simplifies both migration backfill and the sync apply path.
