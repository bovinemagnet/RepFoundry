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
///
/// What a green suite here does not prove: [translator] `null` is
/// self-declared, so a translated quote filed as an English original is
/// checked against its author's death year alone — the Hays failure in its
/// exact original shape; editors named inside [edition] (Torrey d. 1912,
/// Ford d. 1902) have death years no test reads; and
/// [RejectedQuote.attribution] is never asserted on, deliberately, because
/// "Seneca" and "Marcus Aurelius" are live credits and the check would fire
/// on the quotes that legitimately carry them. These rows are evidence a
/// reader has to read, not coverage.
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

/// A quote dropped for licensing, kept so it cannot come back by accident.
///
/// Each of these got through because something other than a death date was
/// doing the reasoning. For Keller it was a publication date. For Hays and
/// Gummere it was the author's dates standing in for the translator's — a
/// public-domain author can still carry an in-copyright translation. For the
/// Semisonic lyric and for Strode it was a credit nobody had checked: a
/// fabricated Seneca name over a 1998 song, a false Emerson one over a
/// writer who died in 1964. For Aristotle, Emerson and Franklin it was an
/// attribution no named pre-1929 edition carries, and for Roosevelt one that
/// the very page the words come from hands to another man. Without this list
/// the only defence is that someone remembers.
class RejectedQuote {
  const RejectedQuote({
    required this.fingerprint,
    required this.attribution,
    required this.reason,
  });

  /// A distinctive fragment of the dropped wording, lowercase, searched for
  /// in every live quote. Kept free of apostrophes and other characters with
  /// look-alike variants, and short enough to survive the rewordings the
  /// saying actually circulates in — a fragment that only matches one
  /// variant lets the others walk back in.
  final String fingerprint;

  /// The name it was credited to when it shipped or was proposed.
  final String attribution;

  final String reason;
}

const List<RejectedQuote> rejectedQuotes = [
  RejectedQuote(
    fingerprint: 'comes from some other beginning',
    attribution: 'Seneca',
    reason: "the hook of Semisonic's Closing Time (1998), verbatim; shipped "
        'under a fabricated Seneca credit',
  ),
  RejectedQuote(
    fingerprint: 'impediment to action advances action',
    attribution: 'Marcus Aurelius',
    reason: "Gregory Hays' 2002 rendering of Meditations — the author is "
        'public domain, the translator is not',
  ),
  RejectedQuote(
    fingerprint: 'full of suffering',
    attribution: 'Helen Keller',
    reason: 'Keller ("Optimism", 1903) died in 1968; in UK/EU copyright '
        'until 2038. Its public-domain status rested on US publication '
        'date alone.',
  ),
  RejectedQuote(
    fingerprint: 'postponing, life speeds by',
    attribution: 'Seneca',
    reason: "Richard M. Gummere's 1917 Loeb translation; Gummere (1883-1969) "
        'died in 1969, so the translation is in copyright until 2039',
  ),
  RejectedQuote(
    // Keyed on the span the circulating variants share rather than on any
    // one of them. This saying travels in more than one wording and under
    // more than one credit; a fingerprint tied to a single variant lets the
    // others walk straight back in.
    fingerprint: 'where the path may lead',
    attribution: 'Muriel Strode',
    reason: 'Strode died in 1964; in copyright until 2034. Long shipped '
        'under a false Emerson credit, which is what made it look safe — '
        'correcting the attribution is what exposed the problem.',
  ),
  RejectedQuote(
    fingerprint: 'well begun is half done',
    attribution: 'Aristotle',
    reason: 'an English proverb, not Aristotle: the wording is in neither '
        "pre-1929 translation checked (Chase's Nicomachean Ethics, Ellis's "
        'Politics). Aristotle is safely dead; that was never the question.',
  ),
  RejectedQuote(
    fingerprint: 'pace of nature',
    attribution: 'Ralph Waldo Emerson',
    reason: "found nowhere in Emerson's collected prose or verse — not in "
        'the Centenary Edition, not in Wikiquote, only on quotation '
        'aggregators. A correct-looking credit to a public-domain author is '
        'what the death-date check cannot see.',
  ),
  RejectedQuote(
    fingerprint: 'persistence conquer all things',
    attribution: 'Benjamin Franklin',
    reason: 'in no Franklin primary text searched (Poor Richard, the '
        'Complete Works, the Autobiography); carried only by quotation '
        'aggregators, under a credit that looks entirely safe.',
  ),
  RejectedQuote(
    // Stops short of "you've got": a re-add typed with a typographic
    // apostrophe would not match a fingerprint carrying a straight one.
    fingerprint: 'do what you can',
    attribution: 'Theodore Roosevelt',
    reason: "Roosevelt's Autobiography (1913, ch. IX) credits it to Squire "
        "Bill Widener of Widener's Valley, Virginia — the credit is "
        'contradicted by the very page the words come from, and no reliable '
        "source gives Widener's death year.",
  ),
];

