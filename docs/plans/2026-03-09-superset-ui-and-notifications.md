# Superset Grouping UI & Workout Notifications Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Complete the remaining Tier 2 features — superset/circuit grouping UI (2.2) and scheduled workout reminder notifications (2.6).

**Architecture:** Superset grouping uses the existing `groupId` field on `WorkoutSet` and `ActiveWorkoutState`, adding controller methods and visual grouping in the active workout screen. Notifications use `flutter_local_notifications` for scheduled local reminders with settings persisted via SharedPreferences following the existing `RestTimerSettings` pattern.

**Tech Stack:** Flutter/Dart, Riverpod, SharedPreferences, flutter_local_notifications, existing Drift database

---

## Part A: Superset / Circuit Grouping UI (2.2)

### Task 1: Add superset controller methods + unit tests

**Files:**
- Modify: `lib/features/workout/presentation/controllers/active_workout_controller.dart`
- Create: `test/features/workout/presentation/controllers/superset_test.dart`

**Step 1: Write the failing tests**

```dart
// test/features/workout/presentation/controllers/superset_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/features/workout/presentation/controllers/active_workout_controller.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';

void main() {
  group('Superset linking', () {
    late ProviderContainer container;
    late ActiveWorkoutController controller;

    setUp(() {
      container = ProviderContainer(overrides: [
        // We need to test the controller directly with a fake state
      ]);
    });

    test('linkSuperset assigns same groupId to two exercises', () {
      // Setup: Create a state with two exercises that have sets
      final set1 = WorkoutSet.create(
        workoutId: 'w1', exerciseId: 'e1', setOrder: 1, weight: 100, reps: 10,
      );
      final set2 = WorkoutSet.create(
        workoutId: 'w1', exerciseId: 'e2', setOrder: 1, weight: 50, reps: 12,
      );

      final state = ActiveWorkoutState(
        activeWorkout: Workout.create(),
        setsByExercise: {'e1': [set1], 'e2': [set2]},
        exercises: [
          const Exercise(id: 'e1', name: 'Bench Press', category: ExerciseCategory.strength, muscleGroup: MuscleGroup.chest, equipment: Equipment.barbell),
          const Exercise(id: 'e2', name: 'Incline Fly', category: ExerciseCategory.strength, muscleGroup: MuscleGroup.chest, equipment: Equipment.dumbbell),
        ],
      );

      // Act: link the two exercises
      final updatedSets = linkSupersetSets(state.setsByExercise, 'e1', 'e2');

      // Assert: both exercises' sets share the same groupId
      expect(updatedSets['e1']!.first.groupId, isNotNull);
      expect(updatedSets['e2']!.first.groupId, isNotNull);
      expect(updatedSets['e1']!.first.groupId, equals(updatedSets['e2']!.first.groupId));
    });

    test('unlinkSuperset clears groupId from all sets in group', () {
      const sharedGroupId = 'group-123';
      final set1 = WorkoutSet.create(
        workoutId: 'w1', exerciseId: 'e1', setOrder: 1, weight: 100, reps: 10, groupId: sharedGroupId,
      );
      final set2 = WorkoutSet.create(
        workoutId: 'w1', exerciseId: 'e2', setOrder: 1, weight: 50, reps: 12, groupId: sharedGroupId,
      );

      final setsByExercise = {'e1': [set1], 'e2': [set2]};

      final updatedSets = unlinkSupersetSets(setsByExercise, 'e1');

      expect(updatedSets['e1']!.first.groupId, isNull);
      expect(updatedSets['e2']!.first.groupId, isNull);
    });

    test('getSupersetGroups returns grouped exercise IDs', () {
      const groupA = 'group-a';
      final set1 = WorkoutSet.create(
        workoutId: 'w1', exerciseId: 'e1', setOrder: 1, weight: 100, reps: 10, groupId: groupA,
      );
      final set2 = WorkoutSet.create(
        workoutId: 'w1', exerciseId: 'e2', setOrder: 1, weight: 50, reps: 12, groupId: groupA,
      );
      final set3 = WorkoutSet.create(
        workoutId: 'w1', exerciseId: 'e3', setOrder: 1, weight: 60, reps: 8,
      );

      final setsByExercise = {'e1': [set1], 'e2': [set2], 'e3': [set3]};

      final groups = getSupersetGroups(setsByExercise);

      expect(groups, hasLength(1));
      expect(groups[groupA], containsAll(['e1', 'e2']));
    });
  });
}
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/features/workout/presentation/controllers/superset_test.dart`
Expected: FAIL — `linkSupersetSets`, `unlinkSupersetSets`, `getSupersetGroups` not defined

