# Virtual Trainer Phase 2a — HR-Aware Coaching Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the coach heart-rate aware — announcing training-zone changes, warning when the user exceeds their safe maximum, and falling silent on encouragement whenever doing so could push someone at risk harder.

**Architecture:** A new event source watches the existing BLE heart-rate stream, maps each reading to a zone via `zoneConfigurationProvider`, and emits typed `TrainerEvent`s onto the existing bus. The `CoachingEngine` gains safety-priority handling for those events plus suppression rules that override its ordinary behaviour. Nothing about the transport, speech service, or bridge changes shape — this is a new event producer plus new engine rules.

**Tech Stack:** Flutter, Riverpod, `hr_zones` 0.0.2, existing `HeartRateService` (BLE), `flutter_tts`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-08-01-virtual-personal-trainer-design.md` §6
**Issue:** #91. Content work (Hype/Sergeant personas, quote bank) is #99 and explicitly **out of scope here**.

## Global Constraints

- Use `gradle21w` in place of `./gradlew`. Use `python3` in place of `python`.
- **British spelling** in all code, comments, strings, and commit messages ("behaviour", "colour"). Flutter API names keep their spelling.
- Author is **Paul Snow**. No AI-assistant references anywhere.
- Domain and application layers are **pure Dart** — no `package:flutter`, no `dart:ui`.
- All user-facing strings in `lib/l10n/app_en.arb` via `S.of(context)!`; run `flutter gen-l10n` and commit generated output.
- Widget tests need `localizationsDelegates: S.localizationsDelegates` and `supportedLocales: S.supportedLocales`, plus `SharedPreferences.setMockInitialValues({})` in `setUp`.
- Strict lints: `always_declare_return_types`, `prefer_const_constructors`, `prefer_final_fields`, `prefer_final_locals`. `dart analyze` must report zero issues.
- `dart format --set-exit-if-changed .` must pass before every commit.
- Full `flutter test` suite (currently 1192) must pass; pre-existing tests must not be weakened.
- **Content rules for every spoken phrase:** never urge load increases, never "push through pain", no ego-lifting, no body-shaming, no guilt framing. Safety phrases must be calm and directive, never alarming.
- Every new phrase key needs a `phraseResolvers` entry (`phrase_resolver.dart`) **and** must be added to the persona-pack tests' loops — those iterate `steadyPersona` only, and a missing resolver means the coach silently says nothing.
- Commit per task on one branch, `feat/91-hr-aware-coaching`. Do not open per-task branches.

## Existing code this builds on — read before starting

- `lib/features/trainer/domain/trainer_event.dart` — `sealed class TrainerEvent`, `TrainerEventKind`.
- `lib/features/trainer/domain/coaching_cue.dart` — `SpeechPriority { encouragement, milestone, countdown, safety }`. **`safety` is currently unreachable; this plan is what makes it real.**
- `lib/features/trainer/application/coaching_engine.dart` — `onEvent(event, {required now, countdownsEnabled, encouragementEnabled})`.
- `lib/features/trainer/presentation/providers/coach_bridge.dart` — subscribes to the bus, resolves phrase keys, speaks.
- `lib/features/trainer/presentation/providers/trainer_event_bus.dart` — `emit` applies the entitlement gate internally.
- `lib/features/heart_rate/presentation/providers/zone_configuration_provider.dart` — `zoneConfigurationProvider` (`ZoneConfiguration?`) and `cautionModeProvider` (`bool`).
- `lib/features/cardio/data/heart_rate_service.dart` — `Stream<int> get heartRateStream`.
- `hr_zones` 0.0.2: `ZoneConfiguration { List<CalculatedZone> zones; int maxHr; ZoneMethod method; ZoneReliability reliability; }`, `CalculatedZone { int zoneNumber; String label; String effortLabel; String descriptiveLabel; int lowerBound; int? upperBound; }`. There is **no** built-in "zone for a given bpm" lookup — Task 1 adds one.
- `lib/features/heart_rate/presentation/providers/max_hr_alert_provider.dart` — the **existing** max-HR alert (sound + haptic + cooldown), fired from `heart_rate_panel_screen.dart`.

## Two decisions already taken — do not revisit

1. **The existing max-HR alert stays as the attention-getter.** A chime cuts through instantly; a spoken line takes ~2 s. The coach speaks its guidance *after* the alert, never over it. This is the #97 lesson: exactly one owner of a given audio moment.
2. **The existing alert only fires while the HR panel screen is mounted.** During a workout with the panel closed, nothing warns the user today. The coach's bridge is app-wide, so this plan closes that gap — Task 4 tests it explicitly.

---

### Task 1: Zone lookup and HR trainer events

Pure Dart. No streams, no Flutter.

**Files:**
- Create: `lib/features/trainer/domain/hr_zone_lookup.dart`
- Modify: `lib/features/trainer/domain/trainer_event.dart`
- Test: `test/features/trainer/domain/hr_zone_lookup_test.dart`

**Interfaces:**
- Produces:
  - `int? zoneNumberFor(ZoneConfiguration config, int bpm)` — the zone containing `bpm`, or null below zone 1. Top zone has a null `upperBound` and extends to `config.maxHr` and beyond.
  - New `TrainerEvent` subclasses: `HeartRateZoneChanged({required int zoneNumber, required String effortLabel, required String descriptiveLabel})`, `HeartRateAboveCap({required int bpm, required int cap})`, `HeartRateBackBelowCap()`.
  - New `TrainerEventKind` values: `hrZoneChanged`, `hrAboveCap`, `hrBackBelowCap`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/features/trainer/domain/hr_zone_lookup.dart';

ZoneConfiguration _config() => calculateZones(
      const HealthProfile(age: 40),
    )!;

void main() {
  group('zoneNumberFor', () {
    test('returns null below the bottom of zone 1', () {
      final config = _config();
      final belowZone1 = config.zones.first.lowerBound - 1;

      expect(zoneNumberFor(config, belowZone1), isNull);
    });

    test('returns the zone containing the reading', () {
      final config = _config();
      for (final zone in config.zones) {
        expect(zoneNumberFor(config, zone.lowerBound), zone.zoneNumber,
            reason: 'lower bound of zone ${zone.zoneNumber} is inclusive');
      }
    });

    test('an upper bound belongs to the next zone up, not its own', () {
      final config = _config();
      final zone1 = config.zones.first;

      expect(zoneNumberFor(config, zone1.upperBound!), 2);
    });

    test('readings above the top zone stay in the top zone', () {
      final config = _config();

      expect(zoneNumberFor(config, config.maxHr + 40),
          config.zones.last.zoneNumber);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/trainer/domain/hr_zone_lookup_test.dart`
