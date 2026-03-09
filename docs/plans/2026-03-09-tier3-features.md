# Tier 3 Features Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement five major features — Programme Builder (3.1), Advanced Analytics (3.2), Cloud Sync (3.3), Health Integration (3.4), and Social/Sharing (3.5). Features 3.1 and 3.2 are detailed for immediate implementation; 3.3–3.5 are planned at high level.

**Architecture:** Programme Builder adds new DB tables and a full feature directory following the existing template pattern. Analytics Dashboard adds a new feature directory with providers querying existing data. Both follow clean architecture with feature-first modularisation.

**Tech Stack:** Flutter/Dart, Riverpod, Drift/SQLite, GoRouter, fl_chart, l10n via ARB

---

## Part A: Programme Builder (3.1) — IMPLEMENT

### Task 1: Domain models

**Files:**
- Create: `lib/features/programmes/domain/models/programme.dart`
- Create: `test/features/programmes/domain/models/programme_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/programmes/domain/models/programme_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';

void main() {
  group('Programme', () {
    test('create generates id and UTC dates', () {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      expect(p.id, isNotEmpty);
      expect(p.name, 'PPL');
      expect(p.durationWeeks, 4);
      expect(p.createdAt.isUtc, isTrue);
    });

    test('copyWith updates name', () {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      final updated = p.copyWith(name: '5/3/1');
      expect(updated.name, '5/3/1');
      expect(updated.id, p.id);
    });
  });

  group('ProgrammeDay', () {
    test('create generates id', () {
      final d = ProgrammeDay.create(
        programmeId: 'p1',
        weekNumber: 1,
        dayOfWeek: 1,
        templateId: 't1',
        templateName: 'Push Day',
      );
      expect(d.id, isNotEmpty);
      expect(d.weekNumber, 1);
      expect(d.dayOfWeek, 1);
    });
  });

  group('ProgressionRule', () {
    test('create generates id', () {
      final r = ProgressionRule.create(
        programmeId: 'p1',
        exerciseId: 'e1',
        type: ProgressionType.fixedIncrement,
        value: 2.5,
      );
      expect(r.id, isNotEmpty);
      expect(r.type, ProgressionType.fixedIncrement);
      expect(r.value, 2.5);
    });

    test('applyProgression with fixedIncrement adds value', () {
      final r = ProgressionRule.create(
        programmeId: 'p1',
        exerciseId: 'e1',
        type: ProgressionType.fixedIncrement,
        value: 2.5,
      );
      expect(r.applyProgression(100.0), 102.5);
    });

    test('applyProgression with percentage scales value', () {
      final r = ProgressionRule.create(
        programmeId: 'p1',
        exerciseId: 'e1',
        type: ProgressionType.percentage,
        value: 5.0,
      );
      expect(r.applyProgression(100.0), 105.0);
    });

    test('applyProgression with deload reduces value', () {
      final r = ProgressionRule.create(
        programmeId: 'p1',
        exerciseId: 'e1',
        type: ProgressionType.deload,
        value: 10.0,
      );
      expect(r.applyProgression(100.0), 90.0);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/programmes/domain/models/programme_test.dart`

**Step 3: Implement the domain models**

```dart
// lib/features/programmes/domain/models/programme.dart
import 'package:uuid/uuid.dart';

enum ProgressionType {
  fixedIncrement,
  percentage,
  deload,
}

class Programme {
  final String id;
  final String name;
  final int durationWeeks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProgrammeDay> days;
  final List<ProgressionRule> rules;

  const Programme({
    required this.id,
    required this.name,
    required this.durationWeeks,
    required this.createdAt,
    required this.updatedAt,
    this.days = const [],
    this.rules = const [],
  });

  static Programme create({
    required String name,
    required int durationWeeks,
  }) {
    final now = DateTime.now().toUtc();
    return Programme(
      id: const Uuid().v4(),
      name: name,
      durationWeeks: durationWeeks,
      createdAt: now,
      updatedAt: now,
    );
  }

  Programme copyWith({
    String? name,
    int? durationWeeks,
    DateTime? updatedAt,
    List<ProgrammeDay>? days,
    List<ProgressionRule>? rules,
  }) {
    return Programme(
      id: id,
      name: name ?? this.name,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      days: days ?? this.days,
      rules: rules ?? this.rules,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Programme && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ProgrammeDay {
  final String id;
  final String programmeId;
  final int weekNumber;
  final int dayOfWeek; // DateTime.monday (1) through DateTime.sunday (7)
  final String templateId;
  final String templateName;

  const ProgrammeDay({
    required this.id,
    required this.programmeId,
    required this.weekNumber,
    required this.dayOfWeek,
    required this.templateId,
    required this.templateName,
  });

  static ProgrammeDay create({
    required String programmeId,
    required int weekNumber,
    required int dayOfWeek,
    required String templateId,
    required String templateName,
  }) {
    return ProgrammeDay(
      id: const Uuid().v4(),
      programmeId: programmeId,
      weekNumber: weekNumber,
      dayOfWeek: dayOfWeek,
      templateId: templateId,
      templateName: templateName,
    );
  }

  ProgrammeDay copyWith({
    int? weekNumber,
    int? dayOfWeek,
    String? templateId,
    String? templateName,
  }) {
    return ProgrammeDay(
      id: id,
      programmeId: programmeId,
      weekNumber: weekNumber ?? this.weekNumber,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgrammeDay &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ProgressionRule {
  final String id;
  final String programmeId;
  final String exerciseId;
  final ProgressionType type;
  final double value;
  final int frequencyWeeks;

  const ProgressionRule({
    required this.id,
    required this.programmeId,
    required this.exerciseId,
    required this.type,
    required this.value,
    this.frequencyWeeks = 1,
  });

  static ProgressionRule create({
    required String programmeId,
    required String exerciseId,
    required ProgressionType type,
    required double value,
    int frequencyWeeks = 1,
  }) {
    return ProgressionRule(
      id: const Uuid().v4(),
      programmeId: programmeId,
      exerciseId: exerciseId,
      type: type,
      value: value,
      frequencyWeeks: frequencyWeeks,
    );
  }

  /// Applies this progression rule to a base weight.
  double applyProgression(double baseWeight) {
    return switch (type) {
      ProgressionType.fixedIncrement => baseWeight + value,
      ProgressionType.percentage => baseWeight * (1 + value / 100),
      ProgressionType.deload => baseWeight * (1 - value / 100),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressionRule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/features/programmes/domain/models/programme_test.dart`
