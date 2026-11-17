import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../history/application/calculate_progress_use_case.dart';
import '../../application/mcp_tool_catalogue.dart';
import '../../data/mcp_server_host.dart';
import '../../domain/mcp_server_status.dart';
import '../../domain/mcp_settings.dart';
import 'mcp_settings_provider.dart';

/// Creates the loopback host. Overridden in tests.
final mcpHostFactoryProvider = Provider<McpHostFactory>(
  (ref) => ({required port, required token, required tools}) =>
      McpServerHost(port: port, token: token, tools: tools),
);

/// The repositories and use cases the tools read from.
final mcpToolDepsProvider = Provider<McpToolDeps>((ref) {
  final workouts = ref.watch(workoutRepositoryProvider);
  return McpToolDeps(
    workouts: workouts,
    exercises: ref.watch(exerciseRepositoryProvider),
    cardio: ref.watch(cardioSessionRepositoryProvider),
    stretching: ref.watch(stretchingSessionRepositoryProvider),
    records: ref.watch(personalRecordRepositoryProvider),
    bodyMetrics: ref.watch(bodyMetricRepositoryProvider),
    templates: ref.watch(workoutTemplateRepositoryProvider),
    programmes: ref.watch(programmeRepositoryProvider),
    clients: ref.watch(clientRepositoryProvider),
    healthProfiles: ref.watch(healthProfileRepositoryProvider),
    calculateProgress: CalculateProgressUseCase(workoutRepository: workouts),
    cardioHistory: ref.watch(buildCardioHistoryUseCaseProvider),
    weeklyHeartReport: ref.watch(buildWeeklyHeartReportUseCaseProvider),
    now: clock.now,
  );
});

/// Starts, restarts and stops the MCP server as [mcpSettingsProvider]
/// changes. The single owner of the host.
///
/// Changes are applied one at a time on a single future chain, so a burst of
/// toggles can never leave two servers bound. Errors become [McpFailed] and
/// never reach the caller: the server must not affect the rest of the app.
class McpServerController extends Notifier<McpServerStatus> {
  McpHost? _host;
  _ServerKey? _applied;
  Future<void> _chain = Future.value();
  bool _disposed = false;

  @override
  McpServerStatus build() {
    if (!ref.watch(mcpHostSupportedProvider)) return const McpStopped();

    ref.listen<McpSettings>(mcpSettingsProvider, (_, __) => _schedule());
    ref.onDispose(() {
      _disposed = true;
      final host = _host;
      _host = null;
      host?.stop();
    });

    _enqueue(() => ref.read(mcpSettingsProvider.notifier).ensureLoaded());
    _schedule();
    return const McpStopped();
  }

  /// Completes once every queued change has been applied.
  Future<void> get idle async {
    Future<void> current;
    do {
      current = _chain;
      await current;
    } while (!identical(current, _chain));
  }

  void _schedule() => _enqueue(_apply);

  void _enqueue(Future<void> Function() step) {
    _chain = _chain.then((_) => _disposed ? null : step()).catchError((_) {});
  }

  Future<void> _apply() async {
    // Always apply the latest settings, so queued changes collapse.
    final settings = ref.read(mcpSettingsProvider);
    final wanted = settings.enabled && settings.token.isNotEmpty
        ? _ServerKey.of(settings)
        : null;
    if (wanted == _applied && (wanted == null) == (_host == null)) return;

    final old = _host;
    _host = null;
    _applied = null;
    await old?.stop();

    if (wanted == null) {
      state = const McpStopped();
      return;
    }

    final host = ref.read(mcpHostFactoryProvider)(
      port: settings.port,
      token: settings.token,
      tools: () => buildMcpTools(ref.read(mcpToolDepsProvider), settings),
    );
    try {
      final port = await host.start();
      if (_disposed) {
        await host.stop();
        return;
      }
      _host = host;
      _applied = wanted;
      state = McpRunning(port);
    } catch (e) {
      _applied = wanted;
      state = McpFailed(e.toString());
    }
  }
}

/// The settings that require a restart when they change.
class _ServerKey {
  const _ServerKey(
    this.port,
    this.token,
    this.includeClients,
    this.includeHealthProfile,
  );

  factory _ServerKey.of(McpSettings s) =>
      _ServerKey(s.port, s.token, s.includeClients, s.includeHealthProfile);

  final int port;
  final String token;
  final bool includeClients;
  final bool includeHealthProfile;

  @override
  bool operator ==(Object other) =>
      other is _ServerKey &&
      other.port == port &&
      other.token == token &&
      other.includeClients == includeClients &&
      other.includeHealthProfile == includeHealthProfile;

  @override
  int get hashCode =>
      Object.hash(port, token, includeClients, includeHealthProfile);
}

final mcpServerControllerProvider =
    NotifierProvider<McpServerController, McpServerStatus>(
  McpServerController.new,
);
