# Desktop & Tablet Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the highest-value desktop/tablet gaps found in the July 2026 review — input ergonomics (mouse drag, scrollbars, keyboard shortcuts, text selection), platform polish (visual density, minimum window size), and one new master-detail power layout (Programmes) — using the app's existing responsive pattern.

**Architecture:** The app already has a deliberate "desktop power-layout" pattern: `lib/core/responsive/breakpoints.dart` (tablet = 600, desktop = 1024, `context.isWide`), a persistent `DesktopNavRail` in `ScaffoldWithNavBar`, and three bespoke `*DesktopView` widgets (History, Analytics, Templates). This plan extends that pattern rather than inventing a new one: small cross-cutting polish lands in `lib/app/` and `lib/core/`, and the Programmes screen gains a `ProgrammesDesktopView` modelled directly on `TemplatesDesktopView`.

**Tech Stack:** Flutter (Material 3), Riverpod 3, go_router 17, Drift/SQLite, `flutter gen-l10n` ARB localisation, `flutter_test` widget tests.

## Global Constraints

- British spelling in all user-facing copy, comments, and docs.
- All user-facing strings go in `lib/l10n/app_en.arb`; run `flutter gen-l10n` after editing; access via `S.of(context)!`.
- Widget tests must set `localizationsDelegates: S.localizationsDelegates` and `supportedLocales: S.supportedLocales` on their `MaterialApp`.
- `dart analyze` must report zero issues (CI enforces this); `dart format --set-exit-if-changed .` must pass.
- Follow the existing adaptive pattern: branch with `if (context.isWide) return const XDesktopView();` at the top of the screen's `build` — never duplicate breakpoint maths.
- Lints treat missing return types as errors: always declare return types; prefer `const`/`final`.
- Commit messages: no Claude/Anthropic mentions, no co-author lines.
- TDD: write the failing test before the implementation in every task that touches Dart code.

---

## Review Findings (context for the tasks)

What is already in place:

- All six platform directories exist (`android/ ios/ linux/ macos/ windows/ web/`); no platform restriction in `pubspec.yaml`.
- Central breakpoints + a user-facing layout override (`LayoutMode` auto/mobile/desktop, only effective at ≥ 600 px; settings screen has an Auto/Mobile/Desktop control).
- Adaptive shell: `ScaffoldWithNavBar` swaps a glass bottom bar (mobile) for a 252 px labelled `DesktopNavRail` (tablet+). Non-adaptive screens are centred at 980 px, not stretched.
- Three desktop power layouts exist: History (master-detail), Analytics (dashboard grid), Templates (library + canvas).
- Mobile-only plugins (`flutter_blue_plus`, `health`, `geolocator`, foreground service, notifications) are already behind `Platform.isAndroid`/`isIOS` guards; CSV export already has explicit Linux/Windows branches.

Gaps this plan closes:

1. No `VisualDensity.adaptivePlatformDensity` — desktop UI renders at touch density (Task 1).
2. Lists cannot be dragged with a mouse; no app-level `ScrollBehavior` (Task 2).
3. No text anywhere is selectable — no `SelectionArea` in the app (Task 3).
4. No minimum window size on Linux/Windows/macOS — the window can shrink below usable width (Task 4).
5. Programmes is a plain phone `ListView` with no wide layout — the most obvious missing power layout (Task 5).
6. Zero keyboard shortcuts — not even destination switching (Task 6).

Gaps deliberately deferred (see "Deferred / separate plans" at the end): client roster ("coach mode"), remaining screen adaptations (Active Workout, Exercise picker, Body Metrics, Workout Detail, PR History), window-state persistence, right-click context menus, drag-and-drop CSV import, desktop plugin no-op verification.

---

### Task 1: Adaptive visual density in the theme

**Files:**
- Modify: `lib/app/theme.dart:145-149`
- Test: `test/app/theme_density_test.dart` (new)

**Interfaces:**
- Consumes: `AppTheme.light` / `AppTheme.dark` static getters (existing).
- Produces: no new API — both themes gain `visualDensity: VisualDensity.adaptivePlatformDensity`.

