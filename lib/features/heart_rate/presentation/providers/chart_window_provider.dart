import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChartWindowNotifier extends StateNotifier<int> {
  ChartWindowNotifier() : super(60) {
    _load();
  }

  static const _key = 'hr_chart_window_seconds';
  static const allowedValues = [30, 60, 90, 120, 300];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final value = prefs.getInt(_key);
    if (value != null && allowedValues.contains(value)) {
      state = value;
    }
  }

  Future<void> setWindow(int seconds) async {
    if (!allowedValues.contains(seconds)) return;
    state = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, seconds);
  }
}

final chartWindowProvider = StateNotifierProvider<ChartWindowNotifier, int>(
  (ref) => ChartWindowNotifier(),
);
