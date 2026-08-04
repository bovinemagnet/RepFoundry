# Coach Quote Bank Wiring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the 21 already-shipped public-domain quotes audible at workout start and after rests of two minutes or longer, behind their own settings toggle.

**Architecture:** The quote is **merged into the utterance it accompanies** rather than emitted as a separate cue. `FlutterTtsSpeechService.speak` drops any cue at equal or lower priority than what is already playing, and both quote moments are moments the coach is already speaking — so a separate quote cue would be silently dropped at both. `CoachingCue` gains an optional `quotePhraseKey`; `CoachBridge` resolves both keys and speaks them as one string. No new `TrainerEvent` class is needed.

**Tech Stack:** Flutter/Dart, Riverpod (`Notifier`, `Provider`, `Provider.family`), `flutter_test`, `gen-l10n` ARB localisation, SharedPreferences.

**Spec:** `docs/superpowers/specs/2026-08-04-quote-bank-wiring-design.md`

## Global Constraints

- **British spelling** in all comments, docs, and user-facing copy.
- **Author:** Paul Snow. No AI-tool references in code, comments, commits, issues, or PRs.
- **All user-facing text goes through ARB.** Never concatenate speakable text with a hardcoded separator — `app_en.arb` has ja/ko/zh siblings.
- **Run `flutter gen-l10n` after every `.arb` edit**, before running tests.
- **`dart analyze` must report zero issues**; CI enforces it. `dart format --set-exit-if-changed .` must pass.
- **Lints in force:** `always_declare_return_types`, `prefer_const_constructors`, `prefer_final_fields`, `prefer_final_locals`.
- **Two-minute rule has exactly one definition:** `CoachingEngine.longRestThreshold`. No layer carries its own copy.
- **Test command:** `flutter test <path>` for one file, `flutter test` for all.
- **Existing baseline:** all tests pass on `main`. Any red test you did not just write is a regression — stop and report it.
- **Branch:** `feat/102-speak-quotes`, already created, spec already committed.

---

### Task 1: `CoachingCue` carries an optional quote

**Files:**
- Modify: `lib/features/trainer/domain/coaching_cue.dart`
- Test: `test/features/trainer/domain/coaching_cue_test.dart` (create)

**Interfaces:**
- Consumes: nothing.
- Produces: `CoachingCue({required String phraseKey, required SpeechPriority priority, Map<String, Object> args = const {}, String? quotePhraseKey})`. Later tasks read `cue.quotePhraseKey`.

- [ ] **Step 1: Write the failing test**

Create `test/features/trainer/domain/coaching_cue_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';

void main() {
  group('CoachingCue.quotePhraseKey', () {
    test('defaults to null so existing cues are unchanged', () {
      const cue = CoachingCue(
        phraseKey: 'coachSteadyStart1',
        priority: SpeechPriority.milestone,
      );

      expect(cue.quotePhraseKey, isNull);
    });

    test('carries an attached quote key when supplied', () {
      const cue = CoachingCue(
        phraseKey: 'coachSteadyStart1',
        priority: SpeechPriority.milestone,
        quotePhraseKey: 'coachQuote3',
      );

      expect(cue.quotePhraseKey, 'coachQuote3');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/trainer/domain/coaching_cue_test.dart`
Expected: FAIL — compile error, `No named parameter with the name 'quotePhraseKey'`.

- [ ] **Step 3: Write minimal implementation**

In `lib/features/trainer/domain/coaching_cue.dart`, add the field to `CoachingCue`:

```dart
class CoachingCue {
  const CoachingCue({
    required this.phraseKey,
    required this.priority,
    this.args = const {},
    this.quotePhraseKey,
  });

  final String phraseKey;
  final SpeechPriority priority;
  final Map<String, Object> args;

  /// An inspirational quote to speak as part of the same utterance, or null.
  ///
  /// Merged into one `speak()` call rather than emitted as a second cue
  /// because `FlutterTtsSpeechService` drops any cue at equal or lower
  /// priority than what is already playing, and every moment a quote is
  /// wanted is a moment the coach is already speaking. A separate quote cue
  /// would be silently dropped at both.
  ///
  /// [phraseKey] stays non-null: a standalone quote is expressed by putting
  /// the quote key in [phraseKey] and leaving this null, so no consumer has
  /// to cope with an empty lead-in.
  final String? quotePhraseKey;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/trainer/domain/coaching_cue_test.dart`
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/trainer/domain/coaching_cue.dart test/features/trainer/domain/coaching_cue_test.dart
git commit -m "feat: CoachingCue can carry an attached quote key (#102)"
```

---

### Task 2: `RestFinished` carries the rest it ended

**Files:**
- Modify: `lib/features/trainer/domain/trainer_event.dart:63-68`
- Test: `test/features/trainer/domain/trainer_event_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `RestFinished({Duration? restDuration})`. Task 4 pattern-matches `RestFinished(:final restDuration)`; Task 7 constructs it with a real duration.

**Why optional:** thirteen existing constructions of `const RestFinished()` across `coaching_engine_test.dart`, `coach_bridge_test.dart` and `rest_timer_widget.dart` must keep compiling. `null` means "duration unknown" and is treated as a short rest, so a caller that does not know can never accidentally trigger a quote.

- [ ] **Step 1: Write the failing test**

Append to the existing `void main()` in `test/features/trainer/domain/trainer_event_test.dart`:

```dart
  group('RestFinished.restDuration', () {
    test('defaults to null so existing constructions are unchanged', () {
      const event = RestFinished();

      expect(event.restDuration, isNull);
      expect(event.kind, TrainerEventKind.restFinished);
    });

    test('carries the duration the rest actually ran for', () {
      const event = RestFinished(restDuration: Duration(minutes: 3));

      expect(event.restDuration, const Duration(minutes: 3));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/trainer/domain/trainer_event_test.dart`
Expected: FAIL — compile error, `The getter 'restDuration' isn't defined`.

- [ ] **Step 3: Write minimal implementation**

Replace `RestFinished` in `lib/features/trainer/domain/trainer_event.dart`:

```dart
/// A rest period ended.
///
/// [restDuration] is what the timer was set to run for, carried so the engine
/// can apply the "quote after rests of two minutes or longer" rule (spec §5)
/// without keeping its own memory of the matching [RestStarted] — which would
/// be wrong whenever a rest began before the coach was switched on.
///
/// Optional, and `null` means "not known", which is treated as a short rest.
/// A caller that cannot supply it therefore fails towards silence rather than
/// towards an unwanted quote.
class RestFinished extends TrainerEvent {
  const RestFinished({this.restDuration});

  final Duration? restDuration;

  @override
  TrainerEventKind get kind => TrainerEventKind.restFinished;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/trainer/domain/trainer_event_test.dart`
Expected: PASS, including the two new tests.

- [ ] **Step 5: Verify nothing else broke**

Run: `flutter test test/features/trainer/ && dart analyze lib test`
Expected: all PASS, analyzer clean. The thirteen `const RestFinished()` call sites still compile because the parameter is optional.

- [ ] **Step 6: Commit**

```bash
git add lib/features/trainer/domain/trainer_event.dart test/features/trainer/domain/trainer_event_test.dart
git commit -m "feat: RestFinished carries the duration the rest ran for (#102)"
```

---

### Task 3: `quotesEnabled` setting

**Files:**
- Modify: `lib/features/trainer/presentation/providers/trainer_settings_provider.dart`
- Test: `test/features/trainer/presentation/trainer_settings_provider_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `TrainerSettings.quotesEnabled` (`bool`, default `true`), `TrainerSettingsNotifier.setQuotes(bool)`, pref key `'trainer_quotes'`. Tasks 4, 5, 6 and 8 read `settings.quotesEnabled`.

- [ ] **Step 1: Write the failing test**

Add to `test/features/trainer/presentation/trainer_settings_provider_test.dart`, following the file's existing container/SharedPreferences setup:

```dart
  group('quotesEnabled', () {
    test('defaults to true — quotes are on unless the user says otherwise',
        () {
      expect(const TrainerSettings().quotesEnabled, isTrue);
    });

    test('setQuotes updates state and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(trainerSettingsProvider.notifier).setQuotes(false);

      expect(container.read(trainerSettingsProvider).quotesEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('trainer_quotes'), isFalse);
    });

    test('restores a persisted false on load', () async {
      SharedPreferences.setMockInitialValues({'trainer_quotes': false});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(trainerSettingsProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(trainerSettingsProvider).quotesEnabled, isFalse);
    });
  });
```

Match the imports already at the top of that file; add `package:shared_preferences/shared_preferences.dart` if it is not there.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/trainer/presentation/trainer_settings_provider_test.dart`
Expected: FAIL — `The getter 'quotesEnabled' isn't defined` / `method 'setQuotes' isn't defined`.

- [ ] **Step 3: Write minimal implementation**

In `trainer_settings_provider.dart`, thread the field through all four places — constructor, field declaration, `copyWith`, and `_load`:

```dart
  const TrainerSettings({
    this.enabled = false,
    this.countdownsEnabled = true,
    this.encouragementEnabled = true,
    this.speechRate = 0.5,
    this.disclaimerAccepted = false,
    this.personaId = 'steady',
    this.hrCalloutsEnabled = true,
    this.hrSafetyWarningsEnabled = true,
    this.quotesEnabled = true,
  });
```

```dart
  /// Whether the coach speaks an inspirational quote at workout start and
  /// after rests of two minutes or longer. Independent of the countdown
  /// toggle: switching countdowns off must not silently mute quotes too.
  final bool quotesEnabled;
```

In `copyWith`, add the `bool? quotesEnabled` parameter and `quotesEnabled: quotesEnabled ?? this.quotesEnabled,`.

In `_load`, add `quotesEnabled: prefs.getBool('trainer_quotes') ?? true,`.

Add the mutator alongside its siblings:

```dart
  Future<void> setQuotes(bool value) async {
    await _loading;
    state = state.copyWith(quotesEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trainer_quotes', value);
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/trainer/presentation/trainer_settings_provider_test.dart`
Expected: PASS, including the three new tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/trainer/presentation/providers/trainer_settings_provider.dart test/features/trainer/presentation/trainer_settings_provider_test.dart
git commit -m "feat: quotesEnabled trainer setting, defaulting on (#102)"
```

---

### Task 4: Engine attaches quotes

**Files:**
- Modify: `lib/features/trainer/application/coaching_engine.dart`
- Test: `test/features/trainer/application/coaching_engine_test.dart`

**Interfaces:**
- Consumes: `CoachingCue.quotePhraseKey` (Task 1), `RestFinished.restDuration` (Task 2).
- Produces: `CoachingEngine.longRestThreshold` (`static const Duration`, 2 minutes) — Task 6 reads it. `onEvent(..., bool quotesEnabled = true)` — Task 5 passes it.

**Behaviour table (from spec §4):**

| Moment | countdowns | quotes | Result |
|---|---|---|---|
| `WorkoutStarted` | — | on | greeting cue, `quotePhraseKey` attached |
| `WorkoutStarted` | — | off | greeting cue alone |
| `RestFinished` ≥2min | on | on | countdown cue, `quotePhraseKey` attached |
| `RestFinished` ≥2min | **off** | on | standalone quote cue at `milestone` |
| `RestFinished` ≥2min | on | off | countdown cue alone |
| `RestFinished` <2min or null | on | on | countdown cue alone |
| `RestFinished` | off | off | `null` |

- [ ] **Step 1: Add quotes to the test persona**

In `test/features/trainer/application/coaching_engine_test.dart`, add a quote bank to `_testPersona` so the engine has something to draw from:

```dart
const _testPersona = Persona(
  id: 'test',
  phrasesByKind: {
    TrainerEventKind.workoutStarted: ['start1', 'start2', 'start3'],
    TrainerEventKind.setLogged: ['set1', 'set2', 'set3'],
    TrainerEventKind.personalRecord: ['pr1', 'pr2', 'pr3'],
    TrainerEventKind.restCountdown: ['count1'],
    TrainerEventKind.restFinished: ['go1', 'go2', 'go3'],
    TrainerEventKind.workoutFinished: ['done1', 'done2', 'done3'],
    TrainerEventKind.quote: ['quote1', 'quote2', 'quote3'],
  },
);
```

- [ ] **Step 2: Write the failing tests**

Add this group to `test/features/trainer/application/coaching_engine_test.dart`:

```dart
  group('quotes', () {
    const longRest = RestFinished(restDuration: Duration(minutes: 2));
    const shortRest = RestFinished(restDuration: Duration(seconds: 90));

    test('attaches a quote to the workout-start greeting', () {
      final cue = _engine().onEvent(const WorkoutStarted(), now: t0);

      expect(cue!.phraseKey, startsWith('start'));
      expect(cue.quotePhraseKey, startsWith('quote'));
      expect(cue.priority, SpeechPriority.milestone);
    });

    test('attaches no quote at workout start when quotes are switched off',
        () {
      final cue = _engine()
          .onEvent(const WorkoutStarted(), now: t0, quotesEnabled: false);

      expect(cue!.phraseKey, startsWith('start'));
      expect(cue.quotePhraseKey, isNull);
    });

    test('attaches a quote to the countdown cue after a rest of two minutes',
        () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(longRest, now: t0.add(_min5));

      expect(cue!.phraseKey, startsWith('go'));
      expect(cue.quotePhraseKey, startsWith('quote'));
      expect(cue.priority, SpeechPriority.countdown);
    });

    test('attaches no quote after a rest shorter than two minutes', () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(shortRest, now: t0.add(_min5));

      expect(cue!.phraseKey, startsWith('go'));
      expect(cue.quotePhraseKey, isNull);
    });

    test('attaches no quote when the rest duration is unknown', () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(const RestFinished(), now: t0.add(_min5));

      expect(cue!.phraseKey, startsWith('go'));
      expect(cue.quotePhraseKey, isNull);
    });

    test(
        'speaks the quote alone after a long rest when countdowns are off, so '
        'the countdown toggle is not a second mute for quotes', () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(
        longRest,
        now: t0.add(_min5),
        countdownsEnabled: false,
      );

      expect(cue!.phraseKey, startsWith('quote'));
      expect(cue.quotePhraseKey, isNull);
      expect(cue.priority, SpeechPriority.milestone);
    });

    test('says nothing at rest end when both countdowns and quotes are off',
        () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(
        longRest,
        now: t0.add(_min5),
        countdownsEnabled: false,
        quotesEnabled: false,
      );

      expect(cue, isNull);
    });

    test('does not attach a quote while the reading is above the safety cap',
        () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);
      engine.onEvent(
        const HeartRateAboveCap(bpm: 190, cap: 175),
        now: t0.add(const Duration(seconds: 10)),
      );

      final cue = engine.onEvent(longRest, now: t0.add(_min5));

      // The countdown cue itself is exempt from the encouragement gate — a
      // missed countdown makes the feature useless — but the quote must not
      // ride along on that exemption.
      expect(cue!.phraseKey, startsWith('go'));
      expect(cue.quotePhraseKey, isNull);
    });

    test('does not attach a quote in caution mode', () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);

      final cue = engine.onEvent(
        longRest,
        now: t0.add(_min5),
        cautionMode: true,
      );

      expect(cue!.quotePhraseKey, isNull);
    });

    test('does not attach a quote once the user has reached zone 5', () {
      final engine = _engine();
      engine.onEvent(const WorkoutStarted(), now: t0);
      engine.onEvent(
        const HeartRateZoneChanged(
          zoneNumber: 5,
          effortLabel: 'Maximum',
          descriptiveLabel: 'Anaerobic',
        ),
        now: t0.add(const Duration(seconds: 10)),
      );

      final cue = engine.onEvent(longRest, now: t0.add(_min5));

      expect(cue!.quotePhraseKey, isNull);
    });

    test('exhausts the bank before repeating a quote', () {
      final engine = _engine();
      final bank = _testPersona.phrasesFor(TrainerEventKind.quote);
      final heard = <String>{};

      var at = t0;
      for (var i = 0; i < bank.length; i++) {
        final cue = engine.onEvent(longRest, now: at, countdownsEnabled: false);
        heard.add(cue!.phraseKey);
        at = at.add(_min5);
      }

      expect(heard, hasLength(bank.length));
    });

    test(
        'a suppressed quote does not consume the bank — switching quotes back '
        'on still offers every quote', () {
      final engine = _engine();
      var at = t0;
      for (var i = 0; i < 10; i++) {
        engine.onEvent(
          longRest,
          now: at,
          countdownsEnabled: false,
          quotesEnabled: false,
        );
        at = at.add(_min5);
      }

      final bank = _testPersona.phrasesFor(TrainerEventKind.quote);
      final heard = <String>{};
      for (var i = 0; i < bank.length; i++) {
        final cue = engine.onEvent(longRest, now: at, countdownsEnabled: false);
        heard.add(cue!.phraseKey);
        at = at.add(_min5);
      }

      expect(heard, hasLength(bank.length));
    });
  });
```

Add `const _min5 = Duration(minutes: 5);` beside the other file-level constants — every rest-end assertion spaces itself well past `encouragementCooldown` so the cooldown never confounds the result.

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/features/trainer/application/coaching_engine_test.dart`
Expected: FAIL — `No named parameter with the name 'quotesEnabled'`.

- [ ] **Step 4: Implement in the engine**

Add the public threshold beside `_capWarningRepeat`:

```dart
  /// Rests at or beyond this length earn an inspirational quote (spec §5).
  ///
  /// Public and `static` because the rest-timer chime suppression
  /// (`coachAnnouncesRestEndProvider`) has to apply the same rule to decide
  /// whether the coach will speak, and a second copy of "two minutes" in the
  /// presentation layer would be free to drift out of step with this one.
  static const Duration longRestThreshold = Duration(minutes: 2);
```

Add the flag to `onEvent`'s signature after `hrSafetyWarningsEnabled`:

```dart
    bool quotesEnabled = true,
```

Replace the `WorkoutStarted` and `RestFinished` arms of the switch:

```dart
      WorkoutStarted() => _withQuote(
          _speak(event.kind, SpeechPriority.milestone, now),
          quotesEnabled,
        ),
```

```dart
      RestFinished(:final restDuration) =>
        _onRestFinished(restDuration, countdownsEnabled, quotesEnabled, now),
```

Add the two helpers below `_onSetLogged`:

```dart
  /// The countdown line, the quote, both merged, or neither.
  ///
  /// Merged rather than returned as a second cue: `FlutterTtsSpeechService`
  /// drops any cue at equal or lower priority than the one already playing,
  /// so a quote emitted straight after the countdown line would never be
  /// heard. See the spec's §2 for the full derivation.
  ///
  /// When countdowns are off the quote is spoken alone, at milestone
  /// priority. Letting it vanish with the countdown line would make the
  /// countdown toggle a hidden second mute for quotes.
  CoachingCue? _onRestFinished(
    Duration? restDuration,
    bool countdownsEnabled,
    bool quotesEnabled,
    DateTime now,
  ) {
    final earnsQuote = quotesEnabled &&
        restDuration != null &&
        restDuration >= longRestThreshold;

    if (!countdownsEnabled) {
      if (!earnsQuote) return null;
      return _speak(TrainerEventKind.quote, SpeechPriority.milestone, now);
    }

    final cue = _speak(
      TrainerEventKind.restFinished,
      SpeechPriority.countdown,
      now,
      encouragement: false,
    );
    return _withQuote(cue, earnsQuote);
  }

  /// Attaches a quote to [cue], or returns it untouched.
  ///
  /// Gated on [_encouragementBlocked] independently of whatever [cue] itself
  /// was allowed through on. The countdown line is exempt from that gate
  /// (`encouragement: false`) because a missed countdown makes the feature
  /// useless — but a motivational quote riding along on that exemption would
  /// put inspirational chatter in the user's ear at the moment their heart
  /// rate is over their clinician cap.
  /// [earnsQuote] is the caller's decision that this moment qualifies —
  /// "quotes are on" at workout start, "quotes are on *and* the rest was long
  /// enough" at rest end.
  CoachingCue? _withQuote(CoachingCue? cue, bool earnsQuote) {
    if (cue == null || !earnsQuote || _encouragementBlocked) return cue;

    final quote = _pickPhrase(TrainerEventKind.quote);
    if (quote == null) return cue;

    _spokenPhrases.add(quote);
    return CoachingCue(
      phraseKey: cue.phraseKey,
      priority: cue.priority,
      args: cue.args,
      quotePhraseKey: quote,
    );
  }
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/trainer/application/coaching_engine_test.dart`
Expected: PASS, all tests including the twelve new ones.

- [ ] **Step 6: Check nothing else regressed**

Run: `flutter test test/features/trainer/ && dart analyze lib test`
Expected: all PASS, analyzer clean.

- [ ] **Step 7: Commit**

```bash
git add lib/features/trainer/application/coaching_engine.dart test/features/trainer/application/coaching_engine_test.dart
git commit -m "feat: engine attaches quotes at workout start and after long rests (#102)"
```

---

### Task 5: Bridge speaks the merged utterance

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/features/trainer/presentation/providers/coach_bridge.dart:114-130`
- Test: `test/features/trainer/presentation/coach_bridge_test.dart`

**Interfaces:**
- Consumes: `CoachingCue.quotePhraseKey` (Task 1), `onEvent(..., quotesEnabled:)` (Task 4), `TrainerSettings.quotesEnabled` (Task 3).
- Produces: `S.coachCueWithQuote(String cue, String quote)`.

**This task carries the acceptance-criterion test** — the one that would fail against `main` today: it asserts a real quote string reaches the speech service, not merely that the bank is non-empty.

- [ ] **Step 1: Add the ARB entry**

In `lib/l10n/app_en.arb`, add both the string and its metadata block (metadata is required here because the entry takes placeholders; the plain toggle strings in this file have none, which is why they have no `@` sibling):

```json
  "coachCueWithQuote": "{cue} {quote}",
  "@coachCueWithQuote": {
    "description": "Joins a spoken coaching cue to an inspirational quote in a single utterance. Localise the separator: a bare space is wrong for ja/ko/zh.",
    "placeholders": {
      "cue": { "type": "String" },
      "quote": { "type": "String" }
    }
  },