Expected: FAIL — `hr_zone_lookup.dart` does not exist.

- [ ] **Step 3: Implement the lookup**

Create `lib/features/trainer/domain/hr_zone_lookup.dart`:

```dart
import 'package:hr_zones/hr_zones.dart';

/// The zone containing [bpm], or null when the reading sits below zone 1.
///
/// Bounds follow the package's convention: `lowerBound` inclusive,
/// `upperBound` exclusive. The top zone has a null `upperBound` and absorbs
/// everything above it — a reading past the configured maximum is still "in"
/// the top zone, and the above-cap warning is what handles that case.
int? zoneNumberFor(ZoneConfiguration config, int bpm) {
  for (final zone in config.zones) {
    if (bpm < zone.lowerBound) continue;
    final upper = zone.upperBound;
    if (upper == null || bpm < upper) return zone.zoneNumber;
  }
  return bpm >= config.zones.first.lowerBound
      ? config.zones.last.zoneNumber
      : null;
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/trainer/domain/hr_zone_lookup_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Add the three events**

In `lib/features/trainer/domain/trainer_event.dart`, add `hrZoneChanged`, `hrAboveCap`, `hrBackBelowCap` to `TrainerEventKind`, then:

```dart
/// The user has settled into a different training zone.
class HeartRateZoneChanged extends TrainerEvent {
  const HeartRateZoneChanged({
    required this.zoneNumber,
    required this.effortLabel,
    required this.descriptiveLabel,
  });

  final int zoneNumber;
  final String effortLabel;
  final String descriptiveLabel;

  @override
  TrainerEventKind get kind => TrainerEventKind.hrZoneChanged;
}

