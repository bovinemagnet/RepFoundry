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

| Field | Required | Purpose | MVP |
|---|---|---|---|
| Age | Yes | Baseline for age-estimated maximum heart rate | Yes |
| Resting heart rate | No | Enables HRR/Karvonen calculation | Yes |
| Known measured max heart rate | No | Improves personalization versus age estimate | Yes |
| Taking beta blocker or heart-rate-lowering medication | No | Triggers caution mode and reduced reliability | Yes |
| Heart condition, arrhythmia, angina, heart failure, or exercise chest pain history | No | Triggers caution mode and custom limit workflow | Yes |
| Clinician-provided max exercise HR or custom cap | No | Overrides standard calculations when supplied | Yes |
| Primary goal: general fitness / endurance / intervals | No | Tones copy and summary emphasis | Future |

#### Onboarding requirements

- The app must explain why each optional field improves guidance.
- The app must allow users to skip non-required fields.
- The app must allow users to return later and edit health and zone preferences.
- If a user selects medication or heart-condition flags, the app must enter caution mode immediately.
- The app must never imply that skipping health fields makes the app unsafe to use; instead it should explain that estimates will be less personalized.

### 4.2 Zone calculation methods

The product must support the following zone methods and choose the safest applicable method in this priority order.

| Priority | Method | When used | Reliability |
|---|---|---|---|
| 1 | Custom zones | User or clinician enters exact zone boundaries | High |
| 2 | Clinician cap / custom max HR | User has prescribed or trusted maximum exercise HR | High |
| 3 | HRR (Karvonen) | Resting HR exists and no caution flags reduce validity | Medium to high |
| 4 | Percent of known measured max HR | Measured max exists but HRR is not used | High |
| 5 | Percent of estimated max HR | Fallback when only age is available | Medium |

#### Default five-zone model

- **Zone 1:** 50–60% of reference maximum or HRR target
- **Zone 2:** 60–70%
- **Zone 3:** 70–80%
- **Zone 4:** 80–90%
- **Zone 5:** 90–100%

The chart legend should use practical labels such as **Easy / Recovery**, **Light Aerobic**, **Moderate**, **Hard**, and **Very Hard**. Avoid making claims such as *“optimal heart rate”* or *“safe zone”* unless the source is clinician-defined.

#### Calculation rules

- The calculator must preserve both the percentage boundaries and the resulting BPM thresholds.
- The system must distinguish between:
    - estimated max HR
    - known measured max HR
    - clinician-provided max HR
    - custom zones
- For caution-mode users, the app must still be able to display HR values but must reduce confidence and suppress aggressive coaching.
- If resting HR is available and caution mode is not active, HRR/Karvonen should be the default personalized method.
- A fixed formula such as `(220 - age) × 0.8` must not be described as the user’s “best heart rate”; it is only one estimated intensity target.

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

### 5.1 Live exercise graph

- Display the current heart-rate line over colored background bands representing active zones.
- Expose threshold lines for at least 50%, 60%, 70%, 80%, 90%, and 100% of the selected method reference.
- Show the current heart rate, current zone label, session average heart rate, session peak heart rate, and elapsed time.
- Apply smoothing to reduce flicker from short-lived sensor spikes.
- Allow users to disable red-zone color or set a custom cap if they prefer conservative visual behavior.

### 5.2 Session summaries

The session summary must include:

- Time spent in each zone
- Total time in moderate-or-higher intensity
- Average heart rate
- Peak heart rate
- Recovery heart-rate drop after exercise, if available

### 5.3 Reliability and caution indicators

The UI must show a reliability indicator:

- **High:** custom zones, clinician cap, or measured max HR with good supporting data
- **Medium:** age-estimated max HR or HRR using estimated max
- **Low:** medication affecting heart rate, heart-condition mode, or missing key personalization data

When caution mode is active, the UI must:

- display a visible caution badge
- suppress “push harder” style coaching
- encourage the use of effort level, talk test, and clinician advice
- clearly mark when clinician-provided caps are in use

## 6. Warning and safety requirements