Expected: 6 tests PASS

**Step 5: Commit**

```bash
git add lib/features/programmes/ test/features/programmes/
git commit -m "feat: add Programme, ProgrammeDay, ProgressionRule domain models with tests"
```

---

### Task 2: Database tables and migration v5

**Files:**
- Create: `lib/core/database/tables/programmes_table.dart`
- Create: `lib/core/database/tables/programme_days_table.dart`
- Create: `lib/core/database/tables/progression_rules_table.dart`
- Modify: `lib/core/database/app_database.dart`

**Step 1: Create the Drift table definitions**

```dart
// lib/core/database/tables/programmes_table.dart
import 'package:drift/drift.dart';

class Programmes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get durationWeeks => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// lib/core/database/tables/programme_days_table.dart
import 'package:drift/drift.dart';

class ProgrammeDays extends Table {
  TextColumn get id => text()();
  TextColumn get programmeId => text()();
  IntColumn get weekNumber => integer()();
  IntColumn get dayOfWeek => integer()();
  TextColumn get templateId => text()();
  TextColumn get templateName => text()();

  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// lib/core/database/tables/progression_rules_table.dart
import 'package:drift/drift.dart';

class ProgressionRules extends Table {
  TextColumn get id => text()();
  TextColumn get programmeId => text()();
  TextColumn get exerciseId => text()();
  TextColumn get type => text()(); // ProgressionType.name
  RealColumn get value => real()();
  IntColumn get frequencyWeeks => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Step 2: Register tables and add migration**

In `app_database.dart`:
- Add imports for new tables
- Add `Programmes`, `ProgrammeDays`, `ProgressionRules` to `@DriftDatabase(tables: [...])`
- Bump `schemaVersion` to `5`
- Add migration block:
```dart
if (from < 5) {
  await customStatement(
    'CREATE TABLE IF NOT EXISTS programmes ('
    'id TEXT NOT NULL PRIMARY KEY, '
    'name TEXT NOT NULL, '
    'duration_weeks INTEGER NOT NULL, '
    'created_at INTEGER NOT NULL, '
    'updated_at INTEGER NOT NULL'
    ')',
  );
  await customStatement(
    'CREATE TABLE IF NOT EXISTS programme_days ('
    'id TEXT NOT NULL PRIMARY KEY, '
    'programme_id TEXT NOT NULL, '
    'week_number INTEGER NOT NULL, '
    'day_of_week INTEGER NOT NULL, '
    'template_id TEXT NOT NULL, '
    'template_name TEXT NOT NULL'
    ')',
  );
  await customStatement(
    'CREATE TABLE IF NOT EXISTS progression_rules ('
    'id TEXT NOT NULL PRIMARY KEY, '
    'programme_id TEXT NOT NULL, '
    'exercise_id TEXT NOT NULL, '
    'type TEXT NOT NULL, '
    'value REAL NOT NULL, '
    'frequency_weeks INTEGER NOT NULL DEFAULT 1'
    ')',
  );
}
```

**Step 3: Regenerate Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`

**Step 4: Run all tests**

Run: `flutter test`
Expected: All existing tests pass

**Step 5: Commit**

```bash
git add lib/core/database/
git commit -m "feat: add programmes, programme_days, progression_rules DB tables (migration v5)"
```

---

### Task 3: Repository interface and Drift implementation

**Files:**
- Create: `lib/features/programmes/domain/repositories/programme_repository.dart`
- Create: `lib/features/programmes/data/drift_programme_repository.dart`
- Create: `test/features/programmes/data/drift_programme_repository_test.dart`

