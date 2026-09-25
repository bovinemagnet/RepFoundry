import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/trainer/application/activity_detector.dart';

/// One reading per second, as a BLE strap delivers them. `true` means the
/// reading sat at or above the Zone 2 floor.
List<bool> _trace(List<(bool elevated, int seconds)> segments) => [
      for (final (elevated, seconds) in segments)
        for (var i = 0; i < seconds; i++) elevated,
    ];

void main() {
  final start = DateTime.utc(2026, 9, 25, 7);

  /// Feeds [trace] at 1 Hz and returns the seconds at which a nudge fired.
  List<int> nudgesFor(
    List<bool> trace, {
    ActivityDetector? detector,
    bool Function(int second)? sessionRunning,
  }) {
    final d = detector ?? ActivityDetector();
    final fired = <int>[];
    for (var i = 0; i < trace.length; i++) {
      final nudge = d.onReading(
        elevated: trace[i],
        at: start.add(Duration(seconds: i)),
        sessionRunning: sessionRunning?.call(i) ?? false,
      );
      if (nudge) fired.add(i);
    }
    return fired;
  }

  test('sustained effort for 90 seconds prompts once', () {
    expect(nudgesFor(_trace([(false, 30), (true, 150)])), [120]);
  });

  test('a brief spike does not prompt', () {
    // Climbing stairs: a minute up, then back to rest.
    expect(nudgesFor(_trace([(false, 30), (true, 60), (false, 60)])), isEmpty);
  });

  test('a dip below the floor restarts the count', () {
    // 80 s up, one reading down, 80 s up: never 90 s unbroken.
    expect(nudgesFor(_trace([(true, 80), (false, 1), (true, 80)])), isEmpty);
  });

  test('never repeats within the same episode', () {
    // Twenty minutes of effort with short breathers between sets.
    final trace = _trace([
      (true, 120),
      for (var i = 0; i < 10; i++) ...[(false, 30), (true, 90)],
    ]);

    expect(nudgesFor(trace), hasLength(1));
  });

  test('prompts again after a real rest ends the episode', () {
    final trace = _trace([(true, 100), (false, 130), (true, 100)]);

    expect(nudgesFor(trace), [90, 320]);
  });

  test('a rest shorter than the episode gap does not re-arm it', () {
    final trace = _trace([(true, 100), (false, 100), (true, 100)]);

    expect(nudgesFor(trace), [90]);
  });

  test('breathers broken up by effort do not add up to a rest', () {
    // 70 s + 70 s below the floor, split by 30 s of effort: never 120 s
    // unbroken, so the episode is still running.
    final trace = _trace([
      (true, 100),
      (false, 70),
      (true, 30),
      (false, 70),
      (true, 100),
    ]);

    expect(nudgesFor(trace), [90]);
  });

  test('never prompts while a workout or cardio session is running', () {
    expect(
      nudgesFor(_trace([(true, 300)]), sessionRunning: (_) => true),
      isEmpty,
    );
  });

  test('does not prompt straight after a session while still elevated', () {
    // Workout ends at 200 s; the heart rate is still up during cool-down.
    final trace = _trace([(true, 400)]);

    expect(nudgesFor(trace, sessionRunning: (s) => s < 200), isEmpty);
  });

  test('prompts again once rested after a session', () {
    final trace = _trace([(true, 200), (false, 130), (true, 100)]);

    expect(nudgesFor(trace, sessionRunning: (s) => s < 200), [420]);
  });

  test('signal loss restarts the count without ending the episode', () {
    final detector = ActivityDetector();
    var t = start;
    bool feed(bool elevated) {
      t = t.add(const Duration(seconds: 1));
      return detector.onReading(
          elevated: elevated, at: t, sessionRunning: false);
    }

    for (var i = 0; i < 80; i++) {
      expect(feed(true), isFalse);
    }
    detector.onSignalLoss();
    for (var i = 0; i < 80; i++) {
      expect(feed(true), isFalse, reason: 'count should have restarted');
    }
    for (var i = 0; i < 20; i++) {
      feed(true);
    }
    // Prompted once; a dropout mid-episode must not earn a second prompt.
    detector.onSignalLoss();
    final later = [for (var i = 0; i < 200; i++) feed(true)];
    expect(later, everyElement(isFalse));
  });

  test('the window is configurable', () {
    final detector = ActivityDetector(window: const Duration(seconds: 30));

    expect(nudgesFor(_trace([(true, 60)]), detector: detector), [30]);
  });
}
