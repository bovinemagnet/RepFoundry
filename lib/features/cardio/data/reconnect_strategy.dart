/// Retry schedule for re-establishing a dropped BLE connection.
///
/// Real-world dropouts (walking out of range, interference) routinely last
/// longer than a few seconds, so the default schedule backs off
/// exponentially and keeps trying for a little over four minutes.
/// Runs [operation]; on failure waits [delay] and retries exactly once.
///
/// Android's BLE stack routinely fails a first connect attempt with the
/// transient GATT error 133 right after a peripheral powers on — a single
/// spaced retry hides that from the user.
Future<T> retryOnceOnFailure<T>(
  Future<T> Function() operation, {
  Duration delay = const Duration(seconds: 1),
}) async {
  try {
    return await operation();
  } catch (_) {
    await Future<void>.delayed(delay);
    return operation();
  }
}

class ReconnectStrategy {
  final List<Duration> delays;

  const ReconnectStrategy({this.delays = defaultDelays});

  static const List<Duration> defaultDelays = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 32),
    Duration(seconds: 60),
    Duration(seconds: 60),
    Duration(seconds: 60),
  ];

  /// Waits each delay in turn, then runs [attempt]. Returns true as soon as
  /// an attempt completes without throwing; false when the schedule is
  /// exhausted or [isCancelled] reports true.
  Future<bool> run({
    required Future<void> Function() attempt,
    required bool Function() isCancelled,
  }) async {
    for (final delay in delays) {
      if (isCancelled()) return false;
      await Future<void>.delayed(delay);
      if (isCancelled()) return false;
      try {
        await attempt();
        return true;
      } catch (_) {
        // Fall through to the next delay.
      }
    }
    return false;
  }
}