**Step 3: Implement the pure functions and controller methods**

Add to `lib/features/workout/presentation/controllers/active_workout_controller.dart`:

```dart
import 'package:uuid/uuid.dart';

/// Pure function: assigns a shared groupId to all sets for two exercises.
Map<String, List<WorkoutSet>> linkSupersetSets(
  Map<String, List<WorkoutSet>> setsByExercise,
  String exerciseId1,
  String exerciseId2,
) {
  final groupId = const Uuid().v4();
  final updated = Map<String, List<WorkoutSet>>.from(setsByExercise);
  for (final eid in [exerciseId1, exerciseId2]) {
    updated[eid] = (updated[eid] ?? [])
        .map((s) => s.copyWith(groupId: groupId))
        .toList();
  }
  return updated;
}

/// Pure function: clears groupId from all sets sharing the same group as exerciseId.
Map<String, List<WorkoutSet>> unlinkSupersetSets(
  Map<String, List<WorkoutSet>> setsByExercise,
  String exerciseId,
) {
  final sets = setsByExercise[exerciseId] ?? [];
  if (sets.isEmpty) return setsByExercise;
  final targetGroupId = sets.first.groupId;
  if (targetGroupId == null) return setsByExercise;

  final updated = Map<String, List<WorkoutSet>>.from(setsByExercise);
  for (final entry in updated.entries) {
    updated[entry.key] = entry.value
        .map((s) => s.groupId == targetGroupId ? s.copyWith(clearGroupId: true) : s)
        .toList();
  }
  return updated;
}

/// Pure function: returns a map of groupId → list of exerciseIds in that superset.
Map<String, List<String>> getSupersetGroups(
  Map<String, List<WorkoutSet>> setsByExercise,
) {
  final groups = <String, List<String>>{};
  for (final entry in setsByExercise.entries) {
    final firstGroupId = entry.value.isNotEmpty ? entry.value.first.groupId : null;
    if (firstGroupId != null) {
      groups.putIfAbsent(firstGroupId, () => []).add(entry.key);
    }
  }
  // Remove any "groups" with only one exercise (orphaned groupId)
  groups.removeWhere((_, ids) => ids.length < 2);
  return groups;
}
```

Then add methods to `ActiveWorkoutController`:

```dart
Future<void> linkSuperset(String exerciseId1, String exerciseId2) async {
  final updated = linkSupersetSets(state.setsByExercise, exerciseId1, exerciseId2);
  state = state.copyWith(setsByExercise: updated);
  // Persist updated groupIds
  for (final eid in [exerciseId1, exerciseId2]) {
    for (final s in updated[eid] ?? []) {
      await _workoutRepository.updateSet(s);
    }
  }
}

Future<void> unlinkSuperset(String exerciseId) async {
  final oldSets = state.setsByExercise;
  final targetGroupId = (oldSets[exerciseId] ?? []).isNotEmpty
      ? oldSets[exerciseId]!.first.groupId
      : null;
  if (targetGroupId == null) return;

  final updated = unlinkSupersetSets(oldSets, exerciseId);
  state = state.copyWith(setsByExercise: updated);
  // Persist cleared groupIds
  for (final entry in updated.entries) {
    for (final s in entry.value) {
      if (oldSets[entry.key]?.any((old) => old.id == s.id && old.groupId == targetGroupId) == true) {
        await _workoutRepository.updateSet(s);
      }
    }
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/features/workout/presentation/controllers/superset_test.dart`
Expected: PASS (3 tests)

