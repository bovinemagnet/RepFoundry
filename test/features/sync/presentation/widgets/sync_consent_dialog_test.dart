import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/sync/presentation/widgets/sync_consent_dialog.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  Widget buildHost(Future<bool> Function(BuildContext context) onPressed) {
    bool? lastResult;
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  lastResult = await onPressed(context);
                },
                child: const Text('Open'),
              ),
              if (lastResult != null) Text('Result: $lastResult'),
            ],
          ),
        ),
      ),
    );
  }

  group('SyncConsentDialog', () {
    testWidgets('shows title, body and both action buttons', (tester) async {
      await tester.pumpWidget(buildHost(SyncConsentDialog.show));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Cross-Device Sync'), findsOneWidget);
      expect(find.textContaining('Google Drive'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('I Understand — Continue'), findsOneWidget);
    });

    testWidgets('Accept resolves the future to true', (tester) async {
      late Future<bool> consentFuture;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => consentFuture = SyncConsentDialog.show(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('I Understand — Continue'));
      await tester.pumpAndSettle();

      expect(await consentFuture, isTrue);
    });

    testWidgets('Cancel resolves the future to false', (tester) async {
      late Future<bool> consentFuture;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => consentFuture = SyncConsentDialog.show(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await consentFuture, isFalse);
    });

    testWidgets('barrier is not dismissible', (tester) async {
      late Future<bool> consentFuture;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => consentFuture = SyncConsentDialog.show(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tapping outside the dialog should NOT dismiss it.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Close it cleanly so the future settles.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await consentFuture, isFalse);
    });
  });
}
