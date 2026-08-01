import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rep_foundry/features/trainer/data/flutter_tts_speech_service.dart';
import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';

import 'flutter_tts_speech_service_test.mocks.dart';

/// Stubs the calls `_configure()` makes so it succeeds without requiring
/// every test to repeat the same boilerplate. Unstubbed calls on a
/// mockito-generated mock throw `MissingStubError`, so any call the
/// implementation makes must have a stub even when a test only cares about
/// a different call.
void _stubSuccessfulConfiguration(MockFlutterTts tts) {
  when(tts.setSpeechRate(any)).thenAnswer((_) async {});
  when(tts.awaitSpeakCompletion(any)).thenAnswer((_) async {});
  when(tts.setIosAudioCategory(any, any, any)).thenAnswer((_) async {});
  when(tts.setQueueMode(any)).thenAnswer((_) async {});
  when(tts.stop()).thenAnswer((_) async {});
}

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

  test('retries a failed configuration on the next call', () async {
    final tts = MockFlutterTts();
    _stubSuccessfulConfiguration(tts);
    when(tts.speak('second attempt', focus: true)).thenAnswer((_) async {});
    var setSpeechRateAttempts = 0;
    when(tts.setSpeechRate(any)).thenAnswer((_) async {
      setSpeechRateAttempts++;
      if (setSpeechRateAttempts == 1) {
        throw Exception('engine not ready');
      }
    });
    final service = FlutterTtsSpeechService(tts: tts);

    // The first call fails during configuration and is swallowed.
    await service.speak('first attempt');
    // A working second call must redo the setup that failed, not skip it.
    await service.speak('second attempt');

    expect(setSpeechRateAttempts, 2);
    verify(tts.setIosAudioCategory(any, any, any)).called(1);
    verifyNever(tts.speak('first attempt', focus: true));
    verify(tts.speak('second attempt', focus: true)).called(1);
  });

  test('a higher-priority cue interrupts a lower-priority cue in flight', () {
    fakeAsync((async) {
      final tts = MockFlutterTts();
      _stubSuccessfulConfiguration(tts);
      final lowCompleter = Completer<dynamic>();
      when(tts.speak('low priority', focus: true))
          .thenAnswer((_) => lowCompleter.future);
      when(tts.speak('high priority', focus: true))
          .thenAnswer((_) async => null);
      final service = FlutterTtsSpeechService(tts: tts);

      unawaited(
        service.speak('low priority', priority: SpeechPriority.encouragement),
      );
      async.flushMicrotasks();

      unawaited(
        service.speak('high priority', priority: SpeechPriority.safety),
      );
      async.flushMicrotasks();

      verify(tts.stop()).called(1);
      verify(tts.speak('high priority', focus: true)).called(1);

      lowCompleter.complete();
      async.flushMicrotasks();
    });
  });

  test(
      'an equal-or-lower-priority cue is dropped rather than queued '
      'while one is in flight', () {
    fakeAsync((async) {
      final tts = MockFlutterTts();
      _stubSuccessfulConfiguration(tts);
      final completer = Completer<dynamic>();
      when(tts.speak('first', focus: true)).thenAnswer((_) => completer.future);
      final service = FlutterTtsSpeechService(tts: tts);

      unawaited(
        service.speak('first', priority: SpeechPriority.milestone),
      );
      async.flushMicrotasks();

      unawaited(
        service.speak('second', priority: SpeechPriority.encouragement),
      );
      async.flushMicrotasks();

      verifyNever(tts.stop());
      verifyNever(tts.speak('second', focus: true));

      completer.complete();
      async.flushMicrotasks();
    });
  });

  test(
      '_currentPriority is not left stale after an interrupted cue '
      'settles late', () {
    fakeAsync((async) {
      final tts = MockFlutterTts();
      _stubSuccessfulConfiguration(tts);
      final lowCompleter = Completer<dynamic>();
      final highCompleter = Completer<dynamic>();
      when(tts.speak('low priority', focus: true))
          .thenAnswer((_) => lowCompleter.future);
      when(tts.speak('high priority', focus: true))
          .thenAnswer((_) => highCompleter.future);
      when(tts.speak('dropped', focus: true)).thenAnswer((_) async => null);
      final service = FlutterTtsSpeechService(tts: tts);

      // The low-priority cue starts and suspends waiting on the engine.
      unawaited(
        service.speak('low priority', priority: SpeechPriority.encouragement),
      );
      async.flushMicrotasks();

      // A safety cue interrupts it, takes over `_currentPriority`, and
      // itself suspends waiting on the engine.
      unawaited(
        service.speak('high priority', priority: SpeechPriority.safety),
      );
      async.flushMicrotasks();
      verify(tts.speak('high priority', focus: true)).called(1);

      // Only now does the cancelled low-priority call's suspended await
      // resolve — after the interrupting cue has already taken over. Its
      // `finally` must not clobber the still-in-flight interrupting cue.
      lowCompleter.complete();
      async.flushMicrotasks();

      // If `_currentPriority` had been wrongly cleared above, this
      // equal-priority cue would be let through instead of dropped,
      // cutting off the safety cue that is still speaking.
      unawaited(
        service.speak('dropped', priority: SpeechPriority.safety),
      );
      async.flushMicrotasks();

      verify(tts.stop()).called(1);
      verifyNever(tts.speak('dropped', focus: true));

      highCompleter.complete();
      async.flushMicrotasks();
    });
  });
}