**Step 5: Run full test suite**

Run: `flutter test`
Expected: All 309+ tests pass

**Step 6: Commit**

```bash
git add test/features/workout/presentation/controllers/superset_test.dart lib/features/workout/presentation/controllers/active_workout_controller.dart
git commit -m "feat: add superset linking/unlinking controller logic with tests"
```

---

### Task 2: Add l10n strings for superset UI

**Files:**
- Modify: `lib/l10n/app_en.arb`

**Step 1: Add new strings to ARB file**

Add before the closing `}` in `app_en.arb`:

```json
  "supersetLabel": "Superset",
  "linkAsSuperset": "Link as Superset",
  "breakSuperset": "Break Superset",
  "supersetWith": "Superset with {name}",
  "@supersetWith": {
    "placeholders": { "name": { "type": "String" } }
  },
  "selectSupersetPartner": "Select Exercise to Link",
  "noOtherExercises": "Add another exercise first"
```

**Step 2: Regenerate l10n**

Run: `flutter gen-l10n`
Expected: Success, no errors

**Step 3: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/generated/
git commit -m "feat: add superset localisation strings"
```

---

### Task 3: Add superset visual grouping to active workout screen

**Files:**
- Modify: `lib/features/workout/presentation/screens/active_workout_screen.dart`

**Step 1: Update the exercise list in `_buildActiveWorkout` to visually group supersets**

The key changes to `active_workout_screen.dart`:

1. Import `uuid` package for the controller functions.

2. In `_buildActiveWorkout`, compute superset groups and render linked exercises together with a visual indicator:

```dart
Widget _buildActiveWorkout(
  BuildContext context,
  WidgetRef ref,
  ActiveWorkoutState state,
  ActiveWorkoutController controller,
) {
  // ... existing empty state handling ...

  final supersetGroups = getSupersetGroups(state.setsByExercise);
  // Build a set of exerciseIds that are in a superset
  final supersetExerciseIds = <String>{};
  for (final ids in supersetGroups.values) {
    supersetExerciseIds.addAll(ids);
  }

  // Track which superset groups we've already rendered
  final renderedGroups = <String>{};

  return ListView(
    padding: const EdgeInsets.only(bottom: 88),
    children: [
      const RestTimerWidget(),
      for (final exercise in state.exercises) ...[
        if (supersetExerciseIds.contains(exercise.id)) ...[
          // Find this exercise's group
          () {
            final groupId = state.setsByExercise[exercise.id]
                ?.firstOrNull?.groupId;
            if (groupId != null && !renderedGroups.contains(groupId)) {
              renderedGroups.add(groupId);
              final groupExerciseIds = supersetGroups[groupId]!;
              final groupExercises = state.exercises
                  .where((e) => groupExerciseIds.contains(e.id))
                  .toList();
              return _SupersetGroup(
                exercises: groupExercises,
                state: state,
                controller: controller,
                onUnlink: (eid) => controller.unlinkSuperset(eid),
              );
            }
            return const SizedBox.shrink(); // Already rendered this group
          }(),
        ] else ...[
          _ExerciseSection(
            exercise: exercise,
            sets: state.setsByExercise[exercise.id] ?? [],
            ghostSets: state.remainingGhosts(exercise.id),
            suggestion: state.nextGhostSet(exercise.id),
            onLogSet: ({ ... }) { ... },
            onDeleteSet: (setId) => controller.deleteSet(setId, exercise.id),
            onEditSet: (updatedSet) => controller.updateSet(updatedSet),
            onLinkSuperset: () => _showSupersetPicker(context, ref, exercise, state),
          ),
        ],
      ],
    ],
  );
}
```

3. Add `_SupersetGroup` widget — a `Card` with a coloured left border that contains multiple `_ExerciseSection` widgets stacked:

```dart
class _SupersetGroup extends StatelessWidget {
  const _SupersetGroup({
    required this.exercises,
    required this.state,
    required this.controller,
    required this.onUnlink,
  });

