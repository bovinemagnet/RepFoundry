# Virtual Personal Trainer — Phases 0 & 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the paid Virtual Personal Trainer ("Coach") v1 — an entitlement-gated audio companion that speaks encouragement, rest-timer countdowns, and milestone celebrations through the user's headphones during strength workouts.

**Architecture:** Existing controllers fire typed `TrainerEvent`s onto a Riverpod stream. A pure-Dart `CoachingEngine` decides *whether and what* to say, applying priority, cooldown, quota, and variety rules, returning a `CoachingCue` that names an ARB phrase key rather than literal text. A presentation-layer bridge resolves the key to a localised string and hands it to a `SpeechService`, implemented over `flutter_tts` with audio ducking. All trainer behaviour sits behind a single `EntitlementService` seam so real store billing can be swapped in later.

**Tech Stack:** Flutter, Riverpod (`Notifier`/`Provider`/`StreamProvider`), `flutter_tts`, `shared_preferences`, `flutter_test` + `mockito`, `gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-08-01-virtual-personal-trainer-design.md`
**Issues:** #86 (phase 0), #87, #88, #89, #90 (phase 1), tracked by epic #94.

## Global Constraints

- Use `gradle21w` in place of `./gradlew`. Use `python3` in place of `python`.
- **British spelling** in all code, comments, strings, and commit messages (e.g. "personalised", "behaviour", "colour"). Exception: Flutter framework API names such as `Color` keep their spelling.
- Author is **Paul Snow**. No AI-assistant references in code, comments, commit messages, issues, or PRs.
- Domain and application layers are **pure Dart** — no `package:flutter` imports, no `dart:ui`.
- All user-facing strings live in `lib/l10n/app_en.arb`; access via `S.of(context)!`. Run `flutter gen-l10n` after editing the ARB and commit the generated output.
- Widget tests must set `localizationsDelegates: S.localizationsDelegates` and `supportedLocales: S.supportedLocales` on their `MaterialApp`.
- Lints are strict: `always_declare_return_types`, `prefer_const_constructors`, `prefer_final_fields`, `prefer_final_locals`. `dart analyze` must report zero issues.
- `dart format --set-exit-if-changed .` must pass before every commit.
- Coverage targets: ≥80% domain/application, ≥60% presentation.
- Trainer speech is **best-effort**: every TTS failure is caught and logged, never surfaced into the workout flow or shown as an error to the user.
- **Content language rules** for every spoken phrase: never urge load increases, never say "push through pain", no ego-lifting, no body-shaming, no guilt framing. Praise completion and consistency, never intensity escalation.
- Branch per task off `main`; commit at the end of every task.

---

### Task 1: Entitlement scaffolding (#86)

The paid-feature seam. No trainer behaviour yet.

**Files:**
- Create: `lib/core/entitlements/entitlement.dart`
- Create: `lib/core/entitlements/entitlement_service.dart`
- Create: `lib/core/entitlements/entitlement_provider.dart`
- Test: `test/core/entitlements/entitlement_service_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum Entitlement { virtualTrainer }`
  - `abstract class EntitlementService { bool has(Entitlement entitlement); }`
  - `class LocalEntitlementService implements EntitlementService` — constructor `LocalEntitlementService(Set<Entitlement> unlocked)`
  - `final entitlementServiceProvider = Provider<EntitlementService>(...)`
  - `final unlockedEntitlementsProvider = NotifierProvider<UnlockedEntitlementsNotifier, Set<Entitlement>>(...)` with `Future<void> toggle(Entitlement)`

- [ ] **Step 1: Write the failing test**

Create `test/core/entitlements/entitlement_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';

void main() {
  group('LocalEntitlementService', () {
    test('reports an unlocked entitlement as held', () {
      final service = LocalEntitlementService({Entitlement.virtualTrainer});

      expect(service.has(Entitlement.virtualTrainer), isTrue);
    });

    test('reports a locked entitlement as not held', () {
      final service = LocalEntitlementService(const {});

      expect(service.has(Entitlement.virtualTrainer), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/entitlements/entitlement_service_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:rep_foundry/core/entitlements/entitlement.dart'`.

- [ ] **Step 3: Write minimal implementation**

Create `lib/core/entitlements/entitlement.dart`:

```dart
/// Paid capabilities that can be unlocked in the app.
enum Entitlement {
  /// The Virtual Personal Trainer audio companion.
  virtualTrainer,
}
```

Create `lib/core/entitlements/entitlement_service.dart`:

```dart
import 'entitlement.dart';

/// The single seam every paid feature checks.
///
/// Feature code must never read a raw unlock flag: it asks this service.
/// Swapping [LocalEntitlementService] for a store-billing implementation
/// later then touches one provider rather than every call site.
abstract class EntitlementService {
  bool has(Entitlement entitlement);
}

/// Entitlements held on this device only, with no store involvement.
class LocalEntitlementService implements EntitlementService {
  const LocalEntitlementService(this._unlocked);

  final Set<Entitlement> _unlocked;

  @override
  bool has(Entitlement entitlement) => _unlocked.contains(entitlement);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/entitlements/entitlement_service_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Write the failing provider test**

Append to the same test file, inside `main()`:

```dart
  group('UnlockedEntitlementsNotifier', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts with nothing unlocked', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(unlockedEntitlementsProvider), isEmpty);
      expect(
        container.read(entitlementServiceProvider).has(Entitlement.virtualTrainer),
        isFalse,
      );
    });

    test('toggle unlocks, persists, and reloads', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(unlockedEntitlementsProvider.notifier)
          .toggle(Entitlement.virtualTrainer);

      expect(
        container.read(entitlementServiceProvider).has(Entitlement.virtualTrainer),
        isTrue,
      );

      final reloaded = ProviderContainer();
      addTearDown(reloaded.dispose);
      await reloaded.read(unlockedEntitlementsProvider.notifier).reload();

      expect(reloaded.read(unlockedEntitlementsProvider),
          contains(Entitlement.virtualTrainer));
    });
  });
```

Add these imports to the top of the test file:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/core/entitlements/entitlement_service_test.dart`
Expected: FAIL — `entitlement_provider.dart` does not exist.

- [ ] **Step 7: Implement the provider**

Create `lib/core/entitlements/entitlement_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'entitlement.dart';
import 'entitlement_service.dart';

const String _prefsKey = 'unlocked_entitlements';

/// The entitlements unlocked on this device.
///
/// Loading is asynchronous, so the initial state is empty and widens once
/// preferences arrive. Features must therefore react to this provider rather
/// than reading it once at start-up.
class UnlockedEntitlementsNotifier extends Notifier<Set<Entitlement>> {
  @override
  Set<Entitlement> build() {
    Future.microtask(reload);
    return const {};
  }

  Future<void> reload() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(_prefsKey) ?? const <String>[];
    state = names
        .map((name) => Entitlement.values.where((e) => e.name == name).firstOrNull)
        .whereType<Entitlement>()
        .toSet();
  }

  Future<void> toggle(Entitlement entitlement) async {
    final next = Set<Entitlement>.from(state);
    if (!next.remove(entitlement)) next.add(entitlement);
    state = next;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      next.map((e) => e.name).toList(),
    );
  }
}

final unlockedEntitlementsProvider =
    NotifierProvider<UnlockedEntitlementsNotifier, Set<Entitlement>>(
  UnlockedEntitlementsNotifier.new,
);

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return LocalEntitlementService(ref.watch(unlockedEntitlementsProvider));
});
```

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/core/entitlements/entitlement_service_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 9: Add the beta unlock toggle to the About screen**

In `lib/features/settings/presentation/screens/about_screen.dart`, add a `SwitchListTile` in the existing list body. Match the file's surrounding widget style:

```dart
Consumer(
  builder: (context, ref, _) {
    final unlocked = ref.watch(unlockedEntitlementsProvider);
    return SwitchListTile(
      title: Text(s.betaUnlockVirtualTrainer),
      subtitle: Text(s.betaUnlockVirtualTrainerSubtitle),
      value: unlocked.contains(Entitlement.virtualTrainer),
      onChanged: (_) => ref
          .read(unlockedEntitlementsProvider.notifier)
          .toggle(Entitlement.virtualTrainer),
    );
  },
),
```

Add to `lib/l10n/app_en.arb`:

```json
  "betaUnlockVirtualTrainer": "Unlock Virtual Trainer (beta)",
  "betaUnlockVirtualTrainerSubtitle": "Enables the audio coaching companion while it is in beta.",
```

Run `flutter gen-l10n`.

- [ ] **Step 10: Verify the whole suite and analysis**

Run: `flutter test && dart analyze && dart format --set-exit-if-changed .`
Expected: all tests pass, zero analysis issues, no formatting changes.

- [ ] **Step 11: Commit**

```bash
git checkout -b feat/86-entitlement-scaffolding
git add lib/core/entitlements lib/features/settings/presentation/screens/about_screen.dart lib/l10n test/core/entitlements
git commit -m "feat: entitlement seam for paid features with beta unlock toggle

Adds EntitlementService as the single gate every paid feature checks,
backed by a device-local implementation persisted in SharedPreferences.
A beta toggle on the About screen unlocks the Virtual Trainer while
store billing remains future work.

Refs #86"
```

---

### Task 2: Trainer domain model (#87, part 1)

Pure-Dart events, cues, and persona abstraction. No engine logic yet.

**Files:**
- Create: `lib/features/trainer/domain/trainer_event.dart`
- Create: `lib/features/trainer/domain/coaching_cue.dart`
- Create: `lib/features/trainer/domain/persona.dart`
- Test: `test/features/trainer/domain/trainer_event_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `sealed class TrainerEvent` with subclasses `WorkoutStarted`, `SetLogged({required int setNumber, required bool isPersonalRecord})`, `RestStarted({required Duration duration})`, `RestCountdown({required int secondsLeft})`, `RestFinished`, `WorkoutFinished({required int totalSets})`
  - `TrainerEventKind get kind` on every event; `enum TrainerEventKind { workoutStarted, setLogged, personalRecord, restStarted, restCountdown, restFinished, workoutFinished, quote }`
  - `enum SpeechPriority { encouragement, milestone, countdown, safety }` — ordinal order is deliberate: later values pre-empt earlier ones.
  - `class CoachingCue { const CoachingCue({required this.phraseKey, required this.priority, this.args = const {}}); final String phraseKey; final SpeechPriority priority; final Map<String, Object> args; }`
  - `class Persona { const Persona({required this.id, required this.phrasesByKind}); final String id; final Map<TrainerEventKind, List<String>> phrasesByKind; }` where each list holds **ARB phrase keys**, not literal text.

- [ ] **Step 1: Write the failing test**

Create `test/features/trainer/domain/trainer_event_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';
import 'package:rep_foundry/features/trainer/domain/persona.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';