```

- [ ] **Step 2: Regenerate localisations**

Run: `flutter gen-l10n`
Expected: succeeds; `S.coachCueWithQuote` now exists in `lib/l10n/generated/app_localizations.dart`.

- [ ] **Step 3: Write the failing tests**

Add to `test/features/trainer/presentation/coach_bridge_test.dart`. It already has `buildContainer`, `SilentSpeechService`, and `lookupS(const Locale('en'))` — reuse them.

```dart
  group('quotes', () {
    test(
        'speaks an actual quote from the bank at workout start — the whole '
        'point of #102, and the assertion that fails against a bank nothing '
        'reads', () async {
      final container = buildContainer();
      final bridge = container.read(_bridgeUnderTest);
      final strings = lookupS(const Locale('en'));
      bridge.strings = strings;

      container.read(trainerEventBusProvider).emit(const WorkoutStarted());
      await Future<void>.delayed(Duration.zero);

      expect(speechService.spoken, hasLength(1));
      final spoken = speechService.spoken.single;
      final quotes = personaForId('steady')
          .phrasesFor(TrainerEventKind.quote)
          .map((key) => phraseResolvers[key]!(strings, const {}))
          .toList();
      expect(
        quotes.any(spoken.contains),
        isTrue,
        reason: 'expected one of the ${quotes.length} bank quotes in "$spoken"',
      );
    });

    test('speaks a quote after a rest of two minutes or longer', () async {
      final container = buildContainer();
      final bridge = container.read(_bridgeUnderTest);
      final strings = lookupS(const Locale('en'));
      bridge.strings = strings;

      container.read(trainerEventBusProvider).emit(const WorkoutStarted());
      await Future<void>.delayed(Duration.zero);
      speechService.spoken.clear();

      container.read(trainerEventBusProvider).emit(
            const RestFinished(restDuration: Duration(minutes: 2)),
          );
      await Future<void>.delayed(Duration.zero);

      final spoken = speechService.spoken.single;
      final quotes = personaForId('steady')
          .phrasesFor(TrainerEventKind.quote)
          .map((key) => phraseResolvers[key]!(strings, const {}))
          .toList();
      expect(quotes.any(spoken.contains), isTrue);
    });

    test('speaks no quote after a short rest', () async {
      final container = buildContainer();
      final bridge = container.read(_bridgeUnderTest);
      final strings = lookupS(const Locale('en'));
      bridge.strings = strings;

      container.read(trainerEventBusProvider).emit(const WorkoutStarted());
      await Future<void>.delayed(Duration.zero);
      speechService.spoken.clear();

      container.read(trainerEventBusProvider).emit(
            const RestFinished(restDuration: Duration(seconds: 60)),
          );
      await Future<void>.delayed(Duration.zero);

      final spoken = speechService.spoken.single;
      final quotes = personaForId('steady')
          .phrasesFor(TrainerEventKind.quote)
          .map((key) => phraseResolvers[key]!(strings, const {}))
          .toList();
      expect(quotes.any(spoken.contains), isFalse);
    });

    test('speaks no quote when the quotes toggle is off', () async {
      final container = buildContainer(
        settings: const TrainerSettings(
          enabled: true,
          disclaimerAccepted: true,
          quotesEnabled: false,
        ),
      );
      final bridge = container.read(_bridgeUnderTest);
      final strings = lookupS(const Locale('en'));
      bridge.strings = strings;

      container.read(trainerEventBusProvider).emit(const WorkoutStarted());
      await Future<void>.delayed(Duration.zero);

      final spoken = speechService.spoken.single;
      final quotes = personaForId('steady')
          .phrasesFor(TrainerEventKind.quote)
          .map((key) => phraseResolvers[key]!(strings, const {}))
          .toList();
      expect(quotes.any(spoken.contains), isFalse);
    });
  });
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `flutter test test/features/trainer/presentation/coach_bridge_test.dart`
Expected: FAIL — the first two report no bank quote found in the spoken string.

- [ ] **Step 5: Implement in the bridge**

Pass the setting into the engine — add to the `_engine.onEvent(...)` argument list in `_onEvent`:

```dart
      quotesEnabled: settings.quotesEnabled,
```

Replace the speak block:

```dart
    if (cue != null) {
      final text = _resolveCue(strings, cue);
      if (text != null) {
        unawaited(
          _ref.read(speechServiceProvider).speak(text, priority: cue.priority),
        );
      }
    }
```

And add the helper as a method on `CoachBridge`:

```dart
  /// Resolves a cue, folding in its attached quote as one utterance.
  ///
  /// Joined through the ARB rather than with a hardcoded space: `app_en.arb`
  /// has ja/ko/zh siblings where a bare inter-sentence space is wrong.
  ///
  /// If exactly one of the two keys fails to resolve, whatever did resolve is
  /// still spoken. `resolvePhrase` returns null for an unknown key, and
  /// speech time is the wrong place to lose a cue over a missing quote.
  String? _resolveCue(S strings, CoachingCue cue) {
    final text = resolvePhrase(strings, cue.phraseKey, cue.args);
    final quoteKey = cue.quotePhraseKey;
    if (quoteKey == null) return text;

    final quote = resolvePhrase(strings, quoteKey, const {});
    if (quote == null) return text;
    if (text == null) return quote;
    return strings.coachCueWithQuote(text, quote);
  }
```

Add `import '../../domain/coaching_cue.dart';` to `coach_bridge.dart` if it is not already imported.

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/features/trainer/presentation/coach_bridge_test.dart`
Expected: PASS, including the four new tests.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/ lib/features/trainer/presentation/providers/coach_bridge.dart test/features/trainer/presentation/coach_bridge_test.dart
git commit -m "feat: speak the quote as part of the cue it accompanies (#102)"
```

---

### Task 6: Rest-timer chime stands down for a standalone quote

**Files:**
- Modify: `lib/features/trainer/presentation/providers/coach_announcements.dart`
- Modify: `lib/features/workout/presentation/widgets/rest_timer_widget.dart:34-63,88-99`
- Test: `test/features/trainer/presentation/coach_announces_rest_end_test.dart`

**Interfaces:**
- Consumes: `CoachingEngine.longRestThreshold` (Task 4), `TrainerSettings.quotesEnabled` (Task 3).
- Produces: `coachAnnouncesRestEndProvider` becomes `Provider.family<bool, Duration>`; `RestTimerNotifier.lastRestDuration` (`Duration?`) — Task 7 also uses it.