**Step 1: Create repository interface**

```dart
// lib/features/programmes/domain/repositories/programme_repository.dart
import '../models/programme.dart';

abstract class ProgrammeRepository {
  Future<Programme> createProgramme(Programme programme);
  Future<Programme?> getProgramme(String id);
  Future<List<Programme>> getAllProgrammes();
  Future<Programme> updateProgramme(Programme programme);
  Future<void> deleteProgramme(String id);
  Stream<List<Programme>> watchAllProgrammes();

  Future<void> addDay(ProgrammeDay day);
  Future<void> removeDay(String dayId);
  Future<List<ProgrammeDay>> getDaysForProgramme(String programmeId);

  Future<void> addRule(ProgressionRule rule);
  Future<void> removeRule(String ruleId);
  Future<List<ProgressionRule>> getRulesForProgramme(String programmeId);
}
```

**Step 2: Write failing test**

```dart
// test/features/programmes/data/drift_programme_repository_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/features/programmes/data/drift_programme_repository.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';

void main() {
  late AppDatabase db;
  late DriftProgrammeRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftProgrammeRepository(db);
  });

  tearDown(() => db.close());

  group('DriftProgrammeRepository', () {
    test('create and get programme', () async {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      await repo.createProgramme(p);

      final fetched = await repo.getProgramme(p.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'PPL');
      expect(fetched.durationWeeks, 4);
    });

    test('getAllProgrammes returns created programmes', () async {
      await repo.createProgramme(Programme.create(name: 'A', durationWeeks: 4));
      await repo.createProgramme(Programme.create(name: 'B', durationWeeks: 8));

      final all = await repo.getAllProgrammes();
      expect(all, hasLength(2));
    });

    test('deleteProgramme removes programme and children', () async {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      await repo.createProgramme(p);
      await repo.addDay(ProgrammeDay.create(
        programmeId: p.id,
        weekNumber: 1,
        dayOfWeek: 1,
        templateId: 't1',
        templateName: 'Push',
      ));
      await repo.addRule(ProgressionRule.create(
        programmeId: p.id,
        exerciseId: 'e1',
        type: ProgressionType.fixedIncrement,
        value: 2.5,
      ));

      await repo.deleteProgramme(p.id);
      final fetched = await repo.getProgramme(p.id);
      expect(fetched, isNull);

      final days = await repo.getDaysForProgramme(p.id);
      expect(days, isEmpty);

      final rules = await repo.getRulesForProgramme(p.id);
      expect(rules, isEmpty);
    });

    test('addDay and getDaysForProgramme', () async {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      await repo.createProgramme(p);

      final day = ProgrammeDay.create(
        programmeId: p.id,
        weekNumber: 1,
        dayOfWeek: DateTime.monday,
        templateId: 't1',
        templateName: 'Push',
      );
      await repo.addDay(day);

      final days = await repo.getDaysForProgramme(p.id);
      expect(days, hasLength(1));
      expect(days.first.templateName, 'Push');
    });

    test('addRule and getRulesForProgramme', () async {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      await repo.createProgramme(p);

      final rule = ProgressionRule.create(
        programmeId: p.id,
        exerciseId: 'e1',
        type: ProgressionType.percentage,
        value: 5.0,
      );
      await repo.addRule(rule);

      final rules = await repo.getRulesForProgramme(p.id);
      expect(rules, hasLength(1));
      expect(rules.first.type, ProgressionType.percentage);
    });
  });
}
```

**Step 3: Implement the Drift repository**

