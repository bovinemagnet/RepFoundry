import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/app/theme.dart';
import 'package:rep_foundry/core/widgets/kinetic.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  group('Kinetic component library', () {
    testWidgets('atoms render together without error', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              KineticAppHeader(),
              KineticEyebrow('No active session'),
              KineticSectionLabel('Or start from'),
              KineticPill('In progress'),
              KineticPill('PR target', variant: KineticPillVariant.volt),
              KineticStatTile(label: 'Duration', value: '42', unit: 'min'),
              KineticCta(label: 'Complete Workout', icon: Icons.bolt),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('eyebrow and section label render uppercased text',
        (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              KineticEyebrow('No active session'),
              KineticSectionLabel('Or start from'),
            ],
          ),
        ),
      );

      expect(find.text('NO ACTIVE SESSION'), findsOneWidget);
      expect(find.text('OR START FROM'), findsOneWidget);
    });

    testWidgets('stat tile shows label, value and unit', (tester) async {
      await tester.pumpWidget(
        host(
          const KineticStatTile(label: 'Duration', value: '42', unit: 'min'),
        ),
      );

      expect(find.text('DURATION'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('min'), findsOneWidget);
    });

    testWidgets('pill renders an uppercased label and icon', (tester) async {
      await tester.pumpWidget(
        host(const KineticPill('In progress', icon: Icons.trending_up)),
      );

      expect(find.text('IN PROGRESS'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('app header shows the bolt logo and notification button',
        (tester) async {
      await tester.pumpWidget(host(const KineticAppHeader()));

      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('CTA fires onPressed when tapped', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        host(
          KineticCta(
            label: 'Log Set',
            icon: Icons.add,
            onPressed: () => tapped++,
          ),
        ),
      );

      expect(find.text('LOG SET'), findsOneWidget);
      await tester.tap(find.byType(KineticCta));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('CTA with a null callback is inert (no crash)', (tester) async {
      await tester.pumpWidget(host(const KineticCta(label: 'Disabled')));

      await tester.tap(find.byType(KineticCta));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in the light scheme too', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: KineticStatTile(label: 'Volume', value: '12,450', unit: 'kg'),
          ),
        ),
      );

      expect(find.text('12,450'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
