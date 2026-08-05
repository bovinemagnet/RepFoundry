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
