class SyncSettings {
  final bool enabled;
  final DateTime? lastSyncAt;
  final String deviceId;
  final bool consentGiven;

  const SyncSettings({
    this.enabled = false,
    this.lastSyncAt,
    required this.deviceId,
    this.consentGiven = false,
  });

  SyncSettings copyWith({
    bool? enabled,
    DateTime? lastSyncAt,
    String? deviceId,
    bool? consentGiven,
  }) {
    return SyncSettings(
      enabled: enabled ?? this.enabled,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      deviceId: deviceId ?? this.deviceId,
      consentGiven: consentGiven ?? this.consentGiven,
    );
  }
}