/// The heart rate has crossed the user's safe maximum. Re-emitted while it
/// stays there so the coach can repeat its warning.
class HeartRateAboveCap extends TrainerEvent {
  const HeartRateAboveCap({required this.bpm, required this.cap});

  final int bpm;
  final int cap;

  @override
  TrainerEventKind get kind => TrainerEventKind.hrAboveCap;
}

class HeartRateBackBelowCap extends TrainerEvent {
  const HeartRateBackBelowCap();

  @override
  TrainerEventKind get kind => TrainerEventKind.hrBackBelowCap;
}
```

Adding to a `sealed` hierarchy makes the engine's `switch` non-exhaustive — that is intentional and Task 2 fixes it. The analyser error between steps is expected.

- [ ] **Step 6: Full suite, analyse, format, commit**

Run: `flutter test && dart analyze && dart format --set-exit-if-changed .`

```bash
git checkout -b feat/91-hr-aware-coaching
git add lib/features/trainer/domain test/features/trainer/domain
git commit -m "feat: heart rate zone lookup and trainer events

Adds a zone-for-bpm lookup over the hr_zones configuration and the three
heart-rate events the coach reacts to: settling into a new zone, crossing
the safe maximum, and returning below it.

Refs #91"
```

---

### Task 2: Engine safety rules

The heart of this issue. Pure Dart, TDD, and the first use of `SpeechPriority.safety`.

**Files:**
- Modify: `lib/features/trainer/application/coaching_engine.dart`
- Test: `test/features/trainer/application/coaching_engine_hr_test.dart`

**Interfaces:**
- Consumes: Task 1's events and kinds.
- Produces: `onEvent` gains two named parameters — `bool hrCalloutsEnabled = true`, `bool cautionMode = false` — and the engine gains `bool get isAboveCap`.

**The rules, from spec §6. Every one needs a test that fails without it.**

1. Above cap, the engine returns a **safety** cue for `HeartRateAboveCap`, and repeats it no more often than every 30 s while it stays above.
2. While above cap, **all encouragement is suppressed** — `SetLogged`, zone callouts, everything except safety and countdown cues. Returning below cap lifts the suppression.
3. In **caution mode**, zone callouts remain but are informational; no encouragement is produced at any intensity.
4. Encouragement never fires when the current zone is **5** — the Zone 4 ceiling from the spec.
5. `hrCalloutsEnabled == false` silences zone callouts but **never** silences cap warnings.

- [ ] **Step 1: Write the failing tests**

Create `test/features/trainer/application/coaching_engine_hr_test.dart`. Cover, one test each:

```dart
// Sketch of the shape; write all nine, each asserting one rule.
test('above cap produces a safety-priority cue', () {
  final engine = _engine();
  final cue = engine.onEvent(
    const HeartRateAboveCap(bpm: 180, cap: 170),
    now: t0,
  );

  expect(cue, isNotNull);
  expect(cue!.priority, SpeechPriority.safety);
  expect(cue.args['bpm'], 180);
});

test('the cap warning repeats no more than every 30 seconds', () {
  final engine = _engine();
  engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);

  final tooSoon = engine.onEvent(
    const HeartRateAboveCap(bpm: 182, cap: 170),
    now: t0.add(const Duration(seconds: 10)),
  );
  final later = engine.onEvent(
    const HeartRateAboveCap(bpm: 182, cap: 170),
    now: t0.add(const Duration(seconds: 31)),
  );

  expect(tooSoon, isNull);
  expect(later, isNotNull);
});

test('encouragement is suppressed entirely while above cap', () {
  final engine = _engine(encouragementEverySets: 1, cooldown: Duration.zero);
  engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);

  final cue = engine.onEvent(
    const SetLogged(setNumber: 1, isPersonalRecord: false),
    now: t0.add(const Duration(seconds: 5)),
  );

  expect(cue, isNull);
});

test('dropping back below the cap lifts the suppression', () {
  final engine = _engine(encouragementEverySets: 1, cooldown: Duration.zero);
  engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);
  engine.onEvent(const HeartRateBackBelowCap(),
      now: t0.add(const Duration(seconds: 20)));

  final cue = engine.onEvent(
    const SetLogged(setNumber: 1, isPersonalRecord: false),
    now: t0.add(const Duration(seconds: 25)),
  );

  expect(cue, isNotNull);
});

