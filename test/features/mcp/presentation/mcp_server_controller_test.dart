import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/database/app_database.dart';
import 'package:rep_foundry/core/database/database_provider.dart';
import 'package:rep_foundry/features/mcp/application/mcp_tool.dart';
import 'package:rep_foundry/features/mcp/data/mcp_server_host.dart';
import 'package:rep_foundry/features/mcp/domain/mcp_server_status.dart';
import 'package:rep_foundry/features/mcp/presentation/providers/mcp_server_controller.dart';
import 'package:rep_foundry/features/mcp/presentation/providers/mcp_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHost implements McpHost {
  _FakeHost(this.log, this.port, this.token, this.tools, this.startDelay,
      this.failWith);

  final _HostLog log;
  final int port;
  final String token;
  final List<McpTool> Function() tools;
  final Duration startDelay;
  final Object? failWith;

  @override
  Future<int> start() async {
    log.starts++;
    await Future<void>.delayed(startDelay);
    if (failWith != null) throw failWith!;
    log.live.add(this);
    return port;
  }

  @override
  Future<void> stop() async {
    log.stops++;
    log.live.remove(this);
  }
}

class _HostLog {
  int starts = 0;
  int stops = 0;
  final live = <_FakeHost>{};
  final created = <_FakeHost>[];
}

/// A container whose host factory records into [log].
ProviderContainer _container(
  _HostLog log, {
  bool supported = true,
  Duration startDelay = Duration.zero,
  Object? failWith,
  McpHostFactory? factory,
}) {
  final c = ProviderContainer(overrides: [
    mcpHostSupportedProvider.overrideWithValue(supported),
    mcpToolDepsProvider.overrideWith((ref) => throw UnimplementedError()),
    mcpHostFactoryProvider.overrideWithValue(factory ??
        ({required port, required token, required tools}) {
          final h = _FakeHost(log, port, token, tools, startDelay, failWith);
          log.created.add(h);
          return h;
        }),
  ]);
  addTearDown(c.dispose);
  return c;
}

