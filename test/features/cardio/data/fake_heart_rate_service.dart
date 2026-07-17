import 'dart:async';

import 'package:rep_foundry/features/cardio/data/heart_rate_service.dart';

class FakeHeartRateService implements HeartRateService {
  bool permissionGranted;
  bool _connected = false;
  String? connectedDeviceId;
  final _heartRateController = StreamController<int>.broadcast();
  final _connectionStateController =
      StreamController<HrConnectionState>.broadcast();
  List<DiscoveredHrDevice> devicesToReturn;
  bool shouldThrowOnConnect;
  Object? scanError;

  FakeHeartRateService({
    this.permissionGranted = true,
    this.devicesToReturn = const [],
    this.shouldThrowOnConnect = false,
    this.scanError,
  });

  bool turnOnBluetoothResult = false;
  bool turnOnBluetoothCalled = false;

  @override
  Future<bool> checkAndRequestPermission() async => permissionGranted;

  @override
  Future<bool> turnOnBluetooth() async {
    turnOnBluetoothCalled = true;
    if (turnOnBluetoothResult) permissionGranted = true;
    return turnOnBluetoothResult;
  }

  @override
  Future<List<DiscoveredHrDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final scanError = this.scanError;
    if (scanError != null) throw scanError;
    return devicesToReturn;
  }

  @override
  Future<void> connectToDevice(String deviceId) async {
    if (shouldThrowOnConnect) {
      throw Exception('Connection failed');
    }
    connectedDeviceId = deviceId;
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    connectedDeviceId = null;
  }

  @override
  Stream<int> get heartRateStream => _heartRateController.stream;

  @override
  Stream<HrConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  bool get isConnected => _connected;

  void emitHeartRate(int bpm) {
    _heartRateController.add(bpm);
  }

  void simulateDisconnection() {
    _connected = false;
    connectedDeviceId = null;
  }

  void emitConnectionState(HrConnectionState connectionState) {
    _connectionStateController.add(connectionState);
  }

  void dispose() {
    _heartRateController.close();
    _connectionStateController.close();
  }
}
