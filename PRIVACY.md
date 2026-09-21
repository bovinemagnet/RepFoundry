# RepFoundry Privacy Policy

**Effective date:** 21 September 2026

RepFoundry is a workout tracking app for iOS and Android, published by Paul Snow. This policy explains what data the app handles, where it is stored, and what control you have over it.

The short version: **RepFoundry has no server, no account system, no advertising and no analytics. Your data stays on your device unless you choose to sync it to your own iCloud or Google Drive account, share it with a health app, or export it yourself.**

## 1. Data the app stores

Everything below is stored in a database on your device. None of it is sent to the developer.

- **Training records** — workouts, exercises, sets (weight, reps, RPE), personal records, templates, programmes and stretching sessions.
- **Cardio sessions** — duration, distance, incline, pace, and, when you enable GPS, the recorded route (a series of timestamped locations).
- **Heart rate** — live readings from a Bluetooth heart rate monitor you connect, the per-session average, peak and time in zone derived from them, and the readings recorded during cardio sessions.
- **Health profile** — optional age, resting heart rate, measured maximum heart rate, a clinician-set heart rate cap, and whether you take beta blockers or have a heart condition. These are used only to calculate training zones and to switch on the app's caution mode. You can leave all of them blank.
- **Body metrics** — weight and optional body fat percentage entries.
- **Client roster (coach mode)** — if you use RepFoundry as a personal trainer, the names and health profiles of clients you add, together with the sessions you log for them. This data is held only on your device and is never included in cloud sync (see section 3).
- **Settings** — preferences such as rest timer, notification reminders, coach persona and units.

## 2. Device features and permissions

RepFoundry asks for permissions only when you use the feature that needs them.

- **Bluetooth** — to scan for and connect to a heart rate monitor. Readings go directly from the monitor to the app.
- **Location (GPS)** — to record distance and route during a cardio session, only while a session is running and only if you turn GPS on for that session. Location is never used for anything else and is never sent anywhere. On Android, an ongoing notification is shown while a session or heart-rate monitoring runs in the background so the phone does not stop the recording.
- **Notifications** — for the workout reminders you schedule and the rest timer.
- **Apple Health / Health Connect** — optional. If you enable Health Sync, the app writes the workouts, weight and heart rate you choose to share, and can read weight entries back. Each of these is a separate toggle. Health data written this way is governed by Apple's or Google's health platform policies and by the permissions you grant there. Only your own data is written to the health platform, never a client's.
- **Speech (coach mode)** — spoken cues use your device's built-in text-to-speech engine. The app sends it only the short phrase to be spoken.

## 3. Cloud sync (optional, off by default)

Cross-device sync uses your own cloud account, not a RepFoundry service:

- **iOS** — your private iCloud database (CloudKit).
- **Android** — a hidden application-data area in your Google Drive, which does not appear alongside your other Drive files.

When sync is on, the app uploads a snapshot of your own training data (your workouts, cardio sessions, heart rate recordings, personal records, templates, programmes, body metrics and stretching sessions) and merges it with what other devices signed into the same account have uploaded. Coach-mode client data and settings are not synced.

On Android, turning on sync signs you in with Google and asks for permission to use Drive's app-data storage only. RepFoundry cannot see or access any other file in your Drive. The developer has no access to your Google or Apple account or to the data stored there.

You can turn sync off at any time. Choosing **Delete cloud data** in Settings removes the synced snapshot from your cloud account and signs the app out.

## 4. Data that leaves your device

Apart from the cloud sync and health platform sharing you enable, RepFoundry sends nothing off your device. Specifically:

- **No analytics or telemetry.** The app does not use any analytics, crash-reporting or advertising service.
- **No developer server.** There is no RepFoundry backend and no account.
- **No third-party tracking.** Fonts and other assets are bundled with the app; nothing is fetched at run time.
- **Exports you initiate** — the app lets you share a cardio session as GPX and CSV files, and export a full JSON backup. Where those files go is decided by the app you share them with.

Links in the About screen open in your browser; what those websites collect is covered by their own policies.

## 5. Your control

- **Edit and delete** — every record can be edited or deleted in the app.
- **Export** — a full JSON backup can be created from Settings and imported again later.
- **Clear all data** — Settings offers a single action to erase everything stored on the device.
- **Uninstalling** the app removes all locally stored data. Data you synced to iCloud or Google Drive remains in your account until you delete it in the app or from your account settings.

## 6. Children

RepFoundry is not directed at children under 13 and does not knowingly collect information from them.

## 7. Changes to this policy

If the app starts handling data differently — for example if a new feature needs a new permission — this policy will be updated and the effective date changed. The current version is always available in this repository.

## 8. Contact

Questions about this policy can be raised as an issue at <https://github.com/bovinemagnet/RepFoundry/issues>.