/// Lets the controller's queued work run.
Future<void> _settle(ProviderContainer c) async {
  await c.read(mcpServerControllerProvider.notifier).idle;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('never starts a server on an unsupported platform', () async {
    SharedPreferences.setMockInitialValues(
        {'mcp_enabled': true, 'mcp_token': 't'});
    final log = _HostLog();
    final c = _container(log, supported: false);
    expect(c.read(mcpServerControllerProvider), isA<McpStopped>());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(log.starts, 0);
    // Control: the same settings start a server where supported.
    final log2 = _HostLog();
    final c2 = _container(log2);
    c2.read(mcpServerControllerProvider);
    await _settle(c2);
    expect(log2.starts, 1);
  });

  test('starts when enabled and reports the port', () async {
    final log = _HostLog();
    final c = _container(log);
    c.read(mcpServerControllerProvider);
    await _settle(c);
    expect(c.read(mcpServerControllerProvider), isA<McpStopped>());

    await c.read(mcpSettingsProvider.notifier).setEnabled(true);
    await _settle(c);
    final status = c.read(mcpServerControllerProvider);
    expect(status, isA<McpRunning>());
    expect((status as McpRunning).port, 47600);
    expect(log.live.single.token, c.read(mcpSettingsProvider).token);
  });

  test('stops when disabled', () async {
    SharedPreferences.setMockInitialValues(
        {'mcp_enabled': true, 'mcp_token': 't'});
    final log = _HostLog();
    final c = _container(log);
    c.read(mcpServerControllerProvider);
    await _settle(c);
    await c.read(mcpSettingsProvider.notifier).setEnabled(false);
    await _settle(c);
    expect(c.read(mcpServerControllerProvider), isA<McpStopped>());
    expect(log.live, isEmpty);
  });

  test('reports a failed start without throwing', () async {
    SharedPreferences.setMockInitialValues(
        {'mcp_enabled': true, 'mcp_token': 't'});
    final log = _HostLog();
    final c = _container(log,
        failWith: const SocketException('Address already in use'));
    c.read(mcpServerControllerProvider);
    await _settle(c);
    final status = c.read(mcpServerControllerProvider);
    expect(status, isA<McpFailed>());
    expect((status as McpFailed).reason, contains('Address already in use'));
  });

  test('rapid on, off, on leaves exactly one live server', () async {
    final log = _HostLog();
    final c = _container(log, startDelay: const Duration(milliseconds: 30));
    c.read(mcpServerControllerProvider);
    await _settle(c);
    final n = c.read(mcpSettingsProvider.notifier);
    unawaited(n.setEnabled(true));
    unawaited(n.setEnabled(false));
    unawaited(n.setEnabled(true));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await _settle(c);
    expect(log.live, hasLength(1));
    expect(log.starts - log.stops, 1);
    expect(c.read(mcpServerControllerProvider), isA<McpRunning>());
  });

  test('restarts with the new token when it is regenerated', () async {
    SharedPreferences.setMockInitialValues(
        {'mcp_enabled': true, 'mcp_token': 'old'});
    final log = _HostLog();
    final c = _container(log);
    c.read(mcpServerControllerProvider);
    await _settle(c);
    await c.read(mcpSettingsProvider.notifier).regenerateToken();
    await _settle(c);
    expect(log.live.single.token, isNot('old'));
    expect(log.live.single.token, c.read(mcpSettingsProvider).token);
  });

  test('does not restart for a change that does not affect the server',
      () async {
    SharedPreferences.setMockInitialValues(
        {'mcp_enabled': true, 'mcp_token': 't'});
    final log = _HostLog();
    final c = _container(log);
    c.read(mcpServerControllerProvider);
    await _settle(c);
    await c.read(mcpSettingsProvider.notifier).acceptDisclosure();
    await _settle(c);
    expect(log.starts, 1);
  });

  test('includes list_clients once client data is switched on', () async {
    SharedPreferences.setMockInitialValues(
        {'mcp_enabled': true, 'mcp_token': 't'});
    final log = _HostLog();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      mcpHostSupportedProvider.overrideWithValue(true),
      mcpHostFactoryProvider
          .overrideWithValue(({required port, required token, required tools}) {
        final h = _FakeHost(log, port, token, tools, Duration.zero, null);
        log.created.add(h);
        return h;
      }),
    ]);
    addTearDown(c.dispose);
    c.read(mcpServerControllerProvider);
    await _settle(c);
    Set<String> names() => log.live.single.tools().map((t) => t.name).toSet();
    expect(names(), isNot(contains('list_clients')));
    await c.read(mcpSettingsProvider.notifier).setIncludeClients(true);
    await _settle(c);
    expect(names(), contains('list_clients'));
  });

  group('with a real host', () {
    HttpOverrides? previous;
    setUpAll(() {
      previous = HttpOverrides.current;
      HttpOverrides.global = null;
    });
    tearDownAll(() => HttpOverrides.global = previous);

    Future<int> post(int port, String token) async {
      final http = HttpClient();
      try {
        final req = await http.postUrl(Uri.parse('http://127.0.0.1:$port/mcp'));
        req.headers.contentType = ContentType.json;
        req.headers.set('Accept', 'application/json, text/event-stream');
        req.headers.set('Authorization', 'Bearer $token');
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

    test('an old token is refused after regeneration', () async {
      SharedPreferences.setMockInitialValues(
          {'mcp_enabled': true, 'mcp_token': 'first-token'});
      final c = ProviderContainer(overrides: [
        mcpHostSupportedProvider.overrideWithValue(true),
        // Port 0 so the test never collides with a running app.
        mcpHostFactoryProvider.overrideWithValue((
                {required port, required token, required tools}) =>
            McpServerHost(port: 0, token: token, tools: () => [])),
      ]);
      addTearDown(c.dispose);
      c.read(mcpServerControllerProvider);
      await _settle(c);
      final firstPort =
          (c.read(mcpServerControllerProvider) as McpRunning).port;
      expect(await post(firstPort, 'first-token'), HttpStatus.ok);

      await c.read(mcpSettingsProvider.notifier).regenerateToken();
      await _settle(c);
      final port = (c.read(mcpServerControllerProvider) as McpRunning).port;
      final fresh = c.read(mcpSettingsProvider).token;
      expect(await post(port, 'first-token'), HttpStatus.forbidden);
      expect(await post(port, fresh), HttpStatus.ok);
    });
  });
}
