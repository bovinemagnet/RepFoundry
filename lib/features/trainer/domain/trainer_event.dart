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
  hrZoneChanged,
  hrAboveCap,
  hrBackBelowCap,
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

/// A rest period ended.
///
/// [restDuration] is what the timer was set to run for, carried so the engine
/// can apply the "quote after rests of two minutes or longer" rule (spec §5)
/// without keeping its own memory of the matching [RestStarted] — which would
/// be wrong whenever a rest began before the coach was switched on.
///
/// Optional, and `null` means "not known", which is treated as a short rest.
/// A caller that cannot supply it therefore fails towards silence rather than
/// towards an unwanted quote.
class RestFinished extends TrainerEvent {
  const RestFinished({this.restDuration});

  final Duration? restDuration;

  @override
  TrainerEventKind get kind => TrainerEventKind.restFinished;
}

class WorkoutFinished extends TrainerEvent {
  const WorkoutFinished({required this.totalSets});

  final int totalSets;

  @override
  TrainerEventKind get kind => TrainerEventKind.workoutFinished;
}

/// The user has settled into a different training zone.
///
/// [descriptiveLabel] (e.g. "Aerobic") is carried for parity with
/// [CalculatedZone] and potential future display/persona use, but the
/// steady persona's spoken cue deliberately does not use it — see
/// `phrase_resolver.dart`'s `coachSteadyZone` entry. [effortLabel] (e.g.
/// "Moderate") already conveys the zone's intensity in a form that reads
/// naturally out loud; adding the descriptive label on top would lengthen
/// the cue without giving the user anything actionable, and the same
/// information is already visible in the zone legend UI.
class HeartRateZoneChanged extends TrainerEvent {
  const HeartRateZoneChanged({
    required this.zoneNumber,
    required this.effortLabel,
    required this.descriptiveLabel,
  });

  final int zoneNumber;
  final String effortLabel;
  final String descriptiveLabel;

  @override
  TrainerEventKind get kind => TrainerEventKind.hrZoneChanged;
}

/// The heart rate has crossed the user's safe maximum. Re-emitted while it
/// stays there so the coach can repeat its warning.
class HeartRateAboveCap extends TrainerEvent {
  const HeartRateAboveCap({required this.bpm, required this.cap});

  final int bpm;
  final int cap;

  @override
  TrainerEventKind get kind => TrainerEventKind.hrAboveCap;
}

class HeartRateBackBelowCap extends TrainerEvent {
  const HeartRateBackBelowCap();

  @override
  TrainerEventKind get kind => TrainerEventKind.hrBackBelowCap;
}
