import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../application/save_stretching_session_use_case.dart';
import '../../domain/models/stretching_session.dart';
import 'stretching_timer_state.dart';

/// Coordinates the in-progress add-stretching flow: stretch selection,
/// timer, manual entry, save/discard. Non-autoDispose because the user can
/// minimise the bottom sheet (or switch tabs) while the timer runs.
class StretchingTimerController extends Notifier<StretchingTimerState> {
  Timer? _timer;

  SaveStretchingSessionUseCase get _saveUseCase =>
      ref.read(saveStretchingSessionUseCaseProvider);

  @override
  StretchingTimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return const StretchingTimerState();
  }

  void setWorkoutId(String workoutId) {
    state = state.copyWith(workoutId: workoutId);
  }

  void selectType({
    required String type,
    String? customName,
    StretchingBodyArea? bodyArea,
  }) {
    state = state.copyWith(
      selectedType: type,
      customName: customName,
      bodyArea: bodyArea,
      clearError: true,
    );
  }

  void setCustomName(String name) {
    state = state.copyWith(customName: name);
  }

  void setBodyArea(StretchingBodyArea? area) {
    if (area == null) {
      state = state.copyWith(clearBodyArea: true);
    } else {
      state = state.copyWith(bodyArea: area);
    }
  }

  void setSide(StretchingSide? side) {
    if (side == null) {
      state = state.copyWith(clearSide: true);
    } else {
      state = state.copyWith(side: side);
    }
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setManualDuration(int seconds) {
    state = state.copyWith(manualSeconds: seconds < 0 ? 0 : seconds);
  }

  void start() {
    if (state.isRunning) return;
    final isFreshSession = state.elapsedSeconds == 0;
    state = state.copyWith(
      isRunning: true,
      savedSuccessfully: false,
      clearError: true,
      startedAt: isFreshSession ? DateTime.now().toUtc() : state.startedAt,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false);
  }

  /// Reset elapsed time without clearing the selected stretch.
  void reset() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      elapsedSeconds: 0,
      manualSeconds: 0,
      isRunning: false,
      clearStartedAt: true,
    );
  }

  /// Discard the in-progress entry entirely.
  void discard() {
    _timer?.cancel();
    _timer = null;
    state = const StretchingTimerState();
  }

  Future<bool> save() async {
    final type = state.selectedType;
    final workoutId = state.workoutId;
    final duration = state.effectiveDurationSeconds;

    if (workoutId == null || workoutId.isEmpty) {
      state = state.copyWith(error: 'No active workout');
      return false;
    }
    if (type == null || type.isEmpty) {
      state = state.copyWith(error: 'Pick a stretch type first');
      return false;
    }
    if (duration <= 0) {
      state = state.copyWith(error: 'Duration must be greater than zero');
      return false;
    }

    _timer?.cancel();
    _timer = null;

    state = state.copyWith(isSaving: true, isRunning: false, clearError: true);
    try {
      final entryMethod = state.elapsedSeconds > 0
          ? StretchingEntryMethod.timer
          : StretchingEntryMethod.manual;
      await _saveUseCase.execute(
        SaveStretchingSessionInput(
          workoutId: workoutId,
          type: type,
          customName: state.customName,
          bodyArea: state.bodyArea,
          side: state.side,
          durationSeconds: duration,
          entryMethod: entryMethod,
          startedAt: entryMethod == StretchingEntryMethod.timer
              ? state.startedAt
              : null,
          endedAt: entryMethod == StretchingEntryMethod.timer
              ? DateTime.now().toUtc()
              : null,
          notes: state.notes,
        ),
      );
      state = StretchingTimerState(
        workoutId: workoutId,
        savedSuccessfully: true,
      );
      return true;
    } on SaveStretchingSessionException catch (e) {
      state = state.copyWith(isSaving: false, error: e.message);
      return false;
    }
  }

  void clearSavedFlag() {
    state = state.copyWith(savedSuccessfully: false);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

/// NON-autoDispose so the timer survives bottom-sheet dismiss / tab switches.
final stretchingTimerProvider =
    NotifierProvider<StretchingTimerController, StretchingTimerState>(
  StretchingTimerController.new,
);
