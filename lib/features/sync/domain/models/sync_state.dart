enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncAt;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncAt,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
