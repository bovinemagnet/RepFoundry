import 'package:material_ui/material_ui.dart';
import 'package:rep_foundry/l10n/app_localizations_delegates.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// Wraps a widget in a [MaterialApp] with localisation delegates configured.
Widget localisedApp({required Widget home}) {
  return MaterialApp(
    localizationsDelegates: kAppLocalizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: home,
  );
}
