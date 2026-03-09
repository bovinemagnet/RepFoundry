import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/providers.dart';
import 'package:rep_foundry/features/cardio/data/heart_rate_service.dart';
import 'package:rep_foundry/features/heart_rate/presentation/controllers/heart_rate_panel_controller.dart';

import '../../../cardio/data/fake_heart_rate_service.dart';

void main() {
  late FakeHeartRateService heartRateService;
  late ProviderContainer container;
  late HeartRatePanelController controller;

  setUp(() {
    heartRateService = FakeHeartRateService();
    container = ProviderContainer(
      overrides: [
        heartRateServiceProvider.overrideWithValue(heartRateService),
      ],
    );
    controller = container.read(heartRatePanelProvider.notifier);
  });

  tearDown(() {
    container.dispose();
    heartRateService.dispose();
  });

  group('HeartRatePanelController', () {
    test('initial state is not monitoring and not connected', () {
      expect(controller.state.isMonitoring, isFalse);
      expect(controller.state.hrConnected, isFalse);
      expect(controller.state.readings, isEmpty);
      expect(controller.state.elapsedSeconds, 0);
    });

    test('connectAndStart connects and starts monitoring', () async {
      await controller.connectAndStart('dev1', 'Polar H10');

      expect(controller.state.hrConnected, isTrue);
      expect(controller.state.hrConnecting, isFalse);
      expect(controller.state.hrDeviceName, 'Polar H10');
      expect(controller.state.isMonitoring, isTrue);
    });

    test('connectAndStart sets error on failure', () async {
      heartRateService.shouldThrowOnConnect = true;

      await controller.connectAndStart('dev1', 'Polar H10');

      expect(controller.state.hrConnected, isFalse);
      expect(controller.state.hrConnecting, isFalse);
      expect(controller.state.error, isNotNull);
      expect(controller.state.isMonitoring, isFalse);
    });

    test('HR stream appends timestamped readings', () async {
      await controller.connectAndStart('dev1', 'Polar H10');

      heartRateService.emitHeartRate(140);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.currentHeartRate, 140);
      expect(controller.state.readings, hasLength(1));
      expect(controller.state.readings.first.bpm, 140);

      heartRateService.emitHeartRate(145);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.currentHeartRate, 145);
      expect(controller.state.readings, hasLength(2));
    });

    test('startMonitoring is idempotent', () async {
      await controller.connectAndStart('dev1', 'Polar H10');
      controller.startMonitoring();
      expect(controller.state.isMonitoring, isTrue);
    });

    test('stopMonitoring pauses without disconnecting', () async {
      await controller.connectAndStart('dev1', 'Polar H10');
      controller.stopMonitoring();

      expect(controller.state.isMonitoring, isFalse);
      expect(controller.state.hrConnected, isTrue);
    });

    test('resetReadings clears readings and elapsed time', () async {
      await controller.connectAndStart('dev1', 'Polar H10');

      heartRateService.emitHeartRate(140);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      controller.resetReadings();

      expect(controller.state.readings, isEmpty);
      expect(controller.state.elapsedSeconds, 0);
      expect(controller.state.isMonitoring, isTrue);
    });

    test('disconnectHeartRate clears all state', () async {
      await controller.connectAndStart('dev1', 'Polar H10');

      heartRateService.emitHeartRate(140);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await controller.disconnectHeartRate();

      expect(controller.state.hrConnected, isFalse);
      expect(controller.state.isMonitoring, isFalse);
      expect(controller.state.currentHeartRate, isNull);
      expect(controller.state.hrDeviceName, isNull);
      expect(controller.state.readings, isEmpty);
      expect(controller.state.elapsedSeconds, 0);
    });

    test('syncFromService picks up existing connection', () async {
      // Simulate cardio having connected the service already.
      await heartRateService.connectToDevice('dev1');

      controller.syncFromService();

      expect(controller.state.hrConnected, isTrue);
    });

    test('reconnecting state is surfaced from connection stream', () async {
      await controller.connectAndStart('dev1', 'Polar H10');

      heartRateService.emitConnectionState(HrConnectionState.reconnecting);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.hrReconnecting, isTrue);

      heartRateService.emitConnectionState(HrConnectionState.connected);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.hrReconnecting, isFalse);
      expect(controller.state.hrConnected, isTrue);
    });

    test('disconnected event from stream sets error', () async {
      await controller.connectAndStart('dev1', 'Polar H10');

      heartRateService.emitConnectionState(HrConnectionState.disconnected);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.state.hrConnected, isFalse);
      expect(controller.state.hrReconnecting, isFalse);
      expect(controller.state.error, isNotNull);
    });

    test('elapsed seconds increment while monitoring', () async {
      await controller.connectAndStart('dev1', 'Polar H10');
      expect(controller.state.isMonitoring, isTrue);

      await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 200));

      expect(controller.state.elapsedSeconds, greaterThanOrEqualTo(1));
      controller.stopMonitoring();
    });
  });
}
