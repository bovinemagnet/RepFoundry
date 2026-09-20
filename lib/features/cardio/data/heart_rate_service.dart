/// Connection state events emitted by [HeartRateService].
enum HrConnectionState { connected, reconnecting, disconnected }

/// Abstraction over BLE heart rate monitors for testability.
abstract class HeartRateService {
  Future<bool> checkAndRequestPermission();

  /// Asks the OS to enable the Bluetooth adapter (system dialog on
  /// Android). Returns true once the adapter reports on.
  Future<bool> turnOnBluetooth();

  /// Every device found so far, re-emitted as the list grows, so a picker
  /// can show a strap the moment it is seen rather than after the whole
  /// scan. Completes when the scan ends.
  Stream<List<DiscoveredHrDevice>> scanDevices({Duration timeout});

  /// The devices found by a complete scan.
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
