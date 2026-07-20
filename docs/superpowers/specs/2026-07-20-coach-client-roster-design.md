# Design: Coach client roster (local, v1)

**Date:** 2026-07-20
**Author:** Paul Snow
**Version:** 0.0.0

## Goal

Let one coach manage several people from a single RepFoundry install: pick a
client from a roster, then log and review that client's workouts, cardio, PRs,
body metrics, and heart-rate zones as if the app were theirs. Coach-managed —
clients never log in, there are no accounts or passwords, and all data belongs
to the coach install. A client is a labelled, owned bucket of training data.

This is **v1: local only**. It works fully on one device. Cross-device roster
sync is deferred to its own spec; v1 must be *sync-safe* (defined below) but
adds no new sync payload.

## Decisions made during design

- **Usage model:** coach-managed. No authentication, no per-client privacy —
  one install, one owner.
- **Default "Me" client:** a single `isSelf` client is created by migration;
  all existing single-user data is backfilled to it. Coaches train themselves
  too, so "Me" is a first-class client, just undeletable.
- **Exercises are global.** The exercise library is shared across all clients
  and is never scoped.
- **Plans are a shared library, assigned by live reference.** Templates and
  programmes stay global. Assigning a plan to a client is a link, not a copy;
  editing a library plan changes it for every assigned client. Per-client
  variation means cloning the plan in the library first.
- **Health profile is per-client.** HR training zones are medical; using the
  coach's age for a client would be misleading. Each client owns a health
  profile; the zone calculator consumes the active client's profile unchanged.
- **Sync deferred, but sync-safe.** v1 does not extend the sync snapshot. The
  apply/merge path must never corrupt or reassign an entity's `clientId`.
- **Active-client indicator is a safety element,** always visible, so the coach
  cannot log Sarah's set under James.

## Scope

**In v1:** clients table + "Me" migration; `clientId` scoping on workouts (and
sets via their workout), cardio sessions, personal records, body metrics;
per-client health profiles; `client_plan_assignments`; active-client state and
filtering of every scoped stream; roster CRUD + plan assignment UI; client
switcher + active-client indicator; sync-safety.

**Deferred to separate specs:** cross-device roster/data **sync** (extend
`SyncSnapshot` with clients + assignments + per-entity `clientId`, bump
`schemaVersion`, merge by `(clientId, entityId)`); any coach reporting, export,
or printout features; per-client unit/preference overrides.

**Out of scope (YAGNI):** client photos/avatars (a colour only); roles or
permissions; assignment scheduling beyond a `startedAt`; client archiving
beyond soft-delete.

## Architecture

### Data model (Drift / SQLite)

New tables:

- **`clients`** — `id` (String UUID PK), `name` (String), `colour` (int, an
  ARGB accent chosen at creation), `notes` (String, nullable), `isSelf` (bool —
  exactly one row true), `createdAt` / `updatedAt` (epoch ms), `deletedAt`
  (epoch ms, nullable — soft delete, matching the existing pattern).
- **`client_plan_assignments`** — `id` (String UUID PK), `clientId` (FK →
  `clients.id`), `planType` (String enum `template` | `programme`), `planId`
  (String — the template or programme id), `startedAt` (epoch ms, nullable —
  anchors per-client programme week for a shared programme), `createdAt` /
  `updatedAt`. Unique index on `(clientId, planType, planId)`.
- **`health_profiles`** — keyed by `clientId` (PK, FK → `clients.id`); the
  fields currently held in the SharedPreferences `HealthProfile` (age, resting
  HR, measured max HR, clinician cap, beta-blocker flag, heart-condition flag,
  any custom zones), plus `updatedAt`.

New nullable-then-backfilled column on existing tables:

- `clientId` (String, FK → `clients.id`) on **`workouts`**,
  **`cardio_sessions`**, **`personal_records`**, **`body_metrics`**.
  `workout_sets` are scoped through their parent workout — no column added.

Unchanged (global): `exercises`, `workout_templates`, `template_exercises`,
`programmes`, `programme_days`, `progression_rules`.

`PRAGMA foreign_keys = ON` already holds; all `clientId` values resolve to a
real `clients` row (the backfill and defaults guarantee this).

### Migration (Drift version bump + one app-side step)

Drift schema migration (next `schemaVersion`):

1. Create `clients`; insert one row `{ isSelf: true, name: "Me" }` with a fixed,
   discoverable id (a constant UUID so app code can reference it).
2. Add the `clientId` column to `workouts`, `cardio_sessions`,
   `personal_records`, `body_metrics`; backfill every existing row to the "Me"
   client id.
3. Create `client_plan_assignments` (empty) and `health_profiles`.

App-side one-time migration (SharedPreferences is not in Drift): on first launch
of the new version, read the existing `HealthProfile` from SharedPreferences and
write it into the "Me" client's `health_profiles` row, then mark the migration
done. `HealthProfileNotifier` reads per-client thereafter.

A migration test asserts: old→new preserves all rows, every backfilled row
carries the "Me" id, the "Me" client exists and is `isSelf`.

### Data layer

- **`ClientRepository`** (interface + `DriftClientRepository`): `watchClients()`
  (excludes soft-deleted), `getClient(id)`, `createClient(Client)`,
  `updateClient(Client)`, `softDeleteClient(id)` — **guards against deleting the
  `isSelf` client** — and the self-client accessor. Soft-deleting a client
  hides it and its scoped data from the roster; the data rows are retained
  (matching existing soft-delete semantics).
