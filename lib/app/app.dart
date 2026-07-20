import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/layout_mode.dart';
import '../core/widgets/app_scroll_behavior.dart';
import '../features/settings/presentation/providers/layout_mode_provider.dart';
import '../features/settings/presentation/providers/theme_mode_provider.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class RepFoundryApp extends ConsumerWidget {
  const RepFoundryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final layoutMode = ref.watch(layoutModeProvider);
    return MaterialApp.router(
      title: 'RepFoundry',
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      // Make the user's layout override available to the width-based breakpoint
      // helpers throughout the routed tree.
      builder: (context, child) => LayoutModeScope(
        mode: layoutMode,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
