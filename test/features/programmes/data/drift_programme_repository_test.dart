import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart'
    hide Programme, ProgrammeDay, ProgressionRule;
import 'package:rep_foundry/features/programmes/data/drift_programme_repository.dart';
import 'package:rep_foundry/features/programmes/domain/models/programme.dart';

void main() {
  late AppDatabase db;
  late DriftProgrammeRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftProgrammeRepository(db);
  });

  tearDown(() => db.close());

  group('DriftProgrammeRepository', () {
    test('create and get programme', () async {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      await repo.createProgramme(p);

      final fetched = await repo.getProgramme(p.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'PPL');
      expect(fetched.durationWeeks, 4);
    });

    test('getAllProgrammes returns created programmes', () async {
      await repo.createProgramme(
        Programme.create(name: 'A', durationWeeks: 4),
      );
      await repo.createProgramme(
        Programme.create(name: 'B', durationWeeks: 8),
      );

      final all = await repo.getAllProgrammes();
      expect(all, hasLength(2));
    });

    test('deleteProgramme removes programme and children', () async {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      await repo.createProgramme(p);
      await repo.addDay(ProgrammeDay.create(
        programmeId: p.id,
        weekNumber: 1,
        dayOfWeek: 1,
        templateId: 't1',
        templateName: 'Push',
      ));
      await repo.addRule(ProgressionRule.create(
        programmeId: p.id,
        exerciseId: 'e1',
        type: ProgressionType.fixedIncrement,
        value: 2.5,
      ));

      await repo.deleteProgramme(p.id);
      final fetched = await repo.getProgramme(p.id);
      expect(fetched, isNull);

      final days = await repo.getDaysForProgramme(p.id);
      expect(days, isEmpty);

      final rules = await repo.getRulesForProgramme(p.id);
      expect(rules, isEmpty);
    });

    test('addDay and getDaysForProgramme', () async {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      await repo.createProgramme(p);

      final day = ProgrammeDay.create(
        programmeId: p.id,
        weekNumber: 1,
        dayOfWeek: DateTime.monday,
        templateId: 't1',
        templateName: 'Push',
      );
      await repo.addDay(day);

      final days = await repo.getDaysForProgramme(p.id);
      expect(days, hasLength(1));
      expect(days.first.templateName, 'Push');
    });

    test('addRule and getRulesForProgramme', () async {
      final p = Programme.create(name: 'PPL', durationWeeks: 4);
      await repo.createProgramme(p);

      final rule = ProgressionRule.create(
        programmeId: p.id,
        exerciseId: 'e1',
        type: ProgressionType.percentage,
        value: 5.0,
      );
      await repo.addRule(rule);

      final rules = await repo.getRulesForProgramme(p.id);
      expect(rules, hasLength(1));
      expect(rules.first.type, ProgressionType.percentage);
    });
  });
}
