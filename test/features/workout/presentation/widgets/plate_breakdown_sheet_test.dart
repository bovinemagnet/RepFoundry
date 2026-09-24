import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/units/weight_unit.dart';
import 'package:rep_foundry/features/workout/presentation/widgets/plate_breakdown_sheet.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required double workingKg,
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues({'weight_unit': 'kg', ...prefs});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(body: PlateBreakdownSheet(workingKg: workingKg)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists the plates for each side', (tester) async {
    await pumpSheet(tester, workingKg: 140);

    expect(find.text('25kg × 2'), findsOneWidget);
    expect(find.text('10kg × 1'), findsOneWidget);
    expect(find.text('140kg · bar 20kg'), findsOneWidget);
  });

  testWidgets('works in pounds from a stored kg weight', (tester) async {
    // 155 lb is stored as 70.307… kg, which converts back to 154.99999…
    // The sheet must not lose that sliver and fall back to smaller plates.
    await pumpSheet(
      tester,
      workingKg: WeightUnit.lbs.toKg(155),
      prefs: {'weight_unit': 'lbs'},
    );

    expect(find.text('155lbs · bar 45lbs'), findsOneWidget);
    expect(find.text('45lbs × 1'), findsOneWidget);
    expect(find.text('10lbs × 1'), findsOneWidget);
    expect(find.textContaining('short'), findsNothing);
  });

  testWidgets('uses the bar weight chosen in settings', (tester) async {
    await pumpSheet(tester, workingKg: 65, prefs: {'plate_bar_kg': 15.0});

    expect(find.text('65kg · bar 15kg'), findsOneWidget);
    expect(find.text('25kg × 1'), findsOneWidget);
  });

  testWidgets('uses the plate sizes chosen in settings', (tester) async {
    await pumpSheet(
      tester,
      workingKg: 100,
      prefs: {
        'plate_sizes_kg': ['15', '10', '5'],
      },
    );

    expect(find.text('15kg × 2'), findsOneWidget);
    expect(find.text('10kg × 1'), findsOneWidget);
  });

  testWidgets('shows plate sizes with two decimals when needed',
      (tester) async {
    await pumpSheet(tester, workingKg: 22.5);

    expect(find.text('1.25kg × 1'), findsOneWidget);
  });

  testWidgets('says how far short the closest load is', (tester) async {
    await pumpSheet(tester, workingKg: 101);

    expect(
      find.text('Closest you can load: 100kg (1kg short)'),
      findsOneWidget,
    );
  });

  testWidgets('an exact load shows no shortfall', (tester) async {
    await pumpSheet(tester, workingKg: 100);

    expect(find.textContaining('Closest'), findsNothing);
  });

  testWidgets('the empty bar reads as just the bar', (tester) async {
    await pumpSheet(tester, workingKg: 20);

    expect(find.text('Just the bar'), findsOneWidget);
  });

  testWidgets('a weight lighter than the bar is called out', (tester) async {
    await pumpSheet(tester, workingKg: 15);

    expect(find.text('Lighter than the 20kg bar'), findsOneWidget);
    expect(find.text('Just the bar'), findsNothing);
  });
}
