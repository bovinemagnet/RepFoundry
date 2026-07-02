import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'heart_rate_service.dart';

/// BLE Heart Rate Service UUID (0x180D).
final _hrServiceUuid = Guid('180D');

/// Heart Rate Measurement characteristic UUID (0x2A37).
final _hrMeasurementUuid = Guid('2A37');

class FlutterBlueHeartRateService implements HeartRateService {
  static const _maxReconnectAttempts = 2;
  static const _reconnectDelay = Duration(seconds: 2);

  final _heartRateController = StreamController<int>.broadcast();
  final _connectionStateController =
      StreamController<HrConnectionState>.broadcast();
  StreamSubscription<List<int>>? _characteristicSub;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  BluetoothDevice? _connectedDevice;
  String? _connectedDeviceId;
  bool _connected = false;
  bool _intentionalDisconnect = false;
  bool _reconnecting = false;

  @override
  Stream<int> get heartRateStream => _heartRateController.stream;

  @override
  Stream<HrConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<bool> checkAndRequestPermission() async {
    try {
      if (await FlutterBluePlus.isSupported == false) return false;

      // The adapter state can report `unknown` briefly on startup; wait for
      // a definitive state rather than treating `unknown` as off.
      final adapterState = await FlutterBluePlus.adapterState
          .where((state) => state != BluetoothAdapterState.unknown)
          .first
          .timeout(const Duration(seconds: 5));
      return adapterState == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<DiscoveredHrDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final devices = <DiscoveredHrDevice>[];
    final seen = <String>{};

    // Collect results via a listener; scanResults only emits when a new
    // advertisement arrives, so awaiting it directly can hang forever once
    // the scan stops.
    final subscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        if (seen.add(r.device.remoteId.str)) {
          var name = r.device.platformName;
          if (name.isEmpty) name = r.advertisementData.advName;
          if (name.isEmpty) name = 'Unknown HR Device';
          devices.add(DiscoveredHrDevice(
            id: r.device.remoteId.str,
            name: name,
          ));
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        withServices: [_hrServiceUuid],
        timeout: timeout,
      );
      // The timeout stops the scan; wait for that rather than for a
      // (possibly never-arriving) final scanResults emission.
      try {
        await FlutterBluePlus.isScanning
            .where((scanning) => !scanning)
            .first
            .timeout(timeout + const Duration(seconds: 5));
      } on TimeoutException {
        // Safety net: the platform never reported the scan stopping.
        // Stop it ourselves and return whatever was found.
        await FlutterBluePlus.stopScan();
      }
    } finally {
      await subscription.cancel();
    }

    return devices;
  }

  @override
  Future<void> connectToDevice(String deviceId) async {
    // Tear down any existing connection so we never hold two devices or
    // duplicate characteristic listeners.
    if (_connectedDevice != null || _connected) {
      await disconnect();
    }
    _intentionalDisconnect = false;
    _connectedDeviceId = deviceId;
    try {
      await _connectAndSubscribe(deviceId);
    } catch (_) {
      // Initial connection failed — surface the error to the caller and
      // don't leave a device id behind that would trigger reconnects.
      _connectedDeviceId = null;
      rethrow;
    }
  }

  Future<void> _connectAndSubscribe(String deviceId) async {
    final device = BluetoothDevice.fromId(deviceId);

    await device.connect(license: License.nonprofit, autoConnect: false);

    BluetoothCharacteristic? hrChar;
    try {
      final services = await device.discoverServices();

      for (final service in services) {
        if (service.uuid == _hrServiceUuid) {
          for (final char in service.characteristics) {
            if (char.uuid == _hrMeasurementUuid) {
              hrChar = char;
              break;
            }
          }
          break;
        }
      }

      if (hrChar == null) {
        throw Exception('Heart rate characteristic not found on device');
      }

      await hrChar.setNotifyValue(true);
    } catch (_) {
      // Disconnect before the state listener below is attached so a setup
      // failure cannot trigger a reconnect loop.
      await device.disconnect();
      rethrow;
    }

    _connectedDevice = device;

    await _characteristicSub?.cancel();
    _characteristicSub = hrChar.lastValueStream.listen((value) {
      if (value.isEmpty) return;
      final bpm = _parseHeartRate(value);
      if (bpm != null) {
        _heartRateController.add(bpm);
      }
    });

    // Listen for disconnection events. Attached only after setup succeeds.
    await _connectionStateSub?.cancel();
    _connectionStateSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connected = false;
        _characteristicSub?.cancel();
        _connectionStateSub?.cancel();
        _connectedDevice = null;

        if (!_intentionalDisconnect && _connectedDeviceId != null) {
          _attemptReconnect(_connectedDeviceId!);
        }
      }
    });

    _connected = true;
    _connectionStateController.add(HrConnectionState.connected);
  }

  Future<void> _attemptReconnect(String deviceId) async {
    if (_reconnecting) return;
    _reconnecting = true;
    try {
      _connectionStateController.add(HrConnectionState.reconnecting);

      for (var attempt = 0; attempt < _maxReconnectAttempts; attempt++) {
        if (_intentionalDisconnect) return;

        await Future<void>.delayed(_reconnectDelay);

        if (_intentionalDisconnect) return;

        try {
          await _connectAndSubscribe(deviceId);
          if (_intentionalDisconnect) {
            // Disconnect was requested while the reconnect was in flight.
            await disconnect();
          }
          return; // Reconnection succeeded.
        } catch (_) {
          // Will retry or fall through.
        }
      }

      // All retries exhausted.
      _connectedDeviceId = null;
      _connectionStateController.add(HrConnectionState.disconnected);
    } finally {
      _reconnecting = false;
    }
  }

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    await _characteristicSub?.cancel();
    _characteristicSub = null;
    await _connectionStateSub?.cancel();
    _connectionStateSub = null;

    final wasConnected = _connected;
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _connectedDeviceId = null;
    _connected = false;

    if (wasConnected) {
      // Tell every listener (cardio and the HR panel share this service).
      _connectionStateController.add(HrConnectionState.disconnected);
    }
  }

  /// Parses the BLE Heart Rate Measurement value.
  ///
  /// Bit 0 of the flags byte indicates the format:
  /// - 0 = UINT8 (1 byte HR value)
  /// - 1 = UINT16 (2 byte HR value, little-endian)
  int? _parseHeartRate(List<int> value) {
    if (value.isEmpty) return null;
    final flags = value[0];
    final is16Bit = (flags & 0x01) == 1;

    if (is16Bit) {
      if (value.length < 3) return null;
      return value[1] | (value[2] << 8);
    } else {
      if (value.length < 2) return null;
      return value[1];
    }
  }
}
