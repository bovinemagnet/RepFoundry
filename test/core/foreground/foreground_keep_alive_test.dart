import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/foreground/foreground_keep_alive.dart';

import '../../features/cardio/data/fake_foreground_session_service.dart';

void main() {
  late FakeForegroundSessionService service;
  late ForegroundKeepAlive keepAlive;

  setUp(() {
    service = FakeForegroundSessionService();
    keepAlive = ForegroundKeepAlive(service);
  });

  test('cardio alone drives the service as before', () async {
    await keepAlive.setCardio(
        sessionRunning: true, gpsEnabled: true, hrConnected: false);

    expect(service.last, (
      sessionRunning: true,
      gpsEnabled: true,
      hrConnected: false,
      coachActive: false
    ));
  });

  test('a monitoring heart-rate panel keeps the process alive on its own',
      () async {
    await keepAlive.setHeartRatePanel(monitoring: true, hrConnected: true);

    expect(service.last, (
      sessionRunning: true,
      gpsEnabled: false,
      hrConnected: true,
      coachActive: false
    ));
  });

  test('the panel stopping does not stop a running cardio session', () async {
    await keepAlive.setCardio(
        sessionRunning: true, gpsEnabled: false, hrConnected: true);
    await keepAlive.setHeartRatePanel(monitoring: true, hrConnected: true);

    await keepAlive.setHeartRatePanel(monitoring: false, hrConnected: false);

    expect(service.last?.sessionRunning, isTrue);
    expect(service.last?.hrConnected, isTrue);
  });

  test('cardio finishing does not stop a monitoring panel', () async {
    await keepAlive.setHeartRatePanel(monitoring: true, hrConnected: true);
    await keepAlive.setCardio(
        sessionRunning: true, gpsEnabled: true, hrConnected: true);

    await keepAlive.setCardio(
        sessionRunning: false, gpsEnabled: false, hrConnected: true);

    expect(service.last, (
      sessionRunning: true,
      gpsEnabled: false,
      hrConnected: true,
      coachActive: false
    ));
  });

  test('a panel that monitors without a strap asks for nothing', () async {
    await keepAlive.setHeartRatePanel(monitoring: true, hrConnected: false);

    expect(service.last?.sessionRunning, isFalse);
  });

  test('an active coach keeps the process alive on its own', () async {
    await keepAlive.setCoach(active: true);

    expect(service.last, (
      sessionRunning: true,
      gpsEnabled: false,
      hrConnected: false,
      coachActive: true,
    ));
  });

  test('the coach going quiet does not stop a running cardio session',
      () async {
    await keepAlive.setCardio(
        sessionRunning: true, gpsEnabled: true, hrConnected: false);
    await keepAlive.setCoach(active: true);

    await keepAlive.setCoach(active: false);

    expect(service.last, (
      sessionRunning: true,
      gpsEnabled: true,
      hrConnected: false,
      coachActive: false,
    ));
  });

  test('cardio finishing does not stop an active coach', () async {
    await keepAlive.setCoach(active: true);
    await keepAlive.setCardio(
        sessionRunning: true, gpsEnabled: true, hrConnected: false);

    await keepAlive.setCardio(
        sessionRunning: false, gpsEnabled: false, hrConnected: false);

    expect(service.last?.sessionRunning, isTrue);
    expect(service.last?.coachActive, isTrue);
  });

  test('the coach stopping releases the service when nothing else needs it',
      () async {
    await keepAlive.setCoach(active: true);
    await keepAlive.setCoach(active: false);

    expect(service.last?.sessionRunning, isFalse);
  });
}