const Map<String, QuoteSource> quoteSources = {
  'coachQuote1': QuoteSource(
    author: 'Marcus Aurelius',
    authorDied: 180,
    work: 'Meditations, X.16',
    edition: 'The Thoughts of the Emperor M. Aurelius Antoninus, trans. George '
        'Long, London: George Bell & Sons, 1887 (the later Long revision, '
        'with "at all" — the 1864 printing lacks it)',
    translator: 'George Long',
    translatorDied: 1879,
  ),
  'coachQuote2': QuoteSource(
    author: 'Marcus Aurelius',
    authorDied: 180,
    work: 'Meditations, XII.17',
    edition: 'The Thoughts of the Emperor M. Aurelius Antoninus, trans. George '
        'Long, London: George Bell & Sons, 1887',
    translator: 'George Long',
    translatorDied: 1879,
  ),
  'coachQuote3': QuoteSource(
    author: 'Seneca',
    authorDied: 65,
    work: 'De Brevitate Vitae, I',
    edition: "L. Annaeus Seneca, Minor Dialogues Together With the Dialogue On "
        "Clemency, trans. Aubrey Stewart, London: George Bell and Sons "
        "(Bohn's Classical Library), 1889",
    translator: 'Aubrey Stewart',
    translatorDied: 1918,
  ),
  'coachQuote5': QuoteSource(
    author: 'Epictetus',
    authorDied: 135,
    work: 'Enchiridion, 5',
    edition: 'Epictetus: The Discourses as Reported by Arrian, the Manual, '
        'and Fragments, Loeb Classical Library vol. II, trans. W. A. '
        'Oldfather, London: Heinemann / Cambridge MA: Harvard UP, first '
        'printed 1928 (the line is in the Manual, not the Discourses)',
    translator: 'W. A. Oldfather',
    translatorDied: 1945,
  ),
  'coachQuote6': QuoteSource(
    author: 'Epictetus',
    authorDied: 135,
    work: 'Discourses, III.23.1',
    edition:
        "The Discourses of Epictetus; with the Encheiridion and Fragments, "
        "trans. George Long, London: George Bell and Sons (Bohn's "
        "Classical Library), 1887",
    translator: 'George Long',
    translatorDied: 1879,
  ),
  // Laozi is traditionally credited as the Tao Te Ching's author, but the
  // text is anciently anonymous and has no attested personal death date.
  // authorDied here is the text's approximate composition era, not a
  // person's death year, and the attribution itself is traditional rather
  // than historical.
  'coachQuote7': QuoteSource(
    author: 'Lao Tzu',
    authorDied: -400,
    work: 'Tâo Teh King, ch. 64 §2',
    edition: 'The Sacred Books of China: The Texts of Tâoism, Part I (Sacred '
        'Books of the East vol. XXXIX), trans. James Legge, Oxford: '
        'Clarendon Press, 1891',
    translator: 'James Legge',
    translatorDied: 1897,
  ),
  // Shipped credit is "Socrates" (the em-dash name in the ARB text), but
  // the words survive only via Plato's report of him — see work.
  'coachQuote8': QuoteSource(
    author: 'Socrates',
    authorDied: -399,
    work: 'Plato, Apology 38a',
    edition: 'The Dialogues of Plato, trans. Benjamin Jowett, 2nd edition, '
        'vol. I, Oxford: Clarendon Press, 1875 (later Jowett revisions '
        'read differently — the 1875 second edition is the one that '
        'matches)',
    translator: 'Benjamin Jowett',
    translatorDied: 1893,
  ),
  'coachQuote9': QuoteSource(
    author: 'Socrates',
    authorDied: -399,
    work: 'Plato, Apology 21d',
    edition: 'The Dialogues of Plato, trans. Benjamin Jowett, 2nd edition, '
        'vol. I, Oxford: Clarendon Press, 1875',
    translator: 'Benjamin Jowett',
    translatorDied: 1893,
  ),
  'coachQuote12': QuoteSource(
    author: 'Ralph Waldo Emerson',
    authorDied: 1882,
    work: 'Essays: First Series, "Circles"',
    edition: 'The Complete Works of Ralph Waldo Emerson, Centenary Edition, '
        'vol. II, Boston: Houghton Mifflin, 1903 (also verified against '
        'Project Gutenberg #2944, Essays — First Series)',
  ),
  'coachQuote14': QuoteSource(
    author: 'Henry David Thoreau',
    authorDied: 1862,
    work: 'Walden; or, Life in the Woods, ch. 18 "Conclusion"',
    edition: 'Walden; or, Life in the Woods, Boston: Ticknor and Fields, 1854',
  ),
  // Bradford Torrey edited this volume of Thoreau's own Journal; the words
  // are Thoreau's English, not a translation, so translator/translatorDied
  // stay null and the editor is named in edition instead.
  'coachQuote15': QuoteSource(
    author: 'Henry David Thoreau',
    authorDied: 1862,
    work: 'Journal, 5 August 1851',
    edition: 'Journal vol. II, ed. Bradford Torrey, Houghton Mifflin, 1906',
  ),
  // Paul Leicester Ford edited this collection of Franklin's own Poor
  // Richard's writings; the words are Franklin's English, not a
  // translation, so translator/translatorDied stay null.
  'coachQuote17': QuoteSource(
    author: 'Benjamin Franklin',
    authorDied: 1790,
    work: "Poor Richard's Almanack, 1737",
    edition: "The Prefaces, Proverbs, and Poems of Benjamin Franklin, "
        "Originally Printed in Poor Richard's Almanacs for 1733–1758, "
        "ed. Paul Leicester Ford, New York/London: G. P. Putnam's Sons, "
        "1889",
  ),
  'coachQuote18': QuoteSource(
    author: 'Oliver Goldsmith',
    authorDied: 1774,
    work: 'The Citizen of the World, Letter VII',
    edition:
        'The Citizen of the World; or, Letters from a Chinese Philosopher, '
        'London: printed for J. Parsons, 1794 (reprint of the 1762 '
        'collected edition; the 1891 J. M. Dent edition adds a comma not '
        'present here)',
  ),
  'coachQuote19': QuoteSource(
    author: 'Theodore Roosevelt',
    authorDied: 1919,
    work: '"Citizenship in a Republic", Sorbonne address, 23 April 1910',
    edition: "African and European Addresses, New York/London: G. P. Putnam's "
        "Sons, 1910",
  ),
  'coachQuote21': QuoteSource(
    author: 'William Shakespeare',
    authorDied: 1616,
    work: 'Coriolanus, III.2',
    edition: 'First Folio, 1623 (verified against Project Gutenberg #1535)',
  ),
  'coachQuote22': QuoteSource(
    author: 'Miguel de Cervantes',
    authorDied: 1616,
    work: 'Don Quixote, Part II, ch. XLIII',
    edition: 'Don Quixote of La Mancha, trans. John Ormsby, London: Smith, '
        'Elder & Co., 1885',
    translator: 'John Ormsby',
    translatorDied: 1895,
  ),
  'coachQuote23': QuoteSource(
    author: 'Leonardo da Vinci',
    authorDied: 1519,
    work: 'The Literary Works of Leonardo da Vinci, No. 682',
    edition: 'The Literary Works of Leonardo da Vinci, compiled and edited by '
        'Jean Paul Richter, London: Sampson Low, Marston, Searle & '
        'Rivington, 1883, vol. I',
    translator: 'Jean-Paul Richter',
    translatorDied: 1937,
  ),
};
