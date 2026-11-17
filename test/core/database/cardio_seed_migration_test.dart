import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cardio_seed_migration');
    dbFile = File('${tempDir.path}/rep_foundry.sqlite');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  /// Creates a database file in the v14 shape: the current schema, minus
  /// the cardio exercises seeded by the v15 upgrade, stamped with
  /// `user_version = 14` so the next open genuinely runs `onUpgrade`.
  Future<void> createV14Database(
      {List<String> extraStatements = const []}) async {
    final database = db.AppDatabase.forTesting(NativeDatabase(dbFile));
    await database.customStatement(
      "DELETE FROM exercises WHERE id IN ('22', '23')",
    );
    for (final statement in extraStatements) {
      await database.customStatement(statement);
    }
    await database.customStatement('PRAGMA user_version = 14');
    await database.close();
  }

  Future<List<String>> exerciseNames(db.AppDatabase database) async {
    final rows = await database.select(database.exercises).get();
    return rows.map((r) => r.name).toList();
  }

  test('v14 -> v15 upgrade seeds Elliptical and Stair Climber', () async {
    await createV14Database();

    final database = db.AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(database.close);

    final rows = await database.select(database.exercises).get();
    final elliptical = rows.singleWhere((r) => r.id == '22');
    expect(elliptical.name, 'Elliptical');
    expect(elliptical.category, 'cardio');
    expect(elliptical.muscleGroup, 'cardio');
    final stairs = rows.singleWhere((r) => r.id == '23');
    expect(stairs.name, 'Stair Climber');
    expect(stairs.category, 'cardio');
    expect(stairs.muscleGroup, 'cardio');
  });

  test(
      'v14 -> v15 upgrade skips a default the user already created under '
      'the same name', () async {
    await createV14Database(extraStatements: [
      'INSERT INTO exercises '
          '(id, name, category, muscle_group, equipment_type, is_custom) '
          "VALUES ('custom-1', 'elliptical', 'cardio', 'cardio', "
          "'cardioMachine', 1)",
    ]);

    final database = db.AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(database.close);

    final names = await exerciseNames(database);
    expect(
      names.where((n) => n.toLowerCase() == 'elliptical'),
      ['elliptical'],
    );
    expect(names, contains('Stair Climber'));
  });
}
