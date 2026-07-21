import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart' as db;
import 'package:rep_foundry/features/clients/domain/models/client.dart';

void main() {
  test('fresh database has a Me self-client and scoped tables default to it',
      () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    // Me client exists and is self.
    final clients = await database.select(database.clients).get();
    expect(clients, hasLength(1));
    expect(clients.single.id, kSelfClientId);
    expect(clients.single.isSelf, isTrue);

    // A workout inserted without a client_id defaults to Me.
    await database.customStatement(
      "INSERT INTO workouts (id, started_at, updated_at) VALUES ('w1', 0, 0)",
    );
    final row = await database
        .customSelect(
          "SELECT client_id FROM workouts WHERE id = 'w1'",
        )
        .getSingle();
    expect(row.read<String>('client_id'), kSelfClientId);

    expect(database.schemaVersion, 13);
  });
}
