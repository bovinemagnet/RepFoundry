# RepFoundry — Product Requirements Document

**Version 1.0 | March 2026**
**Platform: iOS & Android (Flutter)**

---

## 1. Executive Summary

RepFoundry is a cross-platform mobile application designed for gym-goers who want a simple, fast, and reliable way to log their workouts. The app tracks sets, reps, and weight for resistance machines, free weights, and bodyweight exercises, as well as duration, distance, and pace for cardio equipment like treadmills, ellipticals, and stationary bikes.

The primary goal is to replace paper workout logs and scattered note-taking with a purpose-built tool that works offline, launches fast, and gets out of the way during an active workout.

---

## 2. Problem Statement

Most gym-goers struggle with consistent workout tracking. Existing solutions fall into two camps: overly complex apps aimed at competitive athletes with steep learning curves, or generic note-taking apps that lack structure for workout data. The result is that most people either stop tracking or rely on memory, leading to inconsistent progressive overload and plateaued results.

---

## 3. Target Users

### 3.1 Primary Persona

Recreational gym-goers who train 3–5 times per week, use a mix of machines and free weights, and want to track progress without complexity. They are not competitive athletes and do not need periodization planning or macro tracking.

### 3.2 Secondary Persona

Beginners following a structured program (e.g., Starting Strength, PPL) who need guidance on what to do next and want to see their numbers going up over time.

---

## 4. Core Features

### 4.1 Workout Logging

| Feature | Description | Priority |
|---------|-------------|----------|
| Quick-add sets | Tap to log a set with weight and reps; auto-fills from previous session | P0 | *Implemented — ghost rows from previous session pre-fill the SetInputCard* |
| Exercise library | Pre-built list of common gym exercises categorised by muscle group and equipment type | P0 |
| Custom exercises | Users can create their own exercises with custom names and categories | P0 | *Note: domain model exists but no UI for creating custom exercises yet* |
| Rest timer | Configurable countdown timer between sets with vibration/sound alert | P0 | *Implemented — countdown with quick-start chips (1:00, 1:30, 2:00, 3:00); haptic vibration and audible beep on completion; alerts configurable in Settings* |
| Workout templates | Save and reuse workout routines (e.g., Push Day, Leg Day) | P1 |
| Superset support | Group exercises together as supersets or circuits | P2 |

### 4.2 Cardio Tracking

| Feature | Description | Priority |
|---------|-------------|----------|
| Duration tracking | Start/stop timer for treadmill, elliptical, bike, rowing sessions | P0 |
| Distance and pace | Manual entry of distance; calculated pace display | P0 |
| GPS distance | Live GPS-based distance and pace tracking for outdoor runs | P0 | *Implemented — toggle in cardio screen; accumulates distance from position stream* |
| Incline/resistance | Track machine incline or resistance level settings | P1 |
| Heart rate zones | Optional manual HR entry with zone classification | P2 |
| BLE heart rate streaming | Live heart rate from BLE monitors, Apple Watch (broadcast mode), Samsung Galaxy Watch, and chest straps (Polar, Garmin, Wahoo) | P1 | *Implemented — BLE HR Service 0x180D; auto-reconnect on drop; in-app setup guide for watch configuration* |

### 4.3 Progress and History

| Feature | Description | Priority |
|---------|-------------|----------|
| Workout history | Scrollable list of past workouts with date, exercises, and total volume | P0 |
| Exercise history | Per-exercise view showing weight/rep progression over time | P0 |
| Progress charts | Line charts for estimated 1RM, total volume, and frequency per muscle group | P1 | *Note: fl_chart dependency included but charts not yet implemented* |
| Personal records | Automatic PR detection and display with badges | P1 | *Note: domain model exists but automatic detection not yet wired up* |
| Body measurements | Optional logging of body weight, photos, and measurements | P2 |

### 4.4 User Experience

- Offline-first: all core functionality works without internet connectivity
- Sub-2-second cold start: the app must launch and be usable in under 2 seconds
- One-handed operation: primary logging actions reachable with the thumb
- Dark mode: default dark theme to reduce glare in gym lighting; light mode available
- Minimal navigation: three-tap maximum to start logging a set from any screen

---

## 5. Non-Functional Requirements

| Requirement | Target | Notes |
|-------------|--------|-------|
| Platform support | iOS 15+ and Android 10+ | Single codebase via Flutter |
| Offline capability | 100% core features offline | Cloud sync is additive, not required |
| App size | < 30 MB installed | Minimise bundled assets |
| Cold start time | < 2 seconds | Measured on mid-range devices |
| Data export | CSV and JSON | User-initiated export of all workout data — *not yet implemented* |
| Accessibility | WCAG 2.1 AA | Screen reader support, adequate contrast ratios |
| Localisation | English (launch), i18n-ready | String externalisation from day one |

---

## 6. Out of Scope (v1)

- Social features (sharing workouts, leaderboards, following other users)
- AI-generated workout plans or exercise recommendations
- Nutrition and calorie tracking
- Wearable device integration (Apple Watch, Wear OS) — planned for v2. *Note: live heart rate streaming from Apple Watch (BLE broadcast mode) and Samsung Galaxy Watch is now supported via standard BLE HR Service. Full companion app integration remains out of scope for v1.*
- Trainer/coach features and client management
- Video exercise demonstrations (link to external resources instead)

---

## 7. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| 7-day retention | > 60% | Users returning within 7 days of first workout |
| Workouts per user per week | > 2.5 | Average across active users in first month |
| Set logging time | < 5 seconds | Time from tapping +set to confirming entry |
| App store rating | > 4.5 stars | Combined iOS and Android average |
| Crash-free sessions | > 99.5% | Planned — Firebase Crashlytics |

---

## 8. Monetisation Strategy

The app will follow a freemium model:

- **Free tier:** unlimited workout logging, history, basic charts, data export
- **Pro tier ($4.99/month or $39.99/year):** advanced analytics, custom themes, cloud backup and sync across devices, unlimited workout templates

No ads will be shown in either tier. The free tier must be fully functional as a standalone workout tracker.

---

## 9. Release Plan

| Phase | Scope | Timeline | Status |
|-------|-------|----------|--------|
| Alpha | Core logging, exercise library, history view — internal testing | Weeks 1–6 | **Current** — core workout logging works with in-memory storage; no data persistence across restarts |
| Beta | Templates, rest timer, progress charts, cardio tracking — TestFlight/Play Console | Weeks 7–12 | Not started |
| v1.0 Launch | Full P0 + P1 features, both app stores | Week 14 | Not started |
| v1.1 | PR badges, body measurements, superset support | Week 18 | Not started |
| v2.0 | Cloud sync, wearable integration, social features | TBD | Not started |

---

## 10. Open Questions

1. Should the exercise library include animated GIF demonstrations, or link to external video resources?
2. What is the cloud sync provider preference (Firebase, Supabase, custom backend)?
3. Should the free tier limit the number of saved workout templates (e.g., 3)?
4. Is Apple HealthKit / Google Fit integration in scope for v1 or deferred to v2?
