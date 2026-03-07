import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserAgeNotifier extends StateNotifier<int?> {
  UserAgeNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final age = prefs.getInt('user_age');
    state = age;
  }

  Future<void> setAge(int? age) async {
    state = age;
    final prefs = await SharedPreferences.getInstance();
    if (age != null) {
      await prefs.setInt('user_age', age);
    } else {
      await prefs.remove('user_age');
    }
  }
}

final userAgeProvider = StateNotifierProvider<UserAgeNotifier, int?>((ref) {
  return UserAgeNotifier();
});
