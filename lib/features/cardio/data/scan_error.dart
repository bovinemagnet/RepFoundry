import 'package:flutter/services.dart';

/// Why a BLE device scan failed, so the UI can explain and offer a fix
/// instead of surfacing raw platform exception text.
enum ScanErrorKind {
  permissionDenied,
  locationServicesOff,
  bluetoothOff,
  unknown
}

/// Maps a [scanForDevices] failure to a [ScanErrorKind].
///
/// The message patterns come from flutter_blue_plus's Android startScan
/// error strings.
ScanErrorKind classifyScanError(Object error) {
  if (error is! PlatformException) return ScanErrorKind.unknown;
  final message = error.message ?? '';
  if (message.contains('Permission') && message.contains('required')) {
    return ScanErrorKind.permissionDenied;
  }
  if (message.contains('Location services are required')) {
    return ScanErrorKind.locationServicesOff;
  }
  if (message.contains('Bluetooth must be turned on')) {
    return ScanErrorKind.bluetoothOff;
  }
  return ScanErrorKind.unknown;
}
