# User-Documentation Screenshots Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Twenty screenshots on the end-user documentation pages — nineteen feature shots and a composited hero — all regenerable by one command.

**Architecture:** Capture rides on the existing integration-test harness. A shared fixture seeds one database state; capture tests drive the app to each screen and call `binding.takeScreenshot()`; a driver writes the PNGs; a shell script orchestrates both simulators, composites the hero, optimises, and installs the images into the Antora assets directory. Images are committed, so the docs CI needs no simulators.

**Tech Stack:** Flutter `integration_test` + `flutter_driver`, Drift (in-memory), ImageMagick, Antora.

Spec: `docs/superpowers/specs/2026-08-06-user-doc-screenshots-design.md`

## Global Constraints

- **Dark theme.** `themeModeProvider` already defaults to dark (`lib/features/settings/presentation/providers/theme_mode_provider.dart:8`), so no forcing is needed — but do not seed `theme_mode` to anything else.
- **Never an empty state.** Every screenshot must show populated data. A shot of an empty history page is a failed shot, not a shipped one.
- **Every `image::` macro carries real alt text.** Antora accepts `image::x.png[]` silently; that is a failure, not a shortcut.
- **Images land in `src/docs/modules/ROOT/assets/images/`**, referenced from ROOT pages as `image::name.png[Alt text]`.
- **750px wide, PNG, under 200KB each.**
- **Do not touch** `install-android.adoc`, `install-ios.adoc`, or `permissions.adoc`. They document OS chrome that `takeScreenshot()` cannot capture, and they stay text-only by design.
- **Devices:** `iPhone 16 Pro`, `iPad Pro 11-inch (M4)`, AVD `Medium_Phone_API_36.1`. All confirmed present.
- **British spelling** in prose, comments and alt text.
- Use `flutter test` / `flutter drive`, not gradle, for Flutter work. Use `gradle21w antora` for the docs build.
- Author: Paul Snow. Version 0.0.0.

## File Structure

| File | Status | Responsibility |
|---|---|---|
| `integration_test/helpers/test_app.dart` | Modify | Accept seeded SharedPreferences |
| `integration_test/helpers/screenshot_seed.dart` | Create | The one fixture every capture uses |
| `test_driver/integration_test.dart` | Create | Driver entry point; writes PNGs to `build/screenshots/` |
| `integration_test/screenshots/training_test.dart` | Create | Workout, cardio, heart rate, coach, stretching captures |
| `integration_test/screenshots/library_test.dart` | Create | Exercises, templates, programmes, settings, notifications |
| `integration_test/screenshots/progress_test.dart` | Create | History, analytics, body metrics, sync, nav |
| `integration_test/screenshots/clients_test.dart` | Create | The iPad-only clients roster |
| `tools/screenshots.sh` | Create | Orchestration, compositing, optimisation, install |
| `src/docs/modules/ROOT/pages/*.adoc` | Modify | 17 pages gain an `image::` macro |
| `src/docs/modules/ROOT/assets/images/` | Create | 20 committed PNGs |

---

### Task 1: The seed fixture

**Files:**
- Modify: `integration_test/helpers/test_app.dart:17-38`
- Create: `integration_test/helpers/screenshot_seed.dart`
- Test: `integration_test/screenshots/seed_test.dart`

**Interfaces:**
- Produces: `Future<void> seedScreenshotData(AppDatabase database)` and `Map<String, Object> screenshotPrefs()`. `createTestApp` gains a named parameter `Map<String, Object>? initialPrefs`.

- [x] **Step 1: Write the failing test**

Create `integration_test/screenshots/seed_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/screenshot_seed.dart';
import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the screenshot fixture fills the screens we photograph',
      (tester) async {
    final testApp = await createTestApp(initialPrefs: screenshotPrefs());
    await seedScreenshotData(testApp.database);
    await tester.pumpWidget(testApp.app);
    await tester.pumpAndSettle();

    // The home screen must not be showing its empty state — that is the
    // single failure this fixture exists to prevent, and it is invisible
    // in a screenshot review until someone notices the app looks unused.
    expect(find.textContaining('No workouts'), findsNothing);

    await testApp.database.close();
  });
}
```

- [x] **Step 2: Run it and watch it fail**

```bash
flutter test integration_test/screenshots/seed_test.dart
```

Expected: FAIL to compile — `screenshot_seed.dart` does not exist, and `createTestApp` has no `initialPrefs` parameter.

- [x] **Step 3: Add the preferences parameter**

In `test_app.dart`, change the signature and the mock-values line:

```dart
Future<({Widget app, AppDatabase database})> createTestApp({
  FakeHeartRateService? heartRateService,
  FakeLocationService? locationService,
  Map<String, Object>? initialPrefs,
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs ?? {});
```

