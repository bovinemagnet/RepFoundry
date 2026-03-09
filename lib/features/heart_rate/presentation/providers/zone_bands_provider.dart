import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether coloured zone bands are shown on the heart rate chart.
class ZoneBandsNotifier extends Notifier<bool> {
  static const _key = 'hr_show_zone_bands';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

final zoneBandsProvider = NotifierProvider<ZoneBandsNotifier, bool>(
  ZoneBandsNotifier.new,
);
