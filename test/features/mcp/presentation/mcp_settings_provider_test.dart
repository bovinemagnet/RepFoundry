import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/mcp/domain/mcp_settings.dart';
import 'package:rep_foundry/features/mcp/presentation/providers/mcp_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _loadedContainer() async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await container.read(mcpSettingsProvider.notifier).ensureLoaded();
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to off on port 47600 with no token', () async {
    final c = await _loadedContainer();
    final s = c.read(mcpSettingsProvider);
    expect(s.enabled, isFalse);
    expect(s.port, kDefaultMcpPort);
    expect(kDefaultMcpPort, 47600);
    expect(s.token, isEmpty);
    expect(s.includeClients, isFalse);
    expect(s.includeHealthProfile, isFalse);
    expect(s.disclosureAccepted, isFalse);
  });

  test('enabling with no token generates and persists a 43-character token',
      () async {
    final c = await _loadedContainer();
    await c.read(mcpSettingsProvider.notifier).setEnabled(true);
    final s = c.read(mcpSettingsProvider);
    expect(s.enabled, isTrue);
    expect(s.token, hasLength(43));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mcp_token'), s.token);
    expect(prefs.getBool('mcp_enabled'), isTrue);
  });

  test('enabling keeps an existing token', () async {
    SharedPreferences.setMockInitialValues({'mcp_token': 'kept'});
    final c = await _loadedContainer();
    await c.read(mcpSettingsProvider.notifier).setEnabled(true);
    expect(c.read(mcpSettingsProvider).token, 'kept');
  });

  test('regenerateToken changes and persists the token', () async {
    final c = await _loadedContainer();
    final n = c.read(mcpSettingsProvider.notifier);
    await n.setEnabled(true);
    final before = c.read(mcpSettingsProvider).token;
    await n.regenerateToken();
    final after = c.read(mcpSettingsProvider).token;
    expect(after, isNot(before));
    expect(after, hasLength(43));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mcp_token'), after);
  });

  test('setPort rejects ports outside 1024 to 65535', () async {
    final c = await _loadedContainer();
    final n = c.read(mcpSettingsProvider.notifier);
    expect(() => n.setPort(1023), throwsArgumentError);
    expect(() => n.setPort(65536), throwsArgumentError);
    await n.setPort(1024);
    expect(c.read(mcpSettingsProvider).port, 1024);
  });

  test('every setting round-trips through preferences', () async {
    final c = await _loadedContainer();
    final n = c.read(mcpSettingsProvider.notifier);
    await n.setEnabled(true);
    await n.setPort(50000);
    await n.setIncludeClients(true);
    await n.setIncludeHealthProfile(true);
    await n.acceptDisclosure();
    final written = c.read(mcpSettingsProvider);

    final fresh = await _loadedContainer();
    final read = fresh.read(mcpSettingsProvider);
    expect(read.enabled, isTrue);
    expect(read.port, 50000);
    expect(read.token, written.token);
    expect(read.includeClients, isTrue);
    expect(read.includeHealthProfile, isTrue);
    expect(read.disclosureAccepted, isTrue);
  });

  test('generateMcpToken yields distinct url-safe 43-character tokens', () {
    final a = generateMcpToken();
    final b = generateMcpToken();
    expect(a, isNot(b));
    expect(a, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
  });
}