Leave the rest of the function unchanged. Existing callers pass nothing and keep the empty-map behaviour they have today.

- [x] **Step 4: Write the fixture**

Create `integration_test/helpers/screenshot_seed.dart`. It must produce, through the Drift repositories rather than raw table inserts (so it stays valid if the schema moves):

- Three weeks of completed workouts, anchored to `DateTime.now()` so relative
  labels stay correct, across at least six of the seeded exercises. Look up
  exercise IDs via `DriftExerciseRepository(database).getAllExercises()` and
  match by name — do not hardcode UUIDs.
- Sets with realistic weights and reps, some carrying `avgHeartRate` and
  `peakHeartRate`, so the per-set HR summary is not blank.
- Two personal records, so the PR timeline has points on it.
- One cardio session with a heart-rate trace.
- Several body-metric entries spread over the three weeks.
- One workout template and one multi-week programme.
- A second client alongside the always-present self client.

`Workout` and `WorkoutSet` constructors are in
`lib/features/workout/domain/models/`. Both require `updatedAt`; `Workout`
requires `clientId` (use `kSelfClientId` from
`lib/features/clients/domain/models/client.dart`) and needs `completedAt` set
for the workout to count as history rather than in-progress.

`screenshotPrefs()` returns the preferences the app reads at start-up:

```dart
/// Coach mode is gated behind an entitlement that is empty by default, so
/// without this its screens cannot be reached at all — the capture would
/// silently photograph the wrong thing rather than fail.
Map<String, Object> screenshotPrefs() => {
      'unlocked_entitlements': <String>['virtualTrainer'],
    };
```

The key and the string-list shape come from
`lib/core/entitlements/entitlement_provider.dart:7,25`. Do not seed
`theme_mode` — dark is already the default.

- [x] **Step 5: Run it and watch it pass**

```bash
flutter test integration_test/screenshots/seed_test.dart
```

Expected: PASS.

- [x] **Step 6: Prove the test can fail**

Comment out the `await seedScreenshotData(...)` line and re-run. Expected: FAIL on the empty-state assertion — confirming the assertion is reached and the fixture is what satisfies it, rather than the app happening to have data. Restore.

- [x] **Step 7: Confirm nothing else broke and commit**

```bash
flutter test
git add integration_test/ && git commit -m "test: seed fixture for documentation screenshots"
```

---

### Task 2: The driver, and one screenshot end to end

Prove the whole pipeline on a single image before writing nineteen more.

**Files:**
- Create: `test_driver/integration_test.dart`
- Create: `integration_test/screenshots/training_test.dart`

**Interfaces:**
- Consumes: `seedScreenshotData`, `screenshotPrefs`, `createTestApp(initialPrefs:)` from Task 1.
- Produces: the `takeScreenshot` naming convention every later capture follows — the image's final filename without extension, e.g. `workout-logging`.

- [x] **Step 1: Write the driver**

Create `test_driver/integration_test.dart`:

```dart
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('build/screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
```

- [x] **Step 2: Write the first capture**

Create `integration_test/screenshots/training_test.dart` with one test for now:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/screenshot_seed.dart';
import '../helpers/test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('workout-logging', (tester) async {
    // Android renders into a surface the framework cannot read back until
    // this runs; on iOS it is a no-op. Must happen before the first
    // takeScreenshot of the run, not before each one.
    await binding.convertFlutterSurfaceToImage();

    final testApp = await createTestApp(initialPrefs: screenshotPrefs());
    await seedScreenshotData(testApp.database);
    await tester.pumpWidget(testApp.app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Exercise'));
    await tester.pumpAndSettle();
    await pumpUntilFound(tester, find.text('Barbell Bench Press'));
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();

    await binding.takeScreenshot('workout-logging');
    await testApp.database.close();
  });
}
```

- [x] **Step 3: Boot the simulator and capture**

```bash
xcrun simctl boot "iPhone 16 Pro" || true
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots/training_test.dart \
  -d "iPhone 16 Pro"
```

- [x] **Step 4: Verify the artefact, not the exit code**

```bash
ls -la build/screenshots/workout-logging.png
magick identify build/screenshots/workout-logging.png
```

Expected: the file exists, is more than 50KB, and its dimensions match the simulator's logical resolution. Then **open it and look at it**. A green run that produced a screenshot of an empty workout screen, a loading spinner, or a modal barrier is a failure — the exit code cannot tell you that, and this is the one step in this plan that no assertion replaces.

If the screen is wrong, the usual causes are a missing `pumpAndSettle` after an animation, or a bottom sheet still open over the content.

- [x] **Step 5: Commit**

```bash
git add test_driver/ integration_test/screenshots/
git commit -m "test: capture the first documentation screenshot end to end"
```

---

### Task 3: The remaining iPhone captures

**Files:**
- Modify: `integration_test/screenshots/training_test.dart`
- Create: `integration_test/screenshots/library_test.dart`
- Create: `integration_test/screenshots/progress_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 1 and 2.
- Produces: PNGs in `build/screenshots/` named exactly as the spec's coverage table requires.

