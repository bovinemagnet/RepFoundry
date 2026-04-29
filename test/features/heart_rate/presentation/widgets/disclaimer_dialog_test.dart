import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/domain/analytics_events.dart';
import 'package:rep_foundry/features/heart_rate/presentation/widgets/disclaimer_dialog.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAnalyticsReporter implements HrAnalyticsReporter {
  final events = <(HrAnalyticsEvent, Map<String, Object>?)>[];

  @override
  void trackEvent(HrAnalyticsEvent event, [Map<String, Object>? properties]) {
    events.add((event, properties));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHost({
    HrAnalyticsReporter? analytics,
    Future<bool> Function(BuildContext context)? onPressed,
  }) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              await (onPressed ??
                  (ctx) => showDisclaimerIfNeeded(
                        ctx,
                        analytics: analytics,
                      ))(context);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('showDisclaimerIfNeeded', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows the dialog the first time it is invoked',
        (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Heart Rate Monitoring'), findsOneWidget);
      expect(find.text('I understand'), findsOneWidget);
      expect(
        find.textContaining('informational purposes only'),
        findsOneWidget,
      );
    });

    testWidgets('persists shown=true after acknowledgement', (tester) async {
      await tester.pumpWidget(buildHost());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hr_disclaimer_shown'), isTrue);
    });

    testWidgets('reports analytics event on first acknowledgement',
        (tester) async {
      final analytics = _RecordingAnalyticsReporter();
      await tester.pumpWidget(buildHost(analytics: analytics));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();

      final warnings = analytics.events
          .where((e) => e.$1 == HrAnalyticsEvent.warningDisplayed)
          .toList();
      expect(warnings, hasLength(1));
      expect(warnings.first.$2?['type'], 'disclaimer');
    });

    testWidgets('does not show the dialog if it was already acknowledged',
        (tester) async {
      SharedPreferences.setMockInitialValues({'hr_disclaimer_shown': true});

      await tester.pumpWidget(buildHost());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Heart Rate Monitoring'), findsNothing);
      expect(find.text('I understand'), findsNothing);
    });
  });
}
