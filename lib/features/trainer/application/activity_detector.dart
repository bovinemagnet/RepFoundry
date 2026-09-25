/// Notices sustained effort with no workout or cardio session running, so the
/// coach can offer to join in (phase 3). Pure Dart: fed one heart-rate reading
/// at a time, already classified as elevated or not.
///
/// An *episode* is a stretch of activity that earns at most one prompt:
///
/// - It prompts once readings have stayed elevated for [window] without a
///   break. A single reading below the floor restarts the count, so a flight
///   of stairs or a brisk minute's walk never qualifies.
/// - Once prompted, it stays quiet until readings have stayed below the floor
///   for [episodeGap] — a real rest, not a breather between sets.
/// - A running session counts as an episode already under way, so finishing a
///   workout while still out of breath does not earn an invitation to start
///   another one.
/// - Signal loss restarts the count but never ends an episode: a strap that
///   drops out and reconnects mid-exercise must not prompt twice.
class ActivityDetector {
  ActivityDetector({
    this.window = const Duration(seconds: 90),
    this.episodeGap = const Duration(minutes: 2),
  });

  final Duration window;
  final Duration episodeGap;

  DateTime? _elevatedSince;
  DateTime? _restingSince;
  bool _prompted = false;

  /// Returns true exactly when this reading should prompt.
  bool onReading({
    required bool elevated,
    required DateTime at,
    required bool sessionRunning,
  }) {
    if (!elevated) {
      _elevatedSince = null;
      final since = _restingSince ??= at;
      if (at.difference(since) >= episodeGap) _prompted = false;
      return false;
    }

    _restingSince = null;
    if (sessionRunning) {
      _prompted = true;
      _elevatedSince = null;
      return false;
    }
    if (_prompted) return false;

    final since = _elevatedSince ??= at;
    if (at.difference(since) < window) return false;
    _prompted = true;
    _elevatedSince = null;
    return true;
  }

  void onSignalLoss() {
    _elevatedSince = null;
    _restingSince = null;
  }
}