### 6.1 General warning policy

The product must present warnings clearly without creating false reassurance or medical claims.

| Scenario | Required message behavior |
|---|---|
| General onboarding | State that zones are estimates for exercise guidance and are not medical advice or emergency monitoring. |
| Beta blocker or HR-lowering medication selected | Show that heart-rate targets may be less reliable and recommend using effort level and clinician advice. |
| Heart condition selected | State that clinician-provided limits should override standard zone formulas where available. |
| Chest pain, severe dizziness, fainting, or unusual shortness of breath reported during exercise | Immediately show a stop-exercise prompt and urgent-help messaging appropriate to severity and locale. |
| Custom clinician cap entered | Visibly mark that the session is using clinician-provided limits. |

### 6.2 In-exercise warnings

If the user reports or the UI prompts for symptoms such as chest pain, severe dizziness, fainting, or unusual shortness of breath:

- Immediately interrupt coaching-oriented UI
- Show a stop-exercise message
- Show urgent-help guidance appropriate to locale and severity
- Do not continue encouraging intensity progression in the same session

### 6.3 Restricted claims

The product must not claim to:

- diagnose heart disease
- determine exercise safety for a specific medical condition
- detect emergencies solely from consumer heart-rate data
- prescribe a medically safe maximum heart rate unless explicitly configured from clinician-provided input

## 7. Decision logic

| Condition | System behavior | UX effect |
|---|---|---|
| Custom zones exist | Use custom zones | High-confidence, exact thresholds displayed |
| Clinician cap exists | Use clinician cap | Mark as clinician-provided |
| Beta blocker or heart condition | Enable caution mode | Low reliability, use RPE and suppress aggressive coaching |
| Resting HR exists and no caution flags | Use HRR/Karvonen by default | More personalized training zones |
| Only age known | Use age-estimated maximum | Medium reliability estimated zones |

### Selection logic

1. If custom zones exist, use them.
2. Else if a clinician-provided cap exists, use it.
3. Else if caution mode is active, use the safest available display mode and lower reliability.
4. Else if resting HR exists, use HRR/Karvonen.
5. Else use age-estimated maximum HR.

## 8. Non-functional requirements

- Calculations must be deterministic and testable.
- Rounding rules must be consistent across platforms.
- The product must support localization of warnings and urgent-help text.
- Accessibility must support color-blind-friendly rendering; zone labels must not rely on color alone.
- The graph must remain readable under rapid sensor updates and low-connectivity conditions.

## 9. Analytics and telemetry

For MVP, capture anonymous product telemetry where permitted:

- onboarding completion rate
- optional health-field completion rate
- frequency of caution mode activation
- selected zone method
- frequency of custom cap usage
- time-in-zone summary usage
- warning prompt display counts

Do not log sensitive free-text medical details unless specifically designed, consented, and secured for that purpose.

## 10. Acceptance criteria

### Onboarding

- Users can complete onboarding with age only.
- Users can optionally add resting HR, measured max HR, medication, heart-condition flags, and clinician cap.
- Medication or heart-condition selection immediately affects the chosen calculation mode and warning copy.

### Calculations

- Given age 49, percent-of-max estimated max HR returns 171 bpm.
- Given age 49 and resting HR 58, HRR at 80% returns 148 bpm.
- Given custom zones, system ignores age-based and HRR calculations for graph thresholds.
- Given clinician cap, the graph displays clinician-provided thresholds and marks them accordingly.

### Warnings

- General disclaimer appears during onboarding and in settings.
- Caution-mode users see reduced-reliability messaging.
- Symptom-triggered warnings interrupt normal workout coaching.

### UI

- The graph displays colored zone bands plus textual zone labels.
- Time-in-zone and peak/average HR are present in session summary.
- Reliability level is visible in the session UI or settings detail.

## 11. Future enhancements

- Wearable-specific sensor confidence scoring
- Talk-test and perceived-exertion overlays
- Coach mode tuned to workout type
- Advanced recovery metrics
- Clinician-shared programs and exported reports
- Adaptive zones based on validated historical performance
