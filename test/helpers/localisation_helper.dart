import 'package:flutter/material.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// Wraps a widget in a [MaterialApp] with localisation delegates configured.
Widget localisedApp({required Widget home}) {
  return MaterialApp(
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: home,
  );
}
