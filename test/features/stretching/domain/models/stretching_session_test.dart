import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';

void main() {
  group('StretchingSession.create', () {
    test('generates a UUID and UTC updatedAt', () {
      final session = StretchingSession.create(
        workoutId: 'w1',
        type: 'pigeon',
        durationSeconds: 60,
        entryMethod: StretchingEntryMethod.manual,
      );

      expect(session.id, isNotEmpty);
      expect(session.id.length, 36);
      expect(session.updatedAt.isUtc, isTrue);
      expect(session.workoutId, 'w1');
      expect(session.type, 'pigeon');
      expect(session.durationSeconds, 60);
      expect(session.entryMethod, StretchingEntryMethod.manual);
      expect(session.deletedAt, isNull);
    });
  });

  group('StretchingSession.duration', () {
    test('returns a Duration matching durationSeconds', () {
      final session = StretchingSession.create(
        workoutId: 'w1',
        type: 'pigeon',
        durationSeconds: 125,
        entryMethod: StretchingEntryMethod.manual,
      );

      expect(session.duration, const Duration(seconds: 125));
    });
  });

  group('StretchingSession.displayName', () {
    test('returns preset English name for known types', () {
      final session = StretchingSession.create(
        workoutId: 'w1',
        type: 'pigeon',
        durationSeconds: 30,
        entryMethod: StretchingEntryMethod.manual,
      );
      expect(session.displayName(), 'Pigeon Pose');
    });

    test('returns customName when type is custom', () {
      final session = StretchingSession.create(
        workoutId: 'w1',
        type: StretchingSession.customStretchType,
        customName: 'My Special Stretch',
        durationSeconds: 30,
        entryMethod: StretchingEntryMethod.manual,
      );
      expect(session.displayName(), 'My Special Stretch');
    });

    test('falls back to type when custom and customName missing', () {
      final session = StretchingSession.create(
        workoutId: 'w1',
        type: StretchingSession.customStretchType,
        durationSeconds: 30,
        entryMethod: StretchingEntryMethod.manual,
      );
      expect(session.displayName(), 'custom');
    });

    test('uses localiser when provided for known types', () {
      final session = StretchingSession.create(
        workoutId: 'w1',
        type: 'pigeon',
        durationSeconds: 30,
        entryMethod: StretchingEntryMethod.manual,
      );
      expect(
        session.displayName(localiseKey: (k) => 'localised:$k'),
        'localised:pigeon',
      );
    });
  });

  group('StretchingSession.copyWith', () {
    test('updates duration without losing id', () {
      final original = StretchingSession.create(
        workoutId: 'w1',
        type: 'pigeon',
        durationSeconds: 60,
        entryMethod: StretchingEntryMethod.manual,
      );
      final updated = original.copyWith(durationSeconds: 120);

      expect(updated.id, original.id);
      expect(updated.durationSeconds, 120);
    });

    test('clearNotes nulls notes', () {
      final original = StretchingSession.create(
        workoutId: 'w1',
        type: 'pigeon',
        durationSeconds: 60,
        entryMethod: StretchingEntryMethod.manual,
        notes: 'something',
      );
      final updated = original.copyWith(clearNotes: true);
      expect(updated.notes, isNull);
    });
  });

  group('defaultStretches', () {
    test('contains 20 presets including front and side splits', () {
      expect(defaultStretches, hasLength(20));
      expect(defaultStretches.map((p) => p.key), contains('frontSplits'));
      expect(defaultStretches.map((p) => p.key), contains('sideSplits'));
    });

    test('all keys are unique', () {
      final keys = defaultStretches.map((p) => p.key).toSet();
      expect(keys, hasLength(defaultStretches.length));
    });

    test('front splits is mapped to hamstrings body area', () {
      final preset = defaultStretches.firstWhere((p) => p.key == 'frontSplits');
      expect(preset.bodyArea, StretchingBodyArea.hamstrings);
    });

    test('side splits is mapped to adductors body area', () {
      final preset = defaultStretches.firstWhere((p) => p.key == 'sideSplits');
      expect(preset.bodyArea, StretchingBodyArea.adductors);
    });
  });
}
