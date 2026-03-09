# RepFoundry — Cross-Device Sync
## Product Requirements Document

| | |
|---|---|
| **Version** | 1.0 — Draft |
| **Date** | March 2026 |
| **Product** | RepFoundry (Flutter — iOS / Android) |
| **Status** | For Review |

---

## 1. Overview

RepFoundry is an offline-first cross-platform workout logging application. Users log sets, reps, weight, and cardio metrics entirely on-device. This PRD defines the requirements for adding optional cross-device sync that preserves RepFoundry's core privacy promise: **user data is never stored on any RepFoundry or third-party backend server.**

---

## 2. Problem Statement

Users who own multiple devices (e.g. a personal phone and a gym-only device, or an iPhone and an iPad) currently have no way to access their workout history across those devices. All data is siloed to the device on which it was recorded.

> **Key constraint:** RepFoundry must not become a data controller for health data. Workout logs are personal health data subject to GDPR, the Australian Privacy Act, and similar legislation. The sync solution must store data exclusively in the user's own cloud storage accounts.

---

## 3. Goals & Non-Goals

### 3.1 Goals

- Allow users to access their workout history on more than one device.
- Store sync data exclusively in the user's own Google Drive or iCloud account.
- Ensure RepFoundry itself never receives, stores, or processes user workout data.
- Keep sync opt-in — the app works fully offline with no account required.
- Produce a simple, credible privacy policy statement covering sync.

### 3.2 Non-Goals

- Real-time collaborative or shared workout logging.
- Social features or leaderboards.
- RepFoundry-hosted cloud backup or analytics.
- Sync between iOS and Android in v1 (see Section 10 — Future Considerations).

---

## 4. User Stories

| # | As a user, I want to… | So that… |
|---|---|---|
| 1 | Enable sync from the Settings screen | My data starts backing up to my own cloud account |
| 2 | Have my workouts appear on my second device automatically | I don't need to manually export/import |
| 3 | Disable sync and delete all cloud copies | I can fully remove my data from cloud storage |
| 4 | Be clearly informed about where my data is stored | I can make an informed consent decision |
| 5 | Continue using the app fully offline if I choose | Sync is never a requirement to use RepFoundry |

---

## 5. Sync Architecture

### 5.1 Platform Split

Because there is no RepFoundry backend, sync must be implemented separately per platform using each platform's native user-owned cloud storage.

| Platform | Storage Provider | Access Model |
|---|---|---|
| Android | Google Drive — App Data folder | Hidden, app-specific folder. Not browsable by user. Only the app can read/write it. |
| iOS / iPadOS | iCloud — CloudKit Private DB | Data stored in user's private iCloud container. Apple guarantees zero third-party access. |

> **Privacy outcome:** RepFoundry has no read or write access to sync data on either platform. The data owner is always the end user. RepFoundry's servers do not exist in the data flow.

### 5.2 Sync Model

RepFoundry uses a **store-and-forward (last-write-wins)** sync model, not real-time sync. This is appropriate for a workout logger where:

- Data is append-heavy (new workouts added, rarely edited).
- Conflicts are rare (most users log on one device at a time).
- Simplicity of implementation is a priority for an indie app.

#### Sync Flow — Android (Google Drive App Data)

```
User completes workout on Phone A (offline)
  → Written to local SQLite database (existing behaviour)

App comes online
  → Serialise local DB to JSON snapshot
  → Upload snapshot to Google Drive App Data folder
      File: appdata://repfoundry_sync.json
      Overwrite if newer (compare updatedAt timestamp)

Phone B opens RepFoundry
  → Check Drive for snapshot newer than local lastSyncAt
  → Download and merge into local SQLite
  → Update lastSyncAt
```

#### Sync Flow — iOS (iCloud / CloudKit)

```
User completes workout on iPhone (offline)
  → Written to local SQLite database (existing behaviour)

App comes online / enters background
  → Serialise changed records to CloudKit CKRecord objects
  → Save to CloudKit Private Database
      Zone: RepFoundryZone
      RecordTypes: Workout, ExerciseSet, CardioSession

iPad opens RepFoundry
  → CKQuerySubscription fires push notification
  → App fetches changed records since lastChangeToken
  → Merge into local SQLite
  → Persist new changeToken
```

### 5.3 Data Format (Android JSON Snapshot)

```json
{
  "version": 1,
  "exportedAt": "2026-03-09T08:00:00Z",
  "deviceId": "uuid-of-originating-device",
  "exercises": [
    { "id": "...", "name": "Bench Press", "type": "resistance" }
  ],
  "workouts": [
    {
      "id": "...",
      "date": "2026-03-09T07:30:00Z",
      "name": "Push Day",
      "sets": [
        { "exerciseId": "...", "setNumber": 1, "reps": 10, "weightKg": 80 }
      ],
      "cardio": [
        { "exerciseId": "...", "durationSeconds": 1800, "distanceKm": 5.0 }
      ]
    }
  ]
}
```

---

## 6. Conflict Resolution

With a last-write-wins model, conflicts are handled as follows:

| Scenario | Resolution | Rationale |
|---|---|---|
| Two devices add different workouts offline | Both are merged — no conflict | Workouts use UUID primary keys; no collision |
| Two devices edit the same workout concurrently | Device with the newer `updatedAt` wins | Rare case; acceptable for v1 |
| User deletes a workout that syncs to a second device | Deletion wins — soft delete with tombstone record | Prevents deleted items reappearing |
| Sync snapshot is corrupted or unreadable | Local data is preserved; sync skipped with error logged | Local data is always source of truth |

---

## 7. Flutter Implementation — Key Packages

| Package | Platform | Purpose |
|---|---|---|
| `google_sign_in` | Android | Authenticate user with Google account |
| `googleapis` / `drive_v3` | Android | Read/write files in Google Drive App Data scope |
| `cloudkit` (platform channel) | iOS | Write/read CKRecord objects in private CloudKit DB |
| `connectivity_plus` | Both | Detect online/offline state before attempting sync |
| `shared_preferences` | Both | Store `lastSyncAt`, `syncEnabled` flag, `deviceId` |

> **Note:** CloudKit does not have a first-party Flutter package. A Swift platform channel bridging CloudKit calls will be required for the iOS implementation.

---

## 8. UX Requirements

### 8.1 Settings Screen — Sync Section

- Toggle: **Enable Cross-Device Sync** (default: off).
- When toggled on: show platform-appropriate sign-in flow (Google on Android, iCloud confirmation on iOS).
- Display last sync time: *Last synced: Today 8:04 AM*.
- Button: **Sync Now** — triggers manual sync.
- Button: **Disable Sync & Delete Cloud Data** — removes all cloud copies and signs out.

### 8.2 Consent Screen (First Enable)

On first enabling sync, display a plain-language consent screen:

> *"Your workout data will be saved to your own Google Drive / iCloud account. RepFoundry cannot access this data. You can delete it at any time from Settings or directly from your Google Drive / iCloud account."*

User must tap **I Understand — Continue** to proceed. Tapping Cancel leaves sync disabled.

### 8.3 Sync Status Indicators

- Subtle sync icon in the app header when sync is enabled.
- Spinner while sync is in progress.
- Error badge if last sync failed, with a tap-to-retry option.
- No blocking UI — sync runs in background and never interrupts workout logging.

---

## 9. Privacy & Legal

### 9.1 Privacy Policy Statement

> RepFoundry stores all workout data locally on your device. If you enable optional cross-device sync, your data is stored in your own Google Drive account (Android) or iCloud account (iOS). RepFoundry has no access to this data and does not transmit it to any server. You may disable sync and permanently delete your cloud data at any time from within the app.

### 9.2 App Store Compliance

| Store | Requirement | How RepFoundry Meets It |
|---|---|---|
| Apple App Store | Data privacy nutrition label must declare data types collected | Declare: No data collected. iCloud data is user-owned; not "collected" by the developer. |
| Apple App Store | Apple Sign-In required if any social login offered | No social login in v1. Google Sign-In is not offered on iOS. |
| Google Play Store | Safety section must describe data shared | Declare: No data shared with third parties. Google Drive scope is user-owned storage. |
| Google Play Store | Sensitive permissions must be justified | `drive.appdata` is the minimum necessary scope; justification: sync feature. |

---

## 10. Future Considerations

### Cross-Platform Sync (Android ↔ iOS)

v1 intentionally limits sync to same-platform devices. Cross-platform sync (e.g. iPhone to Android) would require a common storage layer. Options to evaluate in a future version:

- Export/import via a standard file format (JSON or CSV) — no cloud account required.
- A neutral storage provider (e.g. Dropbox, or a self-hosted WebDAV server) available on both platforms.
- A user-provided S3-compatible bucket for privacy-conscious power users.

### Selective Sync

Allow users to choose which date range or exercise categories to sync, to reduce storage usage and sync time.

### Encrypted Sync

Offer client-side encryption of the sync snapshot before upload, so even the user's Google or Apple account cannot expose the data in plaintext if compromised.

---

## 11. Success Metrics

| Metric | Target |
|---|---|
| Sync opt-in rate | > 30% of active users within 60 days of launch |
| Sync success rate | > 99% of sync attempts complete without error |
| Sync-related crash rate | 0 crashes attributable to sync in first 30 days |
| App Store review sentiment | No negative reviews citing privacy concerns about sync |
| Support requests about sync | < 5% of active sync users raise a support issue |

---

## 12. Out of Scope

- Any RepFoundry-operated server, database, or analytics pipeline.
- Sync of app settings or preferences (v1 syncs workout data only).
- Sync between different users / shared workout plans.
- Automated backup to email or local file storage.

---

## Appendix — Google Drive App Data Scope

The `drive.appdata` OAuth scope grants access only to a hidden application-specific folder in the user's Google Drive. This folder:

- Is not visible in the user's My Drive view.
- Cannot be accessed by any other application.
- Is automatically deleted if the user revokes the app's Google account access.
- Does not count toward any Drive storage quota visible to the user.

Reference: https://developers.google.com/drive/api/guides/appdata
