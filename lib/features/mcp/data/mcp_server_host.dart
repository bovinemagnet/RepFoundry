import 'dart:io';

import 'package:mcp_dart/mcp_dart.dart';

import '../application/mcp_tool.dart';
import '../application/mcp_tool_catalogue.dart';
import 'mcp_request_guard.dart';

/// A running (or startable) MCP endpoint.
abstract class McpHost {
  /// Binds and starts serving. Returns the bound port.
  Future<int> start();

  /// Stops serving and closes every session.
  Future<void> stop();
}

/// Creates a host; overridden in tests.
typedef McpHostFactory = McpHost Function({
  required int port,
  required String token,
  required List<McpTool> Function() tools,
});

/// Serves [tools] over Streamable HTTP on `127.0.0.1:<port>/mcp`.
///
/// The only place the MCP package is used. Each request (2026-07-28) or
/// session (2025-11-25) gets a fresh `McpServer` built from [tools].
class McpServerHost implements McpHost {
  McpServerHost({
    required this.port,
    required this.token,
    required this.tools,
  });

  final int port;
  final String token;
  final List<McpTool> Function() tools;

  StreamableMcpServer? _server;

  static const _annotations = ToolAnnotations(
    readOnlyHint: true,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  );

  @override
  Future<int> start() async {
    // The SDK logs every request at info level; keep only problems.
    setMcpLogHandler((name, level, message) {
      if (level.index >= LogLevel.warn.index) {
        stderr.writeln('[mcp][${level.name}] $message');
      }
    });

    late final StreamableMcpServer server;
    server = StreamableMcpServer(
      host: InternetAddress.loopbackIPv4.address,
      port: port,
      path: '/mcp',
      allowedOrigins: {kNoBrowserOrigin},
      authenticationHandler: (request) {
        final r = request as HttpRequest;
        final allowed = isMcpRequestAllowed(
          host: r.headers.value(HttpHeaders.hostHeader),
          origin: r.headers.value('origin'),
          authorization: r.headers.value(HttpHeaders.authorizationHeader),
          port: server.boundPort,
          token: token,
        );
        return allowed
            ? const StreamableMcpAuthenticationResult.allow()
            : const StreamableMcpAuthenticationResult.unauthorized();
      },
      serverFactory: (_) => _buildServer(),
    );
    await server.start();
    _server = server;
    return server.boundPort;
  }

  @override
  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.stop();
  }

  McpServer _buildServer() {
    final server = McpServer(
      const Implementation(name: 'repfoundry', version: '0.1.0'),
      options: const McpServerOptions(instructions: kMcpServerInstructions),
    );
    for (final tool in tools()) {
      server.registerTool(
        tool.name,
        description: tool.description,
        annotations: _annotations,
        inputSchema: JsonObject.fromJson(tool.inputSchema),
        callback: (args, extra) => _call(tool, args),
      );
    }
    return server;
  }

  static Future<CallToolResult> _call(
    McpTool tool,
    Map<String, dynamic> args,
  ) async {
    try {
      return CallToolResult.fromStructuredContent(await tool.call(args));
    } on McpToolError catch (e) {
      return CallToolResult(
          isError: true, content: [TextContent(text: e.message)]);
    } catch (e) {
      stderr.writeln('[mcp] ${tool.name} failed: $e');
      return const CallToolResult(
          isError: true, content: [TextContent(text: 'Internal error')]);
    }
  }
}
