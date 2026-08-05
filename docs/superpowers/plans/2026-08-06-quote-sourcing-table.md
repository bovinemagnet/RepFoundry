# Per-Quote Sourcing Table Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Record, in the repository, the per-quote licensing evidence for the coach quote bank — author, work, edition, translator, both death dates — and enforce it with tests so an unsourced quote cannot land.

**Architecture:** A new `quote_sources.dart` beside `persona_packs.dart` holds a `const Map<String, QuoteSource>` keyed by ARB phrase key, plus a `rejectedQuotes` list recording what was dropped and why. A new test file enforces a bijection with the live bank, the life+70 rule, and agreement between each row's `author` and the credit rendered in the spoken text. An audit precedes all of it: every surviving quote is re-verified against a named pre-1929 edition, and anything that fails is dropped.

**Tech Stack:** Dart / Flutter, `flutter_test`, Flutter `gen-l10n` ARB localisation.

Spec: `docs/superpowers/specs/2026-08-06-quote-sourcing-table-design.md`
Issue: #104

## Global Constraints

- **The licensing rule, verbatim:** every named person whose words we ship — original author *and* translator — must have died more than 70 years ago. Publication date alone is not sufficient.
- **Verbatim wording required.** A shipped quote must match the exact text of a named pre-1929 edition. Paraphrases are re-worded to a real edition or dropped.
- **Evidence lives in one place only.** `lib/features/trainer/data/quote_sources.dart`. No duplicate table in `src/docs`, in a research doc, or in a commit message. An inaccurate second copy is worse than none.
- **A phrase key lives in three files.** Dropping or adding a quote means touching `lib/l10n/app_en.arb`, `lib/features/trainer/presentation/providers/phrase_resolver.dart`, and `_quoteBank` in `lib/features/trainer/data/persona_packs.dart`. Miss one and the build breaks or the coach goes silent.
- **The ja, ko and zh ARBs carry no `coachQuote*` keys.** Verified: `grep -c coachQuote lib/l10n/app_*.arb` returns 0 for all but `app_en.arb`. No other locale is affected by a drop.
- **British spelling** in all prose and comments.
- **Prove every new test can fail.** Break the line it protects, watch it go red, restore. Required by `CLAUDE.md`; the specific mutations are named per-task below.
- **Use `flutter test` and `flutter gen-l10n`** (not `gradle21w` — this is the Flutter project).
- Author: Paul Snow. Version 0.0.0 where a version is needed.

## File Structure

| File | Status | Responsibility |
|---|---|---|
| `lib/features/trainer/data/quote_sources.dart` | Create | `QuoteSource`, `quoteSources` map, `RejectedQuote`, `rejectedQuotes` list. Data only, no logic. |
| `test/features/trainer/data/quote_sources_test.dart` | Create | The five enforcement assertions. |
| `lib/l10n/app_en.arb` | Modify (~1104–1124) | Quote text corrections and removals. |
| `lib/features/trainer/presentation/providers/phrase_resolver.dart` | Modify (113–133) | Remove resolver entries for dropped keys. |
| `lib/features/trainer/data/persona_packs.dart` | Modify (15–16, 28–50) | Trim `_quoteBank`; repoint the doc comment from issue #104 to `quote_sources.dart`. |
| `test/features/trainer/data/persona_packs_test.dart` | Modify (153–181) | Lower the bank-size threshold to the surviving count; extend the history comment. |
| `lib/l10n/generated/*` | Regenerated | Never hand-edited; `flutter gen-l10n` output. |

---

### Task 1: Audit the twenty-one surviving quotes

Research only — no repository changes. The deliverable is a findings file in the
scratchpad, reviewed before any code moves. It is deliberately **not** committed:
the repository gets one copy of this evidence, in `quote_sources.dart`, in Task 3.

**Files:**
- Create (scratchpad, not committed): `<scratchpad>/quote-audit-findings.md`
- Read: `lib/l10n/app_en.arb:1104-1124`