```dart
// lib/features/programmes/data/drift_programme_repository.dart
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/converters.dart';
import '../domain/models/programme.dart';
import '../domain/repositories/programme_repository.dart';

class DriftProgrammeRepository implements ProgrammeRepository {
  final db.AppDatabase _db;

  DriftProgrammeRepository(this._db);

  @override
  Future<Programme> createProgramme(Programme programme) async {
    await _db.into(_db.programmes).insert(
      db.ProgrammesCompanion.insert(
        id: programme.id,
        name: programme.name,
        durationWeeks: programme.durationWeeks,
        createdAt: dateTimeToEpochMs(programme.createdAt),
        updatedAt: dateTimeToEpochMs(programme.updatedAt),
      ),
    );
    return programme;
  }

  @override
  Future<Programme?> getProgramme(String id) async {
    final q = _db.select(_db.programmes)..where((t) => t.id.equals(id));
    final row = await q.getSingleOrNull();
    if (row == null) return null;

    final days = await getDaysForProgramme(id);
    final rules = await getRulesForProgramme(id);
    return _toDomain(row, days, rules);
  }

  @override
  Future<List<Programme>> getAllProgrammes() async {
    final q = _db.select(_db.programmes)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await q.get();
    return Future.wait(rows.map((row) async {
      final days = await getDaysForProgramme(row.id);
      final rules = await getRulesForProgramme(row.id);
      return _toDomain(row, days, rules);
    }));
  }

  @override
  Future<Programme> updateProgramme(Programme programme) async {
    await (_db.update(_db.programmes)
          ..where((t) => t.id.equals(programme.id)))
        .write(db.ProgrammesCompanion(
      name: Value(programme.name),
      durationWeeks: Value(programme.durationWeeks),
      updatedAt: Value(dateTimeToEpochMs(programme.updatedAt)),
    ));
    return programme;
  }

  @override
  Future<void> deleteProgramme(String id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.programmeDays)
            ..where((t) => t.programmeId.equals(id)))
          .go();
      await (_db.delete(_db.progressionRules)
            ..where((t) => t.programmeId.equals(id)))
          .go();
      await (_db.delete(_db.programmes)..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Stream<List<Programme>> watchAllProgrammes() {
    final q = _db.select(_db.programmes)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch().asyncMap((rows) async {
      return Future.wait(rows.map((row) async {
        final days = await getDaysForProgramme(row.id);
        final rules = await getRulesForProgramme(row.id);
        return _toDomain(row, days, rules);
      }));
    });
  }

  @override
  Future<void> addDay(ProgrammeDay day) async {
    await _db.into(_db.programmeDays).insert(
      db.ProgrammeDaysCompanion.insert(
        id: day.id,
        programmeId: day.programmeId,
        weekNumber: day.weekNumber,
        dayOfWeek: day.dayOfWeek,
        templateId: day.templateId,
        templateName: day.templateName,
      ),
    );
  }

  @override
  Future<void> removeDay(String dayId) async {
    await (_db.delete(_db.programmeDays)..where((t) => t.id.equals(dayId)))
        .go();
  }

  @override
  Future<List<ProgrammeDay>> getDaysForProgramme(String programmeId) async {
    final q = _db.select(_db.programmeDays)
      ..where((t) => t.programmeId.equals(programmeId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.weekNumber),
        (t) => OrderingTerm.asc(t.dayOfWeek),
      ]);
    final rows = await q.get();
    return rows.map(_dayToDomain).toList();
  }

  @override
  Future<void> addRule(ProgressionRule rule) async {
    await _db.into(_db.progressionRules).insert(
      db.ProgressionRulesCompanion.insert(
        id: rule.id,
        programmeId: rule.programmeId,
        exerciseId: rule.exerciseId,
        type: rule.type.name,
        value: rule.value,
        frequencyWeeks: Value(rule.frequencyWeeks),
      ),
    );
  }

  @override
  Future<void> removeRule(String ruleId) async {
    await (_db.delete(_db.progressionRules)
          ..where((t) => t.id.equals(ruleId)))
        .go();
  }

  @override
  Future<List<ProgressionRule>> getRulesForProgramme(
      String programmeId) async {
    final q = _db.select(_db.progressionRules)
      ..where((t) => t.programmeId.equals(programmeId));
    final rows = await q.get();
    return rows.map(_ruleToDomain).toList();
  }

  Programme _toDomain(
    db.Programme row,
    List<ProgrammeDay> days,
    List<ProgressionRule> rules,
  ) {
    return Programme(
      id: row.id,
      name: row.name,
      durationWeeks: row.durationWeeks,
      createdAt: dateTimeFromEpochMs(row.createdAt),
      updatedAt: dateTimeFromEpochMs(row.updatedAt),
      days: days,
      rules: rules,
    );
  }

  ProgrammeDay _dayToDomain(db.ProgrammeDay row) {
    return ProgrammeDay(
      id: row.id,
      programmeId: row.programmeId,
      weekNumber: row.weekNumber,
      dayOfWeek: row.dayOfWeek,
      templateId: row.templateId,
      templateName: row.templateName,
    );
  }

  ProgressionRule _ruleToDomain(db.ProgressionRule row) {
    return ProgressionRule(
      id: row.id,
      programmeId: row.programmeId,
      exerciseId: row.exerciseId,
      type: ProgressionType.values.byName(row.type),
      value: row.value,
      frequencyWeeks: row.frequencyWeeks,
    );
  }
}
```

**Step 4: Run tests**

Run: `flutter test test/features/programmes/data/drift_programme_repository_test.dart`
Expected: 5 tests PASS

**Step 5: Commit**

```bash
git add lib/features/programmes/ test/features/programmes/
git commit -m "feat: add ProgrammeRepository interface and Drift implementation with tests"
```

---

### Task 4: Register provider and add l10n strings

**Files:**
- Modify: `lib/core/providers.dart`
- Modify: `lib/l10n/app_en.arb`

**Step 1: Add provider**

In `lib/core/providers.dart`, add import and provider:

```dart
import '../features/programmes/data/drift_programme_repository.dart';
import '../features/programmes/domain/repositories/programme_repository.dart';

final programmeRepositoryProvider = Provider<ProgrammeRepository>((ref) {
  return DriftProgrammeRepository(ref.watch(databaseProvider));
});
```

**Step 2: Add l10n strings**

Add to `app_en.arb` before closing `}`:

