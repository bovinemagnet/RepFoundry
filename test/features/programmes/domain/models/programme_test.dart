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
