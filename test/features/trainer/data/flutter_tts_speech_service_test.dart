import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
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

  test(
      'still speaks on a platform whose TTS plugin does not implement '
      'setQueueMode', () async {
    // Regression: `setQueueMode` is Android-only — the iOS and macOS plugins
    // have no case for it, so the platform channel answers
    // FlutterMethodNotImplemented and `invokeMethod` throws
    // MissingPluginException. Configuring without a platform guard therefore
    // aborted `_configure()` before it ever reached `speak()`, silencing the
    // coach permanently on those platforms with no visible symptom.
    final tts = MockFlutterTts();
    _stubSuccessfulConfiguration(tts);
    when(tts.setQueueMode(any)).thenThrow(
      MissingPluginException(
        "No implementation found for method setQueueMode on channel flutter_tts",
      ),
    );
    when(tts.speak('hello', focus: true)).thenAnswer((_) async {});
    final service = FlutterTtsSpeechService(tts: tts);

    await service.speak('hello');

    verify(tts.speak('hello', focus: true)).called(1);
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

  test('concurrent cues share one configuration run rather than repeating it',
      () {
    fakeAsync((async) {
      final tts = MockFlutterTts();
      _stubSuccessfulConfiguration(tts);
      final configureGate = Completer<dynamic>();
      when(tts.setSpeechRate(any)).thenAnswer((_) => configureGate.future);
      when(tts.speak(any, focus: anyNamed('focus')))
          .thenAnswer((_) async => null);
      final service = FlutterTtsSpeechService(tts: tts);

      // Both cues arrive before configuration has finished, so neither can
      // see `_configured` set yet.
      unawaited(service.speak('first', priority: SpeechPriority.milestone));
      unawaited(service.speak('second', priority: SpeechPriority.safety));
      async.flushMicrotasks();

      configureGate.complete();
      async.flushMicrotasks();

      verify(tts.setSpeechRate(any)).called(1);
      verify(tts.awaitSpeakCompletion(any)).called(1);
      verify(tts.setIosAudioCategory(any, any, any)).called(1);
    });
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

  test(
      'a cue cannot lower _currentPriority while a higher-priority cue '
      'claimed by it is still in flight (three concurrent cues)', () {
    fakeAsync((async) {
      final tts = MockFlutterTts();
      _stubSuccessfulConfiguration(tts);
      final encouragementSpeak = Completer<dynamic>();
      final safetySpeak = Completer<dynamic>();
      final stopCalls = <Completer<dynamic>>[];
      when(tts.speak('encouragement cue', focus: true))
          .thenAnswer((_) => encouragementSpeak.future);
      when(tts.speak('safety cue', focus: true))
          .thenAnswer((_) => safetySpeak.future);
      when(tts.speak('milestone cue', focus: true))
          .thenAnswer((_) async => null);
      when(tts.speak('countdown cue', focus: true))
          .thenAnswer((_) async => null);
      // Each `stop()` call gets its own completer so the test can resolve
      // them in a chosen order, rather than all at once.
      when(tts.stop()).thenAnswer((_) {
        final completer = Completer<dynamic>();
        stopCalls.add(completer);
        return completer.future;
      });
      final service = FlutterTtsSpeechService(tts: tts);

      // Cue A (encouragement) starts and suspends waiting on the engine.
      unawaited(
        service.speak(
          'encouragement cue',
          priority: SpeechPriority.encouragement,
        ),
      );
      async.flushMicrotasks();

      // Cue B (safety) arrives: it reads the still-`encouragement` current
      // priority and is now suspended on its own `stop()` call.
      unawaited(
        service.speak('safety cue', priority: SpeechPriority.safety),
      );
      async.flushMicrotasks();

      // Cue C (milestone) arrives while B's `stop()` is still in flight —
      // the exact window in which a read-then-act race could let it read a
      // stale, not-yet-updated current priority.
      unawaited(
        service.speak('milestone cue', priority: SpeechPriority.milestone),
      );
      async.flushMicrotasks();

      // Resolve B's `stop()` before any possible second `stop()` from C, to
      // reproduce the interleaving where the higher-priority cue's own
      // cancellation resolves first.
      stopCalls[0].complete();
      async.flushMicrotasks();
      if (stopCalls.length > 1) {
        stopCalls[1].complete();
        async.flushMicrotasks();
      }

      // The milestone cue must never speak over the still-in-flight safety
      // cue, and must never have issued a second `stop()` call to cut it
      // off.
      verifyNever(tts.speak('milestone cue', focus: true));
      verify(tts.speak('safety cue', focus: true)).called(1);
      verify(tts.stop()).called(1);

      // A countdown cue (lower than safety, higher than milestone) must
      // still be dropped — proving `_currentPriority` reads `safety`, not
      // a `milestone` value a lower-priority cue clobbered it with.
      unawaited(
        service.speak('countdown cue', priority: SpeechPriority.countdown),
      );
      async.flushMicrotasks();
      verifyNever(tts.speak('countdown cue', focus: true));

      safetySpeak.complete();
      encouragementSpeak.complete();
      async.flushMicrotasks();
    });
  });
}