void main() {
  test('each event reports its kind', () {
    expect(const WorkoutStarted().kind, TrainerEventKind.workoutStarted);
    expect(
      const SetLogged(setNumber: 3, isPersonalRecord: false).kind,
      TrainerEventKind.setLogged,
    );
    expect(
      const SetLogged(setNumber: 3, isPersonalRecord: true).kind,
      TrainerEventKind.personalRecord,
    );
    expect(const RestCountdown(secondsLeft: 3).kind,
        TrainerEventKind.restCountdown);
  });

  test('speech priority orders safety above everything else', () {
    expect(SpeechPriority.safety.index,
        greaterThan(SpeechPriority.countdown.index));
    expect(SpeechPriority.countdown.index,
        greaterThan(SpeechPriority.milestone.index));
    expect(SpeechPriority.milestone.index,
        greaterThan(SpeechPriority.encouragement.index));
  });

  test('a persona exposes phrase keys per event kind', () {
    const persona = Persona(
      id: 'steady',
      phrasesByKind: {
        TrainerEventKind.setLogged: ['coachSteadySetLogged1'],
      },
    );

    expect(persona.phrasesByKind[TrainerEventKind.setLogged],
        contains('coachSteadySetLogged1'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/trainer/domain/trainer_event_test.dart`
Expected: FAIL — the three domain files do not exist.

- [ ] **Step 3: Implement the domain files**

Create `lib/features/trainer/domain/trainer_event.dart`:

```dart
/// The categories of moment the coach can speak to.
///
/// A personal record is its own kind rather than a flag so personas can hold
/// a distinct phrase bank for it.
enum TrainerEventKind {
  workoutStarted,
  setLogged,
  personalRecord,
  restStarted,
  restCountdown,
  restFinished,
  workoutFinished,
  quote,
}

/// Something that happened in the workout that the coach may react to.
sealed class TrainerEvent {
  const TrainerEvent();

  TrainerEventKind get kind;
}

class WorkoutStarted extends TrainerEvent {
  const WorkoutStarted();

  @override
  TrainerEventKind get kind => TrainerEventKind.workoutStarted;
}

class SetLogged extends TrainerEvent {
  const SetLogged({required this.setNumber, required this.isPersonalRecord});

  final int setNumber;
  final bool isPersonalRecord;

  @override
  TrainerEventKind get kind => isPersonalRecord
      ? TrainerEventKind.personalRecord
      : TrainerEventKind.setLogged;
}

class RestStarted extends TrainerEvent {
  const RestStarted({required this.duration});

  final Duration duration;

  @override
  TrainerEventKind get kind => TrainerEventKind.restStarted;
}

class RestCountdown extends TrainerEvent {
  const RestCountdown({required this.secondsLeft});

  final int secondsLeft;

  @override
  TrainerEventKind get kind => TrainerEventKind.restCountdown;
}

class RestFinished extends TrainerEvent {
  const RestFinished();

  @override
  TrainerEventKind get kind => TrainerEventKind.restFinished;
}

class WorkoutFinished extends TrainerEvent {
  const WorkoutFinished({required this.totalSets});

  final int totalSets;

  @override
  TrainerEventKind get kind => TrainerEventKind.workoutFinished;
}
```

Create `lib/features/trainer/domain/coaching_cue.dart`:

```dart
/// How urgently a cue must be heard.
///
/// Declaration order matters: a cue pre-empts any cue with a lower index, so
/// safety warnings interrupt countdowns, which interrupt encouragement.
enum SpeechPriority {
  encouragement,
  milestone,
  countdown,
  safety,
}

/// A decision to say something.
///
/// Carries an ARB phrase key rather than literal text so the coaching engine
/// stays pure Dart and the presentation layer localises at the last moment.
class CoachingCue {
  const CoachingCue({
    required this.phraseKey,
    required this.priority,
    this.args = const {},
  });

  final String phraseKey;
  final SpeechPriority priority;
  final Map<String, Object> args;
}
```

Create `lib/features/trainer/domain/persona.dart`:

```dart
import 'trainer_event.dart';

/// A named coaching tone: the bank of phrase keys it draws on per event kind.
class Persona {
  const Persona({required this.id, required this.phrasesByKind});

  final String id;

  /// ARB phrase keys, never literal text.
  final Map<TrainerEventKind, List<String>> phrasesByKind;

  List<String> phrasesFor(TrainerEventKind kind) =>
      phrasesByKind[kind] ?? const [];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/trainer/domain/trainer_event_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Confirm layer purity**

Run: `grep -rn "package:flutter" lib/features/trainer/domain/`
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git checkout -b feat/87-trainer-domain
git add lib/features/trainer/domain test/features/trainer/domain
git commit -m "feat: trainer domain model for coaching events and cues

Sealed TrainerEvent hierarchy, SpeechPriority ordering, and a Persona
holding ARB phrase keys per event kind. Pure Dart with no Flutter
dependency so the coaching engine stays unit-testable without audio.

Refs #87"
```

---

### Task 3: Coaching engine (#87, part 2)

The rules that decide whether and what to say. Deterministic: time and randomness are injected.

**Files:**
- Create: `lib/features/trainer/application/coaching_engine.dart`
- Test: `test/features/trainer/application/coaching_engine_test.dart`

**Interfaces:**
- Consumes: `TrainerEvent`, `TrainerEventKind`, `CoachingCue`, `SpeechPriority`, `Persona` from Task 2.
- Produces:
  - `class CoachingEngine` — constructor `CoachingEngine({required Persona persona, Random? random, Duration encouragementCooldown = const Duration(seconds: 20), int encouragementEverySets = 2})`
  - `CoachingCue? onEvent(TrainerEvent event, {required DateTime now})` — returns null when the coach should stay quiet
  - `void reset()` — clears per-session state (spoken phrases, last-spoken time, set counter)

- [ ] **Step 1: Write the failing tests**

Create `test/features/trainer/application/coaching_engine_test.dart`:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/application/coaching_engine.dart';
import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';
import 'package:rep_foundry/features/trainer/domain/persona.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';

const _testPersona = Persona(
  id: 'test',
  phrasesByKind: {
    TrainerEventKind.workoutStarted: ['start1', 'start2', 'start3'],
    TrainerEventKind.setLogged: ['set1', 'set2', 'set3'],
    TrainerEventKind.personalRecord: ['pr1', 'pr2', 'pr3'],
    TrainerEventKind.restCountdown: ['count1'],
    TrainerEventKind.restFinished: ['go1', 'go2', 'go3'],
    TrainerEventKind.workoutFinished: ['done1', 'done2', 'done3'],
  },
);

CoachingEngine _engine({
  int encouragementEverySets = 2,
  Duration cooldown = const Duration(seconds: 20),
}) =>
    CoachingEngine(
      persona: _testPersona,
      random: Random(1),
      encouragementCooldown: cooldown,
      encouragementEverySets: encouragementEverySets,
    );

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);

  group('countdown', () {
    test('always speaks, ignoring the encouragement cooldown', () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(
        const RestCountdown(secondsLeft: 3),
        now: t0.add(const Duration(seconds: 1)),
      );

      expect(cue, isNotNull);
      expect(cue!.priority, SpeechPriority.countdown);
      expect(cue.args['secondsLeft'], 3);
    });
  });

  group('encouragement quota', () {
    test('stays quiet on the first set and speaks on the second', () {
      final engine = _engine(encouragementEverySets: 2, cooldown: Duration.zero);

      final first = engine.onEvent(
        const SetLogged(setNumber: 1, isPersonalRecord: false),
        now: t0,
      );
      final second = engine.onEvent(
        const SetLogged(setNumber: 2, isPersonalRecord: false),
        now: t0.add(const Duration(minutes: 1)),
      );

      expect(first, isNull);
      expect(second, isNotNull);
    });
  });

  group('cooldown', () {
    test('suppresses encouragement inside the cooldown window', () {
      final engine = _engine(encouragementEverySets: 1);

      final first = engine.onEvent(
        const SetLogged(setNumber: 1, isPersonalRecord: false),
        now: t0,
      );
      final tooSoon = engine.onEvent(
        const SetLogged(setNumber: 2, isPersonalRecord: false),
        now: t0.add(const Duration(seconds: 5)),
      );
      final later = engine.onEvent(
        const SetLogged(setNumber: 3, isPersonalRecord: false),
        now: t0.add(const Duration(seconds: 30)),
      );

      expect(first, isNotNull);
      expect(tooSoon, isNull);
      expect(later, isNotNull);
    });

    test('a personal record is a milestone and ignores the cooldown', () {
      final engine = _engine(encouragementEverySets: 1);
      engine.onEvent(const SetLogged(setNumber: 1, isPersonalRecord: false),
          now: t0);

      final pr = engine.onEvent(
        const SetLogged(setNumber: 2, isPersonalRecord: true),
        now: t0.add(const Duration(seconds: 2)),
      );

      expect(pr, isNotNull);
      expect(pr!.priority, SpeechPriority.milestone);
      expect(pr.phraseKey, startsWith('pr'));
    });
  });

  group('variety', () {
    test('never repeats a phrase within a session', () {
      final engine = _engine(encouragementEverySets: 1, cooldown: Duration.zero);
      final seen = <String>{};

      for (var i = 1; i <= 3; i++) {
        final cue = engine.onEvent(
          const SetLogged(setNumber: 1, isPersonalRecord: false),
          now: t0.add(Duration(minutes: i)),
        );
        expect(cue, isNotNull);
        expect(seen.add(cue!.phraseKey), isTrue,
            reason: 'phrase ${cue.phraseKey} was repeated');
      }
    });

    test('recycles the bank once every phrase has been used', () {
      final engine = _engine(encouragementEverySets: 1, cooldown: Duration.zero);

      for (var i = 1; i <= 4; i++) {
        final cue = engine.onEvent(
          const SetLogged(setNumber: 1, isPersonalRecord: false),
          now: t0.add(Duration(minutes: i)),
        );
        expect(cue, isNotNull, reason: 'engine fell silent on call $i');
      }
    });

    test('reset clears session state', () {
      final engine = _engine(encouragementEverySets: 1, cooldown: Duration.zero);
      final first = engine.onEvent(
        const SetLogged(setNumber: 1, isPersonalRecord: false),
        now: t0,
      );

      engine.reset();

      final afterReset = engine.onEvent(
        const SetLogged(setNumber: 1, isPersonalRecord: false),
        now: t0.add(const Duration(seconds: 1)),
      );

      expect(afterReset, isNotNull);
      expect(afterReset!.phraseKey, first!.phraseKey,
          reason: 'a reset engine with a seeded Random repeats its first pick');
    });
  });

  group('empty banks', () {
    test('stays silent when the persona has no phrases for a kind', () {
      const bare = Persona(id: 'bare', phrasesByKind: {});
      final engine = CoachingEngine(persona: bare, random: Random(1));

      expect(engine.onEvent(const WorkoutStarted(), now: t0), isNull);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/trainer/application/coaching_engine_test.dart`
Expected: FAIL — `coaching_engine.dart` does not exist.

- [ ] **Step 3: Implement the engine**

Create `lib/features/trainer/application/coaching_engine.dart`:

```dart
import 'dart:math';

import '../domain/coaching_cue.dart';
import '../domain/persona.dart';
import '../domain/trainer_event.dart';

/// Decides whether and what the coach says in response to workout events.
///
/// Pure Dart and deterministic: the caller supplies the clock and the random
/// source, so every rule below is directly testable without audio or timers.
class CoachingEngine {
  CoachingEngine({
    required Persona persona,
    Random? random,
    this.encouragementCooldown = const Duration(seconds: 20),
    this.encouragementEverySets = 2,
  })  : _persona = persona,
        _random = random ?? Random();

  final Persona _persona;
  final Random _random;

  /// Minimum quiet period between encouragement cues. Countdown, milestone,
  /// and safety cues are exempt — constant chatter is the commonest complaint
  /// about audio coaching, but a missed countdown makes the feature useless.
  final Duration encouragementCooldown;

  /// Encourage on every Nth logged set rather than every one.
  final int encouragementEverySets;

  final Set<String> _spokenPhrases = {};
  DateTime? _lastSpokenAt;
  int _setsSinceEncouragement = 0;

  /// Clears per-session state. Call when a workout starts or finishes.
  void reset() {
    _spokenPhrases.clear();
    _lastSpokenAt = null;
    _setsSinceEncouragement = 0;
  }

  CoachingCue? onEvent(TrainerEvent event, {required DateTime now}) {
    return switch (event) {
      WorkoutStarted() => _speak(event.kind, SpeechPriority.milestone, now),
      WorkoutFinished(:final totalSets) => _speak(
          event.kind,
          SpeechPriority.milestone,
          now,
          args: {'totalSets': totalSets},
        ),
      SetLogged(isPersonalRecord: true) =>
        _speak(event.kind, SpeechPriority.milestone, now),
      SetLogged(isPersonalRecord: false) => _onSetLogged(now),
      RestCountdown(:final secondsLeft) => _speak(
          event.kind,
          SpeechPriority.countdown,
          now,
          args: {'secondsLeft': secondsLeft},
        ),
      RestFinished() => _speak(event.kind, SpeechPriority.countdown, now),
      RestStarted() => null,
    };
  }

  CoachingCue? _onSetLogged(DateTime now) {
    _setsSinceEncouragement++;
    if (_setsSinceEncouragement < encouragementEverySets) return null;

    final last = _lastSpokenAt;
    if (last != null && now.difference(last) < encouragementCooldown) {
      return null;
    }

    final cue = _speak(
      TrainerEventKind.setLogged,
      SpeechPriority.encouragement,
      now,
    );
    if (cue != null) _setsSinceEncouragement = 0;
    return cue;
  }

  CoachingCue? _speak(
    TrainerEventKind kind,
    SpeechPriority priority,
    DateTime now, {
    Map<String, Object> args = const {},
  }) {
    final phrase = _pickPhrase(kind);
    if (phrase == null) return null;

    _spokenPhrases.add(phrase);
    _lastSpokenAt = now;
    return CoachingCue(phraseKey: phrase, priority: priority, args: args);
  }

  /// Prefers phrases not yet heard this session; once the bank is exhausted it
  /// starts again rather than falling silent.
  String? _pickPhrase(TrainerEventKind kind) {
    final bank = _persona.phrasesFor(kind);
    if (bank.isEmpty) return null;

    final unheard = bank.where((p) => !_spokenPhrases.contains(p)).toList();
    if (unheard.isEmpty) {
      _spokenPhrases.removeAll(bank);
      return bank[_random.nextInt(bank.length)];
    }
    return unheard[_random.nextInt(unheard.length)];
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/trainer/application/coaching_engine_test.dart`
Expected: PASS (9 tests). If the `reset` test fails on phrase identity, the seeded `Random(1)` sequence differs — adjust that single assertion to `isNotNull` rather than weakening the reset behaviour.

- [ ] **Step 5: Check coverage of the application layer**

Run: `flutter test --coverage test/features/trainer/`
Expected: `coaching_engine.dart` at or above 80% line coverage. Add tests for any uncovered branch.

- [ ] **Step 6: Commit**

```bash
git add lib/features/trainer/application test/features/trainer/application
git commit -m "feat: coaching engine deciding when and what the coach says

Applies priority, cooldown, quota, and variety rules to trainer events,
returning phrase keys rather than text. Clock and randomness are injected
so every rule is deterministic under test.

Refs #87"
```

---

### Task 4: Speech service with audio ducking (#88)

Wrap on-device TTS behind the domain interface. This is the only task touching platform audio.

**Files:**
- Create: `lib/features/trainer/domain/speech_service.dart`
- Create: `lib/features/trainer/data/flutter_tts_speech_service.dart`
- Create: `test/features/trainer/data/silent_speech_service.dart` (test double, shared by later tasks)
- Test: `test/features/trainer/data/silent_speech_service_test.dart`
- Modify: `pubspec.yaml` (add `flutter_tts`)

**Interfaces:**
- Consumes: `SpeechPriority` from Task 2.
- Produces:
  - `abstract class SpeechService { Future<void> speak(String text, {SpeechPriority priority}); Future<void> stop(); Future<bool> isAvailable(); void dispose(); }`
  - `class FlutterTtsSpeechService implements SpeechService` — constructor `FlutterTtsSpeechService({FlutterTts? tts, double speechRate = 0.5})`
  - `class SilentSpeechService implements SpeechService` (test-only) exposing `List<String> spoken` and `int stopCount`

- [ ] **Step 1: Spike the ducking configuration**

Add `flutter_tts` to `pubspec.yaml` under `dependencies` (pin the current stable major, e.g. `flutter_tts: ^4.2.0` — check pub.dev and use the latest compatible release), then run `flutter pub get`.

Read the package's iOS `setIosAudioCategory` options and Android audio-focus options. Confirm whether `duckOthers` on iOS and `AndroidAudioFocusGainType.gainTransientMayDuck` on Android are both exposed. **Record the finding as a comment on issue #88.** If either is missing, add `audio_session` as a dependency and configure the session there instead — the interface below does not change either way.

- [ ] **Step 2: Write the failing test for the test double**

Create `test/features/trainer/data/silent_speech_service.dart`:

```dart
import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';
import 'package:rep_foundry/features/trainer/domain/speech_service.dart';

/// Records what would have been spoken so tests never touch platform audio.
class SilentSpeechService implements SpeechService {
  final List<String> spoken = [];
  int stopCount = 0;
  bool available = true;
  bool disposed = false;

  @override
  Future<void> speak(
    String text, {
    SpeechPriority priority = SpeechPriority.encouragement,
  }) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<bool> isAvailable() async => available;

  @override
  void dispose() {
    disposed = true;
  }
}
```

Create `test/features/trainer/data/silent_speech_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';

import 'silent_speech_service.dart';

void main() {
  test('records spoken text and stop calls', () async {
    final service = SilentSpeechService();

    await service.speak('Good set.', priority: SpeechPriority.encouragement);
    await service.stop();

    expect(service.spoken, ['Good set.']);
    expect(service.stopCount, 1);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/trainer/data/silent_speech_service_test.dart`
Expected: FAIL — `speech_service.dart` does not exist.

- [ ] **Step 4: Write the interface**

Create `lib/features/trainer/domain/speech_service.dart`:

```dart
import 'coaching_cue.dart';

/// Speaks coaching cues aloud.
///
/// Every implementation is best-effort: failures are swallowed so a missing or
/// broken speech engine can never interrupt a workout.
abstract class SpeechService {
  Future<void> speak(
    String text, {
    SpeechPriority priority = SpeechPriority.encouragement,
  });

  /// Stops any in-flight speech immediately.
  Future<void> stop();

  /// False when the device has no usable speech engine, which happens on some
  /// de-Googled Android builds.
  Future<bool> isAvailable();

  void dispose();
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/trainer/data/silent_speech_service_test.dart`
Expected: PASS (1 test).

- [ ] **Step 6: Implement the real service**

Create `lib/features/trainer/data/flutter_tts_speech_service.dart`:

```dart
import 'dart:developer' as developer;

import 'package:flutter_tts/flutter_tts.dart';

import '../domain/coaching_cue.dart';
import '../domain/speech_service.dart';

/// Speaks through the device's built-in text-to-speech engine, ducking other
/// audio so the coach is audible over the user's music without stopping it.
class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService({FlutterTts? tts, double speechRate = 0.5})
      : _tts = tts ?? FlutterTts(),
        _speechRate = speechRate;

  final FlutterTts _tts;
  final double _speechRate;

  bool _configured = false;
  SpeechPriority? _currentPriority;

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;

    await _tts.setSpeechRate(_speechRate);
    await _tts.awaitSpeakCompletion(true);
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.duckOthers,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
      IosTextToSpeechAudioMode.spokenAudio,
    );
    // Android ducks via transient audio focus; the plugin requests this when
    // the queue mode leaves existing playback in place.
    await _tts.setQueueMode(0);
  }

  @override
  Future<void> speak(
    String text, {
    SpeechPriority priority = SpeechPriority.encouragement,
  }) async {
    try {
      await _configure();

      // A higher-priority cue cuts off whatever is playing; an equal or lower
      // one waits its turn by being dropped, so cues never pile up.
      final current = _currentPriority;
      if (current != null) {
        if (priority.index <= current.index) return;
        await _tts.stop();
      }

      _currentPriority = priority;
      await _tts.speak(text);
    } catch (e) {
      developer.log('Trainer speech failed', name: 'trainer', error: e);
    } finally {
      _currentPriority = null;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      developer.log('Trainer speech stop failed', name: 'trainer', error: e);
    } finally {
      _currentPriority = null;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final languages = await _tts.getLanguages;
      return languages is List && languages.isNotEmpty;
    } catch (e) {
      developer.log('Trainer speech availability check failed',
          name: 'trainer', error: e);
      return false;
    }
  }

  @override
  void dispose() {
    unawaited(stop());
  }
}

void unawaited(Future<void> future) {}
```

Replace the trailing `unawaited` helper with an import of `dart:async` and its built-in `unawaited` if analysis prefers it — `dart analyze` will tell you.

- [ ] **Step 7: Write a failure-swallowing test**

Create `test/features/trainer/data/flutter_tts_speech_service_test.dart`. Generate a mock with mockito for `FlutterTts` following the existing mockito usage in `test/`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rep_foundry/features/trainer/data/flutter_tts_speech_service.dart';

import 'flutter_tts_speech_service_test.mocks.dart';

@GenerateMocks([FlutterTts])
void main() {
  test('swallows engine failures instead of throwing', () async {
    final tts = MockFlutterTts();
    when(tts.setSpeechRate(any)).thenThrow(Exception('no engine'));
    final service = FlutterTtsSpeechService(tts: tts);

    await expectLater(service.speak('hello'), completes);
  });

  test('reports unavailable when no languages are returned', () async {
    final tts = MockFlutterTts();
    when(tts.getLanguages).thenAnswer((_) async => <String>[]);
    final service = FlutterTtsSpeechService(tts: tts);

    expect(await service.isAvailable(), isFalse);
  });
}
```

Run: `dart run build_runner build --delete-conflicting-outputs` to generate the mocks.

- [ ] **Step 8: Run tests, analysis, and format**

Run: `flutter test && dart analyze && dart format --set-exit-if-changed .`
Expected: all pass, zero issues.

- [ ] **Step 9: Manual device verification**

On a physical Android device and an iOS device: start music in Spotify, run a scratch call to `FlutterTtsSpeechService().speak('Testing one two three')`, and confirm the music dips and restores rather than stopping. Note Bluetooth headphone latency. **Post the results as a comment on issue #88** — this is the acceptance criterion and cannot be automated.

- [ ] **Step 10: Commit**

```bash
git checkout -b feat/88-speech-service
git add pubspec.yaml pubspec.lock lib/features/trainer test/features/trainer/data
git commit -m "feat: text-to-speech service with audio ducking

Wraps flutter_tts behind a SpeechService interface, ducking other audio
so the coach is heard over music rather than stopping it. Engine failures
are logged and swallowed so speech can never interrupt a workout.

Refs #88"
```

---

### Task 5: Emit trainer events from the workout flow (#89)

Wire the existing controllers into the event bus. Every emission is fire-and-forget.

**Files:**
- Create: `lib/features/trainer/presentation/providers/trainer_event_bus.dart`
- Modify: `lib/features/workout/presentation/controllers/active_workout_controller.dart` (`startWorkout`, `logSet`, `finishWorkout`)
- Modify: `lib/features/workout/presentation/widgets/rest_timer_widget.dart` (`RestTimerNotifier.start`, its tick callback, and `stop`)
- Test: `test/features/trainer/presentation/trainer_event_bus_test.dart`
- Test: `test/features/workout/presentation/rest_timer_events_test.dart`

**Interfaces:**
- Consumes: `TrainerEvent` subclasses from Task 2; `entitlementServiceProvider` and `Entitlement` from Task 1.
- Produces:
  - `class TrainerEventBus { TrainerEventBus(this._isEntitled); Stream<TrainerEvent> get events; void emit(TrainerEvent event); void dispose(); }` — `emit` is a no-op when the entitlement check returns false, so call sites carry no gating logic.
  - `final trainerEventBusProvider = Provider<TrainerEventBus>(...)`

Call sites are always `ref.read(trainerEventBusProvider).emit(event);`.

- [ ] **Step 1: Write the failing bus test**

Create `test/features/trainer/presentation/trainer_event_bus_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';

class _AlwaysEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

class _NeverEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => false;
}

void main() {
  test('delivers emitted events to listeners when entitled', () async {
    final container = ProviderContainer(overrides: [
      entitlementServiceProvider.overrideWithValue(_AlwaysEntitled()),
    ]);
    addTearDown(container.dispose);

    final bus = container.read(trainerEventBusProvider);
    final received = <TrainerEvent>[];
    final sub = bus.events.listen(received.add);
    addTearDown(sub.cancel);

    bus.emit(const WorkoutStarted());
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    expect(received.single, isA<WorkoutStarted>());
  });

  test('emits nothing when the trainer is not entitled', () async {
    final container = ProviderContainer(overrides: [
      entitlementServiceProvider.overrideWithValue(_NeverEntitled()),
    ]);
    addTearDown(container.dispose);

    final bus = container.read(trainerEventBusProvider);
    final received = <TrainerEvent>[];
    final sub = bus.events.listen(received.add);
    addTearDown(sub.cancel);

    bus.emit(const WorkoutStarted());
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/trainer/presentation/trainer_event_bus_test.dart`
Expected: FAIL — `trainer_event_bus.dart` does not exist.

- [ ] **Step 3: Implement the bus**

Create `lib/features/trainer/presentation/providers/trainer_event_bus.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/entitlements/entitlement.dart';
import '../../../../core/entitlements/entitlement_provider.dart';
import '../../domain/trainer_event.dart';

/// Carries workout moments to the coach.
///
/// The entitlement check lives here rather than at each call site, so emitting
/// stays a single unconditional line everywhere in the workout code.
class TrainerEventBus {
  TrainerEventBus(this._isEntitled);

  final bool Function() _isEntitled;

  final StreamController<TrainerEvent> _controller =
      StreamController<TrainerEvent>.broadcast();

  Stream<TrainerEvent> get events => _controller.stream;

  void emit(TrainerEvent event) {
    if (_controller.isClosed) return;
    if (!_isEntitled()) return;
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

final trainerEventBusProvider = Provider<TrainerEventBus>((ref) {
  final bus = TrainerEventBus(
    () => ref.read(entitlementServiceProvider).has(Entitlement.virtualTrainer),
  );
  ref.onDispose(bus.dispose);
  return bus;
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/trainer/presentation/trainer_event_bus_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Write the failing rest-timer event test**

Create `test/features/workout/presentation/rest_timer_events_test.dart`:

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/entitlements/entitlement.dart';
import 'package:rep_foundry/core/entitlements/entitlement_provider.dart';
import 'package:rep_foundry/core/entitlements/entitlement_service.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/trainer_event_bus.dart';
import 'package:rep_foundry/features/workout/presentation/widgets/rest_timer_widget.dart';

class _AlwaysEntitled implements EntitlementService {
  @override
  bool has(Entitlement entitlement) => true;
}

void main() {
  test('emits countdown events for the final three seconds', () {
    fakeAsync((async) {
      final container = ProviderContainer(overrides: [
        entitlementServiceProvider.overrideWithValue(_AlwaysEntitled()),
      ]);
      addTearDown(container.dispose);

      final received = <TrainerEvent>[];
      container.read(trainerEventBusProvider).events.listen(received.add);

      container.read(restTimerProvider.notifier).start(5);
      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();

      final countdowns = received.whereType<RestCountdown>().toList();
      expect(countdowns.map((c) => c.secondsLeft), [3, 2, 1]);
      expect(received.whereType<RestStarted>(), hasLength(1));
      expect(received.whereType<RestFinished>(), hasLength(1));
    });
  });
}
```

Confirm `fake_async` is in `dev_dependencies`; add it if not.

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/features/workout/presentation/rest_timer_events_test.dart`
Expected: FAIL — no events received (the notifier does not emit yet).

- [ ] **Step 7: Emit from the rest timer**

In `lib/features/workout/presentation/widgets/rest_timer_widget.dart`, add the imports for `trainer_event_bus.dart` and `trainer_event.dart`, then modify `RestTimerNotifier`:

In `start(int seconds)`, immediately after `state = seconds;`:

```dart
    ref
        .read(trainerEventBusProvider)
        .emit(RestStarted(duration: Duration(seconds: seconds)));
```

Inside the `Timer.periodic` callback, in the `else` branch, after `state = state! - 1;`:

```dart
        final remaining = state!;
        if (remaining >= 1 && remaining <= 3) {
          ref
              .read(trainerEventBusProvider)
              .emit(RestCountdown(secondsLeft: remaining));
        }
```

In the branch where the timer runs out (after `_completedNaturally = true;`):

```dart
      ref.read(trainerEventBusProvider).emit(const RestFinished());
```

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/features/workout/presentation/rest_timer_events_test.dart`
Expected: PASS. If the countdown list is `[3, 2, 1]` but ordering differs, check the decrement happens before the emit.

- [ ] **Step 9: Emit from the active workout controller**

In `lib/features/workout/presentation/controllers/active_workout_controller.dart`, add the same two imports.

In `startWorkout()`, inside the `try` after the state assignment that sets the new active workout:

```dart
      ref.read(trainerEventBusProvider).emit(const WorkoutStarted());
```

In `logSet(...)`, immediately after the `state = state.copyWith(...)` calls in both the PR and non-PR branches — place a single emission after the `if/else` block so it runs in both cases:

```dart
      ref.read(trainerEventBusProvider).emit(
        SetLogged(
          setNumber: updated[exerciseId]!.length,
          isPersonalRecord: result.newPersonalRecords.isNotEmpty,
        ),
      );
```

In `finishWorkout()`, just before `state = const ActiveWorkoutState();`:

```dart
      ref.read(trainerEventBusProvider).emit(
        WorkoutFinished(
          totalSets: state.setsByExercise.values
              .fold<int>(0, (sum, sets) => sum + sets.length),
        ),
      );
```

- [ ] **Step 10: Write the controller emission test**

Add to `test/features/workout/presentation/rest_timer_events_test.dart` (or a sibling file following the existing active-workout test setup in `test/features/workout/`): a test that logs a set through `ActiveWorkoutController` with an entitled container and asserts one `SetLogged` event arrives with the expected `setNumber`, and a second test with an unentitled container asserting no events arrive. Reuse the existing fake repositories that the current `active_workout_controller` tests use — check `test/features/workout/` for the established container setup and copy it rather than inventing a new one.

- [ ] **Step 11: Verify nothing regressed**

Run: `flutter test && dart analyze && dart format --set-exit-if-changed .`
Expected: the full existing suite still passes unchanged — with no entitlement, behaviour is byte-for-byte what it was.

- [ ] **Step 12: Commit**

```bash
git checkout -b feat/89-trainer-events
git add lib/features/trainer lib/features/workout test/features
git commit -m "feat: emit trainer events from workout flow and rest timer

Workout start, logged sets with their personal-record flag, rest start,
the final three countdown seconds, rest end, and workout finish now reach
the trainer event bus. Emission is a no-op without the entitlement, so
behaviour is unchanged for everyone else.

Refs #89"
```

---

### Task 6: Trainer UI, disclaimer gate, and the Steady persona (#90)

The user-facing surface. Completing this ships v1.

**Files:**
- Create: `lib/features/trainer/data/persona_packs.dart`
- Create: `lib/features/trainer/presentation/providers/trainer_settings_provider.dart`
- Create: `lib/features/trainer/presentation/providers/coach_bridge.dart`
- Create: `lib/features/trainer/presentation/screens/trainer_settings_screen.dart`
- Create: `lib/features/trainer/presentation/widgets/trainer_disclaimer_sheet.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/app/router.dart` (add `/settings/trainer`)
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart` (entitlement-gated entry)
- Test: `test/features/trainer/data/persona_packs_test.dart`
- Test: `test/features/trainer/presentation/trainer_settings_screen_test.dart`

**Interfaces:**
- Consumes: `CoachingEngine` (Task 3), `SpeechService`/`SilentSpeechService` (Task 4), `trainerEventBusProvider` (Task 5), `entitlementServiceProvider` (Task 1).
- Produces:
  - `const Persona steadyPersona` in `persona_packs.dart`
  - `class TrainerSettings { final bool enabled; final bool countdownsEnabled; final bool encouragementEnabled; final double speechRate; final bool disclaimerAccepted; final String personaId; }` with `copyWith`
  - `final trainerSettingsProvider = NotifierProvider<TrainerSettingsNotifier, TrainerSettings>` exposing `Future<void> setEnabled(bool)`, `Future<void> setCountdowns(bool)`, `Future<void> setEncouragement(bool)`, `Future<void> setSpeechRate(double)`, `Future<void> acceptDisclaimer()`, `Future<void> revokeDisclaimer()`
  - `final coachBridgeProvider = Provider<void>(...)` — subscribes to the bus, runs the engine, resolves phrase keys, calls `SpeechService.speak`
  - `final speechServiceProvider = Provider<SpeechService>(...)` — overridden with `SilentSpeechService` in tests

- [ ] **Step 1: Write the failing persona pack test**

Create `test/features/trainer/data/persona_packs_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/data/persona_packs.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';

const _spokenKinds = [
  TrainerEventKind.workoutStarted,
  TrainerEventKind.setLogged,
  TrainerEventKind.personalRecord,
  TrainerEventKind.restCountdown,
  TrainerEventKind.restFinished,
  TrainerEventKind.workoutFinished,
];

void main() {
  test('steady persona has at least three phrases per spoken kind', () {
    for (final kind in _spokenKinds) {
      expect(
        steadyPersona.phrasesFor(kind).length,
        greaterThanOrEqualTo(3),
        reason: 'steady persona is thin on $kind',
      );
    }
  });

  test('phrase keys are unique across the pack', () {
    final all = _spokenKinds.expand(steadyPersona.phrasesFor).toList();

    expect(all.toSet().length, all.length, reason: 'duplicate phrase key');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/trainer/data/persona_packs_test.dart`
Expected: FAIL — `persona_packs.dart` does not exist.

- [ ] **Step 3: Write the Steady persona and its ARB strings**

Create `lib/features/trainer/data/persona_packs.dart`:

```dart
import '../domain/persona.dart';
import '../domain/trainer_event.dart';

/// Calm and measured. The only persona in v1; Hype and Sergeant follow.
///
/// Every key here must exist in `app_en.arb` and obey the content rules:
/// praise completion and consistency, never urge more load or pushing through
/// pain.
const Persona steadyPersona = Persona(
  id: 'steady',
  phrasesByKind: {
    TrainerEventKind.workoutStarted: [
      'coachSteadyStart1',
      'coachSteadyStart2',
      'coachSteadyStart3',
    ],
    TrainerEventKind.setLogged: [
      'coachSteadySet1',
      'coachSteadySet2',
      'coachSteadySet3',
      'coachSteadySet4',
    ],
    TrainerEventKind.personalRecord: [
      'coachSteadyPr1',
      'coachSteadyPr2',
      'coachSteadyPr3',
    ],
    TrainerEventKind.restCountdown: [
      'coachSteadyCountdown1',
      'coachSteadyCountdown2',
      'coachSteadyCountdown3',
    ],
    TrainerEventKind.restFinished: [
      'coachSteadyRestDone1',
      'coachSteadyRestDone2',
      'coachSteadyRestDone3',
    ],
    TrainerEventKind.workoutFinished: [
      'coachSteadyFinish1',
      'coachSteadyFinish2',
      'coachSteadyFinish3',
    ],
  },
);
```

Add to `lib/l10n/app_en.arb`:

```json
  "coachSteadyStart1": "Let's get to work. Take your time and move well.",
  "coachSteadyStart2": "Session started. Nice and steady.",
  "coachSteadyStart3": "Good to see you. Let's make this one count.",
  "coachSteadySet1": "Good set. Breathe, reset, go again when you're ready.",
  "coachSteadySet2": "That's logged. Nice control.",
  "coachSteadySet3": "Steady work. Keep that form.",
  "coachSteadySet4": "Well done. Take the rest you need.",
  "coachSteadyPr1": "That's a personal record. Excellent work.",
  "coachSteadyPr2": "New best. All that consistency is paying off.",
  "coachSteadyPr3": "Personal record. Take a moment — you earned it.",
  "coachSteadyCountdown1": "{secondsLeft}",
  "@coachSteadyCountdown1": {
    "placeholders": { "secondsLeft": { "type": "int" } }
  },
  "coachSteadyCountdown2": "{secondsLeft}…",
  "@coachSteadyCountdown2": {
    "placeholders": { "secondsLeft": { "type": "int" } }
  },
  "coachSteadyCountdown3": "{secondsLeft}.",
  "@coachSteadyCountdown3": {
    "placeholders": { "secondsLeft": { "type": "int" } }
  },
  "coachSteadyRestDone1": "Rest is up. Go when you're ready.",
  "coachSteadyRestDone2": "Time. Take your position.",
  "coachSteadyRestDone3": "That's your rest. Next set when you're set.",
  "coachSteadyFinish1": "Session complete. {totalSets} sets logged. Well done.",
  "@coachSteadyFinish1": {
    "placeholders": { "totalSets": { "type": "int" } }
  },
  "coachSteadyFinish2": "That's the work done — {totalSets} sets. Good session.",
  "@coachSteadyFinish2": {
    "placeholders": { "totalSets": { "type": "int" } }
  },
  "coachSteadyFinish3": "Finished. {totalSets} sets in the bank.",
  "@coachSteadyFinish3": {
    "placeholders": { "totalSets": { "type": "int" } }
  },
```

Run `flutter gen-l10n`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/trainer/data/persona_packs_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Write the settings provider**

Create `lib/features/trainer/presentation/providers/trainer_settings_provider.dart`. This mirrors the structure of `rest_timer_settings_provider.dart` — read that file first so the style matches:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainerSettings {
  const TrainerSettings({
    this.enabled = false,
    this.countdownsEnabled = true,
    this.encouragementEnabled = true,
    this.speechRate = 0.5,
    this.disclaimerAccepted = false,
    this.personaId = 'steady',
  });

  final bool enabled;
  final bool countdownsEnabled;
  final bool encouragementEnabled;
  final double speechRate;
  final bool disclaimerAccepted;
  final String personaId;

  TrainerSettings copyWith({
    bool? enabled,
    bool? countdownsEnabled,
    bool? encouragementEnabled,
    double? speechRate,
    bool? disclaimerAccepted,
    String? personaId,
  }) {
    return TrainerSettings(
      enabled: enabled ?? this.enabled,
      countdownsEnabled: countdownsEnabled ?? this.countdownsEnabled,
      encouragementEnabled: encouragementEnabled ?? this.encouragementEnabled,
      speechRate: speechRate ?? this.speechRate,
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
      personaId: personaId ?? this.personaId,
    );
  }
}

class TrainerSettingsNotifier extends Notifier<TrainerSettings> {
  @override
  TrainerSettings build() {
    Future.microtask(_load);
    return const TrainerSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = TrainerSettings(
      enabled: prefs.getBool('trainer_enabled') ?? false,
      countdownsEnabled: prefs.getBool('trainer_countdowns') ?? true,
      encouragementEnabled: prefs.getBool('trainer_encouragement') ?? true,
      speechRate: prefs.getDouble('trainer_speech_rate') ?? 0.5,
      disclaimerAccepted:
          prefs.getBool('trainer_disclaimer_accepted') ?? false,
      personaId: prefs.getString('trainer_persona') ?? 'steady',
    );
  }

  /// Enabling is refused until the safety notice has been accepted, so the
  /// gate cannot be bypassed by toggling the switch.
  Future<void> setEnabled(bool value) async {
    if (value && !state.disclaimerAccepted) return;
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_enabled', value);
  }

  Future<void> setCountdowns(bool value) async {
    state = state.copyWith(countdownsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_countdowns', value);
  }

  Future<void> setEncouragement(bool value) async {
    state = state.copyWith(encouragementEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_encouragement', value);
  }

  Future<void> setSpeechRate(double value) async {
    state = state.copyWith(speechRate: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('trainer_speech_rate', value);
  }

  Future<void> acceptDisclaimer() async {
    state = state.copyWith(disclaimerAccepted: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_disclaimer_accepted', true);
  }

  /// Revoking also silences the coach: consent and speech move together.
  Future<void> revokeDisclaimer() async {
    state = state.copyWith(disclaimerAccepted: false, enabled: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_disclaimer_accepted', false);
    await prefs.setBool('trainer_enabled', false);
  }
}

final trainerSettingsProvider =
    NotifierProvider<TrainerSettingsNotifier, TrainerSettings>(
  TrainerSettingsNotifier.new,
);
```

- [ ] **Step 6: Write the coach bridge**

Two files. First the phrase resolver, which is the only place ARB keys meet generated getters — create `lib/features/trainer/presentation/providers/phrase_resolver.dart`:

```dart
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// Turns a persona's phrase key into speakable text.
///
/// Kept as an explicit map rather than reflection so a missing entry is a
/// compile-time-adjacent failure caught by [phraseResolverKeys] in tests.
typedef PhraseBuilder = String Function(S s, Map<String, Object> args);

final Map<String, PhraseBuilder> phraseResolvers = {
  'coachSteadyStart1': (s, _) => s.coachSteadyStart1,
  'coachSteadyStart2': (s, _) => s.coachSteadyStart2,
  'coachSteadyStart3': (s, _) => s.coachSteadyStart3,
  'coachSteadySet1': (s, _) => s.coachSteadySet1,
  'coachSteadySet2': (s, _) => s.coachSteadySet2,
  'coachSteadySet3': (s, _) => s.coachSteadySet3,
  'coachSteadySet4': (s, _) => s.coachSteadySet4,
  'coachSteadyPr1': (s, _) => s.coachSteadyPr1,
  'coachSteadyPr2': (s, _) => s.coachSteadyPr2,
  'coachSteadyPr3': (s, _) => s.coachSteadyPr3,
  'coachSteadyCountdown1': (s, a) =>
      s.coachSteadyCountdown1(a['secondsLeft']! as int),
  'coachSteadyCountdown2': (s, a) =>
      s.coachSteadyCountdown2(a['secondsLeft']! as int),
  'coachSteadyCountdown3': (s, a) =>
      s.coachSteadyCountdown3(a['secondsLeft']! as int),
  'coachSteadyRestDone1': (s, _) => s.coachSteadyRestDone1,
  'coachSteadyRestDone2': (s, _) => s.coachSteadyRestDone2,
  'coachSteadyRestDone3': (s, _) => s.coachSteadyRestDone3,
  'coachSteadyFinish1': (s, a) => s.coachSteadyFinish1(a['totalSets']! as int),
  'coachSteadyFinish2': (s, a) => s.coachSteadyFinish2(a['totalSets']! as int),
  'coachSteadyFinish3': (s, a) => s.coachSteadyFinish3(a['totalSets']! as int),
};

String? resolvePhrase(S s, String key, Map<String, Object> args) {
  final builder = phraseResolvers[key];
  if (builder == null) return null;
  return builder(s, args);
}
```

Then create `lib/features/trainer/presentation/providers/coach_bridge.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/entitlements/entitlement.dart';
import '../../../../core/entitlements/entitlement_provider.dart';
import '../../application/coaching_engine.dart';
import '../../data/flutter_tts_speech_service.dart';
import '../../data/persona_packs.dart';
import '../../domain/coaching_cue.dart';
import '../../domain/speech_service.dart';
import '../../domain/trainer_event.dart';
import 'phrase_resolver.dart';
import 'trainer_event_bus.dart';
import 'trainer_settings_provider.dart';

final speechServiceProvider = Provider<SpeechService>((ref) {
  final rate = ref.watch(trainerSettingsProvider).speechRate;
  final service = FlutterTtsSpeechService(speechRate: rate);
  ref.onDispose(service.dispose);
  return service;
});

/// Connects the event bus to the engine to the voice.
///
/// Watch this from a widget mounted for the life of the app shell, passing the
/// localisations instance in, so phrase keys can be resolved without a
/// BuildContext reaching the engine.
class CoachBridge {
  CoachBridge(this._ref, this._strings) {
    _engine = CoachingEngine(persona: steadyPersona);
    _subscription = _ref.read(trainerEventBusProvider).events.listen(_onEvent);
  }

  final Ref _ref;
  final S _strings;

  late final CoachingEngine _engine;
  late final StreamSubscription<TrainerEvent> _subscription;

  void _onEvent(TrainerEvent event) {
    final settings = _ref.read(trainerSettingsProvider);
    if (!settings.enabled || !settings.disclaimerAccepted) return;
    if (!_ref
        .read(entitlementServiceProvider)
        .has(Entitlement.virtualTrainer)) {
      return;
    }

    if (event is WorkoutStarted) _engine.reset();

    final cue = _engine.onEvent(event, now: DateTime.now());
    if (cue != null && _allowedBySettings(cue, settings)) {
      final text = resolvePhrase(_strings, cue.phraseKey, cue.args);
      if (text != null) {
        unawaited(
          _ref.read(speechServiceProvider).speak(text, priority: cue.priority),
        );
      }
    }

    // Reset for the next session, but never cut off the sign-off line we just
    // started speaking.
    if (event is WorkoutFinished) {
      _engine.reset();
      if (cue == null) unawaited(_ref.read(speechServiceProvider).stop());
    }
  }

  bool _allowedBySettings(CoachingCue cue, TrainerSettings settings) {
    return switch (cue.priority) {
      SpeechPriority.countdown => settings.countdownsEnabled,
      SpeechPriority.encouragement => settings.encouragementEnabled,
      SpeechPriority.milestone || SpeechPriority.safety => true,
    };
  }

  void dispose() {
    unawaited(_subscription.cancel());
  }
}

/// Family keyed on the localisations instance so the bridge rebuilds if the
/// locale changes mid-session.
final coachBridgeProvider = Provider.family<CoachBridge, S>((ref, strings) {
  final bridge = CoachBridge(ref, strings);
  ref.onDispose(bridge.dispose);
  return bridge;
});
```

Mount it from the shell in `lib/app/router.dart`'s `ShellRoute` builder with a one-line `ref.watch(coachBridgeProvider(S.of(context)!));` inside a `Consumer`.

Then add a resolver-completeness test to `test/features/trainer/data/persona_packs_test.dart`:

```dart
  test('every phrase key in the steady persona has a resolver', () {
    for (final kind in _spokenKinds) {
      for (final key in steadyPersona.phrasesFor(kind)) {
        expect(phraseResolvers.containsKey(key), isTrue,
            reason: 'no resolver entry for $key');
      }
    }
  });
```

Import `package:rep_foundry/features/trainer/presentation/providers/phrase_resolver.dart` in that test file.

- [ ] **Step 7: Write the disclaimer sheet**

Create `lib/features/trainer/presentation/widgets/trainer_disclaimer_sheet.dart`. Read `lib/features/heart_rate/presentation/widgets/health_profile_onboarding.dart` first and match its sheet layout and narrow-phone handling — that file was recently fixed for 411dp devices, so follow its button placement rather than inventing new spacing.

```dart
import 'package:flutter/material.dart';

import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// Shows the safety notice. Resolves true only when the user accepts.
Future<bool?> showTrainerDisclaimer(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final s = S.of(context)!;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.trainerDisclaimerTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(s.trainerDisclaimerBody),
              const SizedBox(height: 24),
              // Stacked rather than side by side: at 411dp a two-button row
              // squeezes these labels onto three lines each.
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(s.trainerDisclaimerAccept),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(s.trainerDisclaimerDecline),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
```

Content (add each to the ARB):

```json
  "trainerDisclaimerTitle": "Before your coach speaks",
  "trainerDisclaimerBody": "The coach is a companion to help you stay on track — not a personal trainer, and not medical advice. It does not know your form, your injuries, or your limits. Stop exercising and seek medical help if you feel pain, dizziness, or chest discomfort.",
  "trainerDisclaimerAccept": "I understand",
  "trainerDisclaimerDecline": "Not now",
```

Accepting calls `trainerSettingsProvider.notifier.acceptDisclaimer()`. Declining leaves the trainer disabled. **The coach must not speak until this is accepted** — that rule lives in the bridge (step 6), not only in the UI.

- [ ] **Step 8: Write the settings screen**

Create `lib/features/trainer/presentation/screens/trainer_settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../providers/coach_bridge.dart';
import '../providers/trainer_settings_provider.dart';
import '../widgets/trainer_disclaimer_sheet.dart';

class TrainerSettingsScreen extends ConsumerWidget {
  const TrainerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final settings = ref.watch(trainerSettingsProvider);
    final notifier = ref.read(trainerSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(s.trainerSettingsTitle)),
      body: ListView(
        children: [
          FutureBuilder<bool>(
            future: ref.read(speechServiceProvider).isAvailable(),
            builder: (context, snapshot) {
              if (snapshot.data == false) {
                return ListTile(
                  leading: const Icon(Icons.volume_off),
                  title: Text(s.trainerVoiceUnavailable),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          SwitchListTile(
            title: Text(s.trainerEnable),
            subtitle: Text(s.trainerEnableSubtitle),
            value: settings.enabled,
            onChanged: (value) async {
              // Enabling without consent shows the notice instead; the notifier
              // refuses the change either way, so the gate cannot be skipped.
              if (value && !settings.disclaimerAccepted) {
                final accepted = await showTrainerDisclaimer(context);
                if (accepted != true) return;
                await notifier.acceptDisclaimer();
              }
              await notifier.setEnabled(value);
            },
          ),
          ListTile(
            title: Text(s.trainerPersona),
            subtitle: Text(
              '${s.trainerPersonaSteady} — ${s.trainerPersonaSteadyDescription}'
              '\n${s.trainerMoreVoicesComing}',
            ),
          ),
          ListTile(
            title: Text(s.trainerSpeechRate),
            subtitle: Slider(
              value: settings.speechRate,
              min: 0.25,
              max: 1.0,
              divisions: 15,
              onChanged: (value) => notifier.setSpeechRate(value),
            ),
            trailing: TextButton(
              onPressed: () =>
                  ref.read(speechServiceProvider).speak(s.trainerTestPhrase),
              child: Text(s.trainerTestVoice),
            ),
          ),
          SwitchListTile(
            title: Text(s.trainerCountdowns),
            value: settings.countdownsEnabled,
            onChanged: notifier.setCountdowns,
          ),
          SwitchListTile(
            title: Text(s.trainerEncouragement),
            value: settings.encouragementEnabled,
            onChanged: notifier.setEncouragement,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.trainerReviewDisclaimer),
            onTap: () => showTrainerDisclaimer(context),
          ),
        ],
      ),
    );
  }
}
```

ARB additions:

```json
  "trainerSettingsTitle": "Virtual Trainer",
  "trainerEnable": "Enable coach",
  "trainerEnableSubtitle": "Speaks encouragement and rest countdowns through your headphones.",
  "trainerPersona": "Coaching voice",
  "trainerPersonaSteady": "Steady",
  "trainerPersonaSteadyDescription": "Calm and measured",
  "trainerMoreVoicesComing": "More voices are on the way.",
  "trainerSpeechRate": "Speech rate",
  "trainerTestVoice": "Test voice",
  "trainerTestPhrase": "This is your coach. Good set — take your rest.",
  "trainerCountdowns": "Rest countdowns",
  "trainerEncouragement": "Encouragement",
  "trainerReviewDisclaimer": "Review safety notice",
  "trainerVoiceUnavailable": "No speech engine found on this device, so the coach cannot speak.",
```

Register `/settings/trainer` in `lib/app/router.dart` following the existing `/settings/notifications` route, and add the entitlement-gated entry to `settings_screen.dart` beside the other `context.push` tiles — visible and enabled only when `entitlementServiceProvider.has(Entitlement.virtualTrainer)`.

- [ ] **Step 9: Write the widget tests**

Create `test/features/trainer/presentation/trainer_settings_screen_test.dart`. Override `speechServiceProvider` with `SilentSpeechService` from Task 4. Cover:

1. The screen renders with the master switch off by default.
2. Turning the master switch on with no accepted disclaimer shows the disclaimer sheet and leaves `enabled` false.
3. Accepting the disclaimer then enabling leaves both `disclaimerAccepted` and `enabled` true.
4. "Test voice" adds exactly one entry to `SilentSpeechService.spoken`.
5. With the trainer unentitled, the Settings screen shows no trainer tile.

Every `MaterialApp` in these tests needs `localizationsDelegates: S.localizationsDelegates` and `supportedLocales: S.supportedLocales`. Seed `SharedPreferences.setMockInitialValues({})` in `setUp`. If a modal barrier swallows gestures, seed the provider state synchronously rather than awaiting the async load — the same trap documented for the HR panel tests.

- [ ] **Step 10: Run the full verification**

Run: `flutter test && dart analyze && dart format --set-exit-if-changed .`
Expected: all pass, zero analysis issues.

- [ ] **Step 11: Manual end-to-end check on a device**

With the beta entitlement unlocked: start a workout, log three sets, start a rest timer, and let it run out. Confirm the coach speaks at workout start, encourages on roughly every second set, counts down the final three seconds, and speaks at finish — with music ducking each time. Confirm turning the master switch off silences everything.

- [ ] **Step 12: Commit**

```bash
git checkout -b feat/90-trainer-ui
git add lib/features/trainer lib/features/settings lib/app/router.dart lib/l10n test/features/trainer
git commit -m "feat: virtual trainer settings, safety disclaimer, and Steady voice

Adds the trainer settings screen, the first-use safety notice that gates
all speech, and the Steady persona phrase bank. Wires the coaching engine
to the event bus so the coach speaks during strength workouts.

Refs #90"
```

---

## Verification checklist for the whole plan

Before closing issues #86–#90:

- [ ] `flutter test` — full suite green, no skipped trainer tests
- [ ] `dart analyze` — zero issues
- [ ] `dart format --set-exit-if-changed .` — clean
- [ ] Coverage: `coaching_engine.dart` ≥80%, trainer presentation ≥60%
- [ ] Device matrix posted on #88 (iOS + Android ducking with music playing)
- [ ] End-to-end device check posted on #90
- [ ] With no entitlement, the app behaves exactly as before — no trainer tile, no events, no audio
- [ ] Coach stays silent until the safety disclaimer is accepted
- [ ] Every phrase in the Steady pack obeys the content language rules

## Known limitation carried into phase 4

Speech stops when the app is backgrounded or the phone locks — the commonest gym posture. This is deliberate for v1 and is the entire subject of issue #93. Do not attempt background audio in these tasks.
