import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/stretching/application/save_stretching_session_use_case.dart';
import 'package:rep_foundry/features/stretching/data/in_memory_stretching_session_repository.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';
import 'package:rep_foundry/features/stretching/presentation/controllers/stretching_timer_controller.dart';

void main() {
  late InMemoryStretchingSessionRepository repo;
  late SaveStretchingSessionUseCase useCase;
  late ProviderContainer container;
  late StretchingTimerController controller;

  setUp(() {
    repo = InMemoryStretchingSessionRepository();
    useCase = SaveStretchingSessionUseCase(repository: repo);
    container = ProviderContainer(
      overrides: [
        stretchingSessionRepositoryProvider.overrideWithValue(repo),
        saveStretchingSessionUseCaseProvider.overrideWithValue(useCase),
      ],
    );
    controller = container.read(stretchingTimerProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('StretchingTimerController', () {
    test('initial state is empty', () {
      expect(controller.state.isRunning, isFalse);
      expect(controller.state.elapsedSeconds, 0);
      expect(controller.state.manualSeconds, 0);
      expect(controller.state.selectedType, isNull);
      expect(controller.state.workoutId, isNull);
    });

    test('selectType updates selectedType and bodyArea', () {
      controller.selectType(
        type: 'pigeon',
        bodyArea: StretchingBodyArea.hips,
      );
      expect(controller.state.selectedType, 'pigeon');
      expect(controller.state.bodyArea, StretchingBodyArea.hips);
    });

    test('start sets isRunning and seeds startedAt', () {
      controller.start();
      expect(controller.state.isRunning, isTrue);
      expect(controller.state.startedAt, isNotNull);
    });

    test('pause stops the timer', () {
      controller.start();
      controller.pause();
      expect(controller.state.isRunning, isFalse);
    });

    test('discard clears all state', () {
      controller.setWorkoutId('w1');
      controller.selectType(type: 'pigeon');
      controller.start();
      controller.discard();
      expect(controller.state.selectedType, isNull);
      expect(controller.state.workoutId, isNull);
      expect(controller.state.elapsedSeconds, 0);
    });

    test('setManualDuration with zero clears the manual entry', () {
      controller.setManualDuration(60);
      expect(controller.state.manualSeconds, 60);
      expect(controller.state.effectiveDurationSeconds, 60);

      controller.setManualDuration(0);
      expect(controller.state.manualSeconds, 0);
    });

    test('setManualDuration ignores negative values', () {
      controller.setManualDuration(-5);
      expect(controller.state.manualSeconds, 0);
    });

    test('save without workoutId returns false and sets error', () async {
      controller.selectType(type: 'pigeon');
      controller.setManualDuration(60);
      final ok = await controller.save();
      expect(ok, isFalse);
      expect(controller.state.error, isNotNull);
    });

    test('save without selected type returns false', () async {
      controller.setWorkoutId('w1');
      controller.setManualDuration(60);
      final ok = await controller.save();
      expect(ok, isFalse);
      expect(controller.state.error, isNotNull);
    });

    test('save without duration returns false', () async {
      controller.setWorkoutId('w1');
      controller.selectType(type: 'pigeon');
      final ok = await controller.save();
      expect(ok, isFalse);
    });

    test('save persists a manual entry and resets state', () async {
      controller.setWorkoutId('w1');
      controller.selectType(
        type: 'pigeon',
        bodyArea: StretchingBodyArea.hips,
      );
      controller.setManualDuration(120);
      controller.setNotes('Post-leg-day');

      final ok = await controller.save();
      expect(ok, isTrue);
      expect(controller.state.savedSuccessfully, isTrue);

      final stored = await repo.getSessionsForWorkout('w1');
      expect(stored, hasLength(1));
      expect(stored.first.entryMethod, StretchingEntryMethod.manual);
      expect(stored.first.durationSeconds, 120);
      expect(stored.first.notes, 'Post-leg-day');

      // After save, workoutId is preserved so the user can add another.
      expect(controller.state.workoutId, 'w1');
      expect(controller.state.selectedType, isNull);
    });

    test('save persists a timer entry with timer entryMethod', () async {
      controller.setWorkoutId('w1');
      controller.selectType(type: 'frontSplits');
      controller.start();
      // Simulate elapsed time
      controller.pause();
      // Force elapsedSeconds via manual API: emulate 5 seconds of timer.
      // Reach into private state by going through a tick: use start() loop
      // would be flaky, so we set directly via the public surface — use
      // setManualDuration as fallback if elapsedSeconds is 0.
      // Easier: re-start, wait a tick, pause.
      controller.start();
      await Future.delayed(const Duration(milliseconds: 1100));
      controller.pause();
      expect(controller.state.elapsedSeconds, greaterThanOrEqualTo(1));

      final ok = await controller.save();
      expect(ok, isTrue);

      final stored = await repo.getSessionsForWorkout('w1');
      expect(stored, hasLength(1));
      expect(stored.first.entryMethod, StretchingEntryMethod.timer);
      expect(stored.first.startedAt, isNotNull);
      expect(stored.first.endedAt, isNotNull);
    });
  });
}
