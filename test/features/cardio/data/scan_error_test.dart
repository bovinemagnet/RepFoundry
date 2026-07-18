import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/data/scan_error.dart';

void main() {
  group('classifyScanError', () {
    test('recognises the Android location permission failure', () {
      final kind = classifyScanError(PlatformException(
        code: 'startScan',
        message: 'Permission android.permission.ACCESS_FINE_LOCATION required '
            'to scan devices',
      ));
      expect(kind, ScanErrorKind.permissionDenied);
    });

    test('recognises the Android 12+ scan permission failure', () {
      final kind = classifyScanError(PlatformException(
        code: 'startScan',
        message: 'Permission android.permission.BLUETOOTH_SCAN required to '
            'scan devices',
      ));
      expect(kind, ScanErrorKind.permissionDenied);
    });

    test('recognises location services being off', () {
      final kind = classifyScanError(PlatformException(
        code: 'startScan',
        message: 'Location services are required for Bluetooth scan',
      ));
      expect(kind, ScanErrorKind.locationServicesOff);
    });

    test('recognises the adapter being off', () {
      final kind = classifyScanError(PlatformException(
        code: 'startScan',
        message: 'Bluetooth must be turned on',
      ));
      expect(kind, ScanErrorKind.bluetoothOff);
    });

    test('falls back to unknown for anything else', () {
      expect(classifyScanError(Exception('boom')), ScanErrorKind.unknown);
      expect(
        classifyScanError(PlatformException(code: 'startScan')),
        ScanErrorKind.unknown,
      );
    });
  });
}
