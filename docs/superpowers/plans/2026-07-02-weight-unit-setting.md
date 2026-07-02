# Weight Unit Setting (kg/lbs) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the currently inert kg/lbs setting functional — a shared typed provider, locale-based first-launch default, and display-only conversion across every weight shown in the app (GitHub issue #56).

**Architecture:** All weights stay stored in kg (domain, Drift, sync unchanged — no migration). A new `WeightUnit` enum + conversion/formatting helpers live in `lib/core/units/`. A public `weightUnitProvider` (NotifierProvider) replaces the file-private provider in the settings screen and is read by presentation widgets, which convert kg↔lbs only at the display/input boundary.

**Tech Stack:** Flutter, Riverpod (Notifier), SharedPreferences, gen-l10n ARB localisation.

## Global Constraints

- Conversion factor: `1 kg = 2.20462 lbs` (verbatim from the issue).
- Locale default: country code `US`, `LR`, `MM` → lbs; everything else (incl. unknown) → kg. Applied ONLY when no `weight_unit` value is persisted.
- SharedPreferences key stays `weight_unit`, values `'kg'` / `'lbs'` (backwards compatible with any existing stored value).
- Storage, sync snapshots, and domain models remain kg — presentation-only conversion.
- Display precision: set/body weights trim to at most 1 dp; volume totals keep their existing rounded/thousands-grouped style.
- All user-facing suffixes routed through the `S` l10n class (existing keys `kgUnit`, `lbsUnit`; new key `percentSuffix`).
- British spelling in comments/docs. No Claude references in commits, no co-author lines.
- CI hygiene at every commit: `dart analyze` zero issues, `dart format` clean, tests pass.
- The working tree contains unrelated uncommitted changes (prior review fixes). Only `git add` the files listed in each task — never `git add -A`.

---

### Task 1: Core weight unit model

**Files:**
- Create: `lib/core/units/weight_unit.dart`
- Test: `test/core/units/weight_unit_test.dart`

**Interfaces:**
- Produces: `enum WeightUnit { kg, lbs }`, `const double lbsPerKg = 2.20462`, `WeightUnit defaultWeightUnitForCountry(String? countryCode)`, `WeightUnit weightUnitFromStorage(String? value)`, extension `WeightUnitConversion` with `double fromKg(double kg)`, `double toKg(double value)`, `String formatFromKg(double kg)`.

- [ ] **Step 1: Write the failing test**

`test/core/units/weight_unit_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';

void main() {
  group('WeightUnit conversions', () {
    test('kg is identity in both directions', () {
      expect(WeightUnit.kg.fromKg(100), 100);
      expect(WeightUnit.kg.toKg(100), 100);
    });

    test('fromKg converts kg to lbs', () {
      expect(WeightUnit.lbs.fromKg(100), closeTo(220.462, 0.001));
    });

    test('toKg converts lbs to kg', () {
      expect(WeightUnit.lbs.toKg(220.462), closeTo(100, 0.001));
    });

    test('entered lbs value round-trips to the same display value', () {
      final storedKg = WeightUnit.lbs.toKg(220.5);
      expect(WeightUnit.lbs.formatFromKg(storedKg), '220.5');
    });
  });

  group('formatFromKg', () {
    test('trims whole numbers to no decimal places', () {
      expect(WeightUnit.kg.formatFromKg(60), '60');
    });

    test('keeps a single decimal place when needed', () {
      expect(WeightUnit.kg.formatFromKg(62.5), '62.5');
    });

    test('rounds converted values to one decimal place', () {
      // 100 kg -> 220.462 lbs -> displayed as 220.5
      expect(WeightUnit.lbs.formatFromKg(100), '220.5');
    });
  });

  group('defaultWeightUnitForCountry', () {
    test('US, LR and MM default to lbs', () {
      expect(defaultWeightUnitForCountry('US'), WeightUnit.lbs);
      expect(defaultWeightUnitForCountry('LR'), WeightUnit.lbs);
      expect(defaultWeightUnitForCountry('MM'), WeightUnit.lbs);
    });

    test('other and unknown countries default to kg', () {
      expect(defaultWeightUnitForCountry('GB'), WeightUnit.kg);
      expect(defaultWeightUnitForCountry('AU'), WeightUnit.kg);
      expect(defaultWeightUnitForCountry(null), WeightUnit.kg);
      expect(defaultWeightUnitForCountry(''), WeightUnit.kg);
    });
  });

  group('weightUnitFromStorage', () {
    test('parses stored strings, defaulting to kg', () {
      expect(weightUnitFromStorage('lbs'), WeightUnit.lbs);
      expect(weightUnitFromStorage('kg'), WeightUnit.kg);
      expect(weightUnitFromStorage(null), WeightUnit.kg);
      expect(weightUnitFromStorage('bogus'), WeightUnit.kg);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/units/weight_unit_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'rep_foundry/core/units/weight_unit.dart'` (file does not exist).

