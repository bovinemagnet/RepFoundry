import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/stretching/application/save_stretching_session_use_case.dart';
import 'package:rep_foundry/features/stretching/data/in_memory_stretching_session_repository.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';

void main() {
  late InMemoryStretchingSessionRepository repo;
  late SaveStretchingSessionUseCase useCase;

  setUp(() {
    repo = InMemoryStretchingSessionRepository();
    useCase = SaveStretchingSessionUseCase(repository: repo);
  });

  group('SaveStretchingSessionUseCase validation', () {
    test('throws when workoutId is empty', () {
      expect(
        () => useCase.execute(
          const SaveStretchingSessionInput(
            workoutId: '',
            type: 'pigeon',
            durationSeconds: 30,
            entryMethod: StretchingEntryMethod.manual,
          ),
        ),
        throwsA(isA<SaveStretchingSessionException>()),
      );
    });

    test('throws when type is empty', () {
      expect(
        () => useCase.execute(
          const SaveStretchingSessionInput(
            workoutId: 'w1',
            type: '',
            durationSeconds: 30,
            entryMethod: StretchingEntryMethod.manual,
          ),
        ),
        throwsA(isA<SaveStretchingSessionException>()),
      );
    });

    test('throws when duration is zero', () {
      expect(
        () => useCase.execute(
          const SaveStretchingSessionInput(
            workoutId: 'w1',
            type: 'pigeon',
            durationSeconds: 0,
            entryMethod: StretchingEntryMethod.manual,
          ),
        ),
        throwsA(isA<SaveStretchingSessionException>()),
      );
    });

    test('throws when duration exceeds 12 hours', () {
      expect(
        () => useCase.execute(
          const SaveStretchingSessionInput(
            workoutId: 'w1',
            type: 'pigeon',
            durationSeconds: 12 * 60 * 60 + 1,
            entryMethod: StretchingEntryMethod.manual,
          ),
        ),
        throwsA(isA<SaveStretchingSessionException>()),
      );
    });

    test('throws when type is custom but customName is missing', () {
      expect(
        () => useCase.execute(
          const SaveStretchingSessionInput(
            workoutId: 'w1',
            type: 'custom',
            durationSeconds: 30,
            entryMethod: StretchingEntryMethod.manual,
          ),
        ),
        throwsA(isA<SaveStretchingSessionException>()),
      );
    });

    test('throws when customName is too long', () {
      expect(
        () => useCase.execute(
          SaveStretchingSessionInput(
            workoutId: 'w1',
            type: 'custom',
            customName: 'x' * 61,
            durationSeconds: 30,
            entryMethod: StretchingEntryMethod.manual,
          ),
        ),
        throwsA(isA<SaveStretchingSessionException>()),
      );
    });
  });

  group('SaveStretchingSessionUseCase untimed', () {
    test('accepts zero duration when entryMethod is untimed', () async {
      final session = await useCase.execute(
        const SaveStretchingSessionInput(
          workoutId: 'w1',
          type: 'pigeon',
          durationSeconds: 0,
          entryMethod: StretchingEntryMethod.untimed,
        ),
      );
      expect(session.entryMethod, StretchingEntryMethod.untimed);
      expect(session.durationSeconds, 0);
    });

    test('rejects non-zero duration on untimed entries', () {
      expect(
        () => useCase.execute(
          const SaveStretchingSessionInput(
            workoutId: 'w1',
            type: 'pigeon',
            durationSeconds: 60,
            entryMethod: StretchingEntryMethod.untimed,
          ),
        ),
        throwsA(isA<SaveStretchingSessionException>()),
      );
    });

    test('still rejects zero duration on manual entries', () {
      expect(
        () => useCase.execute(
          const SaveStretchingSessionInput(
            workoutId: 'w1',
            type: 'pigeon',
            durationSeconds: 0,
            entryMethod: StretchingEntryMethod.manual,
          ),
        ),
        throwsA(isA<SaveStretchingSessionException>()),
      );
    });
  });

  group('SaveStretchingSessionUseCase persists', () {
    test('saves a manual session', () async {
      final session = await useCase.execute(
        const SaveStretchingSessionInput(
          workoutId: 'w1',
          type: 'pigeon',
          durationSeconds: 60,
          entryMethod: StretchingEntryMethod.manual,
          notes: '   ', // whitespace-only -> nulled
        ),
      );

      expect(session.workoutId, 'w1');
      expect(session.notes, isNull);
      final stored = await repo.getSessionsForWorkout('w1');
      expect(stored, hasLength(1));
      expect(stored.first.id, session.id);
    });

    test('trims customName and stores it for custom stretches', () async {
      final session = await useCase.execute(
        const SaveStretchingSessionInput(
          workoutId: 'w1',
          type: 'custom',
          customName: '  Wall stretch  ',
          durationSeconds: 30,
          entryMethod: StretchingEntryMethod.manual,
        ),
      );
      expect(session.type, StretchingSession.customStretchType);
      expect(session.customName, 'Wall stretch');
    });

    test('drops customName when type is a preset', () async {
      final session = await useCase.execute(
        const SaveStretchingSessionInput(
          workoutId: 'w1',
          type: 'pigeon',
          customName: 'Should be ignored',
          durationSeconds: 30,
          entryMethod: StretchingEntryMethod.manual,
        ),
      );
      expect(session.customName, isNull);
    });

    test('preserves startedAt/endedAt for timer entries', () async {
      final start = DateTime.utc(2026, 4, 30, 10);
      final end = DateTime.utc(2026, 4, 30, 10, 5);
      final session = await useCase.execute(
        SaveStretchingSessionInput(
          workoutId: 'w1',
          type: 'pigeon',
          durationSeconds: 300,
          entryMethod: StretchingEntryMethod.timer,
          startedAt: start,
          endedAt: end,
        ),
      );
      expect(session.startedAt, start);
      expect(session.endedAt, end);
    });
  });
}
