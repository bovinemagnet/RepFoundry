import 'package:rep_foundry/features/clients/domain/models/client.dart';
import 'package:rep_foundry/features/clients/domain/repositories/client_repository.dart';

Client testClient(String id, {String name = 'Client', DateTime? deletedAt}) =>
    Client(
      id: id,
      name: name,
      colour: 0xFF2196F3,
      notes: null,
      isSelf: id == kSelfClientId,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      deletedAt: deletedAt,
    );

/// In-memory roster seeded with Me; read methods only.
class FakeClientRepository implements ClientRepository {
  FakeClientRepository([Iterable<Client> others = const []]) {
    _clients[kSelfClientId] = testClient(kSelfClientId, name: 'Me');
    for (final c in others) {
      _clients[c.id] = c;
    }
  }

  final Map<String, Client> _clients = {};

  @override
  Stream<List<Client>> watchClients() =>
      Stream.value(_clients.values.where((c) => c.deletedAt == null).toList());

  @override
  Future<Client?> getClient(String id) async => _clients[id];

  @override
  Future<Client> getSelfClient() async => _clients[kSelfClientId]!;

  @override
  Future<Client> createClient(Client client) => throw StateError('write');

  @override
  Future<Client> updateClient(Client client) => throw StateError('write');

  @override
  Future<void> softDeleteClient(String id) => throw StateError('write');
}