- [ ] **Step 3: Write the implementation**

`lib/core/units/weight_unit.dart`:

```dart
/// Weight display units.
///
/// All weights are stored in kg (domain models, Drift, sync snapshots);
/// conversion to/from lbs happens only at the presentation boundary.
enum WeightUnit { kg, lbs }

/// 1 kg = 2.20462 lbs.
const double lbsPerKg = 2.20462;

/// Countries that customarily use pounds for body/lifting weight.
const Set<String> _poundCountries = {'US', 'LR', 'MM'};

/// First-launch default for a device locale country code.
WeightUnit defaultWeightUnitForCountry(String? countryCode) =>
    _poundCountries.contains(countryCode?.toUpperCase())
        ? WeightUnit.lbs
        : WeightUnit.kg;

/// Parses the persisted `weight_unit` preference value.
WeightUnit weightUnitFromStorage(String? value) =>
    value == 'lbs' ? WeightUnit.lbs : WeightUnit.kg;

extension WeightUnitConversion on WeightUnit {
  /// Converts a stored kg value into this display unit.
  double fromKg(double kg) => this == WeightUnit.kg ? kg : kg * lbsPerKg;

  /// Converts a value entered in this unit back to kg for storage.
  double toKg(double value) => this == WeightUnit.kg ? value : value / lbsPerKg;

  /// Formats a stored kg value in this unit, trimming to at most 1 dp.
  String formatFromKg(double kg) {
    final value = fromKg(kg);
    final oneDp = double.parse(value.toStringAsFixed(1));
    return oneDp == oneDp.truncateToDouble()
        ? oneDp.toInt().toString()
        : oneDp.toStringAsFixed(1);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/units/weight_unit_test.dart`
Expected: PASS (all groups).

- [ ] **Step 5: Commit**

```bash
git add lib/core/units/weight_unit.dart test/core/units/weight_unit_test.dart
git commit -m "feat: add WeightUnit enum with kg/lbs conversion helpers (#56)"
```

---

### Task 2: Public weightUnitProvider with locale default

**Files:**
- Create: `lib/core/units/weight_unit_provider.dart`
- Test: `test/core/units/weight_unit_provider_test.dart`

**Interfaces:**
- Consumes: Task 1's `WeightUnit`, `weightUnitFromStorage`, `defaultWeightUnitForCountry`.
- Produces: `final weightUnitProvider = NotifierProvider<WeightUnitNotifier, WeightUnit>(...)` with `Future<void> set(WeightUnit unit)`; extension `WeightUnitLabel` with `String label(S s)`.

Note: the notifier reads the device locale via `dart:ui`'s raw `PlatformDispatcher.instance` (not the widgets binding) so no binding is required and widget tests (where the raw dispatcher has no meaningful country) deterministically default to kg.

- [ ] **Step 1: Write the failing test**

`test/core/units/weight_unit_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';
import 'package:rep_foundry/core/units/weight_unit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initial synchronous state is kg', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(weightUnitProvider), WeightUnit.kg);
  });

  test('loads a persisted lbs choice', () async {
    SharedPreferences.setMockInitialValues({'weight_unit': 'lbs'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(weightUnitProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(weightUnitProvider), WeightUnit.lbs);
  });

  test('set() updates state and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(weightUnitProvider.notifier).set(WeightUnit.lbs);
    expect(container.read(weightUnitProvider), WeightUnit.lbs);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('weight_unit'), 'lbs');
  });

  test('a persisted choice is never overridden by locale default', () async {
    SharedPreferences.setMockInitialValues({'weight_unit': 'kg'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(weightUnitProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(weightUnitProvider), WeightUnit.kg);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/units/weight_unit_provider_test.dart`
Expected: FAIL — package import for `weight_unit_provider.dart` unresolved.

- [ ] **Step 3: Write the implementation**

