import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the heart rate line takes the colour of the zone each BPM falls
/// in, rather than a single colour (#131).
class ZoneColouredLineNotifier extends Notifier<bool> {
  static const _key = 'hr_zone_coloured_line';

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

final zoneColouredLineProvider =
    NotifierProvider<ZoneColouredLineNotifier, bool>(
  ZoneColouredLineNotifier.new,
);