```json
  "programmesTitle": "Programmes",
  "noProgrammesYet": "No programmes yet",
  "noProgrammesYetSubtitle": "Create a training programme to plan your workouts.",
  "newProgramme": "New Programme",
  "newProgrammeTitle": "New Programme",
  "programmeNameLabel": "Programme Name",
  "durationWeeksLabel": "Duration (weeks)",
  "editProgramme": "Edit Programme",
  "deleteProgrammeTitle": "Delete Programme?",
  "deleteProgrammeContent": "Are you sure you want to delete \"{name}\"? This cannot be undone.",
  "@deleteProgrammeContent": {
    "placeholders": { "name": { "type": "String" } }
  },
  "programmeDashboard": "Dashboard",
  "currentWeek": "Week {current} of {total}",
  "@currentWeek": {
    "placeholders": {
      "current": { "type": "int" },
      "total": { "type": "int" }
    }
  },
  "assignTemplate": "Assign Template",
  "noTemplateAssigned": "Rest day",
  "progressionRules": "Progression Rules",
  "addRule": "Add Rule",
  "fixedIncrementLabel": "Fixed increment",
  "percentageLabel": "Percentage",
  "deloadLabel": "Deload",
  "ruleValueLabel": "Value",
  "everyNWeeks": "Every {count} {count, plural, =1{week} other{weeks}}",
  "@everyNWeeks": {
    "placeholders": { "count": { "type": "int" } }
  },
  "startFromProgramme": "Start from Programme",
  "targetWeight": "Target: {weight} kg",
  "@targetWeight": {
    "placeholders": { "weight": { "type": "String" } }
  },
  "programmeSaved": "Programme saved",
  "weekLabel": "Week {number}",
  "@weekLabel": {
    "placeholders": { "number": { "type": "int" } }
  },
  "dayLabel": "{day}",
  "@dayLabel": {
    "placeholders": { "day": { "type": "String" } }
  }
```

**Step 3: Regenerate l10n**

Run: `flutter gen-l10n`

**Step 4: Commit**

```bash
git add lib/core/providers.dart lib/l10n/
git commit -m "feat: add programme provider and l10n strings"
```

---

### Task 5: Programme list screen

**Files:**
- Create: `lib/features/programmes/presentation/screens/programme_list_screen.dart`
- Modify: `lib/app/router.dart`

**Step 1: Create the screen**

Follow the pattern from `template_list_screen.dart`. The screen should:
- Stream programmes via a top-level `StreamProvider.autoDispose`
- Show empty state with icon + text when no programmes exist
- Show a ListView of programme cards (name, duration, day count)
- FAB to create new programme (dialog with name + duration weeks)
- Popup menu on each card with edit/delete options
- Delete with confirmation dialog
- Navigate to `/programmes/:id` on tap

**Step 2: Add routes**

In `router.dart`, add:
```dart
GoRoute(
  path: '/programmes',
  builder: (context, state) => const ProgrammeListScreen(),
  routes: [
    GoRoute(
      path: ':id',
      builder: (context, state) => ProgrammeEditScreen(
        programmeId: state.pathParameters['id']!,
      ),
    ),
  ],
),
```

**Step 3: Add navigation entry**

Add a "Programmes" tile in the workout start screen (or settings) linking to `/programmes`.

**Step 4: Verify**

Run: `dart analyze` and `flutter test`

**Step 5: Commit**

```bash
git add lib/features/programmes/presentation/ lib/app/router.dart
git commit -m "feat: add programme list screen with create/delete"
```

---

### Task 6: Programme edit screen

**Files:**
- Create: `lib/features/programmes/presentation/screens/programme_edit_screen.dart`

**Step 1: Create the screen**

The edit screen should:
- Load programme by ID from repository
- Show a week-by-day grid (rows = weeks 1..N, columns = Mon-Sun)
- Each cell shows assigned template name or "Rest day"
- Tap a cell → bottom sheet to pick from existing templates
- Section for progression rules: list existing rules with delete, FAB to add
- Add rule: pick exercise → pick type (fixed/percentage/deload) → enter value → enter frequency
- Save button persists all changes

**Step 2: Verify**

Run: `dart analyze` and `flutter test`

**Step 3: Commit**

```bash
git add lib/features/programmes/presentation/screens/programme_edit_screen.dart
git commit -m "feat: add programme edit screen with week/day grid and progression rules"
```

---

### Task 7: Programme-aware workout start

**Files:**
- Modify: `lib/features/workout/presentation/screens/active_workout_screen.dart`
- Modify: `lib/features/workout/presentation/controllers/active_workout_controller.dart`

**Step 1: Add "Start from Programme" button**

In the no-workout state of `active_workout_screen.dart`, add an `OutlinedButton` for "Start from Programme" alongside the existing "Start from Template" button.

**Step 2: Add programme picker**

Show a bottom sheet that lists active programmes. When selected, determine today's template based on the programme's schedule and current week. Start the workout from that template.

**Step 3: Calculate target weights**

In `ActiveWorkoutController`, add a method that:
1. Gets the programme's progression rules
2. Fetches last session's actual weights for each exercise
3. Applies the relevant progression rule to compute target weights
4. Stores these as modified ghost sets with the target weight

**Step 4: Verify**

