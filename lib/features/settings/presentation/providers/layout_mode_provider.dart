import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/responsive/layout_mode.dart';

/// App-wide [LayoutMode] override, persisted via SharedPreferences
/// (`layout_mode`).
///
/// Drives the Layout (Auto / Mobile / Desktop) control on the Settings screen
/// and the [LayoutModeScope] near the app root. Defaults to [LayoutMode.auto],
/// i.e. the layout follows the window width. The override only takes effect at
/// tablet widths and above; phones always use the mobile layout.
final layoutModeProvider = NotifierProvider<LayoutModeNotifier, LayoutMode>(
  LayoutModeNotifier.new,
);

class LayoutModeNotifier extends Notifier<LayoutMode> {
  static const _prefsKey = 'layout_mode';

  @override
  LayoutMode build() {
    _load();
    return LayoutMode.auto;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsKey);
    if (value != null) state = _fromString(value);
  }

  Future<void> set(LayoutMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  LayoutMode _fromString(String value) {
    switch (value) {
      case 'mobile':
        return LayoutMode.mobile;
      case 'desktop':
        return LayoutMode.desktop;
      default:
        return LayoutMode.auto;
    }
  }
}