  final List<Exercise> exercises;
  final ActiveWorkoutState state;
  final ActiveWorkoutController controller;
  final void Function(String exerciseId) onUnlink;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.tertiary,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Superset header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(Icons.link, size: 16, color: Theme.of(context).colorScheme.onTertiaryContainer),
                const SizedBox(width: 6),
                Text(
                  s.supersetLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.link_off, size: 18),
                  tooltip: s.breakSuperset,
                  onPressed: () => onUnlink(exercises.first.id),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Exercise sections inside the superset card
          for (final exercise in exercises)
            Padding(
              padding: const EdgeInsets.all(12),
              child: _ExerciseSectionContent(
                exercise: exercise,
                sets: state.setsByExercise[exercise.id] ?? [],
                ghostSets: state.remainingGhosts(exercise.id),
                suggestion: state.nextGhostSet(exercise.id),
                onLogSet: ({required double weight, required int reps, double? rpe, bool isWarmUp = false}) {
                  controller.logSet(exerciseId: exercise.id, weight: weight, reps: reps, rpe: rpe, isWarmUp: isWarmUp);
                },
                onDeleteSet: (setId) => controller.deleteSet(setId, exercise.id),
                onEditSet: (updatedSet) => controller.updateSet(updatedSet),
              ),
            ),
        ],
      ),
    );
  }
}
```

4. Extract the inner content of `_ExerciseSection` into `_ExerciseSectionContent` so it can be reused inside both standalone cards and superset groups.

5. Add a long-press handler on the exercise name row in `_ExerciseSection` to show "Link as Superset":

```dart
GestureDetector(
  onLongPress: onLinkSuperset,
  child: Row(
    children: [
      Expanded(child: Text(exercise.name, ...)),
      Chip(label: Text(exercise.muscleGroup.name, ...)),
    ],
  ),
),
```

6. Add `_showSupersetPicker` — a bottom sheet listing other non-superset exercises to pair with:

```dart
void _showSupersetPicker(BuildContext context, WidgetRef ref, Exercise exercise, ActiveWorkoutState state) {
  final s = S.of(context)!;
  final otherExercises = state.exercises.where((e) => e.id != exercise.id).toList();
  // Filter out exercises already in a superset
  final supersetGroups = getSupersetGroups(state.setsByExercise);
  final supersetExerciseIds = supersetGroups.values.expand((ids) => ids).toSet();
  final available = otherExercises.where((e) => !supersetExerciseIds.contains(e.id)).toList();

  if (available.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.noOtherExercises)),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(s.selectSupersetPartner, style: Theme.of(ctx).textTheme.titleMedium),
        ),
        const Divider(height: 1),
        for (final other in available)
          ListTile(
            leading: const Icon(Icons.link),
            title: Text(other.name),
            onTap: () {
              Navigator.pop(ctx);
              ref.read(activeWorkoutControllerProvider.notifier).linkSuperset(exercise.id, other.id);
            },
          ),
      ],
    ),
  );
}
```

**Step 2: Run dart analyze**

Run: `dart analyze lib/features/workout/presentation/screens/active_workout_screen.dart`
Expected: No new errors

**Step 3: Run tests**

Run: `flutter test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add lib/features/workout/presentation/screens/active_workout_screen.dart
git commit -m "feat: add superset visual grouping and linking UI in active workout"
```

---

## Part B: Notifications / Workout Reminders (2.6)

### Task 4: Add flutter_local_notifications dependency

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add dependency**

Add to `dependencies:` section in `pubspec.yaml`:

```yaml
  flutter_local_notifications: ^18.0.1
  timezone: ^0.10.0
```

**Step 2: Install**

Run: `flutter pub get`
Expected: Success

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_local_notifications and timezone dependencies"
```

---

### Task 5: Create NotificationService

