import '../models/client.dart';

abstract class ClientRepository {
  Stream<List<Client>> watchClients();
  Future<Client?> getClient(String id);
  Future<Client> getSelfClient();
  Future<Client> createClient(Client client);
  Future<Client> updateClient(Client client);

  /// Soft-deletes a client. Throws [StateError] for the self client.
  Future<void> softDeleteClient(String id);
}
