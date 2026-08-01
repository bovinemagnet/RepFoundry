import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_tts/flutter_tts.dart';

import '../domain/coaching_cue.dart';
import '../domain/speech_service.dart';

/// Speaks through the device's built-in text-to-speech engine, ducking other
/// audio so the coach is audible over the user's music without stopping it.
class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService({FlutterTts? tts, double speechRate = 0.5})
      : _tts = tts ?? FlutterTts(),
        _speechRate = speechRate;

  final FlutterTts _tts;
  final double _speechRate;

  bool _configured = false;
  SpeechPriority? _currentPriority;

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;

    await _tts.setSpeechRate(_speechRate);
    await _tts.awaitSpeakCompletion(true);
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.duckOthers,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
      IosTextToSpeechAudioMode.spokenAudio,
    );
    await _tts.setQueueMode(0);
  }

  @override
  Future<void> speak(
    String text, {
    SpeechPriority priority = SpeechPriority.encouragement,
  }) async {
    try {
      await _configure();

      // A higher-priority cue cuts off whatever is playing; an equal or lower
      // one waits its turn by being dropped, so cues never pile up.
      final current = _currentPriority;
      if (current != null) {
        if (priority.index <= current.index) return;
        await _tts.stop();
      }

      _currentPriority = priority;
      // `focus: true` requests transient, duckable audio focus on Android
      // (AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK); it is ignored on other
      // platforms, where ducking is instead governed by
      // setIosAudioCategory above.
      await _tts.speak(text, focus: true);
    } catch (e) {
      developer.log('Trainer speech failed', name: 'trainer', error: e);
    } finally {
      _currentPriority = null;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      developer.log('Trainer speech stop failed', name: 'trainer', error: e);
    } finally {
      _currentPriority = null;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final languages = await _tts.getLanguages;
      return languages is List && languages.isNotEmpty;
    } catch (e) {
      developer.log('Trainer speech availability check failed',
          name: 'trainer', error: e);
      return false;
    }
  }

  @override
  void dispose() {
    unawaited(stop());
  }
}
