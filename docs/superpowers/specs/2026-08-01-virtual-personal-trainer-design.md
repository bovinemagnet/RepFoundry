# Virtual Personal Trainer ("Coach") — Design Specification

**Date:** 2026-08-01
**Author:** Paul Snow
**Status:** Approved for planning
**Feature type:** Paid add-on (entitlement-gated)

## 1. Summary

An audio-only workout companion that talks to the user through their headphones during
strength workouts: encouragement after logged sets, rest-timer countdowns, PR
celebrations, and inspirational quotes. In later phases it becomes heart-rate aware,
calling out training zones and warning when the user exceeds their safe maximum.

It is explicitly a **companion, not a personal trainer**: it never prescribes load,
never urges the user to push through pain, and gates itself behind a first-use
disclaimer. Speech starts with on-device text-to-speech (TTS) and evolves towards
premium neural voices in a future phase.

### Goals

- Motivate users to complete sessions and stay consistent.
- Reduce injury risk: safety-first language rules, HR cap warnings, caution mode.
- Establish the app's first paid feature boundary via a clean entitlement seam.

### Non-goals

- Programme prescription, load recommendations, or form coaching.
- Medical advice of any kind.
- Conversational/interactive AI voice (future consideration, out of scope here).

## 2. Market context

- **Pre-recorded human audio** (Nike Run Club, Peloton): premium feel, huge content
  cost, nothing reacts to the user's live data.
- **Reactive TTS coaches** (Flaims, Zone Trainer, Voice Rep Counter Coach): closest
  analogues. Flaims speaks on HR-zone changes and milestones but is Apple-Watch-only
  and cardio-leaning; Zone Trainer proves BLE-HR voice alerts work on Android.
- **Gap RepFoundry occupies:** a strength-first audio companion reacting to logged
  sets, rest timers, and a chest-strap HR feed, with clinical-grade safety caps
  (clinician cap, beta-blocker caution mode) that no competitor has.

## 3. Decisions taken

| Decision | Choice |
| --- | --- |
| Monetisation | Entitlement abstraction now; store IAP in a later phase |
| V1 surface | Strength workouts + rest timer only; HR-aware is phase 2 |
| Personas | Selectable tone packs (Steady in v1; Hype and Sergeant in phase 2) |
| Safety posture | Conservative: above cap, encouragement stops and only "ease off" prompts play |
| Audio mixing | Duck other apps' audio ~50% while speaking, then restore |
| Architecture | Event-driven coaching engine (approach A, below) |

### Approaches considered

- **A. Event-driven coaching engine (chosen):** typed events from existing
  controllers feed a pure-Dart engine that selects cues; a `SpeechService`
  interface wraps TTS. Fully unit-testable; phase 2 HR work is a new event source,
  not a rework.
- **B. Presentation-layer listeners:** `ref.listen()` in widgets calling TTS
  directly. Fastest, but coaching logic lands in presentation and phase 2 duplicates
  it.
- **C. Standalone foreground-service coach:** background speech from day one.
  Heavy platform work; v1 triggers already require the app in use. Rejected for now;
  screen-off speech is solved in phase 4 within approach A.

## 4. Architecture

### 4.1 Layout

```
lib/core/entitlements/
  entitlement.dart            // enum Entitlement { virtualTrainer }
  entitlement_service.dart    // abstract EntitlementService { bool has(Entitlement) }
  entitlement_provider.dart   // Provider<EntitlementService>; LocalEntitlementService for now
lib/features/trainer/
  domain/
    trainer_event.dart        // sealed event types
    coaching_cue.dart         // text + SpeechPriority
    persona.dart              // persona id + metadata
    speech_service.dart       // abstract interface
  application/
    coaching_engine.dart      // pure Dart: events in -> cues out
  data/
    flutter_tts_speech_service.dart
    persona_packs.dart        // phrase banks (keys into ARB)
  presentation/
    providers/                // trainerEventBus, trainerSettings, engine wiring
    screens/trainer_settings_screen.dart
    widgets/trainer_status_chip.dart, trainer_disclaimer_sheet.dart
```

### 4.2 Entitlement seam

`EntitlementService.has(Entitlement.virtualTrainer)` is the **single** gate.

- V1 ships `LocalEntitlementService`: a SharedPreferences flag, unlockable via a
  dev/beta toggle in Settings → About.
- A future `IapEntitlementService` (Play Billing / StoreKit via `in_app_purchase`)
  swaps in behind the same interface when the app lists on stores.
- No trainer code checks a raw bool — always the service — so the paid boundary is
  one seam.

### 4.3 Event flow

```
ActiveWorkoutController ──┐
RestTimerNotifier ────────┼──> trainerEventBus ──> CoachingEngine ──> SpeechService.speak(cue)
LogSetUseCase (PR flag) ──┘        (stream)
```

Event types (v1): `workoutStarted`, `setLogged(setNumber, isPr)`,
`restStarted(duration)`, `restCountdown(secondsLeft: 3|2|1)`, `restFinished`,
`workoutFinished(summary)`.

Producers fire-and-forget; each is a one-line addition at an existing trigger point.
If the trainer is disabled or unentitled the bus provider is never built, so the
cost to non-payers is zero.

### 4.4 Coaching engine rules (pure Dart, no Flutter imports)

- **Priority:** safety > countdown > milestone (PR, workout finish) > encouragement.
  A higher-priority cue interrupts (stops) a lower-priority one mid-speech.
