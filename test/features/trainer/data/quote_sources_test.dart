import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/data/persona_packs.dart';
import 'package:rep_foundry/features/trainer/data/quote_sources.dart';
import 'package:rep_foundry/features/trainer/domain/trainer_event.dart';
import 'package:rep_foundry/features/trainer/presentation/providers/phrase_resolver.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

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
}