Run: `dart analyze` and `flutter test`

**Step 5: Commit**

```bash
git add lib/features/workout/presentation/ lib/features/programmes/
git commit -m "feat: add programme-aware workout start with progression-adjusted targets"
```

---

## Part B: Advanced Analytics Dashboard (3.2) — IMPLEMENT

### Task 8: Analytics providers

**Files:**
- Create: `lib/features/analytics/presentation/providers/weekly_volume_provider.dart`
- Create: `lib/features/analytics/presentation/providers/muscle_balance_provider.dart`
- Create: `lib/features/analytics/presentation/providers/pr_timeline_provider.dart`
- Create: `lib/features/analytics/presentation/providers/training_load_provider.dart`
- Create: `test/features/analytics/presentation/providers/analytics_providers_test.dart`

**Step 1: Write the failing tests**

```dart
// test/features/analytics/presentation/providers/analytics_providers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/weekly_volume_provider.dart';
import 'package:rep_foundry/features/analytics/presentation/providers/training_load_provider.dart';

void main() {
  group('Weekly volume calculation', () {
    test('computeWeeklyVolume groups sets by week', () {
      final now = DateTime.now();
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));

      final result = computeWeeklyVolume([
        SetData(date: thisWeek, volume: 1000, rpe: null),
        SetData(date: thisWeek.add(const Duration(days: 1)), volume: 500, rpe: null),
        SetData(date: thisWeek.subtract(const Duration(days: 7)), volume: 800, rpe: null),
      ]);

      expect(result, hasLength(2));
      // Most recent week first
      expect(result.first.totalVolume, 1500);
    });
  });

  group('Training load calculation', () {
    test('computeTrainingLoad calculates sets * avg RPE', () {
      final now = DateTime.now();
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));

      final result = computeTrainingLoad([
        SetData(date: thisWeek, volume: 100, rpe: 8.0),
        SetData(date: thisWeek, volume: 100, rpe: 7.0),
      ]);

      expect(result, hasLength(1));
      expect(result.first.setCount, 2);
      expect(result.first.avgRpe, 7.5);
      expect(result.first.load, closeTo(15.0, 0.01)); // 2 * 7.5
    });
  });
}
```

**Step 2: Run tests to verify they fail**

**Step 3: Implement providers**

Each provider is a `FutureProvider.autoDispose` that reads from `workoutRepositoryProvider` and/or `personalRecordRepositoryProvider`, fetches recent data, and computes aggregations.

**Weekly volume provider:**
```dart
// lib/features/analytics/presentation/providers/weekly_volume_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';

class SetData {
  final DateTime date;
  final double volume;
  final double? rpe;

  const SetData({required this.date, required this.volume, this.rpe});
}

class WeeklyVolume {
  final DateTime weekStart;
  final double totalVolume;
  final double? percentChange;

  const WeeklyVolume({
    required this.weekStart,
    required this.totalVolume,
    this.percentChange,
  });
}

List<WeeklyVolume> computeWeeklyVolume(List<SetData> sets) {
  final byWeek = <DateTime, double>{};
  for (final s in sets) {
    final weekStart = s.date.subtract(Duration(days: s.date.weekday - 1));
    final key = DateTime(weekStart.year, weekStart.month, weekStart.day);
    byWeek[key] = (byWeek[key] ?? 0) + s.volume;
  }

  final sorted = byWeek.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

  final result = <WeeklyVolume>[];
  for (var i = 0; i < sorted.length; i++) {
    final prev = i > 0 ? sorted[i - 1].value : null;
    final change = prev != null && prev > 0
        ? ((sorted[i].value - prev) / prev) * 100
        : null;
    result.add(WeeklyVolume(
      weekStart: sorted[i].key,
      totalVolume: sorted[i].value,
      percentChange: change,
    ));
  }
  return result;
}

final weeklyVolumeProvider = FutureProvider.autoDispose<List<WeeklyVolume>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(limit: 200);
  final allSets = <SetData>[];

  for (final w in workouts) {
    if (w.completedAt == null) continue;
    final sets = await repo.getSetsForWorkout(w.id);
    for (final s in sets) {
      if (!s.isWarmUp) {
        allSets.add(SetData(date: s.timestamp, volume: s.volume, rpe: s.rpe));
      }
    }
  }

  return computeWeeklyVolume(allSets);
});
```

**Muscle balance provider** — computes relative volume per muscle group as percentages for a radar chart:

