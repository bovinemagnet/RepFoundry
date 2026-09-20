import '../domain/models/cardio_session.dart';

/// A saved cardio session together with the facts the history list needs
/// that live on other entities: when it started (the parent workout) and
/// what sport it was (the exercise).
class CardioHistoryEntry {
  final CardioSession session;
  final DateTime startedAt;
  final String exerciseName;

  const CardioHistoryEntry({
    required this.session,
    required this.startedAt,
    required this.exerciseName,
  });

  String get exerciseId => session.exerciseId;
  double? get distanceKm =>
      session.distanceMeters == null ? null : session.distanceMeters! / 1000;
  double? get paceMinutesPerKm => session.paceMinutesPerKm;
}