**Interfaces:**
- Produces: for each of the 21 keys — verdict (`KEEP` / `REWORD` / `DROP`), author, author death year, work and locus, edition title and year, translator, translator death year, and the source consulted. Tasks 2 and 3 consume this directly.

- [ ] **Step 1: List the current wording and credit for all 21 keys**

```bash
grep -n 'coachQuote' lib/l10n/app_en.arb
```

The 21 live keys are `coachQuote` 1, 2, 3, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23. Numbers 4 and 11 are already-dropped entries; 24 was dropped too and renumbering never happened.

- [ ] **Step 2: Recover the already-rejected quotes and the two corrected citations from git**

```bash
git log --format=%B -n 1 6c5a9d5 | grep -A12 'fix round'
```

This merge commit's message enumerates the five earlier rejections and two citation corrections. Record all of them — they are the input to Task 5, and two are already-known-good sourcing rows:

| Dropped | Credit shipped under | Reason |
|---|---|---|
| "Every new beginning comes from some other beginning's end" | Seneca (fabricated) | Semisonic, *Closing Time*, 1998. In copyright. |
| "The impediment to action advances action" | Marcus Aurelius | Gregory Hays' 2002 translation. Translator alive. |
| coachQuote24, "Optimism", 1903 | Helen Keller | Keller d. 1968; UK copyright to 2038. |
| coachQuote4, "While we are postponing, life speeds by." | Seneca | Gummere's 1917 Loeb; Gummere d. 1969. |
| coachQuote11, "I will not follow where the path may lead…" | Muriel Strode (was falsely Emerson) | Strode d. 1964; copyright to 2034. |

Already established and reusable: `coachQuote5` is W. A. Oldfather's 1928 Loeb *Discourses* (Oldfather d. 1945), **not** George Long. `coachQuote8` is Jowett's wording (Jowett d. 1893).

- [ ] **Step 3: Audit the eight translated entries first**

Translator before author — that is where this has bitten twice. Entries: `coachQuote1`, `coachQuote2` (Marcus Aurelius), `coachQuote3` (Seneca), `coachQuote5`, `coachQuote6` (Epictetus), `coachQuote7` (Lao Tzu), `coachQuote8`, `coachQuote9` (Socrates via Plato), `coachQuote10` (Aristotle), `coachQuote22` (Cervantes), `coachQuote23` (Leonardo da Vinci).

For each: identify the translation the shipped English actually comes from, the translator's death year, and the work and locus. Verify against archival or primary sources — Internet Archive, Project Gutenberg, Wikisource, Perseus — never a quotation aggregator. Aggregators are the mechanism by which a Semisonic lyric acquired a Seneca credit.

Known hazards to check explicitly, not assume:
- W. D. Ross, the standard Aristotle translator, **died in 1971** and fails. If `coachQuote10` traces to Ross, it must be re-sourced or dropped.
- `coachQuote3` (Seneca, *De Brevitate Vitae*) — the obvious modern rendering is Basore's 1932 Loeb (d. 1961), which fails. A pre-1929 English *De Brevitate Vitae* exists; pin it or drop the entry.
- `coachQuote6` reads as a paraphrase. Long's actual Epictetus is "First say to yourself what you would be; and then do what you have to do." Reword to a real edition or drop.
- `coachQuote23` (Leonardo) — Richter's 1883 *Literary Works* passes (d. 1937); McCurdy's 1938 *Notebooks* does not (d. 1957).
- `coachQuote7` (Lao Tzu) — Legge 1891 (d. 1897) passes. Confirm the shipped wording is Legge's and not a later rendering.

- [ ] **Step 4: Audit the thirteen English-original entries**

`coachQuote12`–`coachQuote21`. Verbatim still applies: the wording must match a named published edition. `coachQuote19` ships as a compressed "Man in the Arena" — restore Roosevelt's actual clause or drop it. `coachQuote18` was recredited to Oliver Goldsmith in fix round 1; re-verify that credit rather than inheriting it. Confirm each author's death year (Emerson 1882, Thoreau 1862, Franklin 1790, Goldsmith 1774, Roosevelt 1919, Shakespeare 1616 — verify, do not assume).

