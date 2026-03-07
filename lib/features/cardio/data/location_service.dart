import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Abstraction over GPS location for testability.
abstract class LocationService {
  Future<bool> checkAndRequestPermission();
  Stream<Position> getPositionStream();
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  );
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<bool> checkAndRequestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }

  @override
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
