# Product Requirements Document
## Heart Rate Monitoring for Exercise

**Version:** 1.0  
**Prepared for:** Product, Design, Engineering, and QA

| Field | Value |
|---|---|
| Document date | 07 March 2026 |
| Primary objective | Provide safe, understandable heart-rate guidance during exercise using estimated zones, personalized calculations, and caution handling for medical edge cases. |
| Release target | MVP with age-based and HRR zone calculations, onboarding, warnings, and chart overlays. |

**Product principle:** The application must present heart-rate zones as estimated training guidance, not medical diagnosis or emergency monitoring.

## 1. Purpose and scope

This product provides live heart-rate monitoring during exercise, color-coded intensity zones, and post-session summaries. It must support general fitness users while handling medical caveats carefully. The scope includes onboarding, calculation methods, graph behavior, warnings, user education, and engineering rules for zone computation and UI behavior.

### Objectives

- Help users understand current exercise intensity through clear graph overlays and time-in-zone summaries.
- Support multiple heart-rate calculation methods so the app is not dependent on a single age-based formula.
- Protect users by reducing overconfident coaching when medication, heart disease, or user-reported symptoms make heart-rate guidance less reliable.
- Create a foundation that can be extended later to wearables, clinician-defined programs, and advanced training analytics.

### Out of scope for MVP

- Diagnosis, treatment recommendations, or automated detection of heart disease.
- Emergency response workflows beyond warning messages and stop-exercise prompts.
- Full cardiac rehabilitation workflows or regulatory medical-device features.
- Personalized training plans generated from historical performance.

## 2. User problems and personas

Users want a simple answer to the question, *“How hard am I working right now?”* Many also want reassurance that the app is not encouraging unsafe intensity. The product must serve casual exercisers, regular exercisers, and users with medical caution flags.

### Primary personas

| Persona | Context | Needs | Default mode |
|---|---|---|---|
| Casual exerciser | Walking, jogging, cycling | Understand easy, moderate, and hard effort quickly | Age-based zones |
| Regular exerciser | Structured workouts, wearable data | More personalized intensity guidance and summaries | HRR if resting HR is known |
| Medical caution user | Beta blocker, heart condition, clinician cap | Safer defaults, warning visibility, manual caps | Caution mode with reduced coaching |

## 3. Product principles

- **Estimated rather than absolute.** The app must clearly distinguish estimated maximum heart rate, measured peak heart rate, and clinician-provided limits.
- **Safety before performance.** Caution mode must suppress aggressive coaching when reliability is low.
- **Progressive personalization.** Start simple, improve when the user provides resting heart rate, measured max heart rate, or custom limits.
- **Transparent confidence.** The UI should communicate when calculations are high, medium, or low reliability.

## 4. Functional requirements

### 4.1 Onboarding questions

The application must ask the following onboarding questions before showing personalized zones.

| Field | Required | Purpose | MVP | Status |
|---|---|---|---|---|
| Age | Yes | Baseline for age-estimated maximum heart rate | Yes | **Done** — `HealthProfileNotifier.updateAge()` |
| Resting heart rate | No | Enables HRR/Karvonen calculation | Yes | **Done** — `HealthProfileNotifier.updateRestingHeartRate()` |
| Known measured max heart rate | No | Improves personalization versus age estimate | Yes | **Done** — `HealthProfileNotifier.updateMeasuredMaxHeartRate()` |
| Taking beta blocker or heart-rate-lowering medication | No | Triggers caution mode and reduced reliability | Yes | **Done** — `HealthProfileNotifier.setTakingBetaBlocker()` |
| Heart condition, arrhythmia, angina, heart failure, or exercise chest pain history | No | Triggers caution mode and custom limit workflow | Yes | **Done** — `HealthProfileNotifier.setHasHeartCondition()` |
| Clinician-provided max exercise HR or custom cap | No | Overrides standard calculations when supplied | Yes | **Done** — `HealthProfileNotifier.setClinicianMaxHr()` |
| Primary goal: general fitness / endurance / intervals | No | Tones copy and summary emphasis | Future | Not started |

#### Onboarding requirements

- The app must explain why each optional field improves guidance. **Done** — each onboarding step includes explanatory text.
- The app must allow users to skip non-required fields. **Done** — Skip button on each step.
- The app must allow users to return later and edit health and zone preferences. **Done** — Settings screen "Health Profile" section and "Set Up Heart Rate Zones" tile.
- If a user selects medication or heart-condition flags, the app must enter caution mode immediately. **Done** — `HealthProfile.isCautionMode` is reactive; `CautionBadge` appears instantly.
- The app must never imply that skipping health fields makes the app unsafe to use; instead it should explain that estimates will be less personalized. **Done** — copy says "less personalised", not "unsafe".