- [ ] **Step 5: Write the findings file**

One row per key, in the scratchpad file, with a `KEEP` / `REWORD` / `DROP` verdict, the exact replacement wording for every `REWORD`, and the source URL consulted for every row. Where a verdict is `DROP`, state which clause of the rule it fails.

- [ ] **Step 6: Report the verdict counts and stop for review**

Report: how many `KEEP`, how many `REWORD`, how many `DROP`, and the resulting bank size. Do not proceed to Task 2 until the findings are reviewed.

---

### Task 2: Apply the audit's verdicts to the bank

**Files:**
- Modify: `lib/l10n/app_en.arb:1104-1124`
- Modify: `lib/features/trainer/presentation/providers/phrase_resolver.dart:113-133`
- Modify: `lib/features/trainer/data/persona_packs.dart:28-50`
- Modify: `test/features/trainer/data/persona_packs_test.dart:153-181`

**Interfaces:**
- Consumes: Task 1's findings file.
- Produces: a `_quoteBank` containing only verified keys. Task 3's `quoteSources` map must have exactly one row per surviving key.

- [ ] **Step 1: Tighten the bank-size assertion to the surviving count *before* editing the bank**

In `persona_packs_test.dart`, change the threshold on line 177 from `greaterThanOrEqualTo(20)` to the count Task 1 leaves behind. If the audit drops four quotes, that is `greaterThanOrEqualTo(17)`.

Then add a temporary upper bound directly beneath it so this step has a failing test to drive the edit:

```dart
      expect(
        persona.phrasesFor(TrainerEventKind.quote).length,
        lessThanOrEqualTo(17), // TEMPORARY — deleted in step 5
        reason: '${persona.id} persona still ships an unverified quote',
      );
```

- [ ] **Step 2: Run it and watch it fail**

```bash
flutter test test/features/trainer/data/persona_packs_test.dart
```

Expected: FAIL — "steady persona still ships an unverified quote", because the bank is still 21.

- [ ] **Step 3: Remove each dropped key from all three files**

For every `DROP` key, delete:
- its `"coachQuoteN": "..."` line from `lib/l10n/app_en.arb`
- its `'coachQuoteN': (s, _) => s.coachQuoteN,` line from `phrase_resolver.dart`
- its `'coachQuoteN',` line from `_quoteBank` in `persona_packs.dart`

Leaving the resolver entry behind is a compile error once the ARB key is gone, so the analyser catches that half of the mistake. Leaving the `_quoteBank` entry behind is **not** caught by the compiler — it fails only in the resolver-completeness test. Delete all three.

Do not renumber the survivors. The gaps are part of the record.

- [ ] **Step 4: Apply every `REWORD` verdict to the ARB text**

Replace the string value only. Do not touch the key, and do not touch the `@coachQuoteN` metadata block if one exists.

- [ ] **Step 5: Delete the temporary upper bound and extend the history comment**

Remove the `lessThanOrEqualTo` block added in step 1. Then extend the comment above the test (lines 154–173) with a fifth round, in the same voice as the existing four: what this round removed, and the rule it converged on — that a paraphrase matching no identified edition cannot be shown not to be tracking a modern in-copyright translation, which is the Hays failure in a subtler form.

- [ ] **Step 6: Regenerate localisations and run the full suite**

```bash
flutter gen-l10n && flutter test
```

