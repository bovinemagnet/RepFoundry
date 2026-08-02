import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the heart rate panel screen is currently mounted.
///
/// In-memory only, no `SharedPreferences` — this is a widget-lifecycle
/// signal, not a persisted setting. `HrEventSource` reads it to decide
/// whether the panel's own max-HR alert chime is about to sound, so the
/// coach's cap warning can be delayed to land after it rather than talking
/// over it (see the sequencing decision in the phase 2a HR coaching spec).
class HeartRatePanelVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setVisible(bool value) => state = value;
}

final heartRatePanelVisibleProvider =
    NotifierProvider<HeartRatePanelVisibilityNotifier, bool>(
  HeartRatePanelVisibilityNotifier.new,
);
