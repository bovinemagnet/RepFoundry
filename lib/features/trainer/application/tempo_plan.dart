import '../domain/tempo_cue.dart';

export '../domain/tempo_cue.dart';

/// The timeline for counting [targetReps] at one rep every [perRep].
///
/// Each rep is marked as it completes — counting up (1, 2, 3…) or, with
/// [countDown], the reps still to go. With [clusterSize] above zero, every
/// [clusterSize]th rep is followed by a [clusterPause] instead of a count,
/// then a resume cue. The final rep always ends the set, never a pause.
List<TempoCue> tempoPlan({
  required int targetReps,
  required Duration perRep,
  bool countDown = false,
  int clusterSize = 0,
  Duration clusterPause = const Duration(seconds: 10),
}) {
  final cues = <TempoCue>[];
  var at = Duration.zero;
  for (var rep = 1; rep <= targetReps; rep++) {
    at += perRep;
    if (rep == targetReps) {
      cues.add((at: at, kind: TempoCueKind.done, value: targetReps));
    } else if (clusterSize > 0 && rep % clusterSize == 0) {
      cues.add(
          (at: at, kind: TempoCueKind.rest, value: clusterPause.inSeconds));
      at += clusterPause;
      cues.add((at: at, kind: TempoCueKind.resume, value: 0));
    } else {
      cues.add((
        at: at,
        kind: TempoCueKind.count,
        value: countDown ? targetReps - rep : rep,
      ));
    }
  }
  return cues;
}
