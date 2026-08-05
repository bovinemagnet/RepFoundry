import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';

void main() {
  group('CoachingCue.quotePhraseKey', () {
    test('defaults to null so existing cues are unchanged', () {
      const cue = CoachingCue(
        phraseKey: 'coachSteadyStart1',
        priority: SpeechPriority.milestone,
      );

      expect(cue.quotePhraseKey, isNull);
    });

    test('carries an attached quote key when supplied', () {
      const cue = CoachingCue(
        phraseKey: 'coachSteadyStart1',
        priority: SpeechPriority.milestone,
        quotePhraseKey: 'coachQuote3',
      );

      expect(cue.quotePhraseKey, 'coachQuote3');
    });
  });
}
