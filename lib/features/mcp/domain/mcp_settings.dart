import 'dart:convert';
import 'dart:math';

/// Default loopback port for the MCP server.
const int kDefaultMcpPort = 47600;

/// Lowest and highest port the user may choose.
const int kMinMcpPort = 1024;
const int kMaxMcpPort = 65535;

/// User-controlled settings for assistant access over MCP.
class McpSettings {
  const McpSettings({
    this.enabled = false,
    this.port = kDefaultMcpPort,
    this.token = '',
    this.includeClients = false,
    this.includeHealthProfile = false,
    this.disclosureAccepted = false,
  });

  /// Master switch. Off by default.
  final bool enabled;

  /// Loopback port the server binds.
  final int port;

  /// Bearer token clients must present. Empty until first enabled.
  final String token;

  /// Expose other clients' data and the `client_id` argument.
  final bool includeClients;

  /// Expose the `get_health_profile` tool.
  final bool includeHealthProfile;

  /// The one-time disclosure has been accepted.
  final bool disclosureAccepted;

  McpSettings copyWith({
    bool? enabled,
    int? port,
    String? token,
    bool? includeClients,
    bool? includeHealthProfile,
    bool? disclosureAccepted,
  }) {
    return McpSettings(
      enabled: enabled ?? this.enabled,
      port: port ?? this.port,
      token: token ?? this.token,
      includeClients: includeClients ?? this.includeClients,
      includeHealthProfile: includeHealthProfile ?? this.includeHealthProfile,
      disclosureAccepted: disclosureAccepted ?? this.disclosureAccepted,
    );
  }
}

/// A random 256-bit bearer token, base64url without padding (43 characters).
String generateMcpToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}
