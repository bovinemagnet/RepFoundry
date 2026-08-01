import 'coaching_cue.dart';

/// Speaks coaching cues aloud.
///
/// Every implementation is best-effort: failures are swallowed so a missing or
/// broken speech engine can never interrupt a workout.
abstract class SpeechService {
  Future<void> speak(
    String text, {
    SpeechPriority priority = SpeechPriority.encouragement,
  });

  /// Stops any in-flight speech immediately.
  Future<void> stop();

  /// False when the device has no usable speech engine, which happens on some
  /// de-Googled Android builds.
  Future<bool> isAvailable();

  void dispose();
}