- **Cooldown:** no encouragement within 20 s of the previous utterance; countdowns
  and safety cues are exempt.
- **Quota:** encouragement on roughly every 2nd–3rd logged set (randomised), never
  every set — constant chatter is the top complaint about comparable apps.
- **Variety:** never repeat a phrase within a session; random selection from the
  active persona's bank for that event type.

### 4.5 Speech service

Interface: `speak(String text, {SpeechPriority priority})`, `stop()`, `dispose()`.

`FlutterTtsSpeechService` (package `flutter_tts`):

- iOS: `AVAudioSession` with `duckOthers`; Android: audio focus
  `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` — other audio dips ~50% during a phrase and
  restores afterwards.
- Speech rate and pitch configurable from settings; sensible defaults per platform.
- `SilentSpeechService` fake for tests.

## 5. Personas and content

Three tone packs, pure data (phrase keys into `app_en.arb`, with placeholders such
as `{setNumber}`):

| Persona | Tone | Example |
| --- | --- | --- |
| Steady (v1) | Calm, measured | "Good set. Breathe, reset, go again when you're ready." |
| Hype (phase 2) | Energetic | "That's {setNumber} down — you're on fire!" |
| Sergeant (phase 2) | Firm, never demeaning | "Rest's over. Bar's waiting. Move." |

- Shared **quote bank** (phase 2): ~40 public-domain or attributed inspirational
  quotes, spoken at workout start and after rest periods of two minutes or longer.
- Every event type has at least 3 phrases per persona (tested).
- All strings externalised per the project l10n convention.

### Content language rules (enforced in review, noted in each content PR)

- Never urge load increases, "push through pain", or ego-lifting.
- Praise completion and consistency, never intensity escalation.
- No body-shaming, no guilt framing ("you skipped Monday…" is banned).

## 6. Safety

- **First-use disclaimer gate:** the trainer will not speak until the user accepts a
  disclaimer sheet (pattern reused from the HR panel first-use disclaimer):
  companion not a personal trainer; not medical advice; stop if you feel pain,
  dizziness, or chest discomfort. Acceptance persisted; revocable in settings.
- **Phase 2 HR rules** (subscribes to the existing HR stream and
  `zone_bands_provider`):
  - Zone-entry callouts ("entering Zone 3 — moderate").
  - Above clinician cap or estimated max: all encouragement suppressed; calm
    "ease off, bring your heart rate down" repeated every 30 s until below cap.
  - Caution mode (medical flags set in `HealthProfile`): informational callouts
    only — no "push harder" style lines at any intensity.
  - Encouragement never escalates intensity above Zone 4 for any user.
- **Exercise auto-detection** (phase 3): sustained elevated HR with no active
  session prompts "looks like you're working — want company?"; same rules apply.

## 7. Settings UI

Trainer settings screen (entitlement-gated entry point in Settings):

- Master enable/disable.
- Persona picker.
- Speech rate slider; test-speak button.
- Independent toggles: rest countdowns, encouragement, quotes, (phase 2) HR
  callouts, HR safety warnings (safety warnings default ON and are the last thing
  listed, with copy explaining why leaving them on is recommended).
- Disclaimer status and re-display link.
- "Voice unavailable" notice when no TTS engine is present on the device.

## 8. Error handling

- TTS is best-effort, mirroring the sync design principle: any `flutter_tts`
  failure is swallowed and logged, never surfacing into the workout flow.
- Missing TTS engine (some de-Googled Android devices): settings shows a notice;
  everything else degrades silently.
- Speech stops immediately on workout finish/discard and on app pause. This is a
  **known v1 limitation**: with the phone locked or the app backgrounded, the coach
  goes quiet — the most common gym posture. Phase 4 is dedicated to solving it
  (Android foreground service, following the existing cardio
  `foreground_session_service.dart` prior art; iOS background audio mode).

## 9. Testing

- **CoachingEngine unit tests** (target ≥80%): cooldown windows, priority
  pre-emption, quota randomisation bounds, no-repeat guarantee, event → cue mapping.
- **Persona pack tests:** every event type has ≥3 phrases per persona; placeholders
  resolve; no banned-language regressions (simple denylist check).
- **Widget tests** with `SilentSpeechService`: disclaimer gate blocks speech;
  entitlement gate hides the feature; settings toggles persist; TDD for changes to
  existing controllers (event emission).
- **Manual device matrix** (documented per release, not automatable): ducking
  behaviour on iOS and Android with music playing; Bluetooth headphone latency.

## 10. Phasing

Each phase is a shippable release.

| Phase | Contents |
| --- | --- |
| 0 | Entitlement scaffolding (`lib/core/entitlements/`), dev unlock toggle, settings stub |
| 1 (v1) | Event bus, coaching engine, `FlutterTtsSpeechService` with ducking, Steady persona, disclaimer gate, rest countdowns + encouragement + PR/finish milestones |
| 2 | HR-aware callouts (zones, cap warnings, caution mode), Hype + Sergeant personas, quote bank |
| 3 | Exercise auto-detection nudges |
| 4 | Background operation: coach keeps speaking with the screen off or the app backgrounded (Android foreground service, iOS background audio) |
| 5 (future) | Premium neural voices (downloadable or cloud), real store IAP via `IapEntitlementService` |

## 11. Dependencies

- New package: `flutter_tts` (phase 1).
- Possibly `audio_session` if `flutter_tts`'s built-in ducking options prove
  insufficient on either platform (decide during phase 1 spike).
- No backend, no network calls, offline-first — consistent with the rest of the app.
