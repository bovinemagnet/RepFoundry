# Per-Quote Sourcing Table — Design Specification

Issue: #104 (split out of #102)
Author: Paul Snow
Date: 2026-08-06

## 1. Problem

`persona_packs.dart` states the quote bank's licensing rule — every named person
whose words we ship, original author *and* translator, must have died more than
70 years ago; publication date alone is never sufficient. The rule is recorded.
The evidence is not.

The per-quote facts that rule was applied to — author, work and locus, the
translation or edition relied on, both death dates — exist nowhere in the
repository. They lived only in issue #99's fix-round report. Two consequences
follow:

- Auditing or adding a quote means re-deriving all 21 entries from scratch.
- The three quotes already dropped (Helen Keller d. 1968, Muriel Strode d. 1964,
  Gummere's 1917 Loeb Seneca — Gummere d. 1969) can be re-added by someone who
  does not know why they went. The Strode entry is the sharpest case: it was
  dropped *because* a false Emerson attribution was corrected, so under its old
  credit it looks entirely safe.

PR #103 claimed every surviving quote was "pinned to a named pre-1929 edition".
That claim is currently unfalsifiable inside the repo.

## 2. Scope

In scope:

- A per-quote sourcing record for all 21 entries in `_quoteBank`.
- Machine-enforced consistency between that record, the bank, and the ARB text.
- A fresh audit of every entry against a named pre-1929 edition, with the
  translator verified for all eight translated authors: Marcus Aurelius, Seneca,
  Epictetus, Lao Tzu, Socrates via Plato, Aristotle, Cervantes, Leonardo da
  Vinci.
- Removal of entries the audit condemns.

Out of scope:

- Replacement quotes to restore the bank's size.
- A virtual-trainer Antora page.
- Any change to how quotes are selected, merged into cues, or spoken.

## 3. Where the table lives

A new `lib/features/trainer/data/quote_sources.dart`, beside the bank it
documents.

```dart
class QuoteSource {
  const QuoteSource({
    required this.author,
    required this.authorDied,
    required this.work,
    required this.edition,
    this.translator,
    this.translatorDied,
  });

  /// As credited after the em dash in the ARB text.
  final String author;

  /// Year of death. Negative for BCE.
  final int authorDied;

  /// Work and locus, e.g. 'Meditations, X.16'.
  final String work;

  /// The specific edition the shipped wording is taken from.
  final String edition;

  /// null iff the quote was written in English.
  final String? translator;

  /// null iff [translator] is null.
  final int? translatorDied;
}

const Map<String, QuoteSource> quoteSources = { /* one row per quote key */ };
```

**One copy, not two.** No Antora page duplicating the table. PR #103's own
conclusion was that an inaccurate sourcing table is worse than none, because it
invites the false confidence that let the Hays translation through — and two
copies of a table are how one becomes inaccurate. `persona_packs.dart`'s doc
comment loses its "not yet in this repo — see issue #104" note and points at
`quote_sources.dart` instead.

Rejected entries are recorded in the same file as a documented constant, not as
prose, so the reason a quote is absent survives beside the reason the others are
present.

## 4. Enforcement

`test/features/trainer/data/quote_sources_test.dart`:

1. **Bijection.** Every key in `_quoteBank` has a `quoteSources` entry, and
   every `quoteSources` key is in the bank. This is the check that stops the
   next unsourced quote landing.
2. **Life+70.** Every `authorDied`, and every non-null `translatorDied`, is more
   than 70 years before `DateTime.now().year`. The rule stated in prose becomes
   a rule the suite applies. Computing the cutoff from the current year rather
   than hardcoding it means the constraint only ever loosens with time, never
   silently tightens.
3. **No half-filled row.** `translator == null` if and only if
   `translatorDied == null`.
4. **Attribution matches.** The name after the em dash in each ARB quote string
   equals the row's `author`. A corrected attribution that is not carried into
   the table — the exact mistake that exposed the Strode problem — fails here.
5. **Rejected entries stay rejected.** No rejected `fingerprint` — a
   distinctive, lowercase, apostrophe-free fragment of the dropped wording —
   appears in any live quote string. The keys are deliberately not checked:
   `coachQuote4`, `coachQuote11` and `coachQuote24` are gaps in the numbering,
   so a key assertion passes trivially while the wording walks back in under a
   new number. The `attribution` is deliberately not checked either: "Seneca"
   and "Marcus Aurelius" are live credits carried by quotes that passed the
   audit, so asserting on it would fail on every one of them. It is recorded
   for the reader, who needs to know which name the wording travelled under.

6. **No empty row.** `author`, `work` and `edition` are all non-empty.
   Assertion 1 stops an absent row but not a hollow one, and `work: 'TODO'`
   turns a red bijection green without recording anything.

`_quoteBank` is currently private to `persona_packs.dart`. The test reaches it
through `steadyPersona.phrasesFor(TrainerEventKind.quote)`, which is the same
list and needs no visibility change.

### Proving these tests can fail

Per CLAUDE.md, each assertion is mutation-proved before the work is called done:
break the line it protects, watch it go red, restore. Three deserve particular
care because they can pass without ever reaching the behaviour they describe:

- **Bijection** passes vacuously if the bank reference resolves to an empty
  list. Positive control: delete one `quoteSources` row and confirm failure,
  then add a bogus row and confirm failure in the other direction.
- **Life+70** passes if the map is empty or the year arithmetic is inverted.
  Positive control: set one `translatorDied` to 1969 (the Gummere case, a real
  historical failure) and confirm it is caught.
- **Rejected entries** is a negative assertion — "Keller does not appear" reads
  identically whether the guard works or the loop never runs. Positive control:
  add a Keller entry to the bank and confirm the test fails. It is also blind to
  a fingerprint that matches nothing at all, so the suite separately asserts
  that every dropped wording, verbatim from the audit, is caught by some
  fingerprint.
- **No empty row** is proved by blanking one field and confirming the bijection
  stays green while this assertion goes red — the whole reason it exists.

## 5. The audit

Each of the 21 entries is verified against a named pre-1929 edition: exact
wording, work and locus, translator, and both death dates. Verification is
against primary or archival sources, not quotation aggregators — aggregators are
the mechanism by which the Semisonic lyric acquired a Seneca credit.

**Verbatim is required.** Where the shipped wording is a paraphrase, it is
replaced with the exact text of a named public-domain edition carrying that
sense. Where no pre-1929 edition carries it, the entry is dropped. A paraphrase
that matches no identified edition cannot be shown not to be tracking a modern
in-copyright translation, which is the Hays failure in a subtler form.

This will change some quote strings. `coachQuote6` (Epictetus) and
`coachQuote19` (a compressed "Man in the Arena") are the known candidates.

Order of work: translator first for the eight translated authors, since that is
where this has already bitten twice.

## 6. Fallout

- Dropped quotes are removed from `_quoteBank` and `app_en.arb`. The ja, ko and
  zh ARBs carry no `coachQuote*` keys, so no other locale is affected.
- `persona_packs_test.dart`'s `greaterThanOrEqualTo(20)` assertion drops to the
  verified surviving count. Its comment — already a four-round history of this
  bank — is extended with what this round removed and why. The threshold is
  lowered rather than backfilled with new quotes: fewer individually verified
  entries beat a rounder number containing an unverified one, which is the
  principle that comment already states.
- If a quote's wording changes, no test asserts on quote *text*, so nothing
  breaks; the resolver keys are unchanged.

## 7. Success criteria

- [ ] Every one of the surviving quote keys has a complete `QuoteSource` row.
- [ ] Every translated entry names a translator dead more than 70 years.
- [ ] Every shipped wording matches its named edition verbatim.
- [ ] Every dropped quote is recorded as rejected, with reasons — both the ones
      dropped before this work and the ones this audit condemns. The second group
      matters more: they carry correct-looking credits to famously public-domain
      authors, so nothing about them looks wrong on re-reading.
- [ ] All six enforcement assertions are mutation-proved red before green.
- [ ] `dart analyze` clean, `dart format` clean, full suite passing.
