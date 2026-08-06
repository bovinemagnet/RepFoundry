# End-user documentation split

**Date:** 2026-08-06
**Author:** Paul Snow
**Status:** Approved

## Problem

The RepFoundry documentation site is written entirely for developers. Its
landing page opens with clean architecture, Riverpod and Drift; `getting-started`
is a Flutter SDK setup guide; the feature pages name classes such as
`HeartRatePanelScreen` and `FlutterBlueHeartRateService`.

Nobody who uses the app can learn anything from it.

Two further gaps compound this:

- **Seven of sixteen features have no page at all** — `trainer`, `settings`,
  `exercises`, `history`, `templates`, `stretching`, `clients`. Several are
  highly user-facing: coach mode, CSV import from Hevy and Strong, the exercise
  library, and the personal-trainer client roster.
- **The nine pages that do exist are hybrid.** `features/heart-rate.adoc` opens
  with genuine end-user material — where to find the panel, which watches and
  straps work, the safety caveat — then drops into BLE characteristic parsing.
  Neither audience is served well.

## Goals

1. End-user documentation is the site's default, structurally and not merely by
   nav ordering.
2. Developer documentation remains complete and clearly separated.
3. Every one of the sixteen features has an end-user page.
4. Android and iOS are covered for installation, permissions, device pairing,
   and platform differences.
5. The docs build stays green under `--log-failure-level=warn`.

## Non-goals

- **Screenshots.** Text ships first. A capture checklist is produced; no
  `image::` directives are added until the PNGs exist, because a missing image
  reference fails the strict CI build.
- **Developer pages for the seven currently-undocumented features.** Deferred to
  a follow-up. That material does not exist today, and writing it alongside full
  user coverage would make this change unreviewable.
- **Refreshing the repository's agent guidance file**, whose feature list omits
  `trainer`, `clients` and `stretching`. Noted, out of scope.

## Audience

"End user" covers two distinct roles, and the documentation must not conflate
them:

- **The lifter** — logs workouts, tracks cardio and heart rate, follows
  programmes, reviews progress.
- **The personal trainer** — everything above, plus the `clients` roster:
  managing clients, assigning plans, maintaining per-client health profiles, and
  switching the active client.

## Design

### Structure

Two Antora modules within the existing `repfoundry` component.

```
src/docs/
├── antora.yml                  nav: ROOT first, then dev
└── modules/
    ├── ROOT/          ← END USER    /repfoundry/<page>.html
    │   ├── nav.adoc
    │   ├── pages/
    │   │   ├── index.adoc              landing: what RepFoundry is, for users
    │   │   ├── install-android.adoc
    │   │   ├── install-ios.adoc
    │   │   ├── permissions.adoc
    │   │   ├── first-workout.adoc
    │   │   └── guide/                  one page per feature (16)
    │   └── images/                     screenshots, second pass
    └── dev/           ← DEVELOPER  /repfoundry/dev/<page>.html
        ├── nav.adoc
        └── pages/                      today's pages, moved
```

Antora omits the ROOT module from generated URLs. End-user pages therefore sit
at the component root and developer pages sit visibly beneath `/dev/`, which
makes end-user content the default in the URL structure rather than only in nav
ordering. `site.start_page` remains `repfoundry::index.adoc` and now resolves to
the end-user landing page.

Modules were chosen over separate components: a component split would add a
second `antora.yml`, produce a `repfoundry-dev` URL prefix, and require the
component-selector UI, for no separation benefit at this size.

### End-user pages

Journey pages:

| Page | Covers |
|---|---|
| `index` | What the app does, who it is for, where to start |
| `install-android` | Sideloading the signed APK from GitHub Releases |
| `install-ios` | Current iOS availability; no automated build exists |
| `permissions` | Bluetooth, notifications, health data, battery optimisation — per platform |
| `first-workout` | The core journey end to end |

Feature pages under `guide/`, one per feature:

`workout`, `cardio`, `heart-rate`, `trainer` (coach mode), `analytics`,
`programmes`, `templates`, `history`, `exercises`, `body-metrics`,
`stretching`, `clients`, `sync`, `health-sync`, `notifications`, `settings`.

Coach mode warrants particular care: three personas (Steady, Hype, Sergeant),
spoken cues, and the quote bank. It is reached at `/settings/trainer` and has 85
localisation keys behind it, none of it documented anywhere today.

`settings` must cover CSV import from Hevy and Strong, data export, and themes —
all user-facing and all currently undocumented.

### Developer pages

Today's pages move to `dev/` unchanged in substance: `architecture`, `database`,
`state-management`, `responsive-desktop`, `testing`, `localisation`,
`release-versioning`, `product/requirements`, `product/heart-rate-prd`, and the
nine existing `features/` pages.

The nine feature pages have their end-user halves extracted into the
corresponding `guide/` page; what remains is implementation reference.
`getting-started` stays a developer page — it is a Flutter SDK setup guide — and
the end-user install pages are new, not a rewrite of it.

### Navigation and header

`antora.yml` lists both navs with ROOT first, so the sidebar shows end-user docs
above developer docs.

The site header changes from **Overview / Getting Started / Architecture** to
**User Guide / Developer / Source**, pointing at the two module indexes. This
becomes the audience switcher. The header links are hardcoded in
`ui/src/partials/header-content.hbs` and must use component-qualified paths —
site-root paths 404, as fixed in PR #110.

### Migration safety

- Every moved page gets `:page-aliases:` so its old URL redirects rather than
  404s.
- The move breaks many `xref:`s. The strict build catches them; they are fixed in
  source order.
- No `image::` directives are introduced.

## Verification

- `gradle21w antora` exits 0, and `npx antora --log-failure-level=warn` exits 0.
- Every page in both navs resolves — no orphans, no broken `xref:`.
- Generated header links resolve at multiple page depths and on `404.html`, per
  the method used in PR #110.
- `site.start_page` lands on the end-user index, not a developer page.
- Old developer URLs redirect via their aliases.

A green build is necessary but not sufficient: Antora does not validate links
hardcoded in UI templates, which is exactly how the header 404s in PR #110
shipped unnoticed. Header links are therefore checked by resolving generated
hrefs against the built site, not by trusting the build.

## Dependency on PR #110

PR #110 (header nav pointing at component paths rather than the site root) is
**merged**, and this work is based on it. It established that header links must
be component-qualified — site-root paths 404 — which the new **User Guide /
Developer** switcher must also honour.

## Delivery

A single pull request containing the restructure and all new content, per
explicit preference.

Page writing is delegated to parallel `asciidoc-antora-writer` agents, one per
page, following repository convention. Validation and error fixing happen in the
main thread.

## Risks

| Risk | Mitigation |
|---|---|
| Large diff hides a bad page move | Aliases and the strict build; nav reviewed explicitly |
| Documenting features not yet read (`clients`, `stretching`) | Both read before writing; findings recorded above |
| Feature descriptions drift from actual behaviour | Writers work from source, not from the repository's guidance file, which is already stale |
| iOS install story may be "not available yet" | Stated plainly rather than invented |