- [ ] **Step 1: Write the failing test**

```dart
// test/app/theme_density_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/app/theme.dart';

void main() {
  test('themes use adaptive platform density for desktop comfort', () {
    expect(
      AppTheme.light.visualDensity,
      VisualDensity.adaptivePlatformDensity,
    );
    expect(
      AppTheme.dark.visualDensity,
      VisualDensity.adaptivePlatformDensity,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/theme_density_test.dart`
Expected: FAIL — actual density is the `ThemeData` default, not `adaptivePlatformDensity`.

- [ ] **Step 3: Add the density to `_build`**

In `lib/app/theme.dart`, inside `static ThemeData _build(ColorScheme scheme) => ThemeData(`, add one line directly after `useMaterial3: true,`:

```dart
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/app/theme_density_test.dart`
Expected: PASS

- [ ] **Step 5: Analyse, format, commit**

```bash
dart analyze && dart format lib/app/theme.dart test/app/theme_density_test.dart
git add lib/app/theme.dart test/app/theme_density_test.dart
git commit -m "feat: adaptive visual density for desktop layouts"
```

---

### Task 2: App-wide scroll behaviour (mouse drag on lists)

**Files:**
- Create: `lib/core/widgets/app_scroll_behavior.dart`
- Modify: `lib/app/app.dart:18-24`
- Test: `test/core/widgets/app_scroll_behavior_test.dart` (new)

**Interfaces:**
- Produces: `class AppScrollBehavior extends MaterialScrollBehavior` with a `const AppScrollBehavior()` constructor, overriding `Set<PointerDeviceKind> get dragDevices`. Wired via `scrollBehavior:` on `MaterialApp.router`.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/app_scroll_behavior_test.dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/app_scroll_behavior.dart';

