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
  int _speechGeneration = 0;

  /// Runs one-off setup. Left un-flagged until every step succeeds, so a
  /// transient failure (engine not yet connected, etc.) is retried on the
  /// next call rather than permanently disabling ducking for this object.
  Future<void> _configure() async {
    if (_configured) return;

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

    _configured = true;
  }

  @override
  Future<void> speak(
    String text, {
    SpeechPriority priority = SpeechPriority.encouragement,
  }) async {
    // Identifies this call's turn at holding `_currentPriority`. Only
    // assigned once this call has actually taken over speech, so a
    // pre-empted call's `finally` below can tell whether a newer call has
    // since taken over before clearing the field.
    int? generation;
    try {
      await _configure();

      // A higher-priority cue cuts off whatever is playing; an equal or lower
      // one waits its turn by being dropped, so cues never pile up.
      final current = _currentPriority;
      if (current != null) {
        if (priority.index <= current.index) return;
        await _tts.stop();
      }

      generation = ++_speechGeneration;
      _currentPriority = priority;
      // `focus: true` requests transient, duckable audio focus on Android
      // (AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK); it is ignored on other
      // platforms, where ducking is instead governed by
      // setIosAudioCategory above.
      await _tts.speak(text, focus: true);
    } catch (e) {
      developer.log('Trainer speech failed', name: 'trainer', error: e);
    } finally {
      // Only clear if no later call has already taken over — otherwise a
      // cue cancelled by a higher-priority interruption would clobber the
      // interrupting cue's still-in-flight priority once its own cancelled
      // await resolves.
      if (generation != null && generation == _speechGeneration) {
        _currentPriority = null;
      }
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