Each test is named for the image it produces, follows the Task 2 shape, and calls `convertFlutterSurfaceToImage()` once at the start of the first test in its file.

- [x] **Step 1: Finish `training_test.dart`**

Add captures named `first-workout`, `cardio-session`, `heart-rate-panel`, `coach-mode`, `stretching`. Notes:

- `first-workout` differs from `workout-logging`: it shows the screen with a set already logged and the rest timer running, since that is the moment the page describes.
- `heart-rate-panel` needs `FakeHeartRateService` supplying a live BPM — pass one into `createTestApp(heartRateService: ...)` and check `integration_test/helpers/fakes.dart` for how it emits.
- `coach-mode` is reachable only because Task 1 unlocked `virtualTrainer`. If the tile is absent, the preferences did not load — do not work around it by editing the widget tree.
- `stretching` renders as a section inside the active workout screen; it has no route of its own.

- [x] **Step 2: Write `library_test.dart`**

Captures: `exercise-library`, `templates`, `programmes`, `settings`, `notifications`.

- [x] **Step 3: Write `progress_test.dart`**

Captures: `history`, `analytics`, `body-metrics`, `sync-ios`, `nav-ios`.

`sync-ios` is the cloud-sync settings screen showing iCloud. `nav-ios` shows the bottom navigation — it is the counterpart to `nav-android` and exists to illustrate the platform-differences page, so frame it on the navigation rather than on whatever screen happens to be open.

- [x] **Step 4: Capture all three suites**

```bash
for suite in training library progress; do
  flutter drive --driver=test_driver/integration_test.dart \
    --target=integration_test/screenshots/${suite}_test.dart \
    -d "iPhone 16 Pro"
done
ls build/screenshots/
```

Expected: 15 PNGs.

- [x] **Step 5: Look at every one of them**

Open all fifteen. Check each shows the screen its name claims, with populated data, no spinner, no half-open sheet, no debug banner. Note any that need a different waiting strategy and fix them now — a bad screenshot is much cheaper to fix here than after it is wired into a page.

- [x] **Step 6: Commit**

```bash
git add integration_test/screenshots/
git commit -m "test: capture the remaining iPhone documentation screenshots"
```

---

### Task 4: iPad and Android captures

**Files:**
- Create: `integration_test/screenshots/clients_test.dart`
- Modify: `integration_test/screenshots/progress_test.dart` — the platform-suffix guard in step 3

- [ ] **Step 1: Write the clients capture**

The roster and detail screens are reachable **only** via the desktop nav rail at ≥600dp. On a phone they do not exist, so this one runs on an iPad. Seed the second client from Task 1's fixture, navigate via the rail, and capture `clients`.

- [ ] **Step 2: Capture on the iPad**

```bash
xcrun simctl boot "iPad Pro 11-inch (M4)" || true
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots/clients_test.dart \
  -d "iPad Pro 11-inch (M4)"
```

- [ ] **Step 3: Capture the two Android images**

Start the emulator, then run `progress_test.dart` against it. Only `sync-android` and `nav-android` are kept from that run; the rest are discarded by `tools/screenshots.sh` in Task 5.

```bash
emulator -avd Medium_Phone_API_36.1 -no-snapshot -no-boot-anim &
adb wait-for-device
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots/progress_test.dart \
  -d emulator-5554
```

The Android run must produce `sync-android.png` and `nav-android.png`. Add a `--dart-define=SCREENSHOT_PLATFORM=android` guard in the test so the two navigation captures write platform-suffixed names, rather than renaming files afterwards in the shell where the mapping would be invisible.

If `convertFlutterSurfaceToImage()` throws, it is being called more than once in the run — it is once per driver session, not once per test.

- [ ] **Step 4: Look at all three, then commit**

Verify `sync-android` really shows Google Drive and not iCloud — that difference is the entire reason both images exist.

```bash
git add integration_test/screenshots/
git commit -m "test: capture the iPad clients roster and the Android-specific screens"
```

---

### Task 5: The orchestration script

**Files:**
- Create: `tools/screenshots.sh`

- [ ] **Step 1: Write the script**

`tools/screenshots.sh` must, with `set -euo pipefail`:

1. Boot `iPhone 16 Pro`, `iPad Pro 11-inch (M4)`, and the AVD.
2. Run the four capture suites against the right device each.
3. Composite the hero from the already-captured `heart-rate-panel`, `workout-logging` and `analytics` PNGs — workout centred and full size, the other two behind it, scaled to about 80% and offset left and right. Output `hero.png`.
4. Downscale every image to 750px wide and optimise to under 200KB.
5. Copy the twenty final images into `src/docs/modules/ROOT/assets/images/`.
6. **Fail loudly if any of the twenty expected filenames is missing.** A partial run that silently installs eighteen images is how a docs build goes green with two broken pages.

Include the expected filenames as an explicit list in the script, so step 6 checks against a stated contract rather than against whatever happens to be on disk.

- [ ] **Step 2: Run it from a clean state**

```bash
rm -rf build/screenshots src/docs/modules/ROOT/assets/images
bash tools/screenshots.sh
ls src/docs/modules/ROOT/assets/images/ | wc -l
```

Expected: 20.

- [ ] **Step 3: Prove the missing-image guard works**

Delete one PNG from `build/screenshots/` after capture and re-run only the install phase. Expected: the script exits non-zero and names the missing file. Restore.

- [ ] **Step 4: Check the weight**

```bash
du -sh src/docs/modules/ROOT/assets/images/
ls -lS src/docs/modules/ROOT/assets/images/ | head -3
```

Expected: total around 4MB, largest file under 200KB.

- [ ] **Step 5: Commit**

```bash
git add tools/screenshots.sh src/docs/modules/ROOT/assets/images/
git commit -m "feat: one command regenerates every documentation screenshot"
```

---

### Task 6: Wire the images into the pages

**Files:**
- Modify: 17 files under `src/docs/modules/ROOT/pages/`

- [ ] **Step 1: Add the hero to the landing page**

In `index.adoc`, place the hero immediately after the opening paragraph — before `== Who this is for` — so it is the first thing below the intro rather than pushed under a heading:

```asciidoc
image::hero.png[RepFoundry on iPhone: a heart-rate session, an active workout with sets logged, and the analytics dashboard]
```

- [ ] **Step 2: Add one image to each feature page**

Sixteen pages, each taking the image named for it in the spec's coverage table. Place it after the page's opening paragraph, not at the very top — the reader needs a sentence of context first.

`guide/sync.adoc` and `platform-differences.adoc` take two images each, iOS then Android, each labelled in its alt text so a screen-reader user knows which platform they are hearing about.

Alt text describes what is on screen, not what the file is called. "Analytics screen showing weekly training volume rising over eight weeks" — not "Analytics screenshot".

- [ ] **Step 3: Build the docs**

```bash
gradle21w antora
```

Expected: success. A missing image is a build failure at `--log-failure-level=warn`, so this is the step that proves every macro resolves.

- [ ] **Step 4: Prove the build catches a broken image**

Rename one PNG, rebuild, confirm the build fails and names it, then restore. Without this you have only proved the build passes, not that it was ever checking.

- [ ] **Step 5: Look at the rendered site**

Open the generated site and check each image renders at a sensible width, is legible on the page, and sits with the prose it illustrates.

- [ ] **Step 6: Commit**

```bash
git add src/docs/
git commit -m "docs: illustrate the user documentation with app screenshots"
```

---

### Task 7: Verify and open the pull request

- [ ] **Step 1: Full verification**

```bash
flutter test
dart analyze
dart format --set-exit-if-changed .
gradle21w antora
```

Report the real test count. All four must be clean.

- [ ] **Step 2: Confirm the untouched pages really are untouched**

```bash
git diff main --stat -- src/docs/modules/ROOT/pages/install-android.adoc \
  src/docs/modules/ROOT/pages/install-ios.adoc \
  src/docs/modules/ROOT/pages/permissions.adoc
```

Expected: no output.

- [ ] **Step 3: Confirm every image is referenced**

For each of the twenty files in the assets directory, grep the pages for its name. An unreferenced image is dead weight in git; a referenced-but-absent one already failed the build in Task 6.

- [ ] **Step 4: Open the pull request**

The body must state which pages gained images, why the install and permissions pages did not, that `tools/screenshots.sh` regenerates everything, and the repository size added. Attach or reference the hero so a reviewer can see it without checking out the branch.

---

## Notes for the implementer

**The screenshots are the deliverable, and no test can review them.** Every capture task ends with "open the images and look at them" for that reason. A green `flutter drive` proves the app did not crash — nothing more. This project has previously shipped a fully-wired feature that no test could see; a folder of screenshots of loading spinners would be the same failure in a new medium.

**`convertFlutterSurfaceToImage()` is once per driver session**, not once per test, and is a no-op on iOS. Calling it twice throws.

**Do not widen app code to make capture easier.** If a screen is hard to reach, that is worth knowing — reach it the way a user does.

**Seed dates are anchored to the run date on purpose.** Re-shot images will differ in their date text. That is why the design rejected a pixel-comparison CI check, and it is not a bug to fix.