```dart
// lib/features/analytics/presentation/providers/muscle_balance_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../exercises/domain/models/exercise.dart';

class MuscleBalance {
  final MuscleGroup group;
  final double volumePercent;

  const MuscleBalance({required this.group, required this.volumePercent});
}

final muscleBalanceProvider = FutureProvider.autoDispose<List<MuscleBalance>>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);

  final exercises = await exerciseRepo.getAllExercises();
  final exerciseMap = {for (final e in exercises) e.id: e};

  final workouts = await workoutRepo.getWorkoutHistory(limit: 100);
  final volumeByGroup = <MuscleGroup, double>{};

  for (final w in workouts) {
    if (w.completedAt == null) continue;
    final sets = await workoutRepo.getSetsForWorkout(w.id);
    for (final s in sets) {
      if (s.isWarmUp) continue;
      final exercise = exerciseMap[s.exerciseId];
      if (exercise == null) continue;
      volumeByGroup[exercise.muscleGroup] =
          (volumeByGroup[exercise.muscleGroup] ?? 0) + s.volume;
    }
  }

  final total = volumeByGroup.values.fold(0.0, (a, b) => a + b);
  if (total == 0) return [];

  // Filter out cardio for the radar chart
  return volumeByGroup.entries
      .where((e) => e.key != MuscleGroup.cardio)
      .map((e) => MuscleBalance(
            group: e.key,
            volumePercent: (e.value / total) * 100,
          ))
      .toList()
    ..sort((a, b) => a.group.index.compareTo(b.group.index));
});
```

**PR timeline provider:**

```dart
// lib/features/analytics/presentation/providers/pr_timeline_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../history/domain/models/personal_record.dart';

class PrTimelineEntry {
  final PersonalRecord record;
  final String exerciseName;

  const PrTimelineEntry({required this.record, required this.exerciseName});
}

final prTimelineProvider = FutureProvider.autoDispose<List<PrTimelineEntry>>((ref) async {
  final prRepo = ref.watch(personalRecordRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);

  final records = await prRepo.getAllRecords(limit: 200);
  final exercises = await exerciseRepo.getAllExercises();
  final exerciseMap = {for (final e in exercises) e.id: e};

  return records
      .map((r) => PrTimelineEntry(
            record: r,
            exerciseName: exerciseMap[r.exerciseId]?.name ?? 'Unknown',
          ))
      .toList()
    ..sort((a, b) => b.record.achievedAt.compareTo(a.record.achievedAt));
});
```

**Training load provider:**

```dart
// lib/features/analytics/presentation/providers/training_load_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import 'weekly_volume_provider.dart';

class WeeklyLoad {
  final DateTime weekStart;
  final int setCount;
  final double avgRpe;
  final double load;

  const WeeklyLoad({
    required this.weekStart,
    required this.setCount,
    required this.avgRpe,
    required this.load,
  });
}

List<WeeklyLoad> computeTrainingLoad(List<SetData> sets) {
  final byWeek = <DateTime, List<SetData>>{};
  for (final s in sets) {
    final weekStart = s.date.subtract(Duration(days: s.date.weekday - 1));
    final key = DateTime(weekStart.year, weekStart.month, weekStart.day);
    byWeek.putIfAbsent(key, () => []).add(s);
  }

  final sorted = byWeek.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return sorted.map((entry) {
    final setsWithRpe = entry.value.where((s) => s.rpe != null).toList();
    final avgRpe = setsWithRpe.isEmpty
        ? 0.0
        : setsWithRpe.fold(0.0, (sum, s) => sum + s.rpe!) / setsWithRpe.length;
    return WeeklyLoad(
      weekStart: entry.key,
      setCount: entry.value.length,
      avgRpe: avgRpe,
      load: entry.value.length * avgRpe,
    );
  }).toList();
}

final trainingLoadProvider = FutureProvider.autoDispose<List<WeeklyLoad>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final workouts = await repo.getWorkoutHistory(limit: 200);
  final allSets = <SetData>[];

  for (final w in workouts) {
    if (w.completedAt == null) continue;
    final sets = await repo.getSetsForWorkout(w.id);
    for (final s in sets) {
      if (!s.isWarmUp) {
        allSets.add(SetData(date: s.timestamp, volume: s.volume, rpe: s.rpe));
      }
    }
  }

  return computeTrainingLoad(allSets);
});
```

**Step 4: Run tests**

Run: `flutter test test/features/analytics/`
Expected: All tests PASS

**Step 5: Commit**

```bash
git add lib/features/analytics/ test/features/analytics/
git commit -m "feat: add analytics providers (weekly volume, muscle balance, PR timeline, training load)"
```

---

### Task 9: Analytics l10n strings

**Files:**
- Modify: `lib/l10n/app_en.arb`

**Step 1: Add strings**

```json
  "analyticsTitle": "Analytics",
  "weeklyVolumeTitle": "Weekly Volume Trend",
  "weeklyVolumeChange": "{change}% vs previous week",
  "@weeklyVolumeChange": {
    "placeholders": { "change": { "type": "String" } }
  },
  "muscleBalanceTitle": "Muscle Group Balance",
  "prTimelineTitle": "PR Timeline",
  "trainingLoadTitle": "Weekly Training Load",
  "trainingLoadSubtitle": "Sets \u00d7 avg RPE",
  "noAnalyticsData": "Not enough data yet",
  "noAnalyticsDataSubtitle": "Complete a few workouts to see your analytics.",
  "volumeCategory": "Volume by Category",
  "loadScore": "Load: {score}",
  "@loadScore": {
    "placeholders": { "score": { "type": "String" } }
  }
```

**Step 2: Regenerate**

Run: `flutter gen-l10n`

