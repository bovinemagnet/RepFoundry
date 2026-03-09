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

      final adapterState = FlutterBluePlus.adapterStateNow;
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

    await FlutterBluePlus.startScan(
      withServices: [_hrServiceUuid],
      timeout: timeout,
    );

    await for (final results in FlutterBluePlus.scanResults) {
      for (final r in results) {
        if (!seen.contains(r.device.remoteId.str)) {
          seen.add(r.device.remoteId.str);
          final name = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : 'Unknown HR Device';
          devices.add(DiscoveredHrDevice(
            id: r.device.remoteId.str,
            name: name,
          ));
        }
      }
      // Stop after scan completes (timeout triggers scan stop).
      if (!FlutterBluePlus.isScanningNow) break;
    }

    return devices;
  }

  @override
  Future<void> connectToDevice(String deviceId) async {
    _intentionalDisconnect = false;
    _connectedDeviceId = deviceId;
    await _connectAndSubscribe(deviceId);
  }

  Future<void> _connectAndSubscribe(String deviceId) async {
    final device = BluetoothDevice.fromId(deviceId);

    await device.connect(license: License.free, autoConnect: false);
    _connectedDevice = device;

    // Listen for disconnection events.
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

    final services = await device.discoverServices();

    BluetoothCharacteristic? hrChar;
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
      await device.disconnect();
      throw Exception('Heart rate characteristic not found on device');
    }

    await hrChar.setNotifyValue(true);
    _characteristicSub = hrChar.lastValueStream.listen((value) {
      if (value.isEmpty) return;
      final bpm = _parseHeartRate(value);
      if (bpm != null) {
        _heartRateController.add(bpm);
      }
    });

    _connected = true;
    _connectionStateController.add(HrConnectionState.connected);
  }

  Future<void> _attemptReconnect(String deviceId) async {
    _connectionStateController.add(HrConnectionState.reconnecting);

    for (var attempt = 0; attempt < _maxReconnectAttempts; attempt++) {
      if (_intentionalDisconnect) return;

      await Future<void>.delayed(_reconnectDelay);

      if (_intentionalDisconnect) return;

      try {
        await _connectAndSubscribe(deviceId);
        return; // Reconnection succeeded.
      } catch (_) {
        // Will retry or fall through.
      }
    }

    // All retries exhausted.
    _connectedDeviceId = null;
    _connectionStateController.add(HrConnectionState.disconnected);
  }

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _characteristicSub?.cancel();
    _characteristicSub = null;
    _connectionStateSub?.cancel();
    _connectionStateSub = null;

    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _connectedDeviceId = null;
    _connected = false;
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
