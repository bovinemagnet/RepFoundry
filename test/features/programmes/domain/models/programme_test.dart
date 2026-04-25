import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';

void main() {
  group('Programme', () {
    test('create generates id and UTC dates', () {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      expect(p.id, isNotEmpty);
      expect(p.name, 'PPL');
      expect(p.durationWeeks, 4);
      expect(p.createdAt.isUtc, isTrue);
    });

    test('copyWith updates name', () {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      final updated = p.copyWith(name: '5/3/1');
      expect(updated.name, '5/3/1');
      expect(updated.id, p.id);
    });

    test('currentWeek is 1 when not started', () {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      expect(p.isStarted, isFalse);
      expect(p.currentWeek(), 1);
    });

    test('currentWeek advances by 1 every 7 days from startedAt', () {
      final start = DateTime.utc(2026, 1, 5); // Monday
      final p = Programme.create(name: 'PPL', durationWeeks: 4)
          .copyWith(startedAt: start);

      // Day 0 → week 1.
      expect(p.currentWeek(now: start), 1);
      // Day 6 → still week 1.
      expect(p.currentWeek(now: start.add(const Duration(days: 6))), 1);
      // Day 7 → week 2.
      expect(p.currentWeek(now: start.add(const Duration(days: 7))), 2);
      // Day 21 → week 4.
      expect(p.currentWeek(now: start.add(const Duration(days: 21))), 4);
    });

    test('currentWeek is clamped to durationWeeks beyond programme end', () {
      final start = DateTime.utc(2026, 1, 5);
      final p = Programme.create(name: 'PPL', durationWeeks: 4)
          .copyWith(startedAt: start);
      // Day 100 — long past end of 4-week programme.
      expect(p.currentWeek(now: start.add(const Duration(days: 100))), 4);
    });

    test('clearStartedAt resets the started timestamp', () {
      final p = Programme.create(name: 'PPL', durationWeeks: 4)
          .copyWith(startedAt: DateTime.utc(2026, 1, 5));
      expect(p.isStarted, isTrue);
      final reset = p.copyWith(clearStartedAt: true);
      expect(reset.isStarted, isFalse);
    });
  });

  group('ProgrammeDay', () {
    test('create generates id', () {
      final d = ProgrammeDay.create(
        programmeId: 'p1',
        weekNumber: 1,
        dayOfWeek: 1,
        templateId: 't1',
        templateName: 'Push Day',
      );
      expect(d.id, isNotEmpty);
      expect(d.weekNumber, 1);
      expect(d.dayOfWeek, 1);
    });
  });

  group('ProgressionRule', () {
    test('create generates id', () {
      final r = ProgressionRule.create(
        programmeId: 'p1',
        exerciseId: 'e1',
        type: ProgressionType.fixedIncrement,
        value: 2.5,
      );
      expect(r.id, isNotEmpty);
      expect(r.type, ProgressionType.fixedIncrement);
      expect(r.value, 2.5);
    });

    test('applyProgression with fixedIncrement adds value', () {
      final r = ProgressionRule.create(
        programmeId: 'p1',
        exerciseId: 'e1',
        type: ProgressionType.fixedIncrement,
        value: 2.5,
      );
      expect(r.applyProgression(100.0), 102.5);
    });

    test('applyProgression with percentage scales value', () {
      final r = ProgressionRule.create(
        programmeId: 'p1',
        exerciseId: 'e1',
        type: ProgressionType.percentage,
        value: 5.0,
      );
      expect(r.applyProgression(100.0), 105.0);
    });

    test('applyProgression with deload reduces value', () {
      final r = ProgressionRule.create(
        programmeId: 'p1',
        exerciseId: 'e1',
        type: ProgressionType.deload,
        value: 10.0,
      );
      expect(r.applyProgression(100.0), 90.0);
    });
  });
}