Expected: PASS. The resolver-completeness test in `persona_packs_test.dart` is the one that catches a half-finished drop.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/ lib/features/trainer/ test/features/trainer/
git commit -m "fix: drop and re-source quotes the sourcing audit condemned (#104)"
```

---

### Task 3: Record the sourcing table and enforce it covers the bank

**Files:**
- Create: `lib/features/trainer/data/quote_sources.dart`
- Create: `test/features/trainer/data/quote_sources_test.dart`
- Modify: `lib/features/trainer/data/persona_packs.dart:15-16`

**Interfaces:**
- Consumes: Task 1's findings; Task 2's trimmed `_quoteBank`.
- Produces: `class QuoteSource` with fields `author` (`String`), `authorDied` (`int`), `work` (`String`), `edition` (`String`), `translator` (`String?`), `translatorDied` (`int?`); and `const Map<String, QuoteSource> quoteSources`. Tasks 4 and 5 assert over both.

- [ ] **Step 1: Write the failing tests**

Create `test/features/trainer/data/quote_sources_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/data/persona_packs.dart';
import 'package:rep_foundry/features/trainer/data/quote_sources.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';

/// The shared quote bank, read through the persona that carries it —
/// `_quoteBank` is private to persona_packs.dart, and every persona is
/// handed the same list.
final List<String> _bank = steadyPersona.phrasesFor(TrainerEventKind.quote);