`lib/core/units/weight_unit_provider.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weight_unit.dart';

/// App-wide weight display unit, persisted under the `weight_unit` key.
///
/// On first launch (no persisted value) the unit defaults from the device
/// locale: US/LR/MM get lbs, everywhere else kg. An explicit user choice is
/// never overridden.
final weightUnitProvider = NotifierProvider<WeightUnitNotifier, WeightUnit>(
  WeightUnitNotifier.new,
);

class WeightUnitNotifier extends Notifier<WeightUnit> {
  @override
  WeightUnit build() {
    _load();
    return WeightUnit.kg;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('weight_unit');
    if (stored != null) {
      state = weightUnitFromStorage(stored);
    } else {
      state = defaultWeightUnitForCountry(
        ui.PlatformDispatcher.instance.locale.countryCode,
      );
    }
  }

  Future<void> set(WeightUnit unit) async {
    state = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weight_unit', unit.name);
  }
}

extension WeightUnitLabel on WeightUnit {
  /// Localised suffix for this unit ("kg" / "lbs").
  String label(S s) => this == WeightUnit.kg ? s.kgUnit : s.lbsUnit;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/units/weight_unit_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/units/weight_unit_provider.dart test/core/units/weight_unit_provider_test.dart
git commit -m "feat: add public weightUnitProvider with locale-based default (#56)"
```

---

### Task 3: New l10n keys

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_ko.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_zh_Hans.arb`
- Regenerate: `lib/l10n/generated/` via `flutter gen-l10n`

**Interfaces:**
- Produces: `s.weightFieldLabel(String unit)` → "Weight ({unit})"; `s.percentSuffix` → "%"; changed signatures `s.totalVolumeKg(String value, String unit)`, `s.prValueWeight(String value, String unit)`, `s.prValueVolume(String value, String unit)`, `s.prValueE1rm(String value, String unit)`, `s.importWeightPrompt(String weight, String unit)`.
- The existing `weightKgLabel` key is kept for now (still referenced) and removed in Task 9.

- [ ] **Step 1: Edit `app_en.arb`**

Next to `"weightKgLabel": "Weight (kg)"` add:

```json
  "weightFieldLabel": "Weight ({unit})",
  "@weightFieldLabel": {
    "placeholders": { "unit": { "type": "String" } }
  },
  "percentSuffix": "%",
```

Change these existing entries (adding the `unit` placeholder):

```json
  "prValueWeight": "{value} {unit}",
  "@prValueWeight": {
    "placeholders": { "value": { "type": "String" }, "unit": { "type": "String" } }
  },
  "prValueVolume": "{value} {unit} volume",
  "@prValueVolume": {
    "placeholders": { "value": { "type": "String" }, "unit": { "type": "String" } }
  },
  "prValueE1rm": "{value} {unit} e1RM",
  "@prValueE1rm": {
    "placeholders": { "value": { "type": "String" }, "unit": { "type": "String" } }
  },
  "totalVolumeKg": "{value} {unit}",
  "@totalVolumeKg": {
    "placeholders": { "value": { "type": "String" }, "unit": { "type": "String" } }
  },
  "importWeightPrompt": "Import {weight} {unit} from Health?",
  "@importWeightPrompt": {
    "placeholders": { "weight": { "type": "String" }, "unit": { "type": "String" } }
  },
```

- [ ] **Step 2: Mirror in ja/ko/zh/zh_Hans arbs**

For each of the four translated arbs apply the same structural change: copy each key's existing translated text and replace the literal `kg` with `{unit}` (and add `{unit}` metadata placeholders exactly as in `app_en.arb`). Add `weightFieldLabel` by copying the file's `weightKgLabel` translation with `kg` → `{unit}`, and add `"percentSuffix": "%"`. Where a key is absent in a translated arb, skip it (gen-l10n falls back to English).

- [ ] **Step 3: Regenerate and verify**

Run: `flutter gen-l10n && dart analyze lib/l10n`
Expected: generation succeeds; analyze reports pre-existing state (zero new issues). Compile errors in callers are expected NOT to occur yet because no caller uses the new signatures until Tasks 5–8 — but the changed signatures of `totalVolumeKg`, `prValue*`, `importWeightPrompt` WILL break their current call sites. Fix them in this task to keep the tree green, passing the kg label for now via `S`:

  - `lib/features/history/presentation/widgets/workout_history_tile.dart:94`: `s.totalVolumeKg(totalVolume!.toStringAsFixed(0))` → `s.totalVolumeKg(totalVolume!.toStringAsFixed(0), s.kgUnit)`
  - `lib/features/history/presentation/screens/pr_history_screen.dart:125,129,131`: append `, s.kgUnit` argument to `prValueWeight`/`prValueVolume`/`prValueE1rm` calls.
  - `lib/features/workout/presentation/widgets/pr_celebration_overlay.dart:92,96,98`: same.
  - `lib/features/body_metrics/presentation/screens/body_metrics_screen.dart:28`: `s.importWeightPrompt(sample.weightKg.toStringAsFixed(1))` → `s.importWeightPrompt(sample.weightKg.toStringAsFixed(1), s.kgUnit)`

- [ ] **Step 4: Run affected tests**

Run: `flutter test test/features/workout/presentation/widgets/pr_celebration_overlay_test.dart test/features/body_metrics test/features/history`
Expected: PASS (rendered strings unchanged: value + "kg").

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/ lib/features/history/presentation/widgets/workout_history_tile.dart lib/features/history/presentation/screens/pr_history_screen.dart lib/features/workout/presentation/widgets/pr_celebration_overlay.dart lib/features/body_metrics/presentation/screens/body_metrics_screen.dart
git commit -m "feat: add unit placeholders to weight l10n strings (#56)"
```

