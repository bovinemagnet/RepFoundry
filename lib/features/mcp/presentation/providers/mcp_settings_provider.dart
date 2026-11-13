import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/mcp_platform.dart';
import '../../domain/mcp_settings.dart';

/// Whether this platform may host the MCP server. Overridable in tests.
final mcpHostSupportedProvider =
    Provider<bool>((ref) => mcpHostSupportedOnThisPlatform());

/// Assistant access settings, persisted in SharedPreferences.
class McpSettingsNotifier extends Notifier<McpSettings> {
  static const _keyEnabled = 'mcp_enabled';
  static const _keyPort = 'mcp_port';
  static const _keyToken = 'mcp_token';
  static const _keyIncludeClients = 'mcp_include_clients';
  static const _keyIncludeHealthProfile = 'mcp_include_health_profile';
  static const _keyDisclosureAccepted = 'mcp_disclosure_accepted';

  Future<void>? _loadFuture;
  McpSettings? _loaded;

  @override
  McpSettings build() {
    _loadFuture ??= _load();
    return _loaded ?? const McpSettings();
  }

  /// Completes once the persisted settings have been read.
  Future<void> ensureLoaded() => _loadFuture ??= _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _set(McpSettings(
      enabled: prefs.getBool(_keyEnabled) ?? false,
      port: prefs.getInt(_keyPort) ?? kDefaultMcpPort,
      token: prefs.getString(_keyToken) ?? '',
      includeClients: prefs.getBool(_keyIncludeClients) ?? false,
      includeHealthProfile: prefs.getBool(_keyIncludeHealthProfile) ?? false,
      disclosureAccepted: prefs.getBool(_keyDisclosureAccepted) ?? false,
    ));
  }

  void _set(McpSettings next) {
    _loaded = next;
    state = next;
  }

  /// Turns access on or off. The first enable generates a token.
  Future<void> setEnabled(bool enabled) async {
    await ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    var next = state.copyWith(enabled: enabled);
    if (enabled && next.token.isEmpty) {
      next = next.copyWith(token: generateMcpToken());
      await prefs.setString(_keyToken, next.token);
    }
    _set(next);
    await prefs.setBool(_keyEnabled, enabled);
  }

  /// Sets the loopback port. Throws [ArgumentError] outside 1024–65535.
  Future<void> setPort(int port) async {
    if (port < kMinMcpPort || port > kMaxMcpPort) {
      throw ArgumentError.value(port, 'port', 'Must be 1024–65535');
    }
    await ensureLoaded();
    _set(state.copyWith(port: port));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPort, port);
  }

  /// Replaces the token, which invalidates every connected client.
  Future<void> regenerateToken() async {
    await ensureLoaded();
    _set(state.copyWith(token: generateMcpToken()));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, state.token);
  }

  Future<void> setIncludeClients(bool value) async {
    await ensureLoaded();
    _set(state.copyWith(includeClients: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIncludeClients, value);
  }

  Future<void> setIncludeHealthProfile(bool value) async {
    await ensureLoaded();
    _set(state.copyWith(includeHealthProfile: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIncludeHealthProfile, value);
  }

  Future<void> acceptDisclosure() async {
    await ensureLoaded();
    _set(state.copyWith(disclosureAccepted: true));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDisclosureAccepted, true);
  }
}

final mcpSettingsProvider = NotifierProvider<McpSettingsNotifier, McpSettings>(
  McpSettingsNotifier.new,
);
