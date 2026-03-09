# Antora Documentation Design

**Goal:** Comprehensive Antora-based documentation for RepFoundry, built via `gradle21w antora`.

## Structure

```
src/docs/
├── antora.yml
└── modules/ROOT/
    ├── nav.adoc
    └── pages/
        ├── index.adoc
        ├── getting-started.adoc
        ├── architecture.adoc
        ├── database.adoc
        ├── state-management.adoc
        ├── features/
        │   ├── workout.adoc
        │   ├── cardio.adoc
        │   ├── heart-rate.adoc
        │   ├── programmes.adoc
        │   ├── analytics.adoc
        │   ├── health-sync.adoc
        │   ├── body-metrics.adoc
        │   └── notifications.adoc
        ├── testing.adoc
        ├── localisation.adoc
        └── product/
            ├── requirements.adoc
            └── heart-rate-prd.adoc
```

## Build

- Root `build.gradle` with `antora` task calling Antora CLI
- `antora-playbook.yml` at project root
- `settings.gradle` for project name
- Run: `gradle21w antora`

## Content

Convert existing Markdown docs (Architecture.md, PRD, HR PRD) to AsciiDoc.
Add new pages for features implemented since those docs.
Developer guide content from CLAUDE.md.
