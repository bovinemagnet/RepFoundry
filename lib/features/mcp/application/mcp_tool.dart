/// One read-only tool an MCP client can call.
///
/// Pure Dart: arguments and results are JSON-shaped maps, so tools are
/// testable without a server and the MCP package stays in the data layer.
abstract class McpTool {
  /// Tool name as clients see it, in snake_case.
  String get name;

  /// What the tool returns, written for the assistant reading it.
  String get description;

  /// JSON Schema for the arguments; always `type: object`.
  Map<String, Object?> get inputSchema;

  /// Runs the tool. Throws [McpToolError] for bad arguments or unknown ids.
  Future<Map<String, Object?>> call(Map<String, Object?> args);
}

/// A problem with the request, reported to the client as a tool error result.
class McpToolError implements Exception {
  const McpToolError(this.message);

  final String message;

  @override
  String toString() => 'McpToolError: $message';
}
