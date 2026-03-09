import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShowExerciseImagesNotifier extends StateNotifier<bool> {
  ShowExerciseImagesNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    state = prefs.getBool('show_exercise_images') ?? true;
  }

  Future<void> toggle() async {
    final newValue = !state;
    state = newValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_exercise_images', newValue);
  }
}

final showExerciseImagesProvider =
    StateNotifierProvider<ShowExerciseImagesNotifier, bool>(
  (ref) => ShowExerciseImagesNotifier(),
);
