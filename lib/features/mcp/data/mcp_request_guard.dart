/// An origin no browser can send, so the SDK's DNS-rebinding check refuses
/// every request that carries an `Origin` header before CORS handling runs.
const String kNoBrowserOrigin = 'https://no-browser-access.invalid';

/// Whether a request to the loopback MCP server may proceed.
///
/// Only local, non-browser clients holding the token get through:
/// - no `Origin` header, so a web page cannot call the server;
/// - `Host` exactly `127.0.0.1:<port>` or `localhost:<port>`, which defeats
///   DNS rebinding (the SDK's own check ignores the port);
/// - `Authorization: Bearer <token>`, compared in constant time.
bool isMcpRequestAllowed({
  required String? host,
  required String? origin,
  required String? authorization,
  required int port,
  required String token,
}) {
  if (origin != null && origin.trim().isNotEmpty) return false;
  final h = host?.trim().toLowerCase();
  if (h != '127.0.0.1:$port' && h != 'localhost:$port') return false;
  if (token.isEmpty || authorization == null) return false;
  return _constantTimeEquals(authorization, 'Bearer $token');
}

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
