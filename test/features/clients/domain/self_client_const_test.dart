import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/tables/clients_table.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';

void main() {
  test('domain and table self-client ids match', () {
    expect(kSelfClientId, kSelfClientIdConst);
  });
}
