import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';

import 'silent_speech_service.dart';

void main() {
  test('records spoken text and stop calls', () async {
    final service = SilentSpeechService();

    await service.speak('Good set.', priority: SpeechPriority.encouragement);
    await service.stop();

    expect(service.spoken, ['Good set.']);
    expect(service.stopCount, 1);
  });
}