test('a personal record is still suppressed above cap', () {
  // PRs are milestone priority and normally bypass the cooldown, so they are
  // the most likely cue to escape the safety suppression.
  final engine = _engine();
  engine.onEvent(const HeartRateAboveCap(bpm: 180, cap: 170), now: t0);

  final cue = engine.onEvent(
    const SetLogged(setNumber: 1, isPersonalRecord: true),
    now: t0.add(const Duration(seconds: 5)),
  );

  expect(cue, isNull);
});

test('caution mode produces zone callouts but no encouragement', () {
  final engine = _engine(encouragementEverySets: 1, cooldown: Duration.zero);

  final zone = engine.onEvent(
    const HeartRateZoneChanged(
        zoneNumber: 3, effortLabel: 'Moderate', descriptiveLabel: 'Aerobic'),
    now: t0,
    cautionMode: true,
  );
  final encouragement = engine.onEvent(
    const SetLogged(setNumber: 1, isPersonalRecord: false),
    now: t0.add(const Duration(minutes: 1)),
    cautionMode: true,
  );

  expect(zone, isNotNull);
  expect(encouragement, isNull);
});

test('encouragement never fires in zone 5', () {
  final engine = _engine(encouragementEverySets: 1, cooldown: Duration.zero);
  engine.onEvent(
    const HeartRateZoneChanged(
        zoneNumber: 5, effortLabel: 'Maximum', descriptiveLabel: 'VO₂ Max'),
    now: t0,
  );

  final cue = engine.onEvent(
    const SetLogged(setNumber: 1, isPersonalRecord: false),
    now: t0.add(const Duration(minutes: 1)),
  );

  expect(cue, isNull);
});

test('hrCalloutsEnabled false silences zone callouts', () {
  final engine = _engine();

  final cue = engine.onEvent(
    const HeartRateZoneChanged(
        zoneNumber: 3, effortLabel: 'Moderate', descriptiveLabel: 'Aerobic'),
    now: t0,
    hrCalloutsEnabled: false,
  );

  expect(cue, isNull);
});

test('hrCalloutsEnabled false still allows cap warnings', () {
  // The safety path must not be switchable off by a convenience toggle.
  final engine = _engine();

  final cue = engine.onEvent(
    const HeartRateAboveCap(bpm: 180, cap: 170),
    now: t0,
    hrCalloutsEnabled: false,
  );

  expect(cue, isNotNull);
  expect(cue!.priority, SpeechPriority.safety);
});
```

Each must fail against the current engine before you implement. Verify that, do not assume it.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/trainer/application/coaching_engine_hr_test.dart`
Expected: FAIL on every test.

- [ ] **Step 3: Implement the rules**

In `coaching_engine.dart`: track `bool _aboveCap = false` and `DateTime? _lastCapWarningAt`, plus `int? _currentZone`, all cleared by `reset()`. Add the two named parameters. Extend the `switch` with the three new events, and gate every encouragement-producing branch behind `!_aboveCap && !cautionMode && _currentZone != 5`.

Put the suppression check in **one** place that all encouragement paths pass through rather than repeating it per branch — a scattered rule is how a future persona or event kind quietly escapes it.

Keep the existing decision-before-recording property: a suppressed cue must not consume a phrase from the variety bank nor move the cooldown. That was a review finding in phase 1; do not regress it.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/trainer/application/coaching_engine_hr_test.dart` then the full suite.
Expected: all pass, including every pre-existing engine test unchanged.

- [ ] **Step 5: Check coverage**

Run: `flutter test --coverage test/features/trainer/`
Expected: `coaching_engine.dart` still ≥80% (it was 100%). Add tests for uncovered branches rather than lowering the bar.

- [ ] **Step 6: Commit**

```bash
git add lib/features/trainer/application test/features/trainer/application
git commit -m "feat: heart rate safety rules in the coaching engine

Above the user's safe maximum the coach stops encouraging entirely and
repeats a calm ease-off warning at most every thirty seconds. Caution mode
reduces zone callouts to information only, and encouragement never fires in
zone five.