**Step 3: Commit**

```bash
git add lib/l10n/
git commit -m "feat: add analytics l10n strings"
```

---

### Task 10: Analytics dashboard screen

**Files:**
- Create: `lib/features/analytics/presentation/screens/analytics_screen.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/features/history/presentation/widgets/progress_view.dart` (add link to analytics)

**Step 1: Create the screen**

The analytics screen is a `ConsumerWidget` with a `ListView` containing:

1. **Weekly volume trend** — `LineChart` from fl_chart showing `WeeklyVolume` data with % change annotations above each point
2. **Muscle group balance radar** — `RadarChart` from fl_chart showing volume distribution (fl_chart has `RadarChart` widget)
3. **PR timeline** — horizontal scrollable list of PR cards showing exercise name, record type icon, value, and date
4. **Training load chart** — `BarChart` showing `WeeklyLoad.load` per week with set count labels

Each section wrapped in a Card with a title.

**Step 2: Add route**

In `router.dart`, add under the shell routes or as a standalone:
```dart
GoRoute(
  path: '/analytics',
  builder: (context, state) => const AnalyticsScreen(),
),
```

**Step 3: Add navigation link from progress view**

In `progress_view.dart`, add an `OutlinedButton` or `ListTile` at the top: "View Advanced Analytics →" linking to `/analytics`.

**Step 4: Verify**

Run: `dart analyze` and `flutter test`

**Step 5: Commit**

```bash
git add lib/features/analytics/ lib/app/router.dart lib/features/history/
git commit -m "feat: add analytics dashboard screen with charts and route"
```

---

### Task 11: Final verification

**Step 1:** Run `flutter test` — all tests pass
**Step 2:** Run `dart analyze` — 0 errors
**Step 3:** Run `flutter gen-l10n` — success
**Step 4:** Run `dart run build_runner build --delete-conflicting-outputs` — Drift code up to date

---

## Part C: Cloud Sync / Backup (3.3) — PLAN ONLY

### High-Level Architecture

**Dependencies:** `firebase_core`, `firebase_auth`, `cloud_firestore`

**Components:**
1. `lib/features/sync/` feature directory
2. `SyncService` — orchestrates upload/download with Firestore
3. `AuthService` — wraps Firebase Auth (anonymous → email upgrade)
4. Sync trigger: on app open + after workout completion
5. Settings: toggle sync on/off, manual backup/restore, link account

**Data Flow:**
- Each entity type (workouts, sets, exercises, templates, body metrics, PRs) stored as a Firestore collection under `/users/{uid}/`
- Drift change listeners trigger incremental sync
- Conflict resolution: compare `updatedAt` timestamps, last-write-wins
- Offline-first: Firestore SDK handles offline caching automatically

**Platform Config:**
- `google-services.json` (Android), `GoogleService-Info.plist` (iOS)
- Firebase project setup required

**Estimated Tasks:** 8–10 tasks covering auth, sync service, per-entity sync, settings UI, conflict resolution, background sync trigger

---

## Part D: Apple Health / Google Fit Integration (3.4) — PLAN ONLY

### High-Level Architecture

**Dependencies:** `health: ^11.0.0`

**Components:**
1. `lib/features/health_sync/` feature directory
2. `HealthSyncService` — wraps `health` package for read/write
3. Permission request flow on first enable
4. Settings toggles: write workouts, write HR, write body weight, read body weight

**Data Flow:**
- **Write workouts:** After `finishWorkout()`, write workout session to HealthKit/Health Connect with type, start/end time, calories estimate (MET-based)
- **Write HR:** Stream HR samples from `HeartRateService` to health store during cardio
- **Write body weight:** On body metric save, write to health store
- **Read body weight:** On app open (if enabled), fetch latest body weight and offer to import

**Platform Config:**
- iOS: `Info.plist` health permissions, `HealthKit` capability
- Android: Health Connect permissions in manifest

**Estimated Tasks:** 6–8 tasks covering service, permission flow, write workouts, write HR, write body weight, read body weight, settings UI

---

## Part E: Social / Sharing Features (3.5) — PLAN ONLY

### High-Level Architecture

**Dependencies:** `share_plus` (already installed), `screenshot: ^3.0.0` or `RepaintBoundary`

**Components:**
1. `lib/features/sharing/` feature directory
2. `ShareImageGenerator` — renders widgets to PNG using `RepaintBoundary` + `toImage()`
3. Workout summary card widget (styled, not interactive)
4. PR celebration share card widget

**Data Flow:**
- User taps "Share" on workout detail screen → generates styled summary image → opens native share sheet
- User taps "Share" on PR celebration overlay → generates PR card image → share sheet
- No backend, no accounts — purely client-side image generation

**Share Card Content:**
- **Workout summary:** App logo, date, duration, exercise list with top set per exercise, total volume, PR badges
- **PR card:** Exercise name, record type, value, date, celebratory styling

**Estimated Tasks:** 5–6 tasks covering image generator service, workout summary widget, PR card widget, share integration on detail screen, share integration on PR overlay
