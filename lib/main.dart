import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/providers.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/sync/presentation/providers/sync_settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  await NotificationService().init();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const _AppWithLifecycle(),
    ),
  );
}

class _AppWithLifecycle extends ConsumerStatefulWidget {
  const _AppWithLifecycle();

  @override
  ConsumerState<_AppWithLifecycle> createState() => _AppWithLifecycleState();
}

class _AppWithLifecycleState extends ConsumerState<_AppWithLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncOnResume();
    }
  }

  Future<void> _syncOnResume() async {
    try {
      final syncSettings = ref.read(syncSettingsProvider);
      if (!syncSettings.enabled) return;
      final orchestrator = ref.read(syncOrchestratorProvider);
      await orchestrator.sync();
    } catch (_) {
      // Sync on resume is best-effort
    }
  }

  @override
  Widget build(BuildContext context) {
    return const RepFoundryApp();
  }
}
