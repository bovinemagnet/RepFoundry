import 'package:material_ui/material_ui.dart';

import 'generated/app_localizations.dart';

/// The app's strings plus Material, Cupertino and widgets strings from
/// `material_ui`. Use this, not [S.localizationsDelegates]: gen-l10n still
/// lists the `flutter_localizations` delegates there, whose types `material_ui`
/// widgets do not look up, so every non-English locale would have no Material
/// strings.
const List<LocalizationsDelegate<dynamic>> kAppLocalizationsDelegates = [
  S.delegate,
  ...GlobalMaterialLocalizations.delegates,
];
