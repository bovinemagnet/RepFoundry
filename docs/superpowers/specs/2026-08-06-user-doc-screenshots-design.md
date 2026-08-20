# Screenshots for the End-User Documentation — Design Specification

Author: Paul Snow
Date: 2026-08-06

## 1. Problem

The end-user documentation (`src/docs/modules/ROOT/`) is 21 pages of prose with
not one image in it. A reader deciding whether to install RepFoundry, or trying
to find a screen they have been told about, has nothing to look at.

The docs site now publishes to GitHub Pages on every push to `main`, so the
landing page is the app's public face. It currently opens on a paragraph.

## 2. Scope

In scope:

- Scripted, repeatable capture of the app's own screens on the iOS Simulator
  and the Android emulator.
- 19 screenshots placed on the end-user pages, plus a composited hero image on
  the landing page.
- One command that regenerates all of it.

Out of scope:

- The developer module (`modules/dev/`).
- Video or animated capture.
- Device bezels or marketing frames.
- Any change to app UI to make it photograph better.
- OS chrome — see §6.

## 3. Why scripted rather than hand-taken

Hand-taken screenshots rot silently. The docs build already fails on a broken
`xref:` (`--log-failure-level=warn`), but nothing can detect an image showing a
screen that no longer exists — it simply misleads readers until somebody
notices. Scripted capture makes a re-shoot a single command, so the images can
be refreshed as part of any UI change rather than deferred indefinitely.

Scripting also solves two problems that would otherwise block the work
outright:

- A fresh simulator has no data, so every screenshot would show an empty state.
- Coach mode is gated behind `Entitlement.virtualTrainer`, which is empty by
  default, so its screens cannot be reached at all without seeding.

The repository is already most of the way there. `integration_test/helpers/test_app.dart`'s
`createTestApp` returns the `AppDatabase` explicitly "for pre-seeding data",
`integration_test/helpers/fakes.dart` fakes the BLE heart-rate and location
services a simulator cannot provide, and `fake_health_sync_service.dart` covers
HealthKit. Nine flow tests already drive the app end to end.

## 4. Architecture

```
integration_test/screenshots/            capture tests, grouped by doc area
integration_test/helpers/screenshot_seed.dart   the shared deterministic fixture
test_driver/integration_test.dart        driver entry point that writes PNGs
tools/screenshots.sh                     orchestrates both platforms end to end
src/docs/modules/ROOT/assets/images/     committed output
```

Capture uses `IntegrationTestWidgetsFlutterBinding.takeScreenshot()`, which
records the Flutter surface without OS status bar — identical framing on both
platforms, and no clock or battery indicator to date the image. Android
requires `await binding.convertFlutterSurfaceToImage()` first; iOS does not.

`tools/screenshots.sh` boots the simulators, runs the capture suites, composites
the hero with ImageMagick, downscales and optimises, and writes into the assets
directory. Images are committed, so the docs CI needs no simulators and stays
fast.

### 4.1 Seed fixture

`screenshot_seed.dart` seeds one database state used by every capture:

- Three weeks of completed workouts across the default exercise set, enough to
  populate history, analytics and the muscle-balance chart.
- Two personal records, so the PR timeline is not empty.
- One cardio session with a heart-rate trace, for the heart-rate panel.
- Several body-metric entries, for the weight chart.
- One workout template and one multi-week programme.
- A second client alongside the always-present self client.
- `Entitlement.virtualTrainer` unlocked in SharedPreferences.
- Theme forced to dark (§5).

Dates are anchored to the run date rather than hardcoded, so relative labels
("3 days ago") stay correct. The consequence is that re-shot images are **not**
byte-identical, which is why a CI freshness check comparing pixels was rejected:
it would fail on every run for reasons that have nothing to do with the UI.

## 5. Presentation

- **Dark theme throughout**, matching the hero and the Kinetic Green identity.
- **750px wide**, PNG, optimised to roughly 200KB or less. About 4MB total added
  to the repository.
- **Real alt text on every image.** These pages are exactly where a screen-reader
  user needs the description, and Antora will happily ship an empty `[]`.

## 6. The limit: OS chrome cannot be scripted

`takeScreenshot()` records the Flutter surface. It cannot capture anything
outside the app: Android sideload dialogs, TestFlight, or the iOS and Android
system permission prompts.

That affects the three pages a reader might most expect to be illustrated —
`install-android.adoc`, `install-ios.adoc` and `permissions.adoc`. **They stay
text-only.** Mixing in hand-taken images that no script can regenerate would
reintroduce exactly the staleness this design exists to avoid, on the pages
that change most often as OS versions move.

## 7. Coverage

17 images plus the hero. iOS is the default; Android appears only where the
platforms genuinely diverge — and on inspection, nowhere in this set does it.
Cloud sync names no provider on either platform (only `syncConsentBody` does,
and it names both), and the navigation bar is RepFoundry's own Flutter widget,
identical on Android down to the icons. Both were originally shot twice; the
Android copies documented nothing and were dropped, along with the Android
capture run.

| Image | Page | Device |
|---|---|---|
| `hero.png` | `index.adoc` | composited, iPhone |
| `first-workout.png` | `first-workout.adoc` | iPhone |
| `workout-logging.png` | `guide/workout.adoc` | iPhone |
| `cardio-session.png` | `guide/cardio.adoc` | iPhone |
| `heart-rate-panel.png` | `guide/heart-rate.adoc` | iPhone |
| `coach-mode.png` | `guide/trainer.adoc` | iPhone |
| `stretching.png` | `guide/stretching.adoc` | iPhone |
| `exercise-library.png` | `guide/exercises.adoc` | iPhone |
| `templates.png` | `guide/templates.adoc` | iPhone |
| `programmes.png` | `guide/programmes.adoc` | iPhone |
| `history.png` | `guide/history.adoc` | iPhone |
| `analytics.png` | `guide/analytics.adoc` | iPhone |
| `body-metrics.png` | `guide/body-metrics.adoc` | iPhone |
| `settings.png` | `guide/settings.adoc` | iPhone |
| `notifications.png` | `guide/notifications.adoc` | iPhone |
| `clients.png` | `guide/clients.adoc` | **iPad** — see below |
| `sync.png` | `guide/sync.adoc` | iPhone |
| `nav.png` | `platform-differences.adoc` | iPhone |

**The clients page must be shot on an iPad.** The roster and detail screens are
reachable only via the desktop nav rail at ≥600dp; on a phone they do not exist.
Capturing that page on an iPhone is impossible, and capturing the phone-only
active-client switcher instead would illustrate the wrong feature. `iPad Pro
11-inch (M4)` is available locally.

The hero reuses the heart-rate, workout-logging and analytics captures rather
than shooting three more, so it can never drift from the images below it.

Devices: `iPhone 16 Pro` and `iPad Pro 11-inch (M4)`.

## 8. Success criteria

- [ ] `tools/screenshots.sh` regenerates every image from a clean checkout.
- [ ] All 18 images are committed, under 200KB each, and dark-themed.
- [ ] Every `image::` macro carries meaningful alt text.
- [ ] Each screenshot shows populated data, never an empty state.
- [ ] `gradle21w antora` passes at `--log-failure-level=warn` — a missing image
      is a build failure, so this is the check that the wiring is real.
- [ ] The three OS-chrome pages are untouched.
- [ ] `dart analyze` clean, `dart format` clean, full suite passing.
