import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/domain/analytics_events.dart';
import 'package:rep_foundry/features/heart_rate/presentation/widgets/symptom_report_button.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

class _RecordingAnalyticsReporter implements HrAnalyticsReporter {
  final events = <(HrAnalyticsEvent, Map<String, Object>?)>[];

  @override
  void trackEvent(HrAnalyticsEvent event, [Map<String, Object>? properties]) {
    events.add((event, properties));
  }
}

void main() {
  group('SymptomReportButton', () {
    Widget buildHost({
      required VoidCallback onStopRequested,
      HrAnalyticsReporter? analytics,
    }) {
      return MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SymptomReportButton(
            onStopRequested: onStopRequested,
            analytics: analytics,
          ),
        ),
      );
    }

    testWidgets('renders the labelled outlined button', (tester) async {
      await tester.pumpWidget(buildHost(onStopRequested: () {}));
      await tester.pumpAndSettle();

      expect(find.text('Report Symptom'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('tapping the button opens the symptom dialog with all options',
        (tester) async {
      await tester.pumpWidget(buildHost(onStopRequested: () {}));
      await tester.tap(find.text('Report Symptom'));
      await tester.pumpAndSettle();

      expect(find.text('Symptom Report'), findsOneWidget);
      expect(find.text('Chest pain or tightness'), findsOneWidget);
      expect(find.text('Severe dizziness or light-headedness'), findsOneWidget);
      expect(find.text('Feeling faint or about to faint'), findsOneWidget);
      expect(find.text('Unusual shortness of breath'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel closes the dialog without invoking onStopRequested',
        (tester) async {
      var stopCalls = 0;
      await tester.pumpWidget(
        buildHost(onStopRequested: () => stopCalls++),
      );

      await tester.tap(find.text('Report Symptom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Symptom Report'), findsNothing);
      expect(stopCalls, 0);
    });

    testWidgets(
        'choosing a symptom invokes onStopRequested and shows the stop dialog',
        (tester) async {
      var stopCalls = 0;
      await tester.pumpWidget(
        buildHost(onStopRequested: () => stopCalls++),
      );

      await tester.tap(find.text('Report Symptom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chest pain or tightness'));
      await tester.pumpAndSettle();

      expect(stopCalls, 1);
      expect(find.text('Stop Exercise'), findsOneWidget);
      expect(find.byIcon(Icons.emergency), findsOneWidget);
      expect(find.textContaining('chest pain'), findsOneWidget);
    });

    testWidgets('reports analytics event with the chosen symptom',
        (tester) async {
      final analytics = _RecordingAnalyticsReporter();
      await tester.pumpWidget(
        buildHost(onStopRequested: () {}, analytics: analytics),
      );

      await tester.tap(find.text('Report Symptom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Severe dizziness or light-headedness'));
      await tester.pumpAndSettle();

      final warnings = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.warningDisplayed)
          .toList();
      expect(warnings, hasLength(1));
      expect(warnings.first.$2?['type'], 'symptom_report');
      expect(warnings.first.$2?['symptom'],
          'Severe dizziness or light-headedness');
    });
  });
}
