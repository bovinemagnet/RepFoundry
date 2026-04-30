/// Thrown when a remote sync snapshot's `schemaVersion` is incompatible with
/// the local app's schema.
///
/// The merge engine refuses to apply a snapshot built by a newer client; doing
/// so would cause the older client to silently strip unknown fields and
/// re-upload a degraded blob, overwriting the newer device's contributions.
class SyncSchemaVersionException implements Exception {
  /// Schema version reported by the remote snapshot.
  final int remoteVersion;

  /// Schema version of the local app.
  final int localVersion;

  /// User-facing message describing the failure.
  final String message;

  const SyncSchemaVersionException._(
    this.remoteVersion,
    this.localVersion,
    this.message,
  );

  /// The remote snapshot was created by a newer version of the app than the
  /// local client supports.
  factory SyncSchemaVersionException.tooNew(int remote, int local) {
    return SyncSchemaVersionException._(
      remote,
      local,
      'Cloud backup was created by a newer version of RepFoundry '
      '(schema v$remote, this app supports v$local). '
      'Please update RepFoundry and try again.',
    );
  }

  @override
  String toString() => message;
}
