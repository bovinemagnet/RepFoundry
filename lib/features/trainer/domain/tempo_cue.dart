/// What the coach says at one moment of a counted set (#83).
enum TempoCueKind {
  /// A rep marker: the count so far, or the reps still to go.
  count,

  /// A cluster pause starts; the value is its length in seconds.
  rest,

  /// The pause is over; carry on.
  resume,

  /// The target is reached; the value is the reps done.
  done,
}

typedef TempoCue = ({Duration at, TempoCueKind kind, int value});
