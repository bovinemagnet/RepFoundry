import '../domain/models/stretching_session.dart';
import '../domain/repositories/stretching_session_repository.dart';

class SaveStretchingSessionInput {
  final String workoutId;

  /// Either a preset key from `defaultStretches` or
  /// [StretchingSession.customStretchType] when [customName] is set.
  final String type;

  final String? customName;
  final StretchingBodyArea? bodyArea;
  final StretchingSide? side;
  final int durationSeconds;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final StretchingEntryMethod entryMethod;
  final String? notes;

  const SaveStretchingSessionInput({
    required this.workoutId,
    required this.type,
    required this.durationSeconds,
    required this.entryMethod,
    this.customName,
    this.bodyArea,
    this.side,
    this.startedAt,
    this.endedAt,
    this.notes,
  });
}

class SaveStretchingSessionException implements Exception {
  final String message;
  const SaveStretchingSessionException(this.message);

  @override
  String toString() => 'SaveStretchingSessionException: $message';
}

class SaveStretchingSessionUseCase {
  static const int _maxDurationSeconds = 12 * 60 * 60; // 12 hours
  static const int _maxCustomNameLength = 60;

  final StretchingSessionRepository _repository;

  const SaveStretchingSessionUseCase({
    required StretchingSessionRepository repository,
  }) : _repository = repository;

  Future<StretchingSession> execute(SaveStretchingSessionInput input) async {
    final cleanedCustomName = input.customName?.trim();
    _validate(input, cleanedCustomName);

    final session = StretchingSession.create(
      workoutId: input.workoutId,
      type: input.type,
      customName: input.type == StretchingSession.customStretchType
          ? cleanedCustomName
          : null,
      bodyArea: input.bodyArea,
      side: input.side,
      durationSeconds: input.durationSeconds,
      entryMethod: input.entryMethod,
      startedAt: input.startedAt,
      endedAt: input.endedAt,
      notes: input.notes?.trim().isEmpty ?? true ? null : input.notes!.trim(),
    );

    return _repository.createSession(session);
  }

  void _validate(SaveStretchingSessionInput input, String? cleanedCustomName) {
    if (input.workoutId.isEmpty) {
      throw const SaveStretchingSessionException('Workout id required');
    }
    if (input.type.isEmpty) {
      throw const SaveStretchingSessionException('Stretch type required');
    }
    if (input.durationSeconds <= 0) {
      throw const SaveStretchingSessionException(
        'Duration must be greater than zero',
      );
    }
    if (input.durationSeconds > _maxDurationSeconds) {
      throw const SaveStretchingSessionException(
        'Duration must be 12 hours or less',
      );
    }
    if (input.type == StretchingSession.customStretchType) {
      if (cleanedCustomName == null || cleanedCustomName.isEmpty) {
        throw const SaveStretchingSessionException(
          'Custom stretch name is required',
        );
      }
      if (cleanedCustomName.length > _maxCustomNameLength) {
        throw const SaveStretchingSessionException(
          'Custom stretch name must be 60 characters or less',
        );
      }
    }
  }
}
