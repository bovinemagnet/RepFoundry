import '../../../clients/domain/repositories/client_repository.dart';
import '../../../clients/domain/repositories/health_profile_repository.dart';
import '../mcp_args.dart';
import '../mcp_scope.dart';
import '../mcp_tool.dart';

/// The trainer's client roster. Offered only with client data access on.
class ListClientsTool implements McpTool {
  ListClientsTool(this._clients);

  final ClientRepository _clients;

  @override
  String get name => 'list_clients';

  @override
  String get description =>
      'Lists the client roster. Pass a client id as `client_id` to other '
      'tools to read that client\'s training.';

  @override
  Map<String, Object?> get inputSchema => objectSchema({});

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final clients = (await _clients.watchClients().first)
        .where((c) => c.deletedAt == null)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return {
      'clients': [
        for (final c in clients)
          {'id': c.id, 'name': c.name, 'is_self': c.isSelf},
      ],
    };
  }
}

/// Age, heart-rate limits and medical flags. Offered only with its toggle on.
class GetHealthProfileTool implements McpTool {
  GetHealthProfileTool(this._profiles, this._scope);

  final HealthProfileRepository _profiles;
  final McpScope _scope;

  @override
  String get name => 'get_health_profile';

  @override
  String get description =>
      'Returns the health profile used for heart-rate zones: age, resting, '
      'measured maximum and clinician-set maximum heart rate, and whether '
      'beta blockers or a heart condition apply. Treat the clinician maximum '
      'as a hard limit.';

  @override
  Map<String, Object?> get inputSchema =>
      objectSchema({'client_id': kClientIdSchema});

  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    final clientId = await _scope.resolveClientId(args);
    final p = await _profiles.getForClient(clientId);
    return {
      'client_id': clientId,
      'age': p.age,
      'resting_hr_bpm': p.restingHr,
      'measured_max_hr_bpm': p.measuredMaxHr,
      'clinician_max_hr_bpm': p.clinicianMaxHr,
      'beta_blocker': p.betaBlocker,
      'heart_condition': p.heartCondition,
    };
  }
}
