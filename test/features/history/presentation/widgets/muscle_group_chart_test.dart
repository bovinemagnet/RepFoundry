import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/presentation/providers/muscle_group_distribution_provider.dart';
import 'package:rep_foundry/features/history/presentation/widgets/muscle_group_chart.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHost(List<MuscleGroupVolume> data) {
    return ProviderScope(
      overrides: [
        muscleGroupDistributionProvider.overrideWith((ref) async => data),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: MuscleGroupChart()),
      ),
    );
  }

  group('MuscleGroupChart', () {
    testWidgets('renders nothing when distribution data is empty',
        (tester) async {
      await tester.pumpWidget(buildHost(const []));
      await tester.pumpAndSettle();

      expect(find.text('Muscle Group Distribution'), findsNothing);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('renders the title and a BarChart when data is present',
        (tester) async {
      await tester.pumpWidget(buildHost(const [
        MuscleGroupVolume(group: MuscleGroup.chest, volume: 1500),
        MuscleGroupVolume(group: MuscleGroup.back, volume: 1200),
        MuscleGroupVolume(group: MuscleGroup.quadriceps, volume: 1800),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Muscle Group Distribution'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);

      final chart = tester.widget<BarChart>(find.byType(BarChart));
      // maxY = max volume * 1.1 = 1800 * 1.1 = 1980.
      expect(chart.data.maxY, closeTo(1980, 0.001));
      // One BarChartGroupData per data point.
      expect(chart.data.barGroups, hasLength(3));
    });
  });
}
