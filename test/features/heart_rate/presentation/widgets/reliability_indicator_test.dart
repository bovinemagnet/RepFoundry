import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/features/heart_rate/presentation/widgets/reliability_indicator.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  ZoneConfiguration buildConfig(ZoneReliability reliability) {
    return ZoneConfiguration(
      zones: const [
        CalculatedZone(
          zoneNumber: 1,
          label: 'Zone 1',
          effortLabel: 'Easy',
          descriptiveLabel: 'Recovery',
          lowerBound: 90,
          upperBound: 108,
          color: 0xFF4FC3F7,
        ),
      ],
      method: ZoneMethod.percentOfEstimatedMax,
      reliability: reliability,
      maxHr: 180,
      reason: 'Test reason',
    );
  }

  Widget buildHost(ZoneConfiguration config) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: ReliabilityIndicator(config: config)),
    );
  }

  group('ReliabilityIndicator', () {
    testWidgets('renders verified icon and "High" label for high reliability',
        (tester) async {
      await tester.pumpWidget(buildHost(buildConfig(ZoneReliability.high)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.text('High confidence'), findsOneWidget);
    });

    testWidgets('renders info icon and "Medium" label for medium reliability',
        (tester) async {
      await tester.pumpWidget(buildHost(buildConfig(ZoneReliability.medium)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Medium confidence'), findsOneWidget);
    });

    testWidgets('renders warning icon and "Low" label for low reliability',
        (tester) async {
      await tester.pumpWidget(buildHost(buildConfig(ZoneReliability.low)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_outlined), findsOneWidget);
      expect(find.text('Low confidence'), findsOneWidget);
    });

    testWidgets('exposes the reason via a Tooltip', (tester) async {
      const reason = 'Estimated from age (Tanaka).';
      const config = ZoneConfiguration(
        zones: [
          CalculatedZone(
            zoneNumber: 1,
            label: 'Zone 1',
            effortLabel: 'Easy',
            descriptiveLabel: 'Recovery',
            lowerBound: 90,
            upperBound: 108,
            color: 0xFF4FC3F7,
          ),
        ],
        method: ZoneMethod.percentOfEstimatedMax,
        reliability: ZoneReliability.medium,
        maxHr: 180,
        reason: reason,
      );

      await tester.pumpWidget(buildHost(config));
      await tester.pumpAndSettle();

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, reason);
    });
  });
}