void main() {
  // Positive control for every loop below. Each of them iterates the bank or
  // the table, so an empty one would let all of them pass while checking
  // nothing — the failure mode CLAUDE.md calls out for negative assertions.
  test('the bank and the sourcing table are both non-empty', () {
    expect(_bank, isNotEmpty);
    expect(quoteSources, isNotEmpty);
  });

  test('every quote in the bank has a sourcing row', () {
    for (final key in _bank) {
      expect(
        quoteSources.containsKey(key),
        isTrue,
        reason: '$key is spoken to users with no recorded source',
      );
    }
  });

  test('every sourcing row names a quote still in the bank', () {
    for (final key in quoteSources.keys) {
      expect(
        _bank,
        contains(key),
        reason: '$key has a sourcing row but is not in the bank',
      );
    }
  });

  test('a row gives a translator and a translator death year, or neither', () {
    quoteSources.forEach((key, source) {
      expect(
        source.translator == null,
        source.translatorDied == null,
        reason: '$key: translator and translatorDied must be given together',
      );
    });
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

```bash
flutter test test/features/trainer/data/quote_sources_test.dart
```

Expected: FAIL to compile — `Error: Couldn't resolve the package 'rep_foundry/features/trainer/data/quote_sources.dart'`.

- [ ] **Step 3: Create the sourcing file**

```dart
/// Per-quote licensing evidence for the shared quote bank in
/// `persona_packs.dart`.
///
/// This file is the record the licensing rule is applied *to*. The rule
/// itself is stated above `_quoteBank`: every named person whose words we
/// ship, original author and translator alike, must have died more than 70
/// years ago, and publication date alone is never sufficient.
///
/// One row per key in the bank, enforced both ways in
/// `test/features/trainer/data/quote_sources_test.dart` — a quote cannot be
/// added without its evidence, and evidence cannot outlive its quote.
///
/// Deliberately the only copy. A second table in the docs would be a second
/// thing to keep true, and an inaccurate sourcing table is worse than none:
/// it invites exactly the confidence that let a 2002 Gregory Hays
/// translation ship under Marcus Aurelius' long-expired name.
class QuoteSource {
  const QuoteSource({
    required this.author,
    required this.authorDied,
    required this.work,
    required this.edition,
    this.translator,
    this.translatorDied,
  });

  /// The name credited after the em dash in the spoken text. Asserted equal
  /// to it — a corrected attribution that is not carried into this table is
  /// how the Muriel Strode copyright problem stayed hidden.
  final String author;

  /// Year of death. Negative for BCE.
  final int authorDied;

  /// Work and locus, e.g. 'Meditations, X.16'.
  final String work;

  /// The specific published edition the shipped wording is taken from,
  /// verbatim. Not "a public-domain edition" — the one actually relied on.
  final String edition;

  /// null if and only if the quote was written in English.
  final String? translator;

  /// null if and only if [translator] is null.
  final int? translatorDied;
}

const Map<String, QuoteSource> quoteSources = {
  // One entry per surviving key, from the Task 1 findings. Shape:
  'coachQuote5': QuoteSource(
    author: 'Epictetus',
    authorDied: 135,
    work: 'Enchiridion, 5',
    edition: 'The Discourses as Reported by Arrian, Loeb, 1928',
    translator: 'W. A. Oldfather',
    translatorDied: 1945,
  ),
};
```

Fill in every surviving key from the findings file. `coachQuote5` above is a real, already-verified row (fix round 3) — use it as the shape, and keep it.

- [ ] **Step 4: Run the tests and watch them pass**

```bash
flutter test test/features/trainer/data/quote_sources_test.dart
```

Expected: PASS, all four.

- [ ] **Step 5: Prove the bijection tests can fail**

Both directions, one at a time, restoring after each:

1. Comment out one row in `quoteSources`. Run. Expected: FAIL, "…is spoken to users with no recorded source". Restore.
2. Add `'coachQuote99': QuoteSource(author: 'x', authorDied: 1, work: 'x', edition: 'x'),`. Run. Expected: FAIL, "coachQuote99 has a sourcing row but is not in the bank". Remove.
3. Change `_bank` to `const <String>[]`. Run. Expected: FAIL on the non-empty control — this is what stops the whole file passing vacuously. Restore.

Record in the commit message that all three were observed.

- [ ] **Step 6: Repoint the doc comment in `persona_packs.dart`**

Replace lines 15–16:

```dart
/// The per-quote sourcing table (author, work, translation/edition relied on)
/// is not yet in this repo — see issue #104.
```

with:

```dart
/// The per-quote sourcing evidence — author, work, edition, translator, and
/// both death dates — is in `quote_sources.dart`, one row per key here.
/// Tests enforce the correspondence both ways: a quote added here without a
/// row there fails the suite.
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/trainer/data/ test/features/trainer/data/
git commit -m "feat: record per-quote sourcing evidence in the repo (#104)"
```

---

### Task 4: Enforce the life+70 rule and the attribution match

**Files:**
- Modify: `test/features/trainer/data/quote_sources_test.dart`

**Interfaces:**
- Consumes: `quoteSources` from Task 3; `phraseResolvers` from `lib/features/trainer/presentation/providers/phrase_resolver.dart`; `lookupS` from `lib/l10n/generated/app_localizations.dart`.

- [ ] **Step 1: Write the failing tests**

Add these imports to the top of the test file:

```dart
import 'package:flutter/widgets.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/phrase_resolver.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
```

and these tests inside `main()`:

```dart
  test('every author and translator died more than 70 years ago', () {
    // Computed from the current year rather than hardcoded: the rule is
    // life+70, so the cutoff moves. Deriving it means the constraint can
    // only ever loosen with time, never silently tighten around an entry
    // that was verified under a different constant.
    final cutoff = DateTime.now().year - 70;
    quoteSources.forEach((key, source) {
      expect(
        source.authorDied,
        lessThan(cutoff),
        reason: '$key: ${source.author} (d. ${source.authorDied}) is not yet '
            '70 years dead',
      );
      final translatorDied = source.translatorDied;
      if (translatorDied != null) {
        expect(
          translatorDied,
          lessThan(cutoff),
          reason: '$key: translator ${source.translator} '
              '(d. $translatorDied) is not yet 70 years dead',
        );
      }
    });
  });

  test('the name credited in the spoken text matches its sourcing row', () {
    final s = lookupS(const Locale('en'));
    quoteSources.forEach((key, source) {
      final text = phraseResolvers[key]!(s, const {});
      final dash = text.lastIndexOf('—');
      expect(
        dash,
        greaterThan(-1),
        reason: '$key has no "— Author" credit to check against its source',
      );
      expect(
        text.substring(dash + 1).trim(),
        source.author,
        reason: '$key credits someone other than its sourcing row names',
      );
    });
  });
```

- [ ] **Step 2: Run them and watch them pass**

```bash
flutter test test/features/trainer/data/quote_sources_test.dart
```

Expected: PASS. These two pass on first run because Task 1 did the work they check — which is exactly why step 3 is not optional.

- [ ] **Step 3: Prove both can fail**

One at a time, restoring after each:

1. Set any row's `translatorDied` to `1969` — the real Gummere case. Run. Expected: FAIL, "translator … is not yet 70 years dead". Restore.
2. Set any row's `authorDied` to `1968` — the real Helen Keller case. Run. Expected: FAIL. Restore.
3. Change any row's `author` to `'Ralph Waldo Emerson'` — the real Muriel Strode misattribution. Run. Expected: FAIL, "credits someone other than its sourcing row names". Restore.
4. Change `lessThan(cutoff)` to `lessThan(cutoff + 200)`. Run with mutation 1 still applied. Expected: PASS — confirming the assertion, not the loop, is what catches it. Restore both.

- [ ] **Step 4: Commit**

```bash
git add test/features/trainer/data/quote_sources_test.dart
git commit -m "test: enforce life+70 and attribution agreement on the quote table (#104)"
```

---

### Task 5: Record the rejected quotes so they cannot return

**Files:**
- Modify: `lib/features/trainer/data/quote_sources.dart`
- Modify: `test/features/trainer/data/quote_sources_test.dart`

**Interfaces:**
- Produces: `class RejectedQuote` with fields `fingerprint` (`String`, lowercase), `attribution` (`String`), `reason` (`String`); and `const List<RejectedQuote> rejectedQuotes`.

- [ ] **Step 1: Write the failing test**

```dart
  test('quotes dropped for licensing cannot reappear in the bank', () {
    final s = lookupS(const Locale('en'));
    final live = [
      for (final key in _bank) phraseResolvers[key]!(s, const {}).toLowerCase(),
    ];
    // Positive control: this is a negative assertion, and an empty `live`
    // would satisfy it while checking nothing.
    expect(live, isNotEmpty);
    expect(rejectedQuotes, isNotEmpty);
    for (final rejected in rejectedQuotes) {
      for (final text in live) {
        expect(
          text.contains(rejected.fingerprint),
          isFalse,
          reason: 'this was dropped: ${rejected.reason}',
        );
      }
    }
  });
```

- [ ] **Step 2: Run it and watch it fail**

```bash
flutter test test/features/trainer/data/quote_sources_test.dart
```

Expected: FAIL to compile — `rejectedQuotes` and `RejectedQuote` are undefined.

- [ ] **Step 3: Add the rejected list to `quote_sources.dart`**

```dart
/// A quote dropped for licensing, kept so it cannot come back by accident.
///
/// Three of these are the same mistake — reasoning from publication date
/// rather than death date — and one of them, the Strode entry, reads as
/// entirely safe under the false Emerson credit it originally shipped with.
/// Without this list the only defence is that someone remembers.
class RejectedQuote {
  const RejectedQuote({
    required this.fingerprint,
    required this.attribution,
    required this.reason,
  });

  /// A distinctive fragment of the dropped wording, lowercase, searched for
  /// in every live quote.
  final String fingerprint;

  /// The name it was credited to when it shipped or was proposed.
  final String attribution;

  final String reason;
}

const List<RejectedQuote> rejectedQuotes = [
  RejectedQuote(
    fingerprint: 'some other beginning',
    attribution: 'Seneca',
    reason: "the hook of Semisonic's Closing Time (1998), verbatim; the "
        'Seneca credit is an internet attribution that post-dates the song',
  ),
  RejectedQuote(
    fingerprint: 'the impediment to action advances action',
    attribution: 'Marcus Aurelius',
    reason: "Gregory Hays' 2002 rendering of Meditations 5.20 — the author "
        'is public domain, the translator is not',
  ),
  RejectedQuote(
    fingerprint: 'optimism is the faith',
    attribution: 'Helen Keller',
    reason: 'Keller died in 1968; in UK copyright until 2038. Its '
        'public-domain status rested on US publication date alone.',
  ),
  RejectedQuote(
    fingerprint: 'while we are postponing, life speeds by',
    attribution: 'Seneca',
    reason: "Richard M. Gummere's 1917 Loeb translation; Gummere died in "
        '1969, so the translation is in copyright until 2039',
  ),
  RejectedQuote(
    fingerprint: 'follow where the path may lead',
    attribution: 'Muriel Strode',
    reason: 'Strode died in 1964; in copyright until 2034. Long shipped '
        'under a false Emerson credit, which is what made it look safe — '
        'correcting the attribution is what exposed the problem.',
  ),
];
```

Correct each `fingerprint` against the wording recovered in Task 1 step 2 — a fingerprint that does not match the real dropped text guards nothing.

- [ ] **Step 4: Run it and watch it pass**

```bash
flutter test test/features/trainer/data/quote_sources_test.dart
```

Expected: PASS, all seven tests.

- [ ] **Step 5: Prove it can fail**

Temporarily add the Strode quote back — an ARB entry, a resolver entry, and a `_quoteBank` entry:

```json
  "coachQuote11": "I will not follow where the path may lead, but I will go where there is no path, and I will leave a trail. — Ralph Waldo Emerson",
```

Run `flutter gen-l10n && flutter test test/features/trainer/data/quote_sources_test.dart`.
Expected: FAIL, "this was dropped: Strode died in 1964…" — and note that it fails *under the false Emerson credit*, which is the whole point of matching on wording rather than on attribution. Revert all three files and re-run `flutter gen-l10n`.

- [ ] **Step 6: Commit**

```bash
git add lib/features/trainer/data/quote_sources.dart test/features/trainer/data/quote_sources_test.dart
git commit -m "test: record rejected quotes so a dropped entry cannot return (#104)"
```

---

### Task 6: Verify and open the pull request

**Files:** none modified beyond fixes the checks demand.

- [ ] **Step 1: Run the full verification sweep**

```bash
flutter gen-l10n
dart analyze
dart format --set-exit-if-changed .
flutter test
```

Expected: analyser clean, formatter clean, full suite passing. Report the actual test count — do not describe the suite as passing without the number in front of you.

- [ ] **Step 2: Confirm no stray second copy of the table exists**

```bash
grep -ril 'authorDied\|sourcing table' src/docs docs lib test
```

Expected: `quote_sources.dart`, its test, `persona_packs.dart`, and the spec and plan documents. Anything under `src/docs` is a duplicate the design rules out.

- [ ] **Step 3: Confirm no dropped key survives anywhere**

For each dropped `coachQuoteN`:

```bash
grep -rn 'coachQuoteN' lib/ test/
```

Expected: no matches, including in `lib/l10n/generated/` (which will still hold them if `gen-l10n` was not re-run).

- [ ] **Step 4: Open the pull request**

Body must state: the bank's before and after size, every quote dropped with the clause it failed, every quote re-worded with the edition it now matches, and the mutations run in Tasks 3–5 with what each one produced. A reviewer's first question will be "how do you know these tests work" — answer it in the body.

```bash
git push -u origin feat/104-quote-sourcing
gh pr create --title 'docs: record the per-quote sourcing table (#104)' --body-file <path>
```

---

## Notes for the implementer

**Why the audit comes before the table.** Building `quoteSources` from the current 21 entries and then deleting rows would mean writing sourcing evidence for quotes we are about to drop, and would leave the bijection test red in between. Verdicts first, table second.

**Why `_bank` is read through `steadyPersona`.** `_quoteBank` is private to `persona_packs.dart`. Every persona is handed the identical list (see lines 92, 153, 205), so reading it through any one of them reads the bank itself. Do not widen the visibility of `_quoteBank` for the test's convenience.

**The em-dash in the attribution test is `—` (U+2014), not `-` or `--`.** Copy it from `app_en.arb` rather than typing it.

**If Task 1 leaves fewer than about fifteen quotes,** stop and report before Task 2. The design chose to lower the threshold rather than backfill, but a bank that small is a different conversation, not a mechanical continuation of this one.
