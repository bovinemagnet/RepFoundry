import 'package:rep_foundry/features/trainer/domain/coaching_cue.dart';
import 'package:rep_foundry/features/trainer/domain/speech_service.dart';

/// Records what would have been spoken so tests never touch platform audio.
class SilentSpeechService implements SpeechService {
  final List<String> spoken = [];
  int stopCount = 0;
  bool available = true;
  bool disposed = false;

  @override
  Future<void> speak(
    String text, {
    SpeechPriority priority = SpeechPriority.encouragement,
  }) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<bool> isAvailable() async => available;

  @override
  void dispose() {
    disposed = true;
  }
}
