import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/mcp/application/mcp_scope.dart';
import 'package:rep_foundry/features/mcp/application/mcp_tool.dart';

import '../support/fake_client_repository.dart';

void main() {
  final clients = FakeClientRepository([
    testClient('alice'),
    testClient('gone', deletedAt: DateTime.utc(2026, 2)),
  ]);

  group('with client data off', () {
    final scope = McpScope(includeClients: false, clients: clients);

    test('resolves to Me when no client_id is given', () async {
      expect(await scope.resolveClientId({}), kSelfClientId);
    });

    test('rejects a client_id, even Me', () async {
      await expectLater(scope.resolveClientId({'client_id': 'alice'}),
          throwsA(isA<McpToolError>()));
      await expectLater(scope.resolveClientId({'client_id': kSelfClientId}),
          throwsA(isA<McpToolError>()));
    });

    test('can read only Me', () async {
      expect(await scope.canRead(kSelfClientId), isTrue);
      expect(await scope.canRead('alice'), isFalse);
    });
  });

  group('with client data on', () {
    final scope = McpScope(includeClients: true, clients: clients);

    test('resolves to Me when no client_id is given', () async {
      expect(await scope.resolveClientId({}), kSelfClientId);
    });

    test('resolves an existing client', () async {
      expect(await scope.resolveClientId({'client_id': 'alice'}), 'alice');
    });

    test('rejects a deleted or unknown client', () async {
      await expectLater(scope.resolveClientId({'client_id': 'gone'}),
          throwsA(isA<McpToolError>()));
      await expectLater(scope.resolveClientId({'client_id': 'nobody'}),
          throwsA(isA<McpToolError>()));
    });

    test('can read a live client', () async {
      expect(await scope.canRead('alice'), isTrue);
      expect(await scope.canRead(kSelfClientId), isTrue);
    });

    test('cannot read a deleted or unknown client', () async {
      expect(await scope.canRead('gone'), isFalse);
      expect(await scope.canRead('nobody'), isFalse);
    });
  });
}
