import '../../clients/domain/models/client.dart';
import '../../clients/domain/repositories/client_repository.dart';
import 'mcp_tool.dart';

/// Which client's data a tool may read.
///
/// Me-only unless the user has switched on client data. The UI's active
/// client never affects it.
class McpScope {
  const McpScope({required this.includeClients, required this.clients});

  final bool includeClients;
  final ClientRepository clients;

  /// Whether a row owned by [clientId] may be returned.
  bool canRead(String clientId) => includeClients || clientId == kSelfClientId;

  /// The client a scoped tool should read, from its optional `client_id`.
  Future<String> resolveClientId(Map<String, Object?> args) async {
    final requested = args['client_id'];
    if (requested == null) return kSelfClientId;
    if (!includeClients) {
      throw const McpToolError(
          'client_id is not available: client data access is off');
    }
    if (requested is! String) {
      throw const McpToolError('client_id must be a string');
    }
    final client = await clients.getClient(requested);
    if (client == null || client.deletedAt != null) {
      throw const McpToolError('Unknown client_id');
    }
    return client.id;
  }
}
