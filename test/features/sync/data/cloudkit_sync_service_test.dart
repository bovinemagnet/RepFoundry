import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/sync/data/cloudkit_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.repfoundry.app/cloudkit_sync');
  late CloudKitSyncService service;

  setUp(() {
    service = CloudKitSyncService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('isAvailable', () {
    test('returns true when platform returns true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isAvailable') {
          return true;
        }
        return null;
      });

      final result = await service.isAvailable();
      expect(result, isTrue);
    });

    test('returns false when platform returns false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isAvailable') {
          return false;
        }
        return null;
      });

      final result = await service.isAvailable();
      expect(result, isFalse);
    });

    test('returns false when platform throws PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'isAvailable') {
          throw PlatformException(
            code: 'UNAVAILABLE',
            message: 'CloudKit not available',
          );
        }
        return null;
      });

      final result = await service.isAvailable();
      expect(result, isFalse);
    });
  });

  group('uploadSnapshot', () {
    test('sends correct arguments via platform channel', () async {
      String? capturedMethod;
      Map<Object?, Object?>? capturedArgs;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        capturedMethod = methodCall.method;
        capturedArgs = methodCall.arguments as Map<Object?, Object?>?;
        return true;
      });

      const testJson = '{"workouts":[]}';
      await service.uploadSnapshot(testJson);

      expect(capturedMethod, equals('uploadSnapshot'));
      expect(capturedArgs, equals({'json': testJson}));
    });
  });

  group('downloadSnapshot', () {
    test('returns JSON string when platform returns data', () async {
      const expectedJson = '{"workouts":[{"id":"abc"}]}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'downloadSnapshot') {
          return expectedJson;
        }
        return null;
      });

      final result = await service.downloadSnapshot();
      expect(result, equals(expectedJson));
    });

    test('returns null when platform returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'downloadSnapshot') {
          return null;
        }
        return null;
      });

      final result = await service.downloadSnapshot();
      expect(result, isNull);
    });
  });

  group('deleteCloudData', () {
    test('calls the correct platform method', () async {
      String? capturedMethod;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        capturedMethod = methodCall.method;
        return true;
      });

      await service.deleteCloudData();

      expect(capturedMethod, equals('deleteCloudData'));
    });
  });
}
