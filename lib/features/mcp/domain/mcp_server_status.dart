/// Lifecycle of the loopback MCP server, shown in Settings.
sealed class McpServerStatus {
  const McpServerStatus();
}

/// Not running: switched off, unsupported platform, or not yet started.
class McpStopped extends McpServerStatus {
  const McpStopped();
}

/// Listening on `127.0.0.1:[port]`.
class McpRunning extends McpServerStatus {
  const McpRunning(this.port);

  final int port;
}

/// Could not start, for example because the port is already in use.
class McpFailed extends McpServerStatus {
  const McpFailed(this.reason);

  final String reason;
}