**Files:**
- Create: `lib/features/notifications/data/notification_service.dart`
- Create: `test/features/notifications/data/notification_service_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/notifications/data/notification_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/notifications/domain/models/reminder_settings.dart';

void main() {
  group('ReminderSettings', () {
    test('default has no days selected and 18:00 time', () {
      const settings = ReminderSettings();
      expect(settings.enabledDays, isEmpty);
      expect(settings.hour, 18);
      expect(settings.minute, 0);
      expect(settings.streakReminderEnabled, isFalse);
    });

    test('copyWith updates days', () {
      const settings = ReminderSettings();
      final updated = settings.copyWith(enabledDays: {DateTime.monday, DateTime.wednesday});
      expect(updated.enabledDays, {DateTime.monday, DateTime.wednesday});
      expect(updated.hour, 18);
    });

    test('hasReminders is true when days are selected', () {
      final settings = const ReminderSettings().copyWith(
        enabledDays: {DateTime.monday},
      );
      expect(settings.hasReminders, isTrue);
    });

    test('hasReminders is false when no days selected', () {
      const settings = ReminderSettings();
      expect(settings.hasReminders, isFalse);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/notifications/data/notification_service_test.dart`
Expected: FAIL — `ReminderSettings` not defined

**Step 3: Create the domain model**

```dart
// lib/features/notifications/domain/models/reminder_settings.dart

class ReminderSettings {
  final Set<int> enabledDays; // DateTime.monday (1) through DateTime.sunday (7)
  final int hour;
  final int minute;
  final bool streakReminderEnabled;

  const ReminderSettings({
    this.enabledDays = const {},
    this.hour = 18,
    this.minute = 0,
    this.streakReminderEnabled = false,
  });

  bool get hasReminders => enabledDays.isNotEmpty;

  ReminderSettings copyWith({
    Set<int>? enabledDays,
    int? hour,
    int? minute,
    bool? streakReminderEnabled,
  }) {
    return ReminderSettings(
      enabledDays: enabledDays ?? this.enabledDays,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      streakReminderEnabled: streakReminderEnabled ?? this.streakReminderEnabled,
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/notifications/data/notification_service_test.dart`
Expected: PASS (4 tests)

**Step 5: Create the notification service**

```dart
// lib/features/notifications/data/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../domain/models/reminder_settings.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialised = true;
  }

  Future<void> scheduleWeeklyReminders(ReminderSettings reminderSettings) async {
    // Cancel all existing reminders first
    await cancelAllReminders();

    for (final day in reminderSettings.enabledDays) {
      await _plugin.zonedSchedule(
        day, // Use day number as notification ID (1-7)
        'Time to work out!',
        'Your scheduled workout reminder',
        _nextInstanceOfDayAndTime(day, reminderSettings.hour, reminderSettings.minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'workout_reminders',
            'Workout Reminders',
            channelDescription: 'Scheduled workout reminder notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'workout_reminder',
      );
    }
  }

  Future<void> scheduleStreakReminder(int hour, int minute) async {
    const streakId = 100;
    await _plugin.zonedSchedule(
      streakId,
      'Don\'t break your streak!',
      'You haven\'t logged a workout today',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminders',
          'Streak Reminders',
          channelDescription: 'Reminder when workout streak is at risk',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'streak_reminder',
    );
  }

  Future<void> cancelStreakReminder() async {
    await _plugin.cancel(100);
  }

  Future<void> cancelAllReminders() async {
    for (var i = 1; i <= 7; i++) {
      await _plugin.cancel(i);
    }
    await _plugin.cancel(100);
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int day, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Find the next occurrence of the target day
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the time has already passed today, schedule for next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
```

**Step 6: Commit**

```bash
git add lib/features/notifications/ test/features/notifications/
git commit -m "feat: add ReminderSettings model and NotificationService"
```

---

### Task 6: Create reminder settings provider (SharedPreferences persistence)

**Files:**
- Create: `lib/features/notifications/presentation/providers/reminder_settings_provider.dart`
- Create: `test/features/notifications/presentation/providers/reminder_settings_provider_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/notifications/presentation/providers/reminder_settings_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/notifications/domain/models/reminder_settings.dart';

void main() {
  group('ReminderSettings serialisation', () {
    test('daysToString and stringToDays roundtrip', () {
      final days = {DateTime.monday, DateTime.wednesday, DateTime.friday};
      final encoded = daysToString(days);
      final decoded = stringToDays(encoded);
      expect(decoded, days);
    });

    test('empty days produce empty string', () {
      expect(daysToString({}), '');
      expect(stringToDays(''), isEmpty);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/notifications/presentation/providers/reminder_settings_provider_test.dart`
