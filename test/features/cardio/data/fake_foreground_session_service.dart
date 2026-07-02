import 'package:rep_foundry/features/cardio/data/foreground_session_service.dart';

/// Records every reconciliation request for assertions in controller tests.
class FakeForegroundSessionService implements ForegroundSessionService {
  final List<({bool sessionRunning, bool gpsEnabled, bool hrConnected})>
      updates = [];

  ({bool sessionRunning, bool gpsEnabled, bool hrConnected})? get last =>
      updates.isEmpty ? null : updates.last;

  @override
  Future<void> update({
    required bool sessionRunning,
    required bool gpsEnabled,
    required bool hrConnected,
  }) async {
    updates.add((
      sessionRunning: sessionRunning,
      gpsEnabled: gpsEnabled,
      hrConnected: hrConnected,
    ));
  }
}
