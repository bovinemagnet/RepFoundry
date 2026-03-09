class SyncResult {
  final bool success;
  final String? errorMessage;
  final int entitiesMerged;
  final DateTime syncedAt;

  const SyncResult({
    required this.success,
    this.errorMessage,
    this.entitiesMerged = 0,
    required this.syncedAt,
  });

  factory SyncResult.success({required int entitiesMerged}) => SyncResult(
        success: true,
        entitiesMerged: entitiesMerged,
        syncedAt: DateTime.now().toUtc(),
      );

  factory SyncResult.error(String message) => SyncResult(
        success: false,
        errorMessage: message,
        syncedAt: DateTime.now().toUtc(),
      );
}
