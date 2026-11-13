# Read-only MCP Server for Desktop — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The desktop app (macOS, Windows, Linux) hosts a read-only MCP server on loopback so an assistant on the same machine can query the training log.

**Architecture:** A new `lib/features/mcp/` feature. Tool classes in `application/` are pure Dart over the existing repository interfaces and use cases, take a JSON argument map and return a JSON map. `data/McpServerHost` is the only file importing `mcp_dart`. It adapts the tools to a `StreamableMcpServer` bound to `127.0.0.1` behind a token, Host and Origin guard. A Riverpod `McpServerController` starts and stops the host as settings change, and a Settings card controls it.

**Tech Stack:** Flutter 3.50, Riverpod 3, Drift, `mcp_dart` ^2.4.3 (already added to `pubspec.yaml` in the worktree), SharedPreferences.

**Spec:** GitHub issue #154 (`gh issue view 154`). Open questions in it are settled as follows: free (no entitlement), default port 47600, heart-rate summaries only, JSON backup import is the way phone data reaches the desktop, and build-from-source only.

## Global Constraints

- Desktop only. Nothing binds a socket, and no Settings section appears, on iOS, Android or web. The gate is `isMcpHostSupported`, never `context.isDesktop`.
- Off by default. Bind `127.0.0.1` only, never `anyIPv4`.
- Read-only. Every tool declares `readOnlyHint: true`, and no tool calls a mutating repository method.
- Me-only by default. Every client-scoped read uses `kSelfClientId` unless "Include client data" is on. The UI's active client never affects results.
- Tools gated by a toggle are absent from the tool list, not present and refusing.
- Results never contain GPS coordinates.
- Units: weights `*_kg`, distances `*_km`, durations `*_seconds`, heart rate `*_bpm`. Timestamps are ISO 8601 with the local offset. Weekly buckets use the local week, starting Monday.
- Soft-deleted rows are never returned.
- `limit` defaults to 20, minimum 1, capped at 100. List tools return `next_cursor` (null when exhausted).
- An unknown id or bad argument is a tool error result (`isError: true`), not a protocol error.
- `application/` must not import `mcp_dart`, Flutter or presentation code.
- British spelling in code comments, UI copy and docs. All UI strings go through `lib/l10n/app_en.arb`, followed by `flutter gen-l10n`.
- Author Paul Snow, version `0.0.0` in any doc headers.
- Every new test is proven able to fail. Break the protected line, see red, then restore it (project testing guidelines). Negative assertions need a positive control.
- Stage files by name. `analysis_options.yaml` has an unrelated local edit made by tooling and must not be committed.

## Calls made while planning (deviations from the issue)

- **403, not 401.** Without OAuth metadata, `StreamableMcpServer` answers a failed `authenticationHandler` with 403. Advertising fake OAuth metadata to get 401 would push clients into an OAuth flow. We keep 403.
- **Origin rejection.** The SDK's Host check strips the port, and with no `allowedOrigins` it accepts any `localhost` origin. We pass `allowedOrigins: {kNoBrowserOrigin}` (`'https://no-browser-access.invalid'`), so any request carrying an `Origin` header fails the SDK's DNS-rebinding check with 403 before CORS or OPTIONS handling. Our own guard re-checks Origin, exact `Host` with port, and token.
- **Analytics refactor scope.** Only weekly volume and training load were pure functions. Muscle balance was inline in its provider, so it is extracted as `computeMuscleBalance`. PR timeline stays where it is because no tool needs it.
- **Templates and programmes are not client-scoped** in the data model (shared library). Their tools return all of them in both modes.
- **The Settings card lives in `settings_screen.dart`** as a private `_McpCard`, beside `_DataCard` and `_SyncRemindersCard`, because the row and card widgets there are private.
- **Mermaid** is not rendered by the docs build. The diagram goes in `src/docs/modules/dev/examples/mcp-request-flow.mmd` and is included as a `[source,mermaid]` block.

## Review Focus

1. **Another client's id passed to an id-taking tool while client data is off.** `get_workout`, `get_exercise_history` (`client_id`) and `get_health_profile` must answer "not found" or error, never the data. Test in Task 5.
2. **An in-progress workout.** `list_workouts` and `get_workout` return `completed_at: null` and `duration_seconds: null`, with sets so far. Neither throws on the null end. Test in Task 5.
3. **Rapid settings changes** (on, off, on; or a token regenerated while running). Exactly one server ends up bound, the old token is rejected, and no second socket is left behind. Test in Task 10.
4. **Malformed arguments.** `limit: "ten"`, `limit: 0`, `limit: 500`, `from: "yesterday"`, a forged `cursor`. Each gives a tool error or a clamped value, never an uncaught exception. Test in Task 4.
5. **A fresh install** (seed exercises only, no workouts). Every registered tool returns empty lists or zeroed summaries without throwing. Test in Task 8.

