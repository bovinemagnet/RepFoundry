import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';

void main() {
  group('CardioSession', () {
    group('create()', () {
      test('generates a UUID and sets all fields', () {
        final session = CardioSession.create(
          workoutId: 'w1',
          exerciseId: 'e1',
          durationSeconds: 1800,
          distanceMeters: 5000,
          incline: 2.5,
          avgHeartRate: 145,
        );

        expect(session.id, isNotEmpty);
        expect(session.workoutId, 'w1');
        expect(session.exerciseId, 'e1');
        expect(session.durationSeconds, 1800);
        expect(session.distanceMeters, 5000);
        expect(session.incline, 2.5);
        expect(session.avgHeartRate, 145);
      });

      test('generates unique IDs', () {
        final a = CardioSession.create(
          workoutId: 'w1',
          exerciseId: 'e1',
          durationSeconds: 600,
        );
        final b = CardioSession.create(
          workoutId: 'w1',
          exerciseId: 'e1',
          durationSeconds: 600,
        );
        expect(a.id, isNot(b.id));
      });
    });

    group('paceMinutesPerKm', () {
      test('returns null when distanceMeters is null', () {
        const session = CardioSession(
          id: '1',
          workoutId: 'w1',
          exerciseId: 'e1',
          durationSeconds: 1800,
        );
        expect(session.paceMinutesPerKm, isNull);
      });

      test('returns null when distanceMeters is zero', () {
        const session = CardioSession(
          id: '1',
          workoutId: 'w1',
          exerciseId: 'e1',
          durationSeconds: 1800,
          distanceMeters: 0,
        );
        expect(session.paceMinutesPerKm, isNull);
      });

      test('returns null when distanceMeters is negative', () {
        const session = CardioSession(
          id: '1',
          workoutId: 'w1',
          exerciseId: 'e1',
          durationSeconds: 1800,
          distanceMeters: -100,
        );
        expect(session.paceMinutesPerKm, isNull);
      });

      test('calculates correctly (1800s / 5000m = 6.0 min/km)', () {
        const session = CardioSession(
          id: '1',
          workoutId: 'w1',
          exerciseId: 'e1',
          durationSeconds: 1800,
          distanceMeters: 5000,
        );
        expect(session.paceMinutesPerKm, 6.0);
      });
    });

    group('duration', () {
      test('returns correct Duration', () {
        const session = CardioSession(
          id: '1',
          workoutId: 'w1',
          exerciseId: 'e1',
          durationSeconds: 3661,
        );
        expect(session.duration, const Duration(seconds: 3661));
        expect(session.duration.inHours, 1);
        expect(session.duration.inMinutes, 61);
      });
    });

    group('equality', () {
      test('equal when IDs match', () {
        const a = CardioSession(
          id: 'same',
          workoutId: 'w1',
          exerciseId: 'e1',
          durationSeconds: 100,
        );
        const b = CardioSession(
          id: 'same',
          workoutId: 'w2',
          exerciseId: 'e2',
          durationSeconds: 200,
        );
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('not equal when IDs differ', () {
        const a = CardioSession(
          id: 'id1',
          workoutId: 'w1',
          exerciseId: 'e1',
          durationSeconds: 100,
        );
        const b = CardioSession(
          id: 'id2',
          workoutId: 'w1',
          exerciseId: 'e1',
          durationSeconds: 100,
        );
        expect(a, isNot(equals(b)));
      });
    });
  });
}
