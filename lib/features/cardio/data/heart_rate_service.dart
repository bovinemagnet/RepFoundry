/// Connection state events emitted by [HeartRateService].
enum HrConnectionState { connected, reconnecting, disconnected }

/// Abstraction over BLE heart rate monitors for testability.
abstract class HeartRateService {
  Future<bool> checkAndRequestPermission();
  Future<List<DiscoveredHrDevice>> scanForDevices({Duration timeout});
  Future<void> connectToDevice(String deviceId);
  Future<void> disconnect();
  Stream<int> get heartRateStream;

  /// Emits connection lifecycle events including reconnection attempts.
  Stream<HrConnectionState> get connectionStateStream;
  bool get isConnected;
}

class DiscoveredHrDevice {
  final String id;
  final String name;

  const DiscoveredHrDevice({required this.id, required this.name});
}
