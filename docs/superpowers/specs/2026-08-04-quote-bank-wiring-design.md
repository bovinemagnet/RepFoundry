# Wiring the Coach Quote Bank — Design Specification

**Date:** 2026-08-04
**Author:** Paul Snow
**Status:** Approved for planning
**Issue:** #102 (Phase 2b follow-up)
**Depends on:** `docs/superpowers/specs/2026-08-01-virtual-personal-trainer-design.md` §5, §7

## 1. Summary

Issue #99 shipped a 21-entry public-domain quote bank as content: the phrases are in
`app_en.arb`, have `phrase_resolver.dart` entries, and hang off every persona's
`TrainerEventKind.quote` bank. Nothing speaks them. No `TrainerEvent` carries that
kind and `CoachingEngine.onEvent` has no case for it, so the bank is inert.

This work makes quotes audible at the two moments spec §5 calls for — workout start,
and after rest periods of two minutes or longer — behind their own settings toggle.

### Why it did not surface on its own

`onEvent` switches over a **sealed** `TrainerEvent` hierarchy. The dead content hangs
off a `TrainerEventKind` rather than an event class, so exhaustiveness checking cannot
flag it, no test fails, and the analyser stays clean. The end-to-end test in §7 exists
specifically to close that gap: it asserts a quote reaches the speech service, not
merely that the bank is non-empty.

## 2. The constraint that shapes the design

`FlutterTtsSpeechService.speak` drops any cue whose priority is equal to or lower than
what is already playing:

```dart
final current = _currentPriority;
if (current != null && priority.index <= current.index) return;
```

`awaitSpeakCompletion(true)` holds that claim for the whole utterance, and
`SpeechPriority` orders as `encouragement(0) < milestone(1) < countdown(2) < safety(3)`.

Both quote moments are moments the coach is **already speaking**:

| Moment | In-flight cue | A separate quote cue would be | Outcome |
|---|---|---|---|
| Workout start | `workoutStarted` @ `milestone` | `encouragement` (0 ≤ 1) | **dropped** |
| Rest end | `restFinished` @ `countdown` | `encouragement` (0 ≤ 2) | **dropped** |

Issue #102's recommended Option 3 — "have the emitter push a new `QuoteMoment` event;
the engine gains only a passthrough branch" — therefore fails silently at both required
moments. It would ship a second round of inert content that no test catches: the exact
failure mode this issue exists to fix.

**Decision: merge the quote into the utterance it accompanies.** One `speak()` call per
moment, so there is no priority race to lose. A safety warning still pre-empts the
merged utterance exactly as it pre-empts the unmerged one today.

Consequence: no `QuoteMoment` event class is introduced. The design is smaller than the
issue anticipated.

## 3. Domain changes

### 3.1 `RestFinished` carries the rest it ended

```dart
class RestFinished extends TrainerEvent {
  const RestFinished({this.restDuration});
  final Duration? restDuration;
}
```

The field is **optional**, so all thirteen existing constructions across
`coaching_engine_test.dart`, `coach_bridge_test.dart` and production continue to
compile unchanged. `null` means "duration unknown" and is treated as a short rest —
a caller that does not know cannot accidentally trigger a quote.

`rest_timer_widget.dart:45` is the only production emitter and already holds the
duration it started the timer with (`RestTimerNotifier.start(int seconds)`).

This is issue #102's option 1 ("touches the sealed class, every emitter, and every
existing test constructing it"), and the optional field defuses that objection: one
emitter, zero test churn.

### 3.2 `CoachingCue` carries an optional attached quote

```dart
class CoachingCue {
  const CoachingCue({
    required this.phraseKey,
    required this.priority,
    this.args = const {},
    this.quotePhraseKey,
  });
  final String? quotePhraseKey;
}
```

`phraseKey` stays non-null and remains the primary utterance. A standalone quote (§4,
countdowns-off row) is expressed as `phraseKey: <quote key>, quotePhraseKey: null`, not
as a null primary — so no consumer has to handle an empty lead-in.

## 4. Engine behaviour

`CoachingEngine.onEvent` gains a sixth named flag, `bool quotesEnabled = true`,
following the established pattern: toggles go *into* the engine so a suppressed cue
never consumes a phrase from the variety bank nor restarts the encouragement cooldown.

