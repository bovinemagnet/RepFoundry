/// The categories of moment the coach can speak to.
///
/// A personal record is its own kind rather than a flag so personas can hold
/// a distinct phrase bank for it.
enum TrainerEventKind {
  workoutStarted,
  setLogged,
  personalRecord,
  restStarted,
  restCountdown,
  restFinished,
  workoutFinished,
  quote,
}

/// Something that happened in the workout that the coach may react to.
sealed class TrainerEvent {
  const TrainerEvent();

  TrainerEventKind get kind;
}

class WorkoutStarted extends TrainerEvent {
  const WorkoutStarted();

  @override
  TrainerEventKind get kind => TrainerEventKind.workoutStarted;
}

class SetLogged extends TrainerEvent {
  const SetLogged({required this.setNumber, required this.isPersonalRecord});

  final int setNumber;
  final bool isPersonalRecord;

  @override
  TrainerEventKind get kind => isPersonalRecord
      ? TrainerEventKind.personalRecord
      : TrainerEventKind.setLogged;
}

class RestStarted extends TrainerEvent {
  const RestStarted({required this.duration});

  final Duration duration;

  @override
  TrainerEventKind get kind => TrainerEventKind.restStarted;
}

class RestCountdown extends TrainerEvent {
  const RestCountdown({required this.secondsLeft});

  final int secondsLeft;

  @override
  TrainerEventKind get kind => TrainerEventKind.restCountdown;
}

class RestFinished extends TrainerEvent {
  const RestFinished();

  @override
  TrainerEventKind get kind => TrainerEventKind.restFinished;
}

class WorkoutFinished extends TrainerEvent {
  const WorkoutFinished({required this.totalSets});

  final int totalSets;

  @override
  TrainerEventKind get kind => TrainerEventKind.workoutFinished;
}
