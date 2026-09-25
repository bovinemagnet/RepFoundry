import 'dart:async';

import '../domain/tempo_cue.dart';

/// Plays a [tempoPlan] timeline in real time: [onCue] fires at each cue's
/// moment, and [onFinished] once with the reps done when the set completes.
class TempoRunner {
  TempoRunner({
    required List<TempoCue> plan,
    required this.onCue,
    required this.onFinished,
  }) : _plan = plan;

  final List<TempoCue> _plan;
  final void Function(TempoCue cue) onCue;
  final void Function(int repsDone) onFinished;

  final List<Timer> _timers = [];
  int _repsDone = 0;
  bool _running = false;

  bool get isRunning => _running;

  void start() {
    _running = true;
    for (final cue in _plan) {
      _timers.add(Timer(cue.at, () => _fire(cue)));
    }
  }

  void _fire(TempoCue cue) {
    // Every cue but a resume marks a rep just completed.
    if (cue.kind != TempoCueKind.resume) _repsDone++;
    onCue(cue);
    if (cue.kind == TempoCueKind.done) {
      _running = false;
      onFinished(_repsDone);
    }
  }

  /// Cancels what is left and returns the reps completed so far.
  int stop() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    _running = false;
    return _repsDone;
  }
}