`_longRest` is `Duration(minutes: 2)`, a private constant beside `_capWarningRepeat`.

| Moment | countdowns | quotes | Result |
|---|---|---|---|
| `WorkoutStarted` | — | on | greeting cue, `quotePhraseKey` attached |
| `WorkoutStarted` | — | off | greeting cue alone (today's behaviour) |
| `RestFinished`, `restDuration >= 2min` | on | on | countdown cue, `quotePhraseKey` attached |
| `RestFinished`, `restDuration >= 2min` | **off** | on | standalone quote cue at `milestone` |
| `RestFinished`, `restDuration >= 2min` | on | off | countdown cue alone |
| `RestFinished`, `restDuration < 2min` or `null` | on | on | countdown cue alone |
| `RestFinished` | off | off | `null` (today's behaviour) |

The countdowns-off row is the reason quotes are not simply an appendix to an existing
cue. With countdowns off, `RestFinished` produces nothing, and a merged-only quote would
vanish with it — which would make the rest-countdown switch a hidden second mute for
quotes, failing the acceptance criterion that quotes respect *their own* toggle.

### 4.1 Safety interaction

Quote attachment is gated by the existing `_encouragementBlocked` getter
(`_aboveCap || _cautionMode || _currentZone == 5`). A quote therefore never attaches
while the user is above their safety cap, in caution mode, or in zone 5.

This is stricter than the acceptance criterion "quotes never pre-empt or delay a
heart-rate safety warning" requires, and deliberately so. The `RestFinished` countdown
cue is itself exempt from the encouragement gate (`encouragement: false`) because a
missed countdown makes the feature useless — but a motivational quote riding along on
that exemption would put inspirational chatter in the user's ear at the moment their
heart rate is over their clinician cap. The gate is checked for the quote independently
of the cue it attaches to.

The merged utterance is longer than the cue alone, but "delay" is not a risk: a
`safety`-priority warning pre-empts it mid-sentence exactly as it pre-empts any
`milestone` or `countdown` cue today.

### 4.2 Variety and repeats

Quote selection reuses the existing `_pickPhrase(TrainerEventKind.quote)`, which prefers
unheard phrases and only recycles once the bank is exhausted, recording each pick in
`_spokenPhrases`. The "no quote repeats within a session until the bank is exhausted"
criterion is satisfied by reuse rather than by new logic.

### 4.3 Quote memory across a persona switch

Issue #102 flags that "a persona switch resets `_spokenPhrases`". **That is no longer
true.** Fix round 1 of #99 changed `CoachBridge` from discarding the engine on a voice
change to `_engine.persona = personaForId(...)` in place (`coaching_engine.dart:45`),
which leaves `_spokenPhrases` intact. Since `_quoteBank` is the same `const` list in all
three packs, a quote already heard under Steady is still recognised as heard under Hype.

No fix is required. The behaviour is covered by a regression test (§7) so it cannot
silently regress the moment it starts to matter.

## 5. Presentation changes

### 5.1 Localisable join

New ARB entry:

```json
"coachCueWithQuote": "{cue} {quote}"
```

`CoachBridge._onEvent` resolves both keys and combines them through `S.coachCueWithQuote`
rather than concatenating with a hardcoded space. `app_en.arb` has ja/ko/zh siblings
where a bare inter-sentence space is wrong, and the codebase's rule is that no
user-facing text is assembled outside the ARB.

When `quotePhraseKey` is null the bridge speaks the resolved primary exactly as today —
the join is not entered.

If either key fails to resolve, the bridge speaks whatever did resolve rather than
falling silent; `resolvePhrase` already returns null for an unknown key, and speech time
is the wrong place to lose a cue.

### 5.2 Rest-timer chime suppression

`coachAnnouncesRestEndProvider` exists so the rest-timer chime stands down when the
coach will speak at rest end: on Android the chime takes exclusive audio focus
(`AUDIOFOCUS_GAIN`) while the coach only asks to duck, so the two together cut the coach
off mid-sentence (issue #98). It currently returns `false` when countdowns are off,
because that was the only thing that could speak at rest end.

The standalone quote (§4, countdowns-off row) breaks that assumption: the coach now
speaks at rest end with countdowns off, and would be cut off by the chime.

The provider becomes a `Provider.family<bool, Duration>` keyed on the rest that just
finished:

```dart
if (!settings.enabled || !settings.disclaimerAccepted) return false;
if (!entitled) return false;
if (settings.countdownsEnabled) return true;
return settings.quotesEnabled && restDuration >= CoachingEngine.longRestThreshold;
```

`longRestThreshold` is promoted to a public `static const` on `CoachingEngine` so the
two-minute rule has exactly one definition; the widget must not carry its own copy.
`RestTimerNotifier` gains a `lastRestDuration` getter — needed anyway to emit
`RestFinished(restDuration:)` — so the widget can key the family.

**Accepted trade-off:** the provider cannot see the engine's `_encouragementBlocked`
state, so with countdowns off, quotes on, and a long rest ending while the user is above
their safety cap, the chime is suppressed but the quote is also suppressed — the user
gets vibration and silence. This is the right failure direction: above the cap a
`safety`-priority warning is the most likely thing playing, and a chime taking exclusive
audio focus is precisely what must not happen then.

### 5.3 Settings

`TrainerSettings` gains `quotesEnabled` (default `true`), pref key `trainer_quotes`,
mutator `setQuotes`, threaded through `copyWith` and `_load` like its five siblings.
`TrainerSettingsScreen` gains a `SwitchListTile` alongside the countdown and
encouragement switches, with new ARB label and subtitle strings.

`CoachBridge._onEvent` passes `quotesEnabled: settings.quotesEnabled` into `onEvent`.

## 6. Data changes

`persona_packs.dart`'s "**Not yet wired to any event**" doc block is removed — it is the
comment this work falsifies. The adjacent note that the per-quote sourcing table "should
move into this repo when #102 wires the bank up" is repointed at a new follow-up issue
(§8); the licensing rule itself stays where it is, since that is the paragraph an author
adding a quote actually reads.

The bank's contents do not change. It currently holds 21 quotes, not the "30+" the issue
text claims — rounds 2, 4 and 5 dropped Helen Keller, Muriel Strode and the Gummere
translation, leaving gaps at `coachQuote4` and `coachQuote11`.

## 7. Testing

Test-driven: each behaviour below gets a failing test before the code that satisfies it.

**Engine** (`coaching_engine_test.dart`) — one test per row of the §4 table, plus:
- a quote is suppressed while `_aboveCap`, in caution mode, and in zone 5;
- cycling the full bank produces as many distinct quotes as the bank holds before any
  repeat (asserted against the bank's own length, so adding or dropping a quote does
  not require editing the test);
- `quotesEnabled: false` leaves `_spokenPhrases` untouched, proving a suppressed quote
  does not consume the bank.

**End-to-end** (`coach_bridge_test.dart`) — the acceptance-criterion test. A fake
`SpeechService` records spoken text; after a `WorkoutStarted` the recorded string
contains an actual quote from the bank. This asserts spoken output, not bank contents:
it is the test that would have failed against `main` today.

**Regression** (`coach_bridge_test.dart`) — quote memory survives a persona switch
(§4.3): exhaust part of the bank under Steady, switch to Hype, assert no already-heard
quote returns.

**Emitter** (`rest_timer_widget_test.dart`) — `RestFinished` now carries the duration the
timer ran for.

**Chime suppression** (`coach_announces_rest_end_test.dart`) — the existing cases
re-expressed against the family, plus the new one: countdowns off, quotes on, a ≥2min
rest suppresses the chime; the same with a <2min rest does not.

**Settings** — `quotesEnabled` persists and restores; the switch renders and toggles.

## 8. Out of scope

The per-quote sourcing table (author, work, translation/edition, both death dates) gets
its own issue. It is research, not wiring: every translated entry — Marcus Aurelius,
Seneca, Epictetus, Lao Tzu, Socrates via Plato, Aristotle, Cervantes, Leonardo da Vinci
— needs its translator's death date verified against the life+70 rule, and any that
fail must be dropped. Folding that into this change risks shrinking the bank mid-review
for reasons unrelated to wiring it up.

## 9. Acceptance criteria

- [ ] A quote is spoken at workout start, and after rests of ≥2 minutes
- [ ] Quotes respect their own settings toggle, defaulting on
- [ ] Quotes never pre-empt or delay a heart-rate safety warning
- [ ] No quote repeats within a session until the bank is exhausted
- [ ] Test proving a quote is actually spoken end to end — not merely that the bank is
      non-empty