void main() {
  test('lists are draggable with mouse, trackpad, stylus, and touch', () {
    const behaviour = AppScrollBehavior();
    expect(
      behaviour.dragDevices,
      containsAll(<PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      }),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/widgets/app_scroll_behavior_test.dart`
Expected: FAIL — `app_scroll_behavior.dart` does not exist (compile error).

- [ ] **Step 3: Create the behaviour**

```dart
// lib/core/widgets/app_scroll_behavior.dart
import 'dart:ui';

import 'package:flutter/material.dart';

/// Desktop-friendly scrolling: lists can be dragged with a mouse or trackpad
/// as well as touch. The inherited [MaterialScrollBehavior] keeps the default
/// automatic scrollbars on desktop platforms.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
```

- [ ] **Step 4: Wire it into the app**

In `lib/app/app.dart`, add the import and the `scrollBehavior` argument:

```dart
import '../core/widgets/app_scroll_behavior.dart';
```

```dart
    return MaterialApp.router(
      title: 'RepFoundry',
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.light,
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/core/widgets/app_scroll_behavior_test.dart`
Expected: PASS

- [ ] **Step 6: Analyse, format, commit**

```bash
dart analyze && dart format lib/core/widgets/app_scroll_behavior.dart lib/app/app.dart test/core/widgets/app_scroll_behavior_test.dart
git add lib/core/widgets/app_scroll_behavior.dart lib/app/app.dart test/core/widgets/app_scroll_behavior_test.dart
git commit -m "feat: mouse and trackpad drag scrolling app-wide"
```

---

### Task 3: Selectable text on desktop platforms

**Files:**
- Create: `lib/core/widgets/desktop_text_selection.dart`
- Modify: `lib/app/app.dart:29-32` (the `builder`)
- Test: `test/core/widgets/desktop_text_selection_test.dart` (new)

**Interfaces:**
- Produces: `class DesktopTextSelection extends StatelessWidget` with `const DesktopTextSelection({super.key, required this.child})`. Wraps `child` in a `SelectionArea` on Linux/macOS/Windows, passes it through unchanged on Android/iOS/Fuchsia.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/desktop_text_selection_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/desktop_text_selection.dart';

void main() {
  testWidgets('wraps child in SelectionArea on desktop', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(const MaterialApp(
      home: DesktopTextSelection(child: Text('workout notes')),
    ));

    expect(find.byType(SelectionArea), findsOneWidget);
  });

  testWidgets('passes child through untouched on mobile', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(const MaterialApp(
      home: DesktopTextSelection(child: Text('workout notes')),
    ));

    expect(find.byType(SelectionArea), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/widgets/desktop_text_selection_test.dart`
Expected: FAIL — `desktop_text_selection.dart` does not exist (compile error).

- [ ] **Step 3: Create the widget**

```dart
// lib/core/widgets/desktop_text_selection.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Makes all descendant text selectable on desktop platforms, where users
/// expect to be able to copy stats, notes, and error messages. Mobile keeps
/// the default non-selectable text so gestures are unaffected.
class DesktopTextSelection extends StatelessWidget {
  const DesktopTextSelection({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return SelectionArea(child: child);
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return child;
    }
  }
}
```

- [ ] **Step 4: Wire it into the app builder**

In `lib/app/app.dart`, add the import and wrap the routed tree (inside `LayoutModeScope` so the scope stays outermost):

```dart
import '../core/widgets/desktop_text_selection.dart';
```

```dart
      builder: (context, child) => LayoutModeScope(
        mode: layoutMode,
        child: DesktopTextSelection(child: child ?? const SizedBox.shrink()),
      ),
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/core/widgets/desktop_text_selection_test.dart`
Expected: PASS (both tests)

- [ ] **Step 6: Analyse, format, commit**

```bash
dart analyze && dart format lib/core/widgets/desktop_text_selection.dart lib/app/app.dart test/core/widgets/desktop_text_selection_test.dart
git add lib/core/widgets/desktop_text_selection.dart lib/app/app.dart test/core/widgets/desktop_text_selection_test.dart
git commit -m "feat: selectable text on desktop platforms"
```

---

### Task 4: Minimum window size on Linux, Windows, and macOS

Native-code task, no Dart tests — verification is manual. Minimum is 480 × 640 logical px: wide enough for the forced-mobile centred column, tall enough for the workout screen.

**Files:**
- Modify: `linux/runner/my_application.cc:55` (after `gtk_window_set_default_size`)
- Modify: `windows/runner/win32_window.cpp:181-219` (`MessageHandler` switch)
- Modify: `macos/Runner/MainFlutterWindow.swift`

**Interfaces:** none — behavioural change only.

- [ ] **Step 1: Linux — add GTK geometry hints**

In `linux/runner/my_application.cc`, directly after `gtk_window_set_default_size(window, 1280, 720);`:

```c
  GdkGeometry geometry;
  geometry.min_width = 480;
  geometry.min_height = 640;
  gtk_window_set_geometry_hints(window, nullptr, &geometry, GDK_HINT_MIN_SIZE);
```

- [ ] **Step 2: Windows — handle WM_GETMINMAXINFO**

In `windows/runner/win32_window.cpp`, add a case to the `switch (message)` in `Win32Window::MessageHandler` (alongside `WM_SIZE`), scaling by DPI as the existing `Create` code does:

```cpp
    case WM_GETMINMAXINFO: {
      MINMAXINFO* info = reinterpret_cast<MINMAXINFO*>(lparam);
      UINT dpi = FlutterDesktopGetDpiForHWND(hwnd);
      double scale_factor = dpi / 96.0;
      info->ptMinTrackSize.x = static_cast<LONG>(480 * scale_factor);
      info->ptMinTrackSize.y = static_cast<LONG>(640 * scale_factor);
      return 0;
    }
```

(`FlutterDesktopGetDpiForHWND` is already included via `flutter_windows.h` in this file's includes — confirm the include exists; if not, add `#include <flutter_windows.h>`.)

- [ ] **Step 3: macOS — set contentMinSize**

In `macos/Runner/MainFlutterWindow.swift`, inside `awakeFromNib()` before `super.awakeFromNib()`:

```swift
    self.contentMinSize = NSSize(width: 480, height: 640)
```

- [ ] **Step 4: Verify on the host platform**

Run: `flutter run -d linux` and try to drag the window smaller than 480 × 640.
Expected: the window refuses to shrink below the minimum. (Windows/macOS changes are verified when those platforms are next built; the code is standard runner boilerplate.)

- [ ] **Step 5: Commit**

```bash
git add linux/runner/my_application.cc windows/runner/win32_window.cpp macos/Runner/MainFlutterWindow.swift
git commit -m "feat: enforce minimum desktop window size"
```

---

### Task 5: Programmes desktop master-detail power layout

Mirror the Templates pattern: on `context.isWide`, `ProgrammeListScreen` returns a `ProgrammesDesktopView` — a master list of programmes on the left, with the existing `ProgrammeEditScreen` embedded in the right-hand pane (its constructor is `ProgrammeEditScreen({super.key, required this.programmeId})`, so it embeds directly).

**Files:**
- Create: `lib/features/programmes/presentation/providers/programme_list_provider.dart`
- Create: `lib/features/programmes/presentation/widgets/programmes_desktop_view.dart`
- Modify: `lib/features/programmes/presentation/screens/programme_list_screen.dart:10-25`
- Modify: `lib/core/widgets/scaffold_with_nav_bar.dart:41-45` (`_fullWidthDesktopPrefixes`)
- Modify: `lib/l10n/app_en.arb` (one new string)
- Test: `test/features/programmes/presentation/screens/programme_list_screen_test.dart` (new)

**Interfaces:**
- Consumes: `programmeRepositoryProvider` from `lib/core/providers.dart`; `ProgrammeRepository.watchAllProgrammes()` / `.deleteProgramme(String id)`; `ProgrammeEditScreen({required String programmeId})`; `context.isWide` from `lib/core/responsive/breakpoints.dart`.
- Produces: `programmeListProvider` — `StreamProvider.autoDispose<List<Programme>>` (shared by mobile screen and desktop view); `class ProgrammesDesktopView extends ConsumerStatefulWidget` with `const ProgrammesDesktopView({super.key})`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/programmes/presentation/screens/programme_list_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';
import 'package:rep_foundry/features/programmes/domain/repositories/programme_repository.dart';
import 'package:rep_foundry/features/programmes/presentation/screens/programme_list_screen.dart';
import 'package:rep_foundry/features/programmes/presentation/widgets/programmes_desktop_view.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

class _FakeProgrammeRepository implements ProgrammeRepository {
  final List<Programme> programmes;
  _FakeProgrammeRepository(this.programmes);

  @override
  Stream<List<Programme>> watchAllProgrammes() => Stream.value(programmes);

  @override
  Future<List<Programme>> getAllProgrammes() async => programmes;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not needed here');
}

Widget _app(ProgrammeRepository repo) => ProviderScope(
      overrides: [programmeRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: ProgrammeListScreen(),
      ),
    );

void main() {
  testWidgets('wide screens get the desktop master-detail view',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(_FakeProgrammeRepository(const [])));
    await tester.pumpAndSettle();

    expect(find.byType(ProgrammesDesktopView), findsOneWidget);
  });

  testWidgets('phone widths keep the mobile list', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(_FakeProgrammeRepository(const [])));
    await tester.pumpAndSettle();

    expect(find.byType(ProgrammesDesktopView), findsNothing);
  });
}
```

Note: `_FakeProgrammeRepository` relies on `noSuchMethod` for the unused repository methods — if the analyser objects under this project's lint set, implement the remaining `ProgrammeRepository` methods explicitly as `=> throw UnimplementedError();` one-liners instead.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/programmes/presentation/screens/programme_list_screen_test.dart`
Expected: FAIL — `programmes_desktop_view.dart` does not exist (compile error).

- [ ] **Step 3: Extract the shared list provider**

```dart
// lib/features/programmes/presentation/providers/programme_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../domain/models/programme.dart';

/// All programmes, live from the repository. Shared by the mobile list screen
/// and the desktop master-detail view.
final programmeListProvider =
    StreamProvider.autoDispose<List<Programme>>((ref) {
  return ref.watch(programmeRepositoryProvider).watchAllProgrammes();
});
```

In `lib/features/programmes/presentation/screens/programme_list_screen.dart`, delete the private `_programmeListProvider` (lines 10-13), import the new provider file, and replace both usages of `_programmeListProvider` with `programmeListProvider`.

- [ ] **Step 4: Add the l10n string**

In `lib/l10n/app_en.arb`, add (matching the file's existing style):

```json
  "selectProgrammeHint": "Select a programme to edit, or create a new one",
```

Run: `flutter gen-l10n`

- [ ] **Step 5: Create the desktop view**

```dart
// lib/features/programmes/presentation/widgets/programmes_desktop_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/providers.dart';
import '../../domain/models/programme.dart';
import '../providers/programme_list_provider.dart';
import '../screens/programme_edit_screen.dart';

/// Desktop power layout for programmes: a master list on the left with the
/// programme editor embedded in the right-hand pane, mirroring the templates
/// library + canvas view.
class ProgrammesDesktopView extends ConsumerStatefulWidget {
  const ProgrammesDesktopView({super.key});

  @override
  ConsumerState<ProgrammesDesktopView> createState() =>
      _ProgrammesDesktopViewState();
}

class _ProgrammesDesktopViewState extends ConsumerState<ProgrammesDesktopView> {
  String? _selectedId;

  static const _masterWidth = 380.0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final programmesAsync = ref.watch(programmeListProvider);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _masterWidth,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.programmesTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _createProgramme(context),
                        icon: const Icon(Icons.add),
                        label: Text(s.newProgramme),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: programmesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text(s.failedToLoadProgrammes(error.toString())),
                    ),
                    data: (programmes) => programmes.isEmpty
                        ? Center(
                            child: Text(
                              s.noProgrammesYet,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: programmes.length,
                            itemBuilder: (context, index) => _masterTile(
                              context,
                              programmes[index],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedId == null
                ? Center(
                    child: Text(
                      s.selectProgrammeHint,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ProgrammeEditScreen(
                    key: ValueKey(_selectedId),
                    programmeId: _selectedId!,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _masterTile(BuildContext context, Programme programme) {
    final s = S.of(context)!;
    return ListTile(
      selected: programme.id == _selectedId,
      selectedTileColor:
          Theme.of(context).colorScheme.secondaryContainer.withValues(
                alpha: 0.4,
              ),
      leading: const Icon(Icons.calendar_month_outlined),
      title: Text(programme.name),
      subtitle: Text(
        '${s.programmeWeeksCount(programme.durationWeeks)}'
        ' · '
        '${s.programmeDaysCount(programme.days.length)}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'delete') _confirmDelete(context, programme);
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(s.delete),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      onTap: () => setState(() => _selectedId = programme.id),
    );
  }

  Future<void> _createProgramme(BuildContext context) async {
    final s = S.of(context)!;
    final nameController = TextEditingController();
    final weeksController = TextEditingController();
    final result = await showDialog<({String name, int weeks})?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.newProgrammeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: s.programmeNameLabel,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weeksController,
              decoration: InputDecoration(
                labelText: s.durationWeeksLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final weeks = int.tryParse(weeksController.text.trim());
              if (name.isNotEmpty && weeks != null && weeks > 0) {
                Navigator.pop(ctx, (name: name, weeks: weeks));
              }
            },
            child: Text(s.create),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final programme = Programme.create(
        name: result.name,
        durationWeeks: result.weeks,
      );
      await ref.read(programmeRepositoryProvider).createProgramme(programme);
      if (mounted) setState(() => _selectedId = programme.id);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Programme programme,
  ) async {
    final s = S.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteProgrammeTitle),
        content: Text(s.deleteProgrammeContent(programme.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(programmeRepositoryProvider)
          .deleteProgramme(programme.id);
      if (programme.id == _selectedId && mounted) {
        setState(() => _selectedId = null);
      }
    }
  }
}
```

(Selecting on creation opens the new programme in the detail pane, replacing the mobile screen's `context.push`. Check the exact `TextField` input formatter used in `programme_list_screen.dart:109` — carry the `FilteringTextInputFormatter.digitsOnly` over if you keep parity.)

- [ ] **Step 6: Branch in the list screen**

At the top of `ProgrammeListScreen.build` in `programme_list_screen.dart`, after `final s = S.of(context)!;`, add (with imports for `../widgets/programmes_desktop_view.dart` and `../../../../core/responsive/breakpoints.dart`):

```dart
    // Wide screens use the desktop master-detail power layout.
    if (context.isWide) {
      return const ProgrammesDesktopView();
    }
```

- [ ] **Step 7: Let the layout fill the pane**

In `lib/core/widgets/scaffold_with_nav_bar.dart`, add `'/programmes'` to `_fullWidthDesktopPrefixes`:

```dart
  static const _fullWidthDesktopPrefixes = [
    '/history',
    '/analytics',
    '/templates',
    '/programmes',
  ];
```

- [ ] **Step 8: Run tests to verify they pass**

Run: `flutter test test/features/programmes/presentation/screens/programme_list_screen_test.dart`
Expected: PASS (both tests)

Then run the full suite: `flutter test`
Expected: no failures (the repo has no known failing tests).

- [ ] **Step 9: Analyse, format, commit**

```bash
dart analyze && dart format lib/features/programmes test/features/programmes lib/core/widgets/scaffold_with_nav_bar.dart
git add lib/features/programmes lib/core/widgets/scaffold_with_nav_bar.dart lib/l10n test/features/programmes
git commit -m "feat: programmes desktop master-detail power layout"
```

---

### Task 6: Keyboard shortcuts for rail navigation (Ctrl+1…8)

**Files:**
- Modify: `lib/core/widgets/scaffold_with_nav_bar.dart:59-87` (`_buildWithRail`)
- Test: `test/core/widgets/scaffold_with_nav_bar_shortcuts_test.dart` (new)

**Interfaces:**
- Consumes: existing private helpers `_railIndexForLocation` / `_onRailDestinationSelected` in the same file.
- Produces: Ctrl+1 … Ctrl+8 switch to the eight rail destinations (Workout, Cardio, History, Analytics, Heart Rate, Templates, Programmes, Settings) whenever the rail layout is active. No new public API.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/widgets/scaffold_with_nav_bar_shortcuts_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/core/widgets/scaffold_with_nav_bar.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('Ctrl+3 navigates to History on the rail layout',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/workout',
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              ScaffoldWithNavBar(child: child),
          routes: [
            GoRoute(
              path: '/workout',
              builder: (_, __) => const Text('workout page'),
            ),
            GoRoute(
              path: '/history',
              builder: (_, __) => const Text('history page'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
    ));
    await tester.pumpAndSettle();
    expect(find.text('workout page'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('history page'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/widgets/scaffold_with_nav_bar_shortcuts_test.dart`
Expected: FAIL — still on 'workout page' after the key events.

- [ ] **Step 3: Add the shortcuts to the rail layout**

In `scaffold_with_nav_bar.dart`, add the services import at the top:

```dart
import 'package:flutter/services.dart';
```

Add a key list to `ScaffoldWithNavBar` alongside the other statics:

```dart
  /// Ctrl+1 … Ctrl+8 jump to the rail destinations in rail order.
  static const _railShortcutKeys = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
  ];
```

Then wrap the returned `Scaffold` in `_buildWithRail` so it becomes:

```dart
    return CallbackShortcuts(
      bindings: {
        for (var i = 0; i < _railShortcutKeys.length; i++)
          SingleActivator(_railShortcutKeys[i], control: true): () =>
              _onRailDestinationSelected(i, context),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                DesktopNavRail(
                  selectedIndex: _railIndexForLocation(location),
                  onDestinationSelected: (index) =>
                      _onRailDestinationSelected(index, context),
                ),
                Expanded(child: content),
              ],
            ),
          ),
        ),
      ),
    );
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/widgets/scaffold_with_nav_bar_shortcuts_test.dart`
Expected: PASS

Then: `flutter test` — full suite still green.

- [ ] **Step 5: Analyse, format, commit**

```bash
dart analyze && dart format lib/core/widgets/scaffold_with_nav_bar.dart test/core/widgets/scaffold_with_nav_bar_shortcuts_test.dart
git add lib/core/widgets/scaffold_with_nav_bar.dart test/core/widgets/scaffold_with_nav_bar_shortcuts_test.dart
git commit -m "feat: Ctrl+number keyboard shortcuts for rail navigation"
```

---

## Final verification (after all tasks)

- [ ] `flutter test` — full suite passes.
- [ ] `dart analyze` — zero issues.
- [ ] `dart format --set-exit-if-changed .` — clean.
- [ ] `flutter run -d linux` — smoke-test: rail navigation via Ctrl+1…8, mouse-drag a history list, select/copy text from a workout, open Programmes on a wide window and create/select/delete a programme in the master-detail view, shrink the window to confirm the minimum size.

---

## Deferred / separate plans

These came out of the same review but are deliberately **not** in this plan. Each should get its own brainstorm + plan.

### 1. Client roster / coach mode (the "clients list")

The largest idea: let a coach or personal trainer manage several people from one (desktop) install — a client list in the rail, with workouts, cardio, body metrics, PRs, and analytics scoped per client. There is currently **no** multi-user concept anywhere: one implicit user, single `HealthProfile` in SharedPreferences.

Why it needs its own plan — it cuts across every subsystem:
- **Schema**: new `clients` table + a `clientId` FK (nullable, default = "me") on workouts, workout_sets (via workout), cardio_sessions, personal_records, body_metrics, programmes; a Drift schema migration.
- **Sync**: `SyncSnapshot` gains an entity list and a schema-version bump; the merge engine must key on (clientId, entity id).
- **State**: an `activeClientProvider` that every stream provider (history, analytics, PRs) filters by; a client switcher in the `DesktopNavRail` footer.
- **Health profile**: per-client age/HR settings instead of the single SharedPreferences profile.
- **Product questions to brainstorm first**: is this coach-managed (clients never log in) or multi-profile (family sharing a tablet)? Do templates/programmes stay shared or per-client? Is client data included in cloud sync or kept local?

### 2. Remaining screen adaptations (in priority order)

Follow the Task 5 pattern (`*DesktopView` + `context.isWide` branch + `_fullWidthDesktopPrefixes` entry where full-width):
1. **Active Workout** — the home screen and highest-value target: exercise list as a left column, current set input + rest timer as a persistent right pane, ghost sets inline.
2. **Exercise picker** — multi-column grid with hover previews at desktop widths (currently a single `ListView` with search/filter).
3. **Body Metrics** — chart + entry-list two-pane.
4. **Workout Detail / PR History / Exercise Progress** — side-by-side chart + breakdown instead of stacked scrolling.
5. **Template editor** — the list screen is adaptive but `template_edit_screen.dart` is still phone-shaped inside the canvas.

### 3. Desktop platform polish

- **Window-state persistence**: remember size/position/maximised across launches (add `window_manager`; this also supersedes the native min-size code from Task 4 if adopted).
- **Right-click context menus**: `GestureDetector.onSecondaryTapUp` on history/template/programme tiles mirroring their existing `PopupMenuButton` actions.
- **Drag-and-drop CSV import**: the CSV import feature (PR #76) plus the `desktop_drop` package → drop a Strong/Hevy export straight onto the History screen.
- **More shortcuts**: rest-timer start/skip (Space), add-set (Ctrl+Enter), search focus (Ctrl+F in exercise picker); a Cmd variant of the Task 6 activators on macOS.
- **Plugin no-op audit**: confirm `flutter_blue_plus`, `health`, `geolocator`, and notifications degrade gracefully (feature hidden or greyed with an explanation, not crashing) when launched on Linux/Windows — guards exist for Android/iOS branches but desktop behaviour of the Cardio and Heart Rate tabs needs a manual pass.
- **Web target**: `web/` exists but Drift on web needs the WASM/IndexedDB setup — decide whether web is a supported target or the directory should be removed.