Refs #91"
```

---

### Task 3: HR event source

Turns the BLE stream into trainer events, with the hysteresis that stops the coach chattering at a zone boundary.

**Files:**
- Create: `lib/features/trainer/presentation/providers/hr_event_source.dart`
- Test: `test/features/trainer/presentation/hr_event_source_test.dart`

**Interfaces:**
- Consumes: `heartRateServiceProvider`'s `heartRateStream`, `zoneConfigurationProvider`, `cautionModeProvider`, `trainerEventBusProvider`, Task 1's lookup and events.
- Produces: `hrEventSourceProvider` — a `Provider<HrEventSource>` mounted alongside the bridge; `class HrEventSource { HrEventSource(this._ref, {Duration zoneDwell = const Duration(seconds: 10), Duration capRepeat = const Duration(seconds: 30)}); void dispose(); }`.

**Behaviour:**
- A zone change is emitted only after the reading has **stayed** in the new zone for `zoneDwell` (default 10 s). Without this the coach announces a zone change on every boundary flicker — the single most likely way this feature becomes intolerable.
- `HeartRateAboveCap` is emitted on the first reading above `config.maxHr`, then re-emitted every `capRepeat` while it stays above. The engine also rate-limits; belt and braces is deliberate for a safety path.
- `HeartRateBackBelowCap` on the first reading back below, once.
- Nothing is emitted when `zoneConfigurationProvider` is null (no usable profile).
- Emission goes through `trainerEventBusProvider.emit`, which already applies the entitlement gate.

- [ ] **Step 1: Write the failing tests**

Create the test with a controllable stream and `fake_async`. Cover: no emission before dwell elapses; one emission after; no repeat while the zone holds; cap crossing emits immediately; cap repeat at 30 s not before; back-below emits once; null zone config emits nothing; `dispose()` cancels the subscription.

Use a fake `HeartRateService` exposing a `StreamController<int>` you drive directly — do not touch BLE.

- [ ] **Step 2: Run to verify they fail**

Expected: FAIL — `hr_event_source.dart` does not exist.

- [ ] **Step 3: Implement**

Subscribe to `heartRateStream`; on each reading resolve the zone via `zoneNumberFor`; track a candidate zone and the time it was first seen, promoting it to `_currentZone` and emitting only once `zoneDwell` has passed. Track above/below cap separately from zones — a reading can be above the cap while still nominally in the top zone.

Use `clock.now()` from `package:clock` (already a dependency) rather than `DateTime.now()`, so `fake_async` controls time in tests.

- [ ] **Step 4: Run to verify they pass**, then the full suite.

- [ ] **Step 5: Commit**

```bash
git add lib/features/trainer/presentation/providers/hr_event_source.dart test/features/trainer/presentation
git commit -m "feat: heart rate event source feeding the coach

Maps the BLE heart rate stream onto trainer events, requiring a ten second
dwell before announcing a zone change so boundary flicker cannot make the
coach chatter, and re-emitting the above-cap event every thirty seconds
while the reading stays high.

Refs #91"
```

---

### Task 4: Wire it up, settings, and phrases

**Files:**
- Modify: `lib/features/trainer/presentation/providers/coach_bridge.dart` (pass the new engine parameters)
- Modify: `lib/features/trainer/presentation/providers/trainer_settings_provider.dart` (two new settings)
- Modify: `lib/features/trainer/presentation/screens/trainer_settings_screen.dart`
- Modify: `lib/features/trainer/data/persona_packs.dart`, `lib/features/trainer/presentation/providers/phrase_resolver.dart`, `lib/l10n/app_en.arb`
- Modify: `lib/app/router.dart` (mount the HR event source beside the bridge)
- Modify: `lib/features/heart_rate/presentation/screens/heart_rate_panel_screen.dart` (sequencing with the existing alert)
- Test: `test/features/trainer/presentation/hr_coaching_integration_test.dart`, plus additions to the persona-pack and settings tests

**Settings:** `hrCalloutsEnabled` (default true) and `hrSafetyWarningsEnabled` (**default true**, listed last, with copy explaining why leaving it on is recommended). Preference keys `trainer_hr_callouts` and `trainer_hr_safety`. `hrSafetyWarningsEnabled == false` must still be honoured — the user may switch it off — but the setting is presented as the one to leave alone.

**Phrases** — add to the Steady pack and `phraseResolvers`, and **add every new key to the persona-pack test loops**:

```json
  "coachSteadyZone": "Zone {zoneNumber} — {effortLabel}.",
  "coachSteadyAboveCap1": "Your heart rate is above your maximum. Ease off and bring it down.",
  "coachSteadyAboveCap2": "Still above your maximum. Slow down, breathe.",
  "coachSteadyBackBelowCap": "Good — you're back under your maximum.",
