import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:rep_foundry/features/cardio/data/heart_rate_service.dart';
import 'package:rep_foundry/features/cardio/data/location_service.dart';

class FakeHeartRateService implements HeartRateService {
  bool permissionGranted;
  bool _connected = false;
  String? connectedDeviceId;
  final _heartRateController = StreamController<int>.broadcast();
  final _connectionStateController =
      StreamController<HrConnectionState>.broadcast();
  List<DiscoveredHrDevice> devicesToReturn;
  bool shouldThrowOnConnect;

  FakeHeartRateService({
    this.permissionGranted = true,
    this.devicesToReturn = const [],
    this.shouldThrowOnConnect = false,
  });

  @override
  Future<bool> checkAndRequestPermission() async => permissionGranted;

  @override
  Future<List<DiscoveredHrDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
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

class FakeLocationService implements LocationService {
  bool permissionGranted;
  final _positionController = StreamController<Position>.broadcast();
  double fixedDistance;

  FakeLocationService({
    this.permissionGranted = true,
    this.fixedDistance = 10.0,
  });

  @override
  Future<bool> checkAndRequestPermission() async => permissionGranted;

  @override
  Stream<Position> getPositionStream() => _positionController.stream;

  @override
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return fixedDistance;
  }

  void emitPosition({
    double latitude = 51.5074,
    double longitude = -0.1278,
  }) {
    _positionController.add(Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ));
  }

  void dispose() {
    _positionController.close();
  }
}
