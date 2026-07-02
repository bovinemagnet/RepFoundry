import 'dart:async';
import 'dart:io';

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
    // iOS keeps delivering updates while the phone is locked (requires the
    // UIBackgroundModes location entry and shows the system location
    // indicator); Android relies on the cardio foreground service to keep
    // the process alive instead.
    final LocationSettings settings;
    if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }
    return Geolocator.getPositionStream(locationSettings: settings);
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
