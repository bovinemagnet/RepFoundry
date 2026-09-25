import 'dart:async';

import 'package:rep_foundry/features/cardio/data/foreground_session_service.dart';

/// Records every reconciliation request for assertions in controller tests.
class FakeForegroundSessionService implements ForegroundSessionService {
  final List<
      ({
        bool sessionRunning,
        bool gpsEnabled,
        bool hrConnected,
        bool coachActive,
      })> updates = [];

  ({
    bool sessionRunning,
    bool gpsEnabled,
    bool hrConnected,
    bool coachActive,
  })? get last => updates.isEmpty ? null : updates.last;

  @override
  Future<void> update({
    required bool sessionRunning,
    required bool gpsEnabled,
    required bool hrConnected,
    bool coachActive = false,
  }) async {
    updates.add((
      sessionRunning: sessionRunning,
      gpsEnabled: gpsEnabled,
      hrConnected: hrConnected,
      coachActive: coachActive,
    ));
  }

  final _stopCoach = StreamController<void>.broadcast();

  @override
  Stream<void> get coachStopRequests => _stopCoach.stream;

  /// Simulates the user tapping the notification's stop-coach button.
  void pressStopCoach() => _stopCoach.add(null);
}
