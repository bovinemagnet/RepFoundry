import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:rep_foundry/features/cardio/data/location_service.dart';

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
