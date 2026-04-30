import '../domain/repositories/stretching_session_repository.dart';

class DeleteStretchingSessionUseCase {
  final StretchingSessionRepository _repository;

  const DeleteStretchingSessionUseCase({
    required StretchingSessionRepository repository,
  }) : _repository = repository;

  Future<void> execute(String id) async {
    if (id.isEmpty) return;
    await _repository.deleteSession(id);
  }
}