- **`ClientPlanAssignmentRepository`**: `watchAssignments(clientId)`,
  `assign(clientId, planType, planId)`, `unassign(assignmentId)`,
  `watchClientsForPlan(planType, planId)`. Uniqueness enforced by the index;
  `assign` is idempotent.
- **Scoped query methods gain a `clientId`.** `DriftWorkoutRepository`,
  `DriftCardioRepository`, `DriftPersonalRecordRepository`, and
  `DriftBodyMetricRepository` grow `clientId`-filtered variants of their
  watch/query methods (e.g. `watchWorkouts(clientId)`,
  `getSetsFromLastSession(exerciseId, clientId)`). Filtering happens in SQL, not
  in memory. Writes stamp the active `clientId`.

### State (Riverpod)

- **`clientsProvider`** — `StreamProvider<List<Client>>` over
  `ClientRepository.watchClients()`.
- **`activeClientProvider`** — `NotifierProvider<Client>`; holds the currently
  selected client, persists the last-active client id in SharedPreferences, and
  defaults to the "Me" client. Setting it re-drives every scoped provider.
- **Every client-scoped provider filters by `activeClientProvider`.** History,
  analytics (weekly volume, muscle balance, PR timeline, training load), PR
  history, body metrics, cardio history, and the active-workout ghost-set /
  last-session lookup all read the active client id and call the
  `clientId`-scoped repository methods. Writes (logging a set, saving a cardio
  session, recording a body metric) stamp the active client id.
- **`healthProfileProvider`** keys to the active client and loads that client's
  `health_profiles` row. `zone_calculator.dart` and the heart-rate panel already
  consume `healthProfileProvider`, so zones follow the active client with **no
  zone-logic change**. `userAgeProvider` continues to delegate to it.

### UI

- **Roster screen** — a new "Clients" destination in `DesktopNavRail` (fits the
  existing intent groups) and, on mobile, reachable from Settings. Lists clients
  (name, colour, a quick stat such as last-session date); add / edit / soft-
  delete a client (the "Me"/self client shows no delete); open a client to
  assign library templates/programmes and edit their health profile.
- **Client switcher** — in the `DesktopNavRail` footer (the extension point
  already exists): shows the active client, tap to switch. On mobile, a compact
  switcher (a bottom sheet from an app-bar affordance).
- **Active-client indicator** — a persistent, always-visible badge (rail footer
  on desktop, app-bar chip on mobile) naming whose data is shown and logged.
  Safety-critical: it must be present on the logging screens so a coach never
  records under the wrong client.
- **Per-client health profile** — reuses the existing health-profile onboarding
  / settings UI, scoped to the active (or selected) client, reached from the
  roster.
- **Plan assignment** — from a client's detail, pick library plans to assign
  (and unassign); from a library plan, see which clients it's assigned to.

### Sync-safety (v1 constraint)

`SyncSnapshot` keeps its 11 entity lists and merges by entity UUID; v1 adds
**nothing** to it (no clients, no assignments, no `clientId`). The risk is that
applying a downloaded snapshot overwrites a local entity (updatedAt-wins) and
wipes the `clientId` added locally. Guarantee:

- When the apply/merge path writes an entity that **already exists locally**, it
  **preserves the existing local `clientId`**.
- A **brand-new incoming** entity defaults to the "Me" client id.

Because the snapshot domain models carry no `clientId`, this is handled at the
apply layer, not in the pure `SyncMergeEngine`. This keeps single-user ("Me"
only) installs round-tripping perfectly and stops multi-client data losing its
client on same-account sync. No incoming entity can reference a non-existent
client (all resolve to "Me" or an existing local id), so FK integrity holds.
Cross-device roster propagation is the deferred sync spec.

## Error handling

- Deleting the `isSelf` client is refused at the repository layer (and the UI
  hides the action).
- Deleting the last non-self client is fine; the active client falls back to
  "Me".
- If the persisted last-active client id no longer resolves (soft-deleted),
  `activeClientProvider` falls back to "Me".
- Assigning an already-assigned plan is a no-op (idempotent, unique index).
- All scoped writes require a resolved active client; the provider always
  resolves to at least "Me", so writes can never be client-less.

## Testing (TDD)

- **Migration:** old→new preserves all rows; `clientId` backfilled to "Me" on
  all four tables; "Me" client exists and is `isSelf`; SharedPreferences
  `HealthProfile` lands in "Me"'s `health_profiles` row.
- **ClientRepository:** CRUD; `watchClients` excludes soft-deleted; self-client
  delete guard; soft delete hides the client.
- **Assignment repository:** assign/unassign; uniqueness; idempotent assign;
  `watchClientsForPlan` reverse lookup.
- **Scoped isolation:** seed two clients with distinct workouts / cardio / PRs /
  body metrics; assert each scoped query returns only the active client's rows;
  writes stamp the active client.
- **activeClientProvider:** defaults to "Me"; persists and restores last-active;
  falls back to "Me" when the persisted id is gone.
- **Per-client health profile:** switching the active client changes the HR
  zones the calculator produces.
- **Ghost sets:** last-session lookup is scoped to the active client.
- **Sync-safety:** applying a snapshot over existing local rows preserves their
  `clientId`; a new incoming entity resolves to "Me".
- **Widgets:** roster screen (add/edit/delete, self-client undeletable);
  switcher changes the active client; active-client indicator renders on a
  logging screen.

## Deferred / follow-on specs

1. **Coach roster sync** — extend `SyncSnapshot` with `clients`,
   `client_plan_assignments`, and per-entity `clientId`; bump `schemaVersion`;
   merge by `(clientId, entityId)`; roster appears on all coach devices.
2. **Coach reporting/export** — per-client progress printouts or shareable
   summaries.