Expected: FAIL

**Step 3: Create the provider**

```dart
// lib/features/notifications/presentation/providers/reminder_settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/reminder_settings.dart';
import '../../data/notification_service.dart';

String daysToString(Set<int> days) {
  final sorted = days.toList()..sort();
  return sorted.join(',');
}

Set<int> stringToDays(String value) {
  if (value.isEmpty) return {};
  return value.split(',').map(int.parse).toSet();
}

class ReminderSettingsNotifier extends StateNotifier<ReminderSettings> {
  ReminderSettingsNotifier() : super(const ReminderSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    state = ReminderSettings(
      enabledDays: stringToDays(prefs.getString('reminder_days') ?? ''),
      hour: prefs.getInt('reminder_hour') ?? 18,
      minute: prefs.getInt('reminder_minute') ?? 0,
      streakReminderEnabled: prefs.getBool('streak_reminder') ?? false,
    );
  }

  Future<void> toggleDay(int day) async {
    final days = Set<int>.from(state.enabledDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    state = state.copyWith(enabledDays: days);
    await _persist();
    await _reschedule();
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _persist();
    await _reschedule();
  }

  Future<void> toggleStreakReminder() async {
    final newValue = !state.streakReminderEnabled;
    state = state.copyWith(streakReminderEnabled: newValue);
    await _persist();
    if (newValue) {
      await NotificationService().scheduleStreakReminder(state.hour, state.minute);
    } else {
      await NotificationService().cancelStreakReminder();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminder_days', daysToString(state.enabledDays));
    await prefs.setInt('reminder_hour', state.hour);
    await prefs.setInt('reminder_minute', state.minute);
    await prefs.setBool('streak_reminder', state.streakReminderEnabled);
  }

  Future<void> _reschedule() async {
    final service = NotificationService();
    await service.scheduleWeeklyReminders(state);
    if (state.streakReminderEnabled) {
      await service.scheduleStreakReminder(state.hour, state.minute);
    }
  }
}

final reminderSettingsProvider =
    StateNotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
  (ref) => ReminderSettingsNotifier(),
);
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/notifications/presentation/providers/reminder_settings_provider_test.dart`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add lib/features/notifications/presentation/providers/ test/features/notifications/presentation/
git commit -m "feat: add reminder settings provider with SharedPreferences persistence"
```

---

### Task 7: Add notification l10n strings

**Files:**
- Modify: `lib/l10n/app_en.arb`

**Step 1: Add strings**

Add before the closing `}` in `app_en.arb`:

```json
  "sectionReminders": "Reminders",
  "workoutReminders": "Workout Reminders",
  "workoutRemindersSubtitle": "Get notified on your training days",
  "reminderTime": "Reminder Time",
  "reminderTimeSubtitle": "Time to receive workout reminders",
  "reminderDays": "Training Days",
  "streakReminder": "Streak Reminder",
  "streakReminderSubtitle": "Remind me if I haven\u0027t worked out today",
  "mondayShort": "Mon",
  "tuesdayShort": "Tue",
  "wednesdayShort": "Wed",
  "thursdayShort": "Thu",
  "fridayShort": "Fri",
  "saturdayShort": "Sat",
  "sundayShort": "Sun",
  "notificationPermissionRequired": "Notification permission is required for reminders",
  "reminderTimeOfDay": "{hour}:{minute}",
  "@reminderTimeOfDay": {
    "placeholders": {
      "hour": { "type": "String" },
      "minute": { "type": "String" }
    }
  }
```

**Step 2: Regenerate l10n**

Run: `flutter gen-l10n`
Expected: Success

**Step 3: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/generated/
git commit -m "feat: add notification reminder localisation strings"
```

