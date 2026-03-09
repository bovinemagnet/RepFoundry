import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShowExerciseImagesNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
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
    NotifierProvider<ShowExerciseImagesNotifier, bool>(
  ShowExerciseImagesNotifier.new,
);
