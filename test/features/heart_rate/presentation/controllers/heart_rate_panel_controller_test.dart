import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/data/heart_rate_service.dart';
import 'package:rep_foundry/features/heart_rate/presentation/controllers/heart_rate_panel_controller.dart';
import 'package:rep_foundry/core/providers.dart';

import '../../../cardio/data/fake_heart_rate_service.dart';

void main() {
  late FakeHeartRateService heartRateService;
  late ProviderContainer container;

  HeartRatePanelController ctrl() =>
      container.read(heartRatePanelProvider.notifier);

  setUp(() {
    heartRateService = FakeHeartRateService();
    container = ProviderContainer(
      overrides: [
        heartRateServiceProvider.overrideWithValue(heartRateService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    heartRateService.dispose();
  });

  group('HeartRatePanelController', () {
    test('initial state is not monitoring and not connected', () {
      expect(ctrl().state.isMonitoring, isFalse);
      expect(ctrl().state.hrConnected, isFalse);
      expect(ctrl().state.readings, isEmpty);
      expect(ctrl().state.elapsedSeconds, 0);
    });

    test('connectAndStart connects and starts monitoring', () async {
      await ctrl().connectAndStart('dev1', 'Polar H10');

      expect(ctrl().state.hrConnected, isTrue);
      expect(ctrl().state.hrConnecting, isFalse);
      expect(ctrl().state.hrDeviceName, 'Polar H10');
      expect(ctrl().state.isMonitoring, isTrue);
    });

    test('connectAndStart sets error on failure', () async {
      heartRateService.shouldThrowOnConnect = true;

      await ctrl().connectAndStart('dev1', 'Polar H10');

      expect(ctrl().state.hrConnected, isFalse);
      expect(ctrl().state.hrConnecting, isFalse);
      expect(ctrl().state.error, isNotNull);
      expect(ctrl().state.isMonitoring, isFalse);
    });

    test('HR stream appends timestamped readings', () async {
      await ctrl().connectAndStart('dev1', 'Polar H10');

      heartRateService.emitHeartRate(140);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(ctrl().state.currentHeartRate, 140);
      expect(ctrl().state.readings, hasLength(1));
      expect(ctrl().state.readings.first.bpm, 140);

      heartRateService.emitHeartRate(145);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(ctrl().state.currentHeartRate, 145);
      expect(ctrl().state.readings, hasLength(2));
    });

    test('startMonitoring is idempotent', () async {
      await ctrl().connectAndStart('dev1', 'Polar H10');
      ctrl().startMonitoring();
      expect(ctrl().state.isMonitoring, isTrue);
    });

    test('stopMonitoring pauses without disconnecting', () async {
      await ctrl().connectAndStart('dev1', 'Polar H10');
      ctrl().stopMonitoring();

      expect(ctrl().state.isMonitoring, isFalse);
      expect(ctrl().state.hrConnected, isTrue);
    });

    test('resetReadings clears readings and elapsed time', () async {
      await ctrl().connectAndStart('dev1', 'Polar H10');

      heartRateService.emitHeartRate(140);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      ctrl().resetReadings();

      expect(ctrl().state.readings, isEmpty);
      expect(ctrl().state.elapsedSeconds, 0);
      expect(ctrl().state.isMonitoring, isTrue);
    });

    test('disconnectHeartRate clears all state', () async {
      await ctrl().connectAndStart('dev1', 'Polar H10');

      heartRateService.emitHeartRate(140);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await ctrl().disconnectHeartRate();

      expect(ctrl().state.hrConnected, isFalse);
      expect(ctrl().state.isMonitoring, isFalse);
      expect(ctrl().state.currentHeartRate, isNull);
      expect(ctrl().state.hrDeviceName, isNull);
      expect(ctrl().state.readings, isEmpty);
      expect(ctrl().state.elapsedSeconds, 0);
    });

    test('syncFromService picks up existing connection', () async {
      // Simulate cardio having connected the service already.
      await heartRateService.connectToDevice('dev1');

      ctrl().syncFromService();

      expect(ctrl().state.hrConnected, isTrue);
    });

    test('reconnecting state is surfaced from connection stream', () async {
      await ctrl().connectAndStart('dev1', 'Polar H10');

      heartRateService.emitConnectionState(HrConnectionState.reconnecting);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(ctrl().state.hrReconnecting, isTrue);

      heartRateService.emitConnectionState(HrConnectionState.connected);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(ctrl().state.hrReconnecting, isFalse);
      expect(ctrl().state.hrConnected, isTrue);
    });

    test('disconnected event from stream sets error', () async {
      await ctrl().connectAndStart('dev1', 'Polar H10');

      heartRateService.emitConnectionState(HrConnectionState.disconnected);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(ctrl().state.hrConnected, isFalse);
      expect(ctrl().state.hrReconnecting, isFalse);
      expect(ctrl().state.error, isNotNull);
    });

    test('elapsed seconds increment while monitoring', () async {
      await ctrl().connectAndStart('dev1', 'Polar H10');
      expect(ctrl().state.isMonitoring, isTrue);

      await Future<void>.delayed(
          const Duration(seconds: 1, milliseconds: 200));

      expect(ctrl().state.elapsedSeconds, greaterThanOrEqualTo(1));
      ctrl().stopMonitoring();
    });
  });
}