---

### Task 4: Settings screen uses the shared typed provider

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart:37-58,69,365-373`
- Test: `test/features/settings/presentation/screens/settings_screen_test.dart` (add a toggle test)

**Interfaces:**
- Consumes: `weightUnitProvider`, `WeightUnit` from Tasks 1–2.

- [ ] **Step 1: Write the failing test** (append to the existing test file, following its existing pump helper/style — adapt the harness to match what the file already uses):

```dart
testWidgets('weight unit toggle persists lbs via weightUnitProvider',
    (tester) async {
  SharedPreferences.setMockInitialValues({});
  // ...pump SettingsScreen exactly as the existing tests in this file do...
  await tester.tap(find.text('lbs'));
  await tester.pumpAndSettle();
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString('weight_unit'), 'lbs');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/settings/presentation/screens/settings_screen_test.dart`
Expected: the new test FAILS (persists via the private provider is fine — it should actually pass persistence; the REAL assertion of this task is the provider identity. If the persistence test passes against the old private provider, strengthen it by also asserting the shared provider state):

```dart
  final container = ProviderScope.containerOf(
    tester.element(find.byType(SettingsScreen)),
  );
  expect(container.read(weightUnitProvider), WeightUnit.lbs);
```

This fails while the screen still writes only the private `_weightUnitProvider`.

- [ ] **Step 3: Implement**

In `settings_screen.dart`:

1. Delete lines 37–58 (`_weightUnitProvider` and `_WeightUnitNotifier`).
2. Remove the now-orphaned `shared_preferences` import ONLY if nothing else in the file uses it (`_confirmClearData` uses `SharedPreferences.getInstance()` — so keep it).
3. Add imports:

```dart
import '../../../../core/units/weight_unit.dart';
import '../../../../core/units/weight_unit_provider.dart';
```

4. Line 69: `final weightUnit = ref.watch(_weightUnitProvider);` → `final weightUnit = ref.watch(weightUnitProvider);`
5. Lines 365–373:

```dart
                trailing: _CompactSegmented<WeightUnit>(
                  selected: weightUnit,
                  options: [
                    _SegOption(value: WeightUnit.kg, label: s.kgUnit),
                    _SegOption(value: WeightUnit.lbs, label: s.lbsUnit),
                  ],
                  onSelected: (v) =>
                      ref.read(weightUnitProvider.notifier).set(v),
                ),
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/settings/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/presentation/screens/settings_screen.dart test/features/settings/presentation/screens/settings_screen_test.dart
git commit -m "feat: back the settings weight unit toggle with the shared provider (#56)"
```

---

### Task 5: Workout logging flow (input, edit, active-screen displays)

**Files:**
- Modify: `lib/features/workout/presentation/widgets/set_input_card.dart`
- Modify: `lib/features/workout/presentation/widgets/edit_set_dialog.dart`
- Modify: `lib/features/workout/presentation/widgets/pr_celebration_overlay.dart`
- Modify: `lib/features/workout/presentation/screens/active_workout_screen.dart` (volume hero ~1108-1153, "Last:" ~1387, `_SetCard` ~1630-1698, `_GhostSetCard` ~1701-1755, `SetInputCard` construction ~1435, PR overlay construction ~689)
- Test: `test/features/workout/presentation/widgets/set_input_card_test.dart`, `test/features/workout/presentation/widgets/edit_set_dialog_test.dart`

**Interfaces:**
- Consumes: `WeightUnit`, `WeightUnitConversion`, `weightUnitProvider`, `WeightUnitLabel`, `s.weightFieldLabel(unit)`.
- Produces: `SetInputCard({..., WeightUnit unit = WeightUnit.kg})` — `onLogSet` still receives **kg**. `showEditSetDialog(context, set, {WeightUnit unit = WeightUnit.kg})` — returned set's weight is **kg**. `PRCelebrationOverlay({..., WeightUnit unit = WeightUnit.kg})`.

- [ ] **Step 1: Write failing tests** (append to `set_input_card_test.dart`, following the file's existing pump pattern):

```dart
testWidgets('lbs unit: ghost suggestion shown in lbs, logged weight stored as kg',
    (tester) async {
  const suggestion = GhostSet(weight: 100, reps: 5, setOrder: 1);
  double? loggedWeight;
  // pump SetInputCard(unit: WeightUnit.lbs, suggestion: suggestion,
  //   onLogSet: ({required weight, required reps, rpe, isWarmUp}) =>
  //       loggedWeight = weight)
  // — using the same MaterialApp/localisation harness as the other tests.

  // Ghost prefill converted for display: 100 kg -> 220.5 lbs.
  final fields = find.byType(TextFormField);
  expect(tester.widget<TextFormField>(fields.at(0)).controller?.text, '220.5');

  // Log without editing: parses 220.5 lbs -> ~100.02 kg.
  await tester.tap(find.text('Log Set'.toUpperCase()).first); // match existing test's tap target
  await tester.pump();
  expect(loggedWeight, closeTo(100.0, 0.05));
});
```

And an edit-dialog round-trip test in `edit_set_dialog_test.dart` (matching its harness):

```dart
testWidgets('lbs unit: unchanged weight is not drifted by conversion',
    (tester) async {
  // open showEditSetDialog(context, setWith(weight: 100), unit: WeightUnit.lbs)
  // tap Save without editing
  // expect returned set.weight == 100 exactly (no kg->lbs->kg drift)
});

testWidgets('lbs unit: edited weight is parsed as lbs and stored as kg',
    (tester) async {
  // enter '225' in the weight field, Save
  // expect returned set.weight closeTo(102.06, 0.05)
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/workout/presentation/widgets/set_input_card_test.dart test/features/workout/presentation/widgets/edit_set_dialog_test.dart`
Expected: FAIL — `unit` named parameter does not exist.

- [ ] **Step 3: Implement `SetInputCard`**

In `set_input_card.dart`:

1. Import `package:rep_foundry/core/units/weight_unit.dart` and `package:rep_foundry/core/units/weight_unit_provider.dart` (for the `label(S)` extension).
2. Add field + constructor param: `final WeightUnit unit;` / `this.unit = WeightUnit.kg,`.
3. `initState` prefill: `text: s != null ? widget.unit.formatFromKg(s.weight) : '0'` (same in `didUpdateWidget`). RPE prefill unchanged (`_formatWeight` stays for RPE).
4. `_submit`: `final weight = widget.unit.toKg(double.tryParse(_weightController.text) ?? 0);`
5. Weight field label (line 165): `label: s.weightFieldLabel(widget.unit.label(s)),`

- [ ] **Step 4: Implement `edit_set_dialog.dart`**

1. Same two imports as above.
2. `showEditSetDialog(BuildContext context, WorkoutSet existingSet, {WeightUnit unit = WeightUnit.kg})`, pass into `_EditSetDialog(existingSet: existingSet, unit: unit)`; add `final WeightUnit unit;` field.
3. `initState`: `_weightController = TextEditingController(text: widget.unit.formatFromKg(widget.existingSet.weight));` and keep the initial string: `late final String _initialWeightText;` assigned the same value.
4. `_submit` drift guard:

```dart
    final weightText = _weightController.text;
    final weight = weightText == _initialWeightText
        ? widget.existingSet.weight
        : widget.unit.toKg(double.tryParse(weightText) ?? 0);
```

5. Weight field label (line 90): `labelText: s.weightFieldLabel(widget.unit.label(s)),`

- [ ] **Step 5: Implement `pr_celebration_overlay.dart`**

1. Imports as above.
2. Add `final WeightUnit unit;` / `this.unit = WeightUnit.kg,` to `PRCelebrationOverlay`.
3. `_formattedValue`: for `maxWeight`/`maxVolume`/`estimatedOneRepMax` use `final formatted = widget.unit.fromKg(value).toStringAsFixed(1);` and pass `widget.unit.label(s)` as the second argument to `s.prValueWeight/prValueVolume/prValueE1rm`. `maxReps` unchanged (`s.prValueReps`).

- [ ] **Step 6: Implement `active_workout_screen.dart`**

1. Imports: `import '../../../../core/units/weight_unit.dart';` and `import '../../../../core/units/weight_unit_provider.dart';`
2. `_KineticVolumeHero` → `ConsumerWidget` (`build(BuildContext context, WidgetRef ref)`), add `final unit = ref.watch(weightUnitProvider);` and `final s = S.of(context)!;` at the top of build, then:

```dart
    final volume = unit.fromKg(volumeKg);
    final volumeStr = volume >= 1000
        ? '${(volume / 1000).toStringAsFixed(1)}k'
        : volume.toStringAsFixed(0);
```

and the `'kg'` literal at line 1146 → `unit.label(s)`.
3. `_ExerciseSectionContent` → `ConsumerWidget`; in build: `final unit = ref.watch(weightUnitProvider);`
   - Line 1387: `'Last: ${unit.formatFromKg(sets.last.weight)}${unit.label(s)} × ${sets.last.reps}'` (an `s` is already in scope in that build).
   - `SetInputCard(...)` construction: add `unit: unit,`.
4. `_SetCard` → `ConsumerWidget`; `final unit = ref.watch(weightUnitProvider);` and `final s = S.of(context)!;`
   - Line 1655: `showEditSetDialog(context, set, unit: unit)`.
   - Line 1678: `'${unit.formatFromKg(set.weight)}${unit.label(s)}'`.
5. `_GhostSetCard` → `ConsumerWidget`; same pattern; line 1735: `'${unit.formatFromKg(ghost.weight)}${unit.label(s)}'`.
6. `_showPRCelebration` (line ~689): add `unit: ref.read(weightUnitProvider),` to the `PRCelebrationOverlay(...)` construction.

- [ ] **Step 7: Run tests**

Run: `flutter test test/features/workout/`
Expected: PASS, including the new lbs tests. If any existing test pumping these widgets lacks a `ProviderScope`, wrap it.

- [ ] **Step 8: Commit**

```bash
git add lib/features/workout/ test/features/workout/
git commit -m "feat: display and enter set weights in the selected unit (#56)"
```

---

### Task 6: Body metrics screen

**Files:**
- Modify: `lib/features/body_metrics/presentation/screens/body_metrics_screen.dart`
- Test: `test/features/body_metrics/presentation/screens/body_metrics_screen_test.dart`

**Interfaces:**
- Consumes: `weightUnitProvider`, `WeightUnitConversion.formatFromKg/toKg`, `WeightUnitLabel.label`, `s.percentSuffix`, `s.importWeightPrompt(weight, unit)`.

- [ ] **Step 1: Write the failing test** (append, using the file's existing harness with `SharedPreferences.setMockInitialValues`):

```dart
testWidgets('add dialog stores an lbs entry converted to kg', (tester) async {
  SharedPreferences.setMockInitialValues({'weight_unit': 'lbs'});
  // pump BodyMetricsScreen with the existing fake repository harness,
  // pumpAndSettle so the provider loads the lbs pref.
  // open the add dialog, enter '165' in the weight field, tap Save.
  // expect repository.created.single.weight closeTo(74.84, 0.05)
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/body_metrics/`
Expected: new test FAILS (stored weight is 165, not ~74.84).

- [ ] **Step 3: Implement**

1. Imports: `import '../../../../core/units/weight_unit.dart';` and `import '../../../../core/units/weight_unit_provider.dart';`
2. Import prompt (line 28): the screen build has `ref`; add `final unit = ref.watch(weightUnitProvider);` and use `s.importWeightPrompt(unit.formatFromKg(sample.weightKg), unit.label(s))`.
3. `_AddBodyMetricDialog` → `ConsumerStatefulWidget` / `ConsumerState`:
   - `suffixText: 'kg'` (line 179) → `suffixText: ref.watch(weightUnitProvider).label(s),`
   - `suffixText: '%'` (line 196) → `suffixText: s.percentSuffix,`
   - Save handler: `final weight = ref.read(weightUnitProvider).toKg(double.parse(_weightController.text));`
4. `_LatestCard` → `ConsumerWidget`; line 292: `'${unit.formatFromKg(metric.weight)} ${unit.label(s)}'`.
5. `_MetricTile` (already `ConsumerWidget`): add `final s = S.of(context)!;` and `final unit = ref.watch(weightUnitProvider);`; line 342: `title: Text('${unit.formatFromKg(metric.weight)} ${unit.label(s)}'),`.

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/body_metrics/`
Expected: PASS — the existing `75.5 kg` assertion still holds (`formatFromKg(75.5)` in kg → `75.5`).

- [ ] **Step 5: Commit**

```bash
git add lib/features/body_metrics/ test/features/body_metrics/
git commit -m "feat: body metrics respect the selected weight unit (#56)"
```

---

### Task 7: History and PR displays

**Files:**
- Modify: `lib/features/history/presentation/screens/workout_detail_screen.dart` (~239, ~426, ~454, ~458)
- Modify: `lib/features/history/presentation/screens/exercise_progress_screen.dart` (~100, ~108, ~197, ~211, chart data)
- Modify: `lib/features/history/presentation/screens/history_list_screen.dart` (~333-357, ~556-557)
- Modify: `lib/features/history/presentation/widgets/workout_history_tile.dart` (~94)
- Modify: `lib/features/history/presentation/widgets/history_desktop_view.dart` (~154-155, ~264, ~366, ~406)
- Modify: `lib/features/history/presentation/widgets/muscle_group_chart.dart` (~63 and chart values)
- Modify: `lib/features/history/presentation/screens/pr_history_screen.dart` (~122-132)
- Test: existing history tests (update any 'kg' string assertions that legitimately change)

**Interfaces:**
- Consumes: `weightUnitProvider`, `WeightUnitConversion`, `WeightUnitLabel`.

Pattern for every site: the nearest widget owning the string becomes a `ConsumerWidget` (or uses its existing `ref`), reads `final unit = ref.watch(weightUnitProvider);`, converts the kg value with `unit.fromKg(...)` (keeping each site's existing precision/formatting style, e.g. `_formatKg(unit.fromKg(totalKg))`), and replaces the literal `'kg'` / `' kg'` with `unit.label(s)`.

- [ ] **Step 1: `workout_detail_screen.dart`** — `_WorkoutDetailBody` and `_ExerciseSetsCard` → `ConsumerWidget`:
  - `value: '${unit.fromKg(totalVolume).toStringAsFixed(0)} ${unit.label(s)}'`
  - `'Vol: ${unit.fromKg(volume).toStringAsFixed(0)} ${unit.label(s)}'`
  - `_tableCell(context, '${unit.formatFromKg(sets[i].weight)} ${unit.label(s)}')`
  - e1RM cell: `unit.fromKg(sets[i].estimatedOneRepMax).toStringAsFixed(1)`

- [ ] **Step 2: `exercise_progress_screen.dart`** — `_ProgressBody` → `ConsumerWidget`:
  - Best e1RM: `'${progress.maxEstimated1RM != null ? unit.fromKg(progress.maxEstimated1RM!).toStringAsFixed(1) : '—'} ${unit.label(s)}'`
  - Total volume: same pattern with `toStringAsFixed(0)`.
  - Set rows: `'${unit.formatFromKg(set.weight)} ${unit.label(s)}'`; e1RM column `unit.fromKg(set.estimatedOneRepMax).toStringAsFixed(1)`.
  - Any `ProgressDataPoint(value: ...)` fed from kg values: wrap with `unit.fromKg(...)` so chart axes match.

- [ ] **Step 3: `history_list_screen.dart`**:
  - `_WeeklyVolumeCard` (already `ConsumerWidget`): big figure `_formatKg(unit.fromKg(totalKg))`, `'kg'` text → `unit.label(s)` (add `final s = S.of(context)!;` if absent).
  - `_SessionCard` → `ConsumerWidget`: `metaString` uses `_formatKg(unit.fromKg(totalKg))` and `unit.label(s)` instead of `' kg'`.

- [ ] **Step 4: `workout_history_tile.dart`** — `WorkoutHistoryTile` → `ConsumerWidget`: `s.totalVolumeKg(unit.fromKg(totalVolume!).toStringAsFixed(0), unit.label(s))`.

- [ ] **Step 5: `history_desktop_view.dart`**:
  - `_SessionRow` → `ConsumerWidget`: meta string conversion as in Step 3.
  - `_DetailPane` (already `ConsumerWidget`): stat tile `value: _formatKg(unit.fromKg(item.totalVolume)), unit: unit.label(s)`.
  - `_ExerciseBreakdownCard` → `ConsumerWidget`: `'e1RM ${unit.fromKg(bestE1rm).toStringAsFixed(0)}'`.
  - `_SetChip` → `ConsumerWidget`: `'${warm ? 'W' : index} · ${_trimWeight(unit.fromKg(weight))}${unit.label(s)} · ×$reps...'`.

- [ ] **Step 6: `muscle_group_chart.dart`** — pass `unit` (and `s`-derived label) from `MuscleGroupChart` (already `ConsumerWidget`) into `_Chart` as constructor params, or make `_Chart` a `ConsumerWidget`; convert bar rod values AND tooltip: `'${labelForMuscleGroup(item.group)}\n${unit.fromKg(item.volume).toStringAsFixed(0)} ${unit.label(s)}'` with `maxY: unit.fromKg(maxVolume) * 1.1`.

- [ ] **Step 7: `pr_history_screen.dart`** — `_ExercisePrCard` → `ConsumerWidget`; `_formattedValue(S s, WeightUnit unit, RecordType type, double value)`: weight/volume/e1rm cases use `unit.fromKg(value).toStringAsFixed(1)` and pass `unit.label(s)`; reps unchanged.

- [ ] **Step 8: Run tests**

Run: `flutter test test/features/history/`
Expected: PASS; update any assertions that now differ only by trimmed formatting (e.g. `60.0 kg` → `60 kg`).

- [ ] **Step 9: Commit**

```bash
git add lib/features/history/ test/features/history/
git commit -m "feat: history and PR displays respect the selected weight unit (#56)"
```

---

### Task 8: Analytics displays

**Files:**
- Modify: `lib/features/analytics/presentation/screens/analytics_screen.dart` (weekly volume chart ~188-220)
- Modify: `lib/features/analytics/presentation/widgets/analytics_desktop_view.dart` (`_KpiRow` ~110-155)

**Interfaces:**
- Consumes: `weightUnitProvider`, `WeightUnitConversion`, `WeightUnitLabel`.

- [ ] **Step 1: `analytics_screen.dart`** — in the widget building the weekly-volume `LineChart` (make it a `ConsumerWidget`/use existing `ref`):
  - FlSpot data: `FlSpot(i.toDouble(), unit.fromKg(data[i].totalVolume))` — converts axis labels too.
  - Tooltip: `'$dateLabel\n${unit.fromKg(week.totalVolume).toStringAsFixed(0)} ${unit.label(s)}$changeText'`.
  - Leave the training-load chart alone (load is unitless).

- [ ] **Step 2: `analytics_desktop_view.dart`** — `_KpiRow` → `ConsumerWidget`:
  - `value: _formatKg(unit.fromKg(totalVolume)), unit: unit.label(s)` for both volume tiles (total + avg/session).

- [ ] **Step 3: Run tests**

Run: `flutter test test/features/analytics/`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/analytics/
git commit -m "feat: analytics volume displays respect the selected weight unit (#56)"
```

---

### Task 9: Remove the dead key, full verification

**Files:**
- Modify: all five arb files (delete `weightKgLabel`), regenerate `lib/l10n/generated/`

- [ ] **Step 1: Confirm `weightKgLabel` has no remaining callers**

Run: `grep -rn "weightKgLabel" lib/ test/`
Expected: matches only in arb + generated files. (If callers remain, they were missed in Task 5 — fix them first.)

- [ ] **Step 2: Delete the key** from `app_en.arb`, `app_ja.arb`, `app_ko.arb`, `app_zh.arb`, `app_zh_Hans.arb`; run `flutter gen-l10n`.

- [ ] **Step 3: Full verification**

```bash
dart analyze                          # expect: zero issues
dart format --set-exit-if-changed .   # expect: clean (format first if needed)
flutter test                          # expect: all pass
```

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/
git commit -m "chore: drop the superseded weightKgLabel l10n key (#56)"
```

---

## Acceptance criteria trace (issue #56)

| Criterion | Covered by |
|---|---|
| Toggling kg/lbs updates every weight shown | Tasks 4–8 |
| lbs entries stored correctly in kg, round-trip | Task 1 (round-trip test), Task 5 (set input + edit dialog tests), Task 6 (body metrics test) |
| Fresh US install defaults lbs; explicit choice never overridden | Tasks 1–2 (pure function + provider tests) |
| Stored data & sync stay kg (no schema change) | Design: conversion only in presentation; no data/domain/sync file touched |
| Unit tests for conversion helper + widget test for lbs set persistence | Tasks 1, 5 |