**Why:** the chime takes exclusive audio focus on Android while the coach only asks to duck, so the two together cut the coach off (issue #98). The provider currently returns `false` when countdowns are off, because nothing else could speak at rest end. Task 4's standalone quote breaks that assumption.

- [ ] **Step 1: Write the failing tests**

In `test/features/trainer/presentation/coach_announces_rest_end_test.dart`, extend the `_container` helper with `bool quotesEnabled = true` (pass it into the seeded `TrainerSettings`), then convert the existing reads to the family form and add the new cases:

```dart
const _short = Duration(seconds: 60);
const _long = Duration(minutes: 2);
```

Every existing `read(coachAnnouncesRestEndProvider)` becomes
`read(coachAnnouncesRestEndProvider(_short))`. Then add:

```dart
    test(
        'with countdowns off, a long rest still silences the chime — the '
        'coach speaks a standalone quote there', () {
      final container = _container(countdownsEnabled: false);

      expect(container.read(coachAnnouncesRestEndProvider(_long)), isTrue);
    });

    test('with countdowns off, a short rest lets the chime through', () {
      final container = _container(countdownsEnabled: false);

      expect(container.read(coachAnnouncesRestEndProvider(_short)), isFalse);
    });

    test('with countdowns and quotes both off, the chime always plays', () {
      final container =
          _container(countdownsEnabled: false, quotesEnabled: false);

      expect(container.read(coachAnnouncesRestEndProvider(_long)), isFalse);
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/trainer/presentation/coach_announces_rest_end_test.dart`
Expected: FAIL — the provider is not callable as a family.

- [ ] **Step 3: Implement the provider**

Replace the provider in `coach_announcements.dart`:

```dart
/// True when the coach will speak its own line at the end of a rest of
/// [restDuration], so the rest-timer chime must stand down.
///
/// On Android the chime takes exclusive audio focus (`AUDIOFOCUS_GAIN`)
/// whereas the coach only asks to duck, so the two firing together cut the
/// coach off mid-sentence. When the coach speaks, the chime is redundant
/// anyway.
///
/// Keyed on the rest's length because the answer now depends on it. With
/// countdowns on, the coach always speaks the end-of-rest line. With
/// countdowns off it still speaks a standalone quote, but only after a rest
/// of [CoachingEngine.longRestThreshold] or more.
///
/// This cannot see the engine's above-cap/caution/zone-5 suppression, so with
/// countdowns off and quotes on a long rest ending above the safety cap
/// silences the chime for a quote the engine then withholds — vibration, and
/// no sound. That is the right way to be wrong: above the cap a
/// safety-priority warning is the likeliest thing playing, and a chime seizing
/// exclusive audio focus is exactly what must not happen then.
final coachAnnouncesRestEndProvider =
    Provider.family<bool, Duration>((ref, restDuration) {
  final settings = ref.watch(trainerSettingsProvider);
  if (!settings.enabled || !settings.disclaimerAccepted) return false;
  if (!ref.watch(entitlementServiceProvider).has(Entitlement.virtualTrainer)) {
    return false;
  }

  if (settings.countdownsEnabled) return true;
  return settings.quotesEnabled &&
      restDuration >= CoachingEngine.longRestThreshold;
});
```

Add `import '../../application/coaching_engine.dart';`.

- [ ] **Step 4: Expose the rest length on the notifier**

In `rest_timer_widget.dart`, have `RestTimerNotifier` remember what it started:

```dart
  Duration? _lastRestDuration;

  /// What the most recent rest was set to run for, so the chime-suppression
  /// rule and the coach's quote rule read the same number.
  Duration? get lastRestDuration => _lastRestDuration;
```

Set it as the first statement of `start`:

```dart
  void start(int seconds) {
    _timer?.cancel();
    _lastRestDuration = Duration(seconds: seconds);
    state = seconds;
    ...
```

- [ ] **Step 5: Key the chime check on it**

Replace the guard in `_onTimerComplete`:

```dart
    final restDuration =
        ref.read(restTimerProvider.notifier).lastRestDuration ?? Duration.zero;
    if (settings.soundEnabled &&
        !ref.read(coachAnnouncesRestEndProvider(restDuration))) {
      _audioPlayer?.play(AssetSource('sounds/timer_complete.wav'));
    }
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/features/trainer/presentation/coach_announces_rest_end_test.dart test/features/workout/presentation/widgets/rest_timer_alert_test.dart`
Expected: PASS. If `rest_timer_alert_test.dart` fails, it is reading the provider in its old non-family form — update those reads too.

- [ ] **Step 7: Commit**

```bash
git add lib/features/trainer/presentation/providers/coach_announcements.dart lib/features/workout/presentation/widgets/rest_timer_widget.dart test/
git commit -m "fix: chime stands down for a standalone quote after a long rest (#102)"
```

---

### Task 7: Emit the rest duration

**Files:**
- Modify: `lib/features/workout/presentation/widgets/rest_timer_widget.dart:45`
- Test: `test/features/workout/presentation/widgets/rest_timer_widget_test.dart`

**Interfaces:**
- Consumes: `RestFinished({Duration? restDuration})` (Task 2), `RestTimerNotifier.lastRestDuration` (Task 6).
- Produces: nothing further.

This is the last link: without it every `RestFinished` still carries `null` and no quote ever fires at rest end in the real app, however green Tasks 4 and 5 are.

- [ ] **Step 1: Write the failing test**

Add to `test/features/workout/presentation/widgets/rest_timer_widget_test.dart`, following its existing container setup. The bus needs a permissive entitlement callback so the event is not filtered:

```dart
  test('RestFinished carries the duration the timer ran for', () async {
    final bus = TrainerEventBus(() => true);
    final events = <TrainerEvent>[];
    final sub = bus.events.listen(events.add);
    addTearDown(sub.cancel);

    final container = ProviderContainer(
      overrides: [trainerEventBusProvider.overrideWithValue(bus)],
    );
    addTearDown(container.dispose);

    fakeAsync((async) {
      container.read(restTimerProvider.notifier).start(2);
      async.elapse(const Duration(seconds: 4));
    });
    await Future<void>.delayed(Duration.zero);

    final finished = events.whereType<RestFinished>().single;
    expect(finished.restDuration, const Duration(seconds: 2));
  });
```

Add imports for `package:fake_async/fake_async.dart`, `trainer_event.dart` and `trainer_event_bus.dart` if absent. If `fake_async` is not already a dev dependency, drive the timer with `await Future.delayed` and real seconds instead rather than adding a package.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/workout/presentation/widgets/rest_timer_widget_test.dart`
Expected: FAIL — `Expected: Duration:0:00:02.000000  Actual: <null>`.

- [ ] **Step 3: Implement**

In `RestTimerNotifier.start`, pass the stored duration when the timer runs out:

```dart
        ref
            .read(trainerEventBusProvider)
            .emit(RestFinished(restDuration: _lastRestDuration));
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/workout/presentation/widgets/rest_timer_widget_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/workout/presentation/widgets/rest_timer_widget.dart test/features/workout/presentation/widgets/rest_timer_widget_test.dart
git commit -m "feat: rest timer emits the duration the rest ran for (#102)"
```

---

### Task 8: Quotes toggle in settings

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/features/trainer/presentation/screens/trainer_settings_screen.dart:115-125`
- Test: `test/features/trainer/presentation/trainer_settings_screen_test.dart`

**Interfaces:**
- Consumes: `TrainerSettings.quotesEnabled` and `setQuotes` (Task 3).
- Produces: `S.trainerQuotes`, `S.trainerQuotesSubtitle`.

- [ ] **Step 1: Add the ARB strings**

In `lib/l10n/app_en.arb`, beside `trainerEncouragement`. No `@` metadata blocks — these take no placeholders, matching the other toggle strings in this file:

```json
  "trainerQuotes": "Inspirational quotes",
  "trainerQuotesSubtitle": "Speaks a short quote when a workout starts and after rests of two minutes or longer.",
```

- [ ] **Step 2: Regenerate localisations**

Run: `flutter gen-l10n`
Expected: succeeds; `S.trainerQuotes` and `S.trainerQuotesSubtitle` exist.

- [ ] **Step 3: Write the failing test**

Add to `test/features/trainer/presentation/trainer_settings_screen_test.dart`, following its existing pump helper:

```dart
  testWidgets('renders the quotes toggle and writes the setting through',
      (tester) async {
    final container = await pumpSettingsScreen(tester);

    final tile = find.widgetWithText(SwitchListTile, 'Inspirational quotes');
    expect(tile, findsOneWidget);
    expect(
      container.read(trainerSettingsProvider).quotesEnabled,
      isTrue,
    );

    await tester.tap(find.descendant(of: tile, matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    expect(container.read(trainerSettingsProvider).quotesEnabled, isFalse);
  });
```

Match the helper name and return type this file already uses; if it exposes the container differently, follow that pattern rather than inventing `pumpSettingsScreen`.

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/features/trainer/presentation/trainer_settings_screen_test.dart`
Expected: FAIL — no `SwitchListTile` with that label.

- [ ] **Step 5: Implement**

In `trainer_settings_screen.dart`, insert after the encouragement switch (before the HR callouts switch):

```dart
          SwitchListTile(
            title: Text(s.trainerQuotes),
            subtitle: Text(s.trainerQuotesSubtitle),
            value: settings.quotesEnabled,
            onChanged: notifier.setQuotes,
          ),
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/trainer/presentation/trainer_settings_screen_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/ lib/features/trainer/presentation/screens/trainer_settings_screen.dart test/features/trainer/presentation/trainer_settings_screen_test.dart
git commit -m "feat: quotes toggle in trainer settings (#102)"
```

---

### Task 9: Persona-switch regression test

**Files:**
- Test: `test/features/trainer/presentation/coach_bridge_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 1–5. Adds no production code.

**Why a test and not a fix:** issue #102 says "a persona switch resets `_spokenPhrases`". That was true when `CoachBridge` discarded the engine on a voice change; fix round 1 of #99 changed it to `_engine.persona = personaForId(...)` in place (`coaching_engine.dart:45`), which leaves `_spokenPhrases` intact. Since `_quoteBank` is the same `const` list in all three packs, a quote heard under Steady is still recognised as heard under Hype. **Verify this before writing the test** — if it does not hold, stop and report, because the plan's premise is wrong.

- [ ] **Step 1: Write the test**

Add to the `quotes` group in `coach_bridge_test.dart`. The seeded settings notifier's `forceUpdate` is how the persona changes under the bridge's feet:

```dart
    test(
        'a persona switch does not make an already-heard quote available '
        'again — the bank is shared, so quote memory must survive the switch',
        () async {
      final container = buildContainer();
      final bridge = container.read(_bridgeUnderTest);
      final strings = lookupS(const Locale('en'));
      bridge.strings = strings;
      final bus = container.read(trainerEventBusProvider);

      final quoteTexts = personaForId('steady')
          .phrasesFor(TrainerEventKind.quote)
          .map((key) => phraseResolvers[key]!(strings, const {}))
          .toList();
      String? quoteIn(String spoken) =>
          quoteTexts.where(spoken.contains).firstOrNull;

      bus.emit(const WorkoutStarted());
      await Future<void>.delayed(Duration.zero);
      final firstQuote = quoteIn(speechService.spoken.single);
      expect(firstQuote, isNotNull);

      container
          .read(trainerSettingsProvider.notifier)
          .forceUpdate(const TrainerSettings(
            enabled: true,
            disclaimerAccepted: true,
            personaId: 'hype',
          ));

      // Draw the rest of the bank under the new persona; the quote already
      // heard under Steady must not come back until every other one has.
      final heardAfterSwitch = <String>{};
      for (var i = 0; i < quoteTexts.length - 1; i++) {
        speechService.spoken.clear();
        bus.emit(const RestFinished(restDuration: Duration(minutes: 2)));
        await Future<void>.delayed(Duration.zero);
        final quote = quoteIn(speechService.spoken.single);
        if (quote != null) heardAfterSwitch.add(quote);
      }

      expect(heardAfterSwitch, isNot(contains(firstQuote)));
    });
```

Add `import 'package:collection/collection.dart';` for `firstOrNull` if the file does not already have it; if `collection` is not a dependency, replace `.firstOrNull` with a `where(...).toList()` and an `isEmpty ? null : first`.

- [ ] **Step 2: Run the test**

Run: `flutter test test/features/trainer/presentation/coach_bridge_test.dart`
Expected: PASS without any production change. If it FAILS, the premise above is wrong — stop, report, and do not paper over it by clearing state somewhere.

- [ ] **Step 3: Commit**

```bash
git add test/features/trainer/presentation/coach_bridge_test.dart
git commit -m "test: quote memory survives a persona switch (#102)"
```

---

### Task 10: Correct the persona-packs doc comment and open the follow-up

**Files:**
- Modify: `lib/features/trainer/data/persona_packs.dart:4-30`

**Interfaces:** none — documentation and issue hygiene.

The doc block on `_quoteBank` currently asserts the bank is dead. That comment is what this work falsifies, and #99's fix round 5 exists because a stale comment asserting the wrong thing is how the original bug survived review. It must not be left behind.

- [ ] **Step 1: Open the sourcing-table follow-up issue**

```bash
gh issue create \
  --title "Record the per-quote sourcing table in the repo" \
  --label enhancement,virtual-trainer \
  --body "The quote bank's licensing rule (author *and* translator dead more than 70 years) is documented in \`persona_packs.dart\`, but the per-quote evidence — author, work, translation/edition relied on, both death dates — exists nowhere in the repo. It lived only in issue #99's fix-round report.

Without it, the next person adding or auditing a quote has to re-derive every entry, and the three quotes already dropped (Helen Keller, Muriel Strode, the Gummere translation) can be re-added by someone who does not know why they went.

Every translated entry needs its translator verified against the life+70 rule: Marcus Aurelius, Seneca, Epictetus, Lao Tzu, Socrates via Plato, Aristotle, Cervantes, Leonardo da Vinci. Quotes that fail should be dropped.

Split out of #102, which wired the bank up but deliberately did not take on the research."
```

Note the number it returns; it is referenced in the next step.

- [ ] **Step 2: Rewrite the doc block**

In `lib/features/trainer/data/persona_packs.dart`, delete the "**Not yet wired to any event**" paragraph entirely, and repoint the sourcing-table paragraph at the new issue. Replace `<NNN>` with the number from Step 1:

```dart
/// Shared inspirational quote bank (spec §5).
///
/// **Licensing rule for anyone adding a quote:** every named person whose
/// words we ship — original author *and* translator — must have died more
/// than 70 years ago. Publication date alone is not sufficient. The
/// translator clause matters just as much as the author clause: a
/// public-domain author can still have an in-copyright translation, which is
/// how Gregory Hays' 2002 rendering of Marcus Aurelius nearly shipped under
/// Marcus Aurelius' own (long-expired) name. Check both death dates before
/// adding an entry, and drop it rather than guess if either is unclear.
///
/// The per-quote sourcing table (author, work, translation/edition relied on)
/// is not yet in this repo — see issue #<NNN>.
///
/// Spoken at workout start and after rests of
/// [CoachingEngine.longRestThreshold] or longer, merged into the cue for that
/// moment rather than spoken as a separate one — see `CoachingCue`'s
/// `quotePhraseKey`.
///
/// Attached to every persona's [TrainerEventKind.quote] bank rather than
/// kept as a standalone list, so the existing per-persona
/// uniqueness/resolver/denylist test loops cover it automatically instead of
/// needing a parallel set of checks. That sharing is also what lets quote
/// memory survive a persona switch.
```

Do not add an import for `CoachingEngine` solely for that doc reference — if `dart analyze` flags the unresolved doc link, write it as `` `CoachingEngine.longRestThreshold` `` in backticks instead.

- [ ] **Step 3: Verify**

Run: `flutter test test/features/trainer/data/persona_packs_test.dart && dart analyze lib`
Expected: PASS, analyzer clean.

- [ ] **Step 4: Commit**

```bash
git add lib/features/trainer/data/persona_packs.dart
git commit -m "docs: the quote bank is wired now; point sourcing table at its own issue (#102)"
```

---

### Task 11: Full verification and PR

**Files:** none modified unless verification finds a problem.

- [ ] **Step 1: Format**

Run: `dart format .`
Then: `dart format --set-exit-if-changed .`
Expected: exit 0.

- [ ] **Step 2: Analyse**

Run: `dart analyze`
Expected: "No issues found!"

- [ ] **Step 3: Full test suite**

Run: `flutter test`
Expected: all tests pass. The baseline on `main` is green, so any failure here is caused by this branch — fix it rather than recording it as pre-existing.

- [ ] **Step 4: Check the acceptance criteria by hand**

Confirm against issue #102, and paste the evidence into the PR body:

- A quote is spoken at workout start, and after rests of ≥2 minutes → Task 5 tests 1 and 2
- Quotes respect their own toggle, defaulting on → Task 3, Task 5 test 4, Task 8
- Quotes never pre-empt or delay a HR safety warning → Task 4, the above-cap/caution/zone-5 tests
- No quote repeats within a session until the bank is exhausted → Task 4 exhaustion test, Task 9
- Test proving a quote is actually spoken end to end → Task 5 test 1

- [ ] **Step 5: Push and open the PR**

```bash
git push -u origin feat/102-speak-quotes
gh pr create --title "feat: speak the coach quote bank (#102)" --body "$(cat <<'EOF'
Wires the 21-quote public-domain bank shipped inert in #99 so quotes are actually spoken: at workout start, and after rests of two minutes or longer, behind their own settings toggle.

## The issue's recommended approach does not work

#102 suggested emitting a `QuoteMoment` event the engine passes through. `FlutterTtsSpeechService.speak` drops any cue at equal or lower priority than what is already playing, and both quote moments are moments the coach is already speaking — workout start at `milestone`, rest end at `countdown`. A separate `encouragement`-priority quote cue is dropped at both, so that approach would have shipped a second round of inert content that no test catches.

The quote is merged into the utterance it accompanies instead: one `speak()` call, no priority race. No new event class is needed, so the change is smaller than the issue anticipated.

## Also here

- The rest-timer chime had to learn about this. It stands down when the coach speaks (#98, exclusive audio focus on Android cuts the coach off), and returned `false` whenever countdowns were off — but countdowns-off plus a long rest now still speaks a standalone quote. `coachAnnouncesRestEndProvider` becomes a family keyed on the rest's length.
- The issue's third note — "a persona switch resets `_spokenPhrases`" — is already fixed by #99's fix round 1, which set the persona in place instead of rebuilding the engine. Covered by a regression test rather than a fix.
- The bank holds 21 quotes, not the "30+" the issue says; rounds 2, 4 and 5 dropped three.

Spec: `docs/superpowers/specs/2026-08-04-quote-bank-wiring-design.md`
Plan: `docs/superpowers/plans/2026-08-04-quote-bank-wiring.md`

Closes #102

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_011qvccJvVhjCU5E6tKnf8rj
EOF
)"
```