### 4.2 Zone calculation methods

The product must support the following zone methods and choose the safest applicable method in this priority order.

| Priority | Method | When used | Reliability | Status |
|---|---|---|---|---|
| 1 | Custom zones | User or clinician enters exact zone boundaries | High | **Done** — `ZoneMethod.custom` |
| 2 | Clinician cap / custom max HR | User has prescribed or trusted maximum exercise HR | High | **Done** — `ZoneMethod.clinicianCap` |
| 3 | HRR (Karvonen) | Resting HR exists and no caution flags reduce validity | Medium to high | **Done** — `ZoneMethod.hrr` |
| 4 | Percent of known measured max HR | Measured max exists but HRR is not used | High | **Done** — `ZoneMethod.percentOfMeasuredMax` |
| 5 | Percent of estimated max HR | Fallback when only age is available | Medium | **Done** — `ZoneMethod.percentOfEstimatedMax` |

#### Default five-zone model

- **Zone 1:** 50–60% of reference maximum or HRR target
- **Zone 2:** 60–70%
- **Zone 3:** 70–80%
- **Zone 4:** 80–90%
- **Zone 5:** 90–100%

The chart legend should use practical labels such as **Easy / Recovery**, **Light Aerobic**, **Moderate**, **Hard**, and **Very Hard**. Avoid making claims such as *”optimal heart rate”* or *”safe zone”* unless the source is clinician-defined.

**Status:** **Done** — dual labels implemented (e.g. “Easy (Recovery)”, “Moderate (Aerobic)”, “Hard (Anaerobic)”, “Very Hard (VO₂ Max)”) via `CalculatedZone.displayLabel`.

#### Calculation rules

- The calculator must preserve both the percentage boundaries and the resulting BPM thresholds. **Done** — `CalculatedZone` stores `lowerPercent`, `upperPercent`, `lowerBpm`, `upperBpm`.
- The system must distinguish between:
    - estimated max HR — **Done** (`ZoneMethod.percentOfEstimatedMax`)
    - known measured max HR — **Done** (`ZoneMethod.percentOfMeasuredMax`)
    - clinician-provided max HR — **Done** (`ZoneMethod.clinicianCap`)
    - custom zones — **Done** (`ZoneMethod.custom`)
- For caution-mode users, the app must still be able to display HR values but must reduce confidence and suppress aggressive coaching. **Done** — caution mode sets `ZoneReliability.low`, shows `CautionBadge`, and no “push harder” coaching exists.
- If resting HR is available and caution mode is not active, HRR/Karvonen should be the default personalized method. **Done** — priority chain in `calculateZones()`.
- A fixed formula such as `(220 - age) × 0.8` must not be described as the user’s “best heart rate”; it is only one estimated intensity target. **Done** — no such claims in code or UI.

### 4.3 Example calculations

Engineering must use explicit formulas and preserve the percentage range used to derive each zone.

| Example | Formula | Inputs | Result |
|---|---|---|---|
| Estimated max HR | `220 − age` | age = 49 | 171 bpm |
| 80% of estimated max | `171 × 0.80` | max = 171 | 137 bpm |
| HRR target at 80% | `resting + 0.80 × (max − resting)` | resting = 58, max = 171 | 148 bpm |
| Zone 3 HRR lower bound | `58 + 0.70 × (171 − 58)` | 70% | 137 bpm |
| Zone 3 HRR upper bound | `58 + 0.80 × (171 − 58)` | 80% | 148 bpm |

#### Worked example

For a 49-year-old user with a resting heart rate of 58 bpm:

1. Estimated max HR = `220 - 49 = 171 bpm`
2. A simple 80% line using percent-of-max = `171 × 0.80 = 136.8`, rounded to **137 bpm**
3. An HRR/Karvonen 80% target = `58 + 0.80 × (171 - 58)`  
   = `58 + 0.80 × 113`  
   = `58 + 90.4`  
   = **148 bpm**
4. Zone 3 using HRR becomes **137–148 bpm**

This example shows why a fixed line such as `(220 − age) × 0.8` should not be described as the user’s best heart rate. It is one intensity target, not a universal prescription.

## 5. UI and graph requirements

### 5.1 Live exercise graphs

The application must provide two simultaneous heart rate charts during active monitoring:

