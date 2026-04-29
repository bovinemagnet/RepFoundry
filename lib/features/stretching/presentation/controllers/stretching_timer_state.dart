import '../../domain/models/stretching_session.dart';

/// State for the in-progress add/edit stretching flow. The active workout
/// owner sets [workoutId] before saving.
class StretchingTimerState {
  final String? workoutId;
  final String? selectedType;
  final String? customName;
  final StretchingBodyArea? bodyArea;
  final StretchingSide? side;
  final String notes;

  /// Elapsed time accumulated by the timer (manual entries write directly to
  /// [manualSeconds] instead).
  final int elapsedSeconds;

  /// Manually-entered duration in seconds. When > 0 it takes precedence over
  /// [elapsedSeconds] on save.
  final int manualSeconds;

  final bool isRunning;
  final bool isSaving;
  final bool savedSuccessfully;
  final String? error;

  /// Wall-clock start of the timer. Set when [start] is first called.
  final DateTime? startedAt;

  const StretchingTimerState({
    this.workoutId,
    this.selectedType,
    this.customName,
    this.bodyArea,
    this.side,
    this.notes = '',
    this.elapsedSeconds = 0,
    this.manualSeconds = 0,
    this.isRunning = false,
    this.isSaving = false,
    this.savedSuccessfully = false,
    this.error,
    this.startedAt,
  });

  bool get hasDuration => effectiveDurationSeconds > 0;

  int get effectiveDurationSeconds =>
      manualSeconds > 0 ? manualSeconds : elapsedSeconds;

  StretchingTimerState copyWith({
    String? workoutId,
    bool clearWorkoutId = false,
    String? selectedType,
    bool clearSelectedType = false,
    String? customName,
    bool clearCustomName = false,
    StretchingBodyArea? bodyArea,
    bool clearBodyArea = false,
    StretchingSide? side,
    bool clearSide = false,
    String? notes,
    int? elapsedSeconds,
    int? manualSeconds,
    bool? isRunning,
    bool? isSaving,
    bool? savedSuccessfully,
    String? error,
    bool clearError = false,
    DateTime? startedAt,
    bool clearStartedAt = false,
  }) {
    return StretchingTimerState(
      workoutId: clearWorkoutId ? null : (workoutId ?? this.workoutId),
      selectedType:
          clearSelectedType ? null : (selectedType ?? this.selectedType),
      customName: clearCustomName ? null : (customName ?? this.customName),
      bodyArea: clearBodyArea ? null : (bodyArea ?? this.bodyArea),
      side: clearSide ? null : (side ?? this.side),
      notes: notes ?? this.notes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      manualSeconds: manualSeconds ?? this.manualSeconds,
      isRunning: isRunning ?? this.isRunning,
      isSaving: isSaving ?? this.isSaving,
      savedSuccessfully: savedSuccessfully ?? this.savedSuccessfully,
      error: clearError ? null : (error ?? this.error),
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
    );
  }
}