---

### Task 8: Add reminders section to settings screen

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

**Step 1: Add the reminders UI section**

Add imports at top:

```dart
import '../../../notifications/presentation/providers/reminder_settings_provider.dart';
import '../../../notifications/domain/models/reminder_settings.dart';
```

Add a new section in the `ListView` children after the rest timer section and before the data section:

```dart
_SectionHeader(title: s.sectionReminders),
_ReminderDaysPicker(ref: ref, settings: ref.watch(reminderSettingsProvider)),
ListTile(
  leading: const Icon(Icons.access_time),
  title: Text(s.reminderTime),
  subtitle: Text(s.reminderTimeSubtitle),
  trailing: Text(
    s.reminderTimeOfDay(
      ref.watch(reminderSettingsProvider).hour.toString().padLeft(2, '0'),
      ref.watch(reminderSettingsProvider).minute.toString().padLeft(2, '0'),
    ),
    style: Theme.of(context).textTheme.bodyLarge,
  ),
  onTap: () async {
    final settings = ref.read(reminderSettingsProvider);
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
    );
    if (time != null) {
      ref.read(reminderSettingsProvider.notifier).setTime(time.hour, time.minute);
    }
  },
),
SwitchListTile(
  secondary: const Icon(Icons.local_fire_department_outlined),
  title: Text(s.streakReminder),
  subtitle: Text(s.streakReminderSubtitle),
  value: ref.watch(reminderSettingsProvider).streakReminderEnabled,
  onChanged: (_) => ref.read(reminderSettingsProvider.notifier).toggleStreakReminder(),
),
```

Add the day picker widget at the bottom of the file:

```dart
class _ReminderDaysPicker extends StatelessWidget {
  const _ReminderDaysPicker({required this.ref, required this.settings});

  final WidgetRef ref;
  final ReminderSettings settings;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final dayLabels = {
      DateTime.monday: s.mondayShort,
      DateTime.tuesday: s.tuesdayShort,
      DateTime.wednesday: s.wednesdayShort,
      DateTime.thursday: s.thursdayShort,
      DateTime.friday: s.fridayShort,
      DateTime.saturday: s.saturdayShort,
      DateTime.sunday: s.sundayShort,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: dayLabels.entries.map((entry) {
          final selected = settings.enabledDays.contains(entry.key);
          return FilterChip(
            label: Text(entry.value),
            selected: selected,
            onSelected: (_) => ref.read(reminderSettingsProvider.notifier).toggleDay(entry.key),
          );
        }).toList(),
      ),
    );
  }
}
```

**Step 2: Run dart analyze**

Run: `dart analyze lib/features/settings/presentation/screens/settings_screen.dart`
Expected: No new errors

**Step 3: Run tests**

Run: `flutter test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat: add workout reminders section to settings screen"
```

---

### Task 9: Add Android platform configuration for notifications

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

**Step 1: Add notification permissions**

Add these permissions after the existing Bluetooth permissions:

```xml
    <!-- Notification permissions -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

Add the boot receiver and scheduled notification receiver inside `<application>`:

```xml
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
```

**Step 2: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "chore: add Android notification permissions and receivers"
```

---

### Task 10: Initialise NotificationService in main.dart

**Files:**
- Modify: `lib/main.dart`

**Step 1: Add init call**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'features/notifications/data/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  await NotificationService().init();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const RepFoundryApp(),
    ),
  );
}
```

**Step 2: Run dart analyze**

Run: `dart analyze lib/main.dart`
Expected: No errors

**Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialise notification service on app start"
```

---

### Task 11: Final verification

**Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests pass (309+ existing + new tests)

**Step 2: Run linter**

Run: `dart analyze`
Expected: 0 errors (only pre-existing info items)

**Step 3: Regenerate l10n**

Run: `flutter gen-l10n`
Expected: Success

**Step 4: Final commit (if any remaining changes)**

```bash
git add -A
git commit -m "feat: complete superset grouping UI and workout notifications (Tier 2.2 + 2.6)"
```
