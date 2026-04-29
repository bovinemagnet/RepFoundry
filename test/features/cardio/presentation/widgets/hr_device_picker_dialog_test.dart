import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/cardio/data/heart_rate_service.dart';
import 'package:rep_foundry/features/cardio/presentation/widgets/hr_device_picker_dialog.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../data/fake_heart_rate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHost(FakeHeartRateService service) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showHrDevicePicker(
              context: context,
              heartRateService: service,
            ),
            child: const Text('Open picker'),
          ),
        ),
      ),
    );
  }

  group('HrDevicePickerDialog', () {
    late FakeHeartRateService service;

    tearDown(() {
      service.dispose();
    });

    testWidgets('shows the no-devices empty state with Scan Again help',
        (tester) async {
      service = FakeHeartRateService();
      await tester.pumpWidget(buildHost(service));
      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();

      expect(find.text('Heart Rate Monitors'), findsOneWidget);
      expect(
          find.textContaining('No heart rate monitors found'), findsOneWidget);
      expect(find.text('Scan Again'), findsOneWidget);
      expect(find.text('Setup Help'), findsOneWidget);
    });

    testWidgets('lists discovered devices when scan returns results',
        (tester) async {
      service = FakeHeartRateService(devicesToReturn: [
        const DiscoveredHrDevice(
          id: '00:11:22:33:44:55',
          name: 'Polar H10',
        ),
        const DiscoveredHrDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          name: 'Wahoo TICKR',
        ),
      ]);
      await tester.pumpWidget(buildHost(service));
      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();

      expect(find.text('Polar H10'), findsOneWidget);
      expect(find.text('Wahoo TICKR'), findsOneWidget);
      expect(find.text('00:11:22:33:44:55'), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth), findsNWidgets(2));
    });

    testWidgets('tapping a device returns it as the dialog result',
        (tester) async {
      service = FakeHeartRateService(devicesToReturn: [
        const DiscoveredHrDevice(id: 'id-1', name: 'Polar H10'),
      ]);

      DiscoveredHrDevice? picked;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                picked = await showHrDevicePicker(
                  context: context,
                  heartRateService: service,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Polar H10'));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.id, 'id-1');
      expect(picked!.name, 'Polar H10');
    });
  });
}