---

### Task 1: Spike — prove the SDK against two real clients (throwaway)

Nothing from this task is committed. Work in a temporary directory outside the repository, a `dart create -t console` project depending on `mcp_dart: ^2.4.3`.

- [ ] **Step 1:** Write `bin/spike.dart`. It starts a `StreamableMcpServer` on `host: '127.0.0.1'`, port 47699, path `/mcp`, `allowedOrigins: {'https://no-browser-access.invalid'}`, and an `authenticationHandler` allowing only `Authorization: Bearer spike-token`. It registers one tool `ping` with `annotations: ToolAnnotations(readOnlyHint: true)` and an input schema built from a raw `Map` (find the SDK's map-to-`JsonSchema` conversion, e.g. `JsonSchema.fromJson`). The tool returns structured content `{ "pong": true }` plus a JSON text fallback.
- [ ] **Step 2:** Client 1, TypeScript SDK: `npx -y @modelcontextprotocol/inspector --cli http://127.0.0.1:47699/mcp --transport http --header "Authorization: Bearer spike-token" --method tools/list`, then `--method tools/call --tool-name ping`. Expected: the tool is listed with `readOnlyHint: true`, and the call returns `pong`.
- [ ] **Step 3:** Client 2, mcp_dart client: `bin/client.dart` with `McpClient` + `StreamableHttpClientTransport` passing the header via `requestInit: {'headers': {...}}`. It lists tools and calls `ping`. Expected: same result.
- [ ] **Step 4:** Negative probes with `curl -i`: no token gives 403; `-H 'Origin: http://localhost:5173'` gives 403; `-H 'Host: evil.example:47699'` gives 403; `-H 'Host: localhost:1'` with a valid token gives 403, which proves our port check runs.
- [ ] **Step 5:** Record what was learnt (the exact schema conversion call, the structured-content constructor, the header option, whether the handler runs per session or per request) as a short note appended to this plan under "Spike result". If either client cannot connect, stop and report before Task 2.

### Task 2: Move analytics aggregates to an application layer

**Files:**
- Create: `lib/features/analytics/application/training_aggregates.dart`
- Modify: `lib/features/analytics/presentation/providers/weekly_volume_provider.dart`, `training_load_provider.dart`, `muscle_balance_provider.dart`
- Test: `test/features/analytics/application/training_aggregates_test.dart`

**Interfaces:**
- Produces: `SetData`, `WeeklyVolume`, `List<WeeklyVolume> computeWeeklyVolume(List<SetData>)`, `WeeklyLoad`, `List<WeeklyLoad> computeTrainingLoad(List<SetData>)`, `MuscleBalance`, `List<MuscleBalance> computeMuscleBalance(Iterable<WorkoutSet> sets, Map<String, Exercise> exercisesById)`.

- [ ] **Step 1:** Run `flutter test test/features/analytics`. Expected: all pass (baseline).
- [ ] **Step 2: Write failing tests** for `computeMuscleBalance`: skips warm-ups; skips sets whose exercise is missing from the map; percentages are of total volume *including* cardio, while cardio is omitted from the output (current behaviour); sorted by `MuscleGroup.index`; empty input gives `[]`.
- [ ] **Step 3:** Run them. Expected: FAIL, as the file does not exist.
- [ ] **Step 4:** Move `SetData`, `WeeklyVolume`, `computeWeeklyVolume`, `WeeklyLoad`, `computeTrainingLoad` and `MuscleBalance` verbatim into `training_aggregates.dart`. Extract the provider's inline loop as `computeMuscleBalance`. Each provider file imports it and re-exports what its callers used (`export '../../application/training_aggregates.dart' show ...;`), so screens and existing tests need no import changes. `muscleBalanceProvider` calls `computeMuscleBalance` over the flattened sets.
- [ ] **Step 5:** Run `flutter test test/features/analytics`. Expected: all pass, old and new.
- [ ] **Step 6:** Mutation check: change the cardio filter in `computeMuscleBalance` and confirm a test goes red, then restore it.
- [ ] **Step 7:** Commit `refactor: move analytics aggregates to an application layer (#154)`.

### Task 3: MCP settings, status and platform gate

**Files:**
- Create: `lib/features/mcp/domain/mcp_settings.dart`, `lib/features/mcp/domain/mcp_server_status.dart`, `lib/features/mcp/domain/mcp_host_support.dart`, `lib/features/mcp/data/mcp_platform.dart`, `lib/features/mcp/presentation/providers/mcp_settings_provider.dart`
- Test: `test/features/mcp/domain/mcp_host_support_test.dart`, `test/features/mcp/presentation/mcp_settings_provider_test.dart`

**Interfaces:**
- Produces:
  - `class McpSettings { bool enabled = false; int port = 47600; String token = ''; bool includeClients = false; bool includeHealthProfile = false; bool disclosureAccepted = false; McpSettings copyWith(...); }` with `const kDefaultMcpPort = 47600;`
  - `sealed class McpServerStatus` with `McpStopped()`, `McpRunning(int port)`, `McpFailed(String reason)`.
  - `bool isMcpHostSupported({bool isWeb = false, bool isMacOS = false, bool isWindows = false, bool isLinux = false})`
  - `bool mcpHostSupportedOnThisPlatform()`, in data, reading `kIsWeb` first and then `Platform`.
  - `final mcpHostSupportedProvider = Provider<bool>((ref) => mcpHostSupportedOnThisPlatform());`
  - `McpSettingsNotifier extends Notifier<McpSettings>` with `Future<void> ensureLoaded()`, `setEnabled(bool)`, `setPort(int)`, `regenerateToken()`, `setIncludeClients(bool)`, `setIncludeHealthProfile(bool)`, `acceptDisclosure()`; `mcpSettingsProvider`.
  - SharedPreferences keys: `mcp_enabled`, `mcp_port`, `mcp_token`, `mcp_include_clients`, `mcp_include_health_profile`, `mcp_disclosure_accepted`.
  - `String generateMcpToken()`: 32 bytes from `Random.secure()`, base64url without padding (43 chars).

- [ ] **Step 1: Failing tests:**
  - `isMcpHostSupported` is true for each of macOS, Windows and Linux, and false for web, for all-false (iOS/Android) and for `isWeb: true, isMacOS: true`.
  - With empty mock prefs, the notifier loads `enabled: false`, port 47600 and an empty token.
  - `setEnabled(true)` with an empty token generates and persists a 43-char token.
  - `regenerateToken()` changes the token and persists it.
  - `setPort` rejects values outside 1024–65535 with `ArgumentError`.
  - Values round-trip through prefs (a new container reads them back).
- [ ] **Step 2:** Run. Expected: FAIL (missing files).
- [ ] **Step 3:** Implement following the `RestTimerSettingsNotifier` pattern, with an `ensureLoaded()` future the controller can await, like `SyncSettingsNotifier.ensureLoaded`.
- [ ] **Step 4:** Run. Expected: PASS. Mutation: make `isMcpHostSupported` return true for all-false and see red.
- [ ] **Step 5:** Commit `feat: MCP settings and desktop platform gate (#154)`.

### Task 4: Tool contract, scope and argument parsing

**Files:**
- Create: `lib/features/mcp/application/mcp_tool.dart`, `lib/features/mcp/application/mcp_scope.dart`, `lib/features/mcp/application/mcp_args.dart`
- Test: `test/features/mcp/application/mcp_args_test.dart`, `test/features/mcp/application/mcp_scope_test.dart`

**Interfaces:**
- Produces:
  - `abstract class McpTool { String get name; String get description; Map<String, Object?> get inputSchema; Future<Map<String, Object?>> call(Map<String, Object?> args); }`. `inputSchema` is a raw JSON Schema object map.
  - `class McpToolError implements Exception { final String message; }`
  - `class McpScope { const McpScope({required bool includeClients, required ClientRepository clients}); bool canRead(String clientId); Future<String> resolveClientId(Map<String, Object?> args); }`.
    - `canRead` is `includeClients || clientId == kSelfClientId`.
    - `resolveClientId` returns `kSelfClientId` when `client_id` is absent.
    - When `client_id` is present and `includeClients` is false, it throws `McpToolError('client_id is not available')`.
    - When `client_id` is present and `includeClients` is true, the client must exist and not be deleted, else `McpToolError('Unknown client_id')`.
  - In `mcp_args.dart`:
    - `int parseLimit(Map args, {int defaultValue = 20, int max = 100})`: accepts int or integral num; clamps to 1..max; a non-number throws `McpToolError`.
    - `DateTime? parseDate(Map args, String key)`: ISO 8601 date or date-time; bad input throws `McpToolError`.
    - `String? requireString(Map args, String key)` / `String? optionalString(...)`.
    - `String encodeCursor(DateTime before)` / `DateTime? decodeCursor(Map args)`: base64url of epoch ms; a forged value throws `McpToolError('Invalid cursor')`.
    - `String isoLocal(DateTime)`: `toLocal()` ISO 8601 with a `+hh:mm` offset.
    - `double round1(double)`, which every `_kg`/`_km` value goes through.
  - `Map<String, Object?> objectSchema(Map<String, Object?> properties, {List<String> required = const []})`, a small schema builder.

- [ ] **Step 1: Failing tests** for each Review Focus #4 input:
  - `parseLimit` with `"ten"` throws; 0 gives 1; 500 gives 100; absent gives 20; `12.0` gives 12.
  - `parseDate` with `"yesterday"` throws; `"2026-11-01"` gives local midnight.
  - `decodeCursor` with `"!!"` throws; it round-trips with `encodeCursor`.
  - `isoLocal` output parses back to the same instant.
  - `McpScope` with clients off: `client_id` throws and `canRead('other')` is false. With clients on: a deleted client throws and an existing client returns its id.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS. Mutation: drop the clamp in `parseLimit` and see red.
- [ ] **Step 5:** Commit `feat: MCP tool contract, client scope and argument parsing (#154)`.

### Task 5: Workout tools

**Files:**
- Create: `lib/features/mcp/application/tools/workout_tools.dart`
- Test: `test/features/mcp/application/tools/workout_tools_test.dart`, using `InMemoryWorkoutRepository`, `InMemoryExerciseRepository`, `InMemoryCardioSessionRepository`, `InMemoryStretchingSessionRepository`, and a small fake `ClientRepository`.

**Interfaces:**
- Consumes: Task 4.
- Produces: `ListWorkoutsTool(WorkoutRepository, ExerciseRepository, McpScope)` and `GetWorkoutTool(WorkoutRepository, ExerciseRepository, CardioSessionRepository, StretchingSessionRepository, McpScope)`.

Result shapes:
- `list_workouts`, args `from`, `to`, `limit`, `cursor`, `client_id`. Returns `{ workouts: [{ id, started_at, completed_at|null, duration_seconds|null, notes|null, exercises: [name], working_set_count, total_volume_kg }], next_cursor|null }`. Newest first.
  - Paging: `getWorkoutHistory(clientId, limit: limit + 1, before: cursor ?? to)`. `before` is exclusive. Drop rows before `from`. `next_cursor` is the last returned `startedAt`, present only if an extra row existed.
  - Warm-ups are excluded from count and volume. Deleted rows are skipped.
- `get_workout`, arg `workout_id` (required). Returns `{ id, started_at, completed_at, duration_seconds, notes, exercises: [{ exercise_id, name, sets: [{ set_order, weight_kg, reps, rpe|null, is_warm_up, estimated_1rm_kg, avg_hr_bpm|null, peak_hr_bpm|null, logged_at }] }], cardio: [{ exercise_name, duration_seconds, distance_km|null, pace_min_per_km|null, incline|null, avg_hr_bpm|null }], stretching: [{ name, body_area|null, side|null, duration_seconds }] }`.
  - Exercises are ordered by their first set's `setOrder`. A stretch's `name` is `customName ?? type`.
  - Missing, deleted, or `!scope.canRead(workout.clientId)` all give `McpToolError('Workout not found')`, the same message so existence is not leaked.

- [ ] **Step 1: Failing tests:**
  - Paging over 25 seeded workouts with limit 10 yields 10, 10 and 5, with no duplicates and a null cursor at the end.
  - `from`/`to` filter.
  - A warm-up is excluded from volume.
  - A deleted workout is absent.
  - Review Focus #2: an in-progress workout has `completed_at` null, `duration_seconds` null and the sets so far.
  - Review Focus #1: `get_workout` on a second client's workout with clients off gives a "Workout not found" error. Positive control: the same id with clients on returns it.
  - `get_workout` result contains no key named `latitude`/`longitude`/`track_points` anywhere (recursive key walk). Control: the seeded cardio session has track points saved.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS. Mutations: remove the `canRead` check (the Review Focus #1 test must go red); remove the warm-up filter (red).
- [ ] **Step 5:** Commit `feat: MCP workout tools (#154)`.

### Task 6: Exercise, record and training summary tools

**Files:**
- Create: `lib/features/mcp/application/tools/exercise_tools.dart`, `lib/features/mcp/application/tools/summary_tools.dart`
- Test: `test/features/mcp/application/tools/exercise_tools_test.dart`, `test/features/mcp/application/tools/summary_tools_test.dart`

**Interfaces:**
- Consumes: Tasks 2 and 4, `CalculateProgressUseCase`.
- Produces: `ListExercisesTool(ExerciseRepository, WorkoutRepository, McpScope)`, `GetExerciseHistoryTool(ExerciseRepository, CalculateProgressUseCase, McpScope)`, `ListPersonalRecordsTool(PersonalRecordRepository, ExerciseRepository, McpScope)`, `GetTrainingSummaryTool(WorkoutRepository, ExerciseRepository, McpScope, DateTime Function() now)`.

Result shapes:
- `list_exercises`, args `query`, `muscle_group` (enum `.name`; unknown value is a tool error). Returns `{ exercises: [{ id, name, category, muscle_group, equipment, is_custom, times_used }] }`. `times_used` comes from `getExerciseUsageCounts(clientId)`. Sorted by name.
- `get_exercise_history`, args `exercise_id` (required), `from`, `to`, `limit` (number of sessions), `client_id`. Returns `{ exercise_id, name, max_estimated_1rm_kg|null, total_volume_kg, sessions: [{ workout_id, date, sets: [{ weight_kg, reps, rpe, is_warm_up, estimated_1rm_kg }] }] }`. Sessions newest first. An unknown or deleted exercise gives `McpToolError('Exercise not found')`.
- `list_personal_records`, args `exercise_id`, `from`, `client_id`. Returns `{ records: [{ exercise_id, exercise_name, record_type, value, unit, achieved_at }] }`.
  - `unit` is `kg` for `estimatedOneRepMax`/`maxWeight`, `reps` for `maxReps`, and `kg_x_reps` for `maxVolume`. Newest first.
- `get_training_summary`, arg `weeks` (default 8, clamp 1–52). Returns `{ weeks: [{ week_start (yyyy-MM-dd), total_volume_kg, percent_change|null, working_set_count, avg_rpe|null, load }], muscle_balance: [{ muscle_group, volume_percent }] }`.
  - Data: completed workouts from `getWorkoutHistory(limit: 200)` and their non-warm-up sets.
  - Only sets whose local week start is within the last `weeks` weeks count, the current week included.
  - Weekly figures come from `computeWeeklyVolume` and `computeTrainingLoad`, joined on `weekStart`. Muscle balance comes from `computeMuscleBalance` over the same windowed sets. `avg_rpe` is null when no set had RPE (the aggregate's `0.0` is mapped to null).

- [ ] **Step 1: Failing tests:**
  - `times_used` counts.
  - `muscle_group: "wings"` gives an error.
  - History groups sets by session.
  - A PR `unit` per type.
  - The summary window excludes a set 10 weeks old with `weeks: 8`; a control with `weeks: 12` includes it.
  - **Seam test:** for a seed entirely inside the window, `get_training_summary`'s `total_volume_kg` per week equals `weeklyVolumeProvider`'s output, and `muscle_balance` equals `muscleBalanceProvider`'s, run in a `ProviderContainer` over the same in-memory repos with `activeClientProvider` overridden to Me.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS. Mutation: make the window off by one week and see red.
- [ ] **Step 5:** Commit `feat: MCP exercise, record and training summary tools (#154)`.

### Task 7: Cardio and heart-rate tools

**Files:**
- Create: `lib/features/mcp/application/tools/cardio_tools.dart`
- Test: `test/features/mcp/application/tools/cardio_tools_test.dart`

**Interfaces:**
- Consumes: `BuildCardioHistoryUseCase.execute({required String clientId})`, `CardioProgress.compute(entries, now:, weeks: 6)` and `BuildWeeklyHeartReportUseCase.execute({required clientId, required now})`.
- Produces: `ListCardioSessionsTool(BuildCardioHistoryUseCase, McpScope)`, `GetCardioProgressTool(BuildCardioHistoryUseCase, McpScope, DateTime Function() now)`, `GetWeeklyHeartReportTool(BuildWeeklyHeartReportUseCase, McpScope, DateTime Function() now)`.

Result shapes:
- `list_cardio_sessions`, args `sport` (case-insensitive match on exercise name), `from`, `to`, `limit`, `cursor`, `client_id`. Returns `{ sessions: [{ id, workout_id, sport, started_at, duration_seconds, distance_km|null, pace_min_per_km|null, incline|null, avg_hr_bpm|null }], next_cursor|null }`. Newest first. The cursor is on `startedAt`, applied in memory.
- `get_cardio_progress`, arg `sport`. Returns `{ weeks: 6, total_distance_km, session_count, total_duration_seconds, weekly_distance_km: [6 numbers, oldest first], best_pace_min_per_km|null, avg_hr_bpm|null, pace_trend: [{ date, pace_min_per_km }] }`.
- `get_weekly_heart_report`, no args except `client_id`. Returns `{ sessions: [{ workout_id, kind, title, started_at, avg_bpm, peak_bpm }], avg_bpm|null, peak_bpm|null, daily_peak_bpm: [7], seconds_in_zone: { "1": n, ... } }`. Read the `WeeklyHeartReport` fields and map each one.

- [ ] **Step 1: Failing tests:**
  - The sport filter.
  - Pages without overlap.
  - No GPS keys anywhere (recursive walk), with a control that the session has track points.
  - Progress has six weekly buckets.
  - The heart report maps `secondsInZone` keys to strings.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS. Mutation: drop the sport filter and see red.
- [ ] **Step 5:** Commit `feat: MCP cardio and heart-rate tools (#154)`.

### Task 8: Library and client tools, and the tool catalogue

**Files:**
- Create: `lib/features/mcp/application/tools/library_tools.dart`, `lib/features/mcp/application/tools/client_tools.dart`, `lib/features/mcp/application/mcp_tool_catalogue.dart`
- Test: `test/features/mcp/application/tools/library_tools_test.dart`, `test/features/mcp/application/mcp_tool_catalogue_test.dart`

**Interfaces:**
- Produces:
  - `ListBodyMetricsTool(BodyMetricRepository, McpScope)`, which returns `{ entries: [{ date, weight_kg, body_fat_percent|null, notes|null }] }` newest first, with args `from`, `to`, `client_id`.
  - `ListTemplatesTool(WorkoutTemplateRepository)`, which returns `{ templates: [{ id, name, exercises: [{ exercise_id, name, target_sets, target_reps }] }] }`, ordered by `orderIndex`.
  - `ListProgrammesTool(ProgrammeRepository, ExerciseRepository)`, which returns `{ programmes: [{ id, name, duration_weeks, started_at|null, days: [{ week, day_of_week, template_id, template_name }], progression_rules: [{ exercise_id, exercise_name, type, value, frequency_weeks }] }] }`, from `getDaysForProgramme` and `getRulesForProgramme`.
  - `ListClientsTool(ClientRepository)`, which returns `{ clients: [{ id, name, is_self }] }` and excludes deleted clients.
  - `GetHealthProfileTool(HealthProfileRepository, McpScope)`, which returns `{ client_id, age|null, resting_hr_bpm|null, measured_max_hr_bpm|null, clinician_max_hr_bpm|null, beta_blocker, heart_condition }`.
  - `class McpToolDeps` holding the ten repositories, three use cases and `DateTime Function() now`.
  - `List<McpTool> buildMcpTools(McpToolDeps deps, McpSettings settings)`:
    - Always: the 12 base tools.
    - `list_clients` only if `includeClients`.
    - `get_health_profile` only if `includeHealthProfile`.
    - The `McpScope` is built from `settings.includeClients`.
  - `const String kMcpServerInstructions`: states the unit, timestamp, local-week, soft-delete, limit and cursor conventions, and that data is read-only and Me-only unless client access is on.

- [ ] **Step 1: Failing tests:**
  - With default settings, tool names are the 12 base names, and `list_clients` and `get_health_profile` are absent. Control: both toggles on gives 14.
  - Every tool's `inputSchema['type'] == 'object'`.
  - **Read-only proof:** build every tool over fakes whose mutating methods (`create*`, `update*`, `delete*`, `add*`, `remove*`, `save*`, `mark*`, `softDelete*`) throw `StateError('write')`. Call each tool with valid args on a seeded database and expect none to throw. Control: a test-only tool that calls a mutating method does throw.
  - **Review Focus #5:** on empty repos (seed exercises only), every tool with no required args returns without throwing, and list keys are empty.
  - Library tools exclude deleted rows.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS. Mutation: always include `list_clients` and see red.
- [ ] **Step 5:** Commit `feat: MCP library and client tools and tool catalogue (#154)`.

### Task 9: Loopback host

**Files:**
- Create: `lib/features/mcp/data/mcp_request_guard.dart`, `lib/features/mcp/data/mcp_server_host.dart`
- Modify: `macos/Runner/Release.entitlements` (add `com.apple.security.network.server` = true)
- Test: `test/features/mcp/data/mcp_request_guard_test.dart`, `test/features/mcp/data/mcp_server_host_test.dart` (plain `test()`, real sockets)

**Interfaces:**
- Consumes: `McpTool`, `kMcpServerInstructions`, and the spike's notes.
- Produces:
  - `bool isMcpRequestAllowed({required String? host, required String? origin, required String? authorization, required int port, required String token})`.
    - True only when `origin` is null or blank.
    - `host` must equal `127.0.0.1:$port` or `localhost:$port`, case-insensitive.
    - `token` must be non-empty and `authorization == 'Bearer $token'`, compared in constant time.
  - `const kNoBrowserOrigin = 'https://no-browser-access.invalid';`
  - `abstract class McpHost { Future<int> start(); Future<void> stop(); }`
  - `class McpServerHost implements McpHost { McpServerHost({required int port, required String token, required List<McpTool> Function() tools}); }`
    - `start()` returns the bound port and accepts port 0 in tests. A bind failure propagates as `SocketException`.
    - It builds a `StreamableMcpServer` with:
      - `host: '127.0.0.1'`, `path: '/mcp'`
      - `allowedOrigins: {kNoBrowserOrigin}`
      - `authenticationHandler` calling `isMcpRequestAllowed` with the bound port
      - a `serverFactory` creating an `McpServer` (`Implementation(name: 'repfoundry', version: '0.1.0')`) with `instructions: kMcpServerInstructions`, registering each tool with `ToolAnnotations(readOnlyHint: true)`
    - A tool callback returns structured content plus `jsonEncode` text. `McpToolError` becomes `isError: true` with its message. Any other exception becomes `isError: true` with `'Internal error'` and is not rethrown.
  - `typedef McpHostFactory = McpHost Function({required int port, required String token, required List<McpTool> Function() tools});`

- [ ] **Step 1: Failing guard tests:**
  - Exact host and port with a token passes. Each single deviation fails: wrong port, `evil.example:port`, missing token, wrong token, `Bearer ` with an empty configured token, a present Origin.
- [ ] **Step 2: Failing host tests** on port 0 with an mcp_dart client:
  - `tools/list` returns the stub tools, each with `readOnlyHint: true`.
  - A call returns structured content.
  - `McpToolError` gives `isError` with its message.
  - Raw `HttpClient` POSTs: no token, `Origin: http://localhost:5173`, and wrong Host each give 403. Control: the same POST with a correct Host and token is not 403.
  - The server socket's address is loopback: connecting via a non-loopback local interface address, if one exists, is refused (skip the case when none exists).
  - After `stop()`, a connection is refused.
- [ ] **Step 3:** Run. Expected: FAIL.
- [ ] **Step 4:** Implement, and add the macOS entitlement.
- [ ] **Step 5:** Run. Expected: PASS. Mutations: drop the Origin clause from the guard (guard test red); change the bind host to `0.0.0.0` (loopback test red, where an interface exists).
- [ ] **Step 6:** Commit `feat: loopback MCP host with token, Host and Origin checks (#154)`.

### Task 10: Server controller, startup and Settings card

**Files:**
- Create: `lib/features/mcp/presentation/providers/mcp_server_controller.dart`
- Modify: `lib/main.dart` (`_AppWithLifecycleState.initState` reads `mcpServerControllerProvider`), `lib/features/settings/presentation/screens/settings_screen.dart` (add `_McpCard` with `KineticSectionLabel(s.sectionMcp)` between Data and About, shown only when `mcpHostSupportedProvider` is true), `lib/l10n/app_en.arb`
- Test: `test/features/mcp/presentation/mcp_server_controller_test.dart`, `test/features/settings/presentation/screens/settings_mcp_test.dart`

**Interfaces:**
- Produces:
  - `final mcpHostFactoryProvider = Provider<McpHostFactory>(...)`, defaulting to `McpServerHost.new`.
  - `final mcpToolDepsProvider = Provider<McpToolDeps>(...)`, built from `core/providers.dart` and `clock.now`.
  - `McpServerController extends Notifier<McpServerStatus>`; `mcpServerControllerProvider`.
    - `build()`: if `!ref.watch(mcpHostSupportedProvider)`, return `McpStopped()` and do nothing else. Otherwise await `ensureLoaded`, `ref.listen(mcpSettingsProvider, ...)`, apply the current settings, and `ref.onDispose(stop)`.
    - Applying settings is serialised through a single `Future` chain. Each change stops the current host, then, if `enabled` and the token is non-empty, creates a host with `buildMcpTools(deps, settings)` and starts it. The result is `McpRunning(port)`, or `McpFailed(e.toString())` on any error. Errors are never rethrown.
- ARB keys (English):
  - `sectionMcp` "AI Assistant Access (MCP)"
  - `mcpEnableTitle` "Allow assistants to read my data"
  - `mcpEnableSubtitle` "Apps on this computer can query your training log"
  - `mcpStatusTitle` "Status"
  - `mcpStatusStopped` "Off"
  - `mcpStatusRunning` "Running on 127.0.0.1:{port}"
  - `mcpStatusFailed` "Could not start: {reason}"
  - `mcpEndpointTitle` "Endpoint"
  - `mcpTokenTitle` "Access token"
  - `mcpCopy` "Copy"
  - `mcpCopied` "Copied"
  - `mcpRegenerateToken` "Regenerate"
  - `mcpPortTitle` "Port"
  - `mcpPortInvalid` "Enter a port between 1024 and 65535"
  - `mcpIncludeClientsTitle` "Include client data"
  - `mcpIncludeClientsSubtitle` "Let assistants read your clients' training"
  - `mcpIncludeHealthTitle` "Include health profile"
  - `mcpIncludeHealthSubtitle` "Age, heart-rate limits and medical flags"
  - `mcpDisclosureTitle` "Before you turn this on"
  - `mcpDisclosureBody` "An assistant you connect can read your training data. Most assistants send what they read to their AI provider. Nothing is shared until you connect an assistant using the endpoint and token shown here."
  - `mcpDisclosureAccept` "Turn on"
  - `cancel`, reusing the existing key if one exists.

- [ ] **Step 1: Failing controller tests**, with a fake `McpHost` recording start and stop calls and a `mcpHostSupportedProvider` override:
  - Unsupported platform: enabling never calls the factory. Control: supported does.
  - Enable gives `McpRunning`.
  - A start that throws `SocketException` gives `McpFailed` and the container does not throw.
  - **Review Focus #3:** on, off, on in quick succession gives exactly one live host (starts − stops == 1) and the final status is running.
  - Regenerating the token restarts with the new token.
  - Toggling `includeClients` restarts with a tool list containing `list_clients`.
  - One real-host test: after regenerate, the old token gets 403 and the new one is accepted.
- [ ] **Step 2: Failing widget tests** (`settings_mcp_test.dart`, MaterialApp with `S` delegates):
  - The card is absent when unsupported (control: present when supported).
  - The first switch-on shows the disclosure, and Cancel leaves it off.
  - Accept turns it on and later toggles skip the dialog.
  - The status row shows "Running on 127.0.0.1:47600" from an overridden controller.
- [ ] **Step 3:** Run. Expected: FAIL.
- [ ] **Step 4:** Implement the controller, ARB entries (then `flutter gen-l10n`), `_McpCard` and the `main.dart` read. The port row opens a dialog with a numeric field validated 1024–65535. The copy buttons use `Clipboard.setData` and show a SnackBar.
- [ ] **Step 5:** Run the new tests plus `flutter test test/features/settings`. Expected: PASS. Mutation: remove the serialising chain and confirm the Review Focus #3 test goes red; if it does not, strengthen the fake with a delayed `start()`.
- [ ] **Step 6:** Commit `feat: MCP server controller and Settings card (#154)`.

### Task 11: Privacy policy and documentation

**Files:**
- Modify: `PRIVACY.md` (section 4 gains an "AI assistant access (desktop only, off by default)" bullet, and the effective date becomes 13 November 2026), `src/docs/modules/ROOT/pages/privacy.adoc` (same change), `src/docs/modules/ROOT/nav.adoc`, `src/docs/modules/dev/nav.adoc`, the project notes file (add `mcp` to the feature directory list and one bullet under Additional Features)
- Create: `src/docs/modules/ROOT/pages/guide/ai-assistants.adoc` (switching it on, connecting an assistant with the endpoint and token, what is and is not shared, Me-only default and the two toggles; no class names), `src/docs/modules/dev/pages/features/mcp.adoc` (layers, tool catalogue table, security model including the 403 and Origin calls above, testing notes; links to the ROOT page and back), `src/docs/modules/dev/examples/mcp-request-flow.mmd`

- [ ] **Step 1:** Dispatch the `asciidoc-antora-writer` agent for the two `.adoc` pages, the nav entries and `privacy.adoc`, and the `mermaid-diagram-creator` agent for the `.mmd`, in parallel. Edit `PRIVACY.md` and the project notes file directly.
- [ ] **Step 2:** Run `gradle25w antora`. Expected: no warnings or errors (CI runs with `--log-failure-level=warn`).
- [ ] **Step 3:** Commit `docs: AI assistant access guide, developer page and privacy update (#154)`.

### Task 12: Whole-branch verification

- [ ] **Step 1:** `dart format --set-exit-if-changed lib test`. Expected: exit 0.
- [ ] **Step 2:** `dart analyze`. Expected: "No issues found!"
- [ ] **Step 3:** `flutter test`. Expected: all pass.
- [ ] **Step 4:** `flutter build macos --debug` and run the app. Enable the MCP toggle, then run the Task 1 Inspector CLI command against port 47600 with the token from Settings. Expected: 12 tools listed, and `list_workouts` returns JSON.
- [ ] **Step 5:** `flutter build macos --release`. Expected: the build succeeds with the new entitlement.

## Spike result

Run on 2026-11-13 against `mcp_dart` 2.4.3:

- Schema from a raw map: `JsonObject.fromJson(map)` (`ToolInputSchema` is `JsonObject`).
- Result: `CallToolResult.fromStructuredContent(map)` fills both `structuredContent` and a JSON text fallback. Errors use `CallToolResult(isError: true, content: [TextContent(text: ...)])`.
- `authenticationHandler`'s parameter is typed `dynamic`, so cast it to `HttpRequest` inside.
- `serverFactory` runs per request for 2026-07-28 peers and per session for 2025-11-25 peers, so tools are registered per call and settings are read when the host is built.
- Client header: `StreamableHttpClientTransportOptions(requestInit: {'headers': {'Authorization': 'Bearer …'}})`.
- Clients that connected:
  - the mcp_dart client on 2026-07-28 (stateless) and on 2025-11-25 (`McpProtocol.legacy`)
  - raw `curl` JSON-RPC on 2025-11-25: initialize, then `notifications/initialized` (202), `tools/list` and `tools/call`
  - The Inspector CLI (`npx`) was blocked by the session's permission policy.
- Negative probes all returned 403: no token, `Origin: http://localhost:5173` (POST and OPTIONS), `Host: evil.example:port`, and `Host: localhost:1` with a valid token. A valid `Host: localhost:port` returned 200.
- `ToolAnnotations(readOnlyHint: true)` alone serialises `destructiveHint: true, openWorldHint: true` (SDK defaults). Set `destructiveHint: false, idempotentHint: true, openWorldHint: false` explicitly.
