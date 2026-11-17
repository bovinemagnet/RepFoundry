import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:rep_foundry/features/mcp/application/mcp_args.dart';
import 'package:rep_foundry/features/mcp/application/mcp_tool.dart';
import 'package:rep_foundry/features/mcp/data/mcp_server_host.dart';

class _EchoTool implements McpTool {
  @override
  String get name => 'echo_count';
  @override
  String get description => 'Echoes a count.';
  @override
  Map<String, Object?> get inputSchema => objectSchema({
        'count': {'type': 'integer'}
      });
  @override
  Future<Map<String, Object?>> call(Map<String, Object?> args) async {
    if (args['count'] == -1) throw const McpToolError('count must be positive');
    if (args['count'] == -2) throw StateError('database exploded');
    return {'count': args['count']};
  }
}

const _token = 'host-test-token';

Future<McpClient> _connect(int port, {String token = _token}) async {
  final client = McpClient(const Implementation(name: 'test', version: '0'));
  await client.connect(StreamableHttpClientTransport(
    Uri.parse('http://127.0.0.1:$port/mcp'),
    opts: StreamableHttpClientTransportOptions(requestInit: {
      'headers': {'Authorization': 'Bearer $token'},
    }),
  ));
  return client;
}

/// Status of a raw initialize POST with the given headers.
Future<int> _rawPost(int port, Map<String, String> headers) async {
  final http = HttpClient();
  try {
    final req = await http.postUrl(Uri.parse('http://127.0.0.1:$port/mcp'));
    req.headers.contentType = ContentType.json;
    req.headers.set('Accept', 'application/json, text/event-stream');
    headers.forEach(req.headers.set);
    req.write(jsonEncode({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {
        'protocolVersion': '2025-11-25',
        'capabilities': {},
        'clientInfo': {'name': 'raw', 'version': '0'},
      },
    }));
    final res = await req.close();
    await res.drain<void>();
    return res.statusCode;
  } finally {
    http.close(force: true);
  }
}

void main() {
  late McpServerHost host;
  late int port;

  // flutter_test installs a mock HttpClient that answers every request with
  // 400; these tests need real loopback HTTP.
  HttpOverrides? previousOverrides;
  setUpAll(() {
    previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
  });
  tearDownAll(() => HttpOverrides.global = previousOverrides);

  setUp(() async {
    host = McpServerHost(port: 0, token: _token, tools: () => [_EchoTool()]);
    port = await host.start();
  });

  tearDown(() => host.stop());

  test('lists tools as read-only and non-destructive', () async {
    final client = await _connect(port);
    addTearDown(client.close);
    final tool = (await client.listTools()).tools.single;
    expect(tool.name, 'echo_count');
    expect(tool.annotations?.readOnlyHint, isTrue);
    expect(tool.annotations?.destructiveHint, isFalse);
    expect(tool.annotations?.openWorldHint, isFalse);
  });

  test('returns structured content with a text fallback', () async {
    final client = await _connect(port);
    addTearDown(client.close);
    final r = await client.callTool(
        const CallToolRequest(name: 'echo_count', arguments: {'count': 3}));
    expect(r.isError, isFalse);
    expect(r.structuredContent, {'count': 3});
    expect(jsonDecode((r.content.single as TextContent).text), {'count': 3});
  });

  test('reports McpToolError as a tool error with its message', () async {
    final client = await _connect(port);
    addTearDown(client.close);
    final r = await client.callTool(
        const CallToolRequest(name: 'echo_count', arguments: {'count': -1}));
    expect(r.isError, isTrue);
    expect((r.content.single as TextContent).text, 'count must be positive');
  });

  test('hides unexpected errors behind a generic tool error', () async {
    final client = await _connect(port);
    addTearDown(client.close);
    final r = await client.callTool(
        const CallToolRequest(name: 'echo_count', arguments: {'count': -2}));
    expect(r.isError, isTrue);
    expect((r.content.single as TextContent).text, 'Internal error');
  });

  group('request checks', () {
    final auth = {'Authorization': 'Bearer $_token'};

    test('control: a correct request is accepted', () async {
      expect(await _rawPost(port, auth), HttpStatus.ok);
    });

    test('rejects a request without the token', () async {
      expect(await _rawPost(port, {}), HttpStatus.forbidden);
    });

    test('rejects a request with an Origin header', () async {
      expect(await _rawPost(port, {...auth, 'Origin': 'http://localhost:5173'}),
          HttpStatus.forbidden);
    });

    test('rejects a foreign or wrong-port Host', () async {
      expect(await _rawPost(port, {...auth, 'Host': 'evil.example:$port'}),
          HttpStatus.forbidden);
      expect(await _rawPost(port, {...auth, 'Host': 'localhost:1'}),
          HttpStatus.forbidden);
    });
  });

  test('listens on loopback only', () async {
    final interfaces =
        await NetworkInterface.list(type: InternetAddressType.IPv4);
    final external = [
      for (final i in interfaces)
        for (final a in i.addresses)
          if (!a.isLoopback) a,
    ];
    if (external.isEmpty) {
      markTestSkipped('no non-loopback IPv4 interface on this machine');
      return;
    }
    // Control: loopback accepts a connection.
    final ok = await Socket.connect(InternetAddress.loopbackIPv4, port);
    ok.destroy();
    await expectLater(
      Socket.connect(external.first, port, timeout: const Duration(seconds: 2)),
      throwsA(isA<SocketException>()),
    );
  });

  test('refuses connections once stopped', () async {
    await host.stop();
    await expectLater(Socket.connect(InternetAddress.loopbackIPv4, port),
        throwsA(isA<SocketException>()));
  });

  test('start fails when the port is taken', () async {
    final blocker = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(blocker.close);
    final second =
        McpServerHost(port: blocker.port, token: _token, tools: () => []);
    await expectLater(second.start(), throwsA(isA<SocketException>()));
  });
}
