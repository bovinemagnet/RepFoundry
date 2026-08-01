import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rep_foundry/features/trainer/data/flutter_tts_speech_service.dart';

import 'flutter_tts_speech_service_test.mocks.dart';

@GenerateMocks([FlutterTts])
void main() {
  test('swallows engine failures instead of throwing', () async {
    final tts = MockFlutterTts();
    when(tts.setSpeechRate(any)).thenThrow(Exception('no engine'));
    final service = FlutterTtsSpeechService(tts: tts);

    await expectLater(service.speak('hello'), completes);
  });

  test('reports unavailable when no languages are returned', () async {
    final tts = MockFlutterTts();
    when(tts.getLanguages).thenAnswer((_) async => <String>[]);
    final service = FlutterTtsSpeechService(tts: tts);

    expect(await service.isAvailable(), isFalse);
  });
}