```

Calm and directive, never alarming. `coachSteadyAboveCap*` must never suggest continuing.

**Sequencing with the existing alert (decision 1):** in `heart_rate_panel_screen.dart`, the alert keeps firing exactly as it does today. The coach's warning must land *after* it, not with it. Implement by having the HR event source delay the first `HeartRateAboveCap` emission by the alert's duration (~1.5 s) when `maxHrAlertProvider.soundEnabled` is true and the panel is mounted. Do not suppress the alert — that is the opposite of the #97 fix here, because the chime is the faster signal.

- [ ] **Step 1: Settings + phrases + resolver, TDD as in phase 1.**
- [ ] **Step 2: Bridge passes `hrCalloutsEnabled` and `cautionMode` into `onEvent`;** read `cautionModeProvider` for the latter. Cap warnings pass through when `hrSafetyWarningsEnabled` is true.
- [ ] **Step 3: Mount `hrEventSourceProvider`** beside `coachBridgeProvider` in the router shell, disposed the same way. **Verify exactly one instance exists** — this is the defect that shipped in phase 1 (`Provider.family` is not `autoDispose`), so write the test that would catch a duplicate.
- [ ] **Step 4: Integration test** — pump readings through a fake HR service into a real container with `SilentSpeechService`, and assert the full path: zone change after dwell speaks; cap crossing speaks a safety line; encouragement goes silent above cap and returns below it.
- [ ] **Step 5: Test the gap closure from decision 2** — with the HR panel *not* mounted, a cap crossing still produces a spoken warning. This is the user-visible benefit of the issue and it must not regress.
- [ ] **Step 6:** `flutter gen-l10n`, full suite, analyse, format, commit.

---

### Task 5: Device verification (Polar H9 + Galaxy S9+)

Not automatable. Phase 1 shipped a defect that every test and six reviews missed because it lived in a shared platform resource; this task exists so that does not repeat.

- [ ] **Step 1:** Build and install on the S9+ (`flutter run -d <id> --debug --flavor dev`). Pair the Polar H9.
- [ ] **Step 2:** Confirm zone callouts fire on real readings, and that boundary flicker does **not** produce repeated announcements — wear the strap through a zone boundary deliberately.
- [ ] **Step 3:** Provoke a cap crossing (lower the clinician cap in the health profile to just above resting HR to make this safe and repeatable — do **not** ask anyone to exercise to their real maximum). Confirm the alert fires first and the coach's line follows it intact, not clipped.
- [ ] **Step 4:** Capture `adb logcat | grep MediaFocusControl` across the crossing. Success: the coach's `req=3` request, no `propagateFocusLossFromGain` against it while it holds focus, and a clean `abandonAudioFocus`. This is the same measurement that found and verified #97.
- [ ] **Step 5:** Confirm the coach warns with the HR panel closed (decision 2's gap).
- [ ] **Step 6:** Record all findings on #91 — including anything that fails.

---

## Verification checklist

- [ ] `flutter test` green; `dart analyze` zero issues; `dart format` clean
- [ ] `coaching_engine.dart` coverage ≥80%
- [ ] Every new phrase key has a resolver entry AND appears in the persona-pack test loops
- [ ] Encouragement provably silent above cap, in caution mode, and in zone 5
- [ ] Cap warnings survive `hrCalloutsEnabled == false`
- [ ] Exactly one `HrEventSource` instance, with a test proving it
- [ ] Device matrix recorded on #91
- [ ] With no entitlement, nothing changes: no HR subscription, no events, no audio

## Out of scope

Hype and Sergeant personas and the quote bank are #99. Exercise auto-detection is #92. Background operation is #93.