| Chart | Description | Status |
|---|---|---|
| Recent (sliding window) | Shows the most recent N seconds of readings. Default window is 60 seconds. User-configurable: 30s, 60s, 90s, 120s, 300s via a dropdown. Provides a zoomed-in view of current effort. | **Done** — `HeartRateChart` with `windowSeconds` parameter; `ChartWindowNotifier` persists selection. |
| Full session | Shows all readings from session start. Provides the big-picture view of the entire workout. No sliding window. | **Done** — `HeartRateChart` without `windowSeconds`. |

Both charts must:

- Display the current heart-rate line over coloured background bands representing active zones. **Done** — `_zoneAnnotations()` reads from `ZoneConfiguration.zones`.
- Show zone bands derived from the selected calculation method (not hardcoded). **Done** — bands from `ZoneConfiguration`.
- Expose threshold lines for at least 50%, 60%, 70%, 80%, 90%, and 100% of the selected method reference. **Partial** — zone bands shown as horizontal range annotations; explicit threshold lines not yet drawn.
- Show the current heart rate, current zone label, session average heart rate, session peak heart rate, and elapsed time. **Done** — HR display card + stats card.
- Apply smoothing to reduce flicker from short-lived sensor spikes. **Done** — `curveSmoothness: 0.15` on the line chart.
- Allow users to disable red-zone colour or set a custom cap if they prefer conservative visual behaviour. **Partial** — clinician cap overrides zones; dedicated colour toggle not yet implemented.

### 5.2 Session summaries

The session summary must include:

- Time spent in each zone — **Done** — `TimeInZoneSummary.zoneTime` with per-zone progress bars (`_ZoneTimeBar`)
- Total time in moderate-or-higher intensity — **Done** — `TimeInZoneSummary.moderateOrHigher`
- Average heart rate — **Done** — stats card
- Peak heart rate — **Done** — stats card
- Recovery heart-rate drop after exercise, if available — **Done** — `TimeInZoneSummary.recoveryHrDrop`

### 5.3 Reliability and caution indicators

The UI must show a reliability indicator: **Done** — `ReliabilityIndicator` widget with colour-coded icon and tooltip.

- **High:** custom zones, clinician cap, or measured max HR with good supporting data — **Done**
- **Medium:** age-estimated max HR or HRR using estimated max — **Done**
- **Low:** medication affecting heart rate, heart-condition mode, or missing key personalization data — **Done**

When caution mode is active, the UI must:

- display a visible caution badge — **Done** — `CautionBadge` widget (amber card with warning icon)
- suppress “push harder” style coaching — **Done** — no coaching copy exists; caution badge shown instead
- encourage the use of effort level, talk test, and clinician advice — **Done** — caution badge copy references RPE, talk test, and clinician advice
- clearly mark when clinician-provided caps are in use — **Done** — “Clinician-provided limits in use” marker in `HeartRateZoneLegend`

## 6. Warning and safety requirements

### 6.1 General warning policy

The product must present warnings clearly without creating false reassurance or medical claims.

| Scenario | Required message behavior | Status |
|---|---|---|
| General onboarding | State that zones are estimates for exercise guidance and are not medical advice or emergency monitoring. | **Done** — `disclaimer_dialog.dart` shown on first visit |
| Beta blocker or HR-lowering medication selected | Show that heart-rate targets may be less reliable and recommend using effort level and clinician advice. | **Done** — `WarningMessages.betaBlockerWarning` shown in `CautionBadge` |
| Heart condition selected | State that clinician-provided limits should override standard zone formulas where available. | **Done** — `WarningMessages.heartConditionWarning` shown in `CautionBadge` |
| Chest pain, severe dizziness, fainting, or unusual shortness of breath reported during exercise | Immediately show a stop-exercise prompt and urgent-help messaging appropriate to severity and locale. | **Done** — `SymptomReportButton` → symptom selection → stop-exercise dialog |
| Custom clinician cap entered | Visibly mark that the session is using clinician-provided limits. | **Done** — "Clinician-provided limits in use" in zone legend |

### 6.2 In-exercise warnings

If the user reports or the UI prompts for symptoms such as chest pain, severe dizziness, fainting, or unusual shortness of breath:

- Immediately interrupt coaching-oriented UI — **Done** — `onStopRequested` callback stops monitoring
- Show a stop-exercise message — **Done** — `WarningMessages.stopExercisePrompt` in stop-exercise dialog
- Show urgent-help guidance appropriate to locale and severity — **Done** — "I need help" and "I'm OK, stopping exercise" options
- Do not continue encouraging intensity progression in the same session — **Done** — monitoring stopped on symptom report

### 6.3 Restricted claims

The product must not claim to:

- diagnose heart disease
- determine exercise safety for a specific medical condition
- detect emergencies solely from consumer heart-rate data
- prescribe a medically safe maximum heart rate unless explicitly configured from clinician-provided input

## 7. Decision logic

| Condition | System behavior | UX effect | Status |
|---|---|---|---|
| Custom zones exist | Use custom zones | High-confidence, exact thresholds displayed | **Done** |
| Clinician cap exists | Use clinician cap | Mark as clinician-provided | **Done** |
| Beta blocker or heart condition | Enable caution mode | Low reliability, use RPE and suppress aggressive coaching | **Done** |
| Resting HR exists and no caution flags | Use HRR/Karvonen by default | More personalized training zones | **Done** |
| Only age known | Use age-estimated maximum | Medium reliability estimated zones | **Done** |

### Selection logic

All implemented in `calculateZones()` in `lib/features/heart_rate/domain/zone_calculator.dart`:

1. If custom zones exist, use them. **Done**
2. Else if a clinician-provided cap exists, use it. **Done**
3. Else if caution mode is active, use the safest available display mode and lower reliability. **Done**
4. Else if resting HR exists, use HRR/Karvonen. **Done**
5. Else use age-estimated maximum HR. **Done**

## 8. Non-functional requirements

- Calculations must be deterministic and testable. **Done** — pure Dart functions with 32 unit tests.
- Rounding rules must be consistent across platforms. **Done** — `round()` used consistently in zone calculator.
- The product must support localization of warnings and urgent-help text. **Partial** — string constants in `warning_messages.dart` are localisation-ready but not yet externalised to `.arb` files.
- Accessibility must support color-blind-friendly rendering; zone labels must not rely on color alone. **Done** — zones have textual labels alongside colour swatches.
- The graph must remain readable under rapid sensor updates and low-connectivity conditions. **Done** — chart uses 200ms animation duration and curved smoothing.

## 9. Analytics and telemetry

For MVP, capture anonymous product telemetry where permitted:

- onboarding completion rate — **Done** — `HrAnalyticsEvent.onboardingCompleted`
- optional health-field completion rate — **Done** — `HrAnalyticsEvent.healthFieldCompleted`
- frequency of caution mode activation — **Done** — `HrAnalyticsEvent.cautionModeActivated`
- selected zone method — **Done** — `HrAnalyticsEvent.zoneMethodSelected`
- frequency of custom cap usage — **Done** — `HrAnalyticsEvent.customCapUsed`
- time-in-zone summary usage — **Done** — `HrAnalyticsEvent.timeInZoneSummaryViewed`
- warning prompt display counts — **Done** — `HrAnalyticsEvent.warningDisplayed`

Do not log sensitive free-text medical details unless specifically designed, consented, and secured for that purpose.

**Status:** Analytics event infrastructure is **Done** (`HrAnalyticsReporter` interface + `NoopAnalyticsReporter` for MVP). Events are defined but firing points are wired to no-op; a production reporter can be swapped in via `hrAnalyticsReporterProvider`.

## 10. Acceptance criteria

### Onboarding

- Users can complete onboarding with age only. **Done** — tested manually and via onboarding flow.
- Users can optionally add resting HR, measured max HR, medication, heart-condition flags, and clinician cap. **Done**
- Medication or heart-condition selection immediately affects the chosen calculation mode and warning copy. **Done**

### Calculations

- Given age 49, percent-of-max estimated max HR returns 171 bpm. **Done** — `zone_calculator_test.dart`
- Given age 49 and resting HR 58, HRR at 80% returns 148 bpm. **Done** — `zone_calculator_test.dart`
- Given custom zones, system ignores age-based and HRR calculations for graph thresholds. **Done** — `zone_calculator_test.dart`
- Given clinician cap, the graph displays clinician-provided thresholds and marks them accordingly. **Done** — `zone_calculator_test.dart` + "Clinician-provided limits in use" marker

### Warnings

- General disclaimer appears during onboarding and in settings. **Done**
- Caution-mode users see reduced-reliability messaging. **Done**
- Symptom-triggered warnings interrupt normal workout coaching. **Done**

### UI

- The graph displays coloured zone bands plus textual zone labels. **Done**
- Two charts: recent sliding window (configurable 30s–5m) and full session. **Done**
- Time-in-zone and peak/average HR are present in session summary. **Done**
- Reliability level is visible in the session UI or settings detail. **Done**

## 11. Future enhancements

- Wearable-specific sensor confidence scoring
- Talk-test and perceived-exertion overlays
- Coach mode tuned to workout type
- Advanced recovery metrics
- Clinician-shared programs and exported reports
- Adaptive zones based on validated historical performance
