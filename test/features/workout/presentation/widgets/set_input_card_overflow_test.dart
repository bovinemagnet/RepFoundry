import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/workout/presentation/widgets/set_input_card.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

/// Phone-width layout guard for [SetInputCard]'s action row.
///
/// **This test lives alone in its own file on purpose.** Flutter lays a
/// widget out differently the second time the same overflowing `RenderFlex`
/// is built in one test run: the first build reports the true offset (LOG SET
/// at x=521.8 against 393pt available) and throws; every later build in the
/// same file reports the clamped 393.0 and throws nothing. A layout guard
/// sharing a file with other tests therefore passes or fails according to its
/// position rather than according to the layout, which is worse than having
/// no guard at all.
///
/// The bug this protects against: the action row carries "+ ADD RPE", the
/// "WARM-UP" pill, "+ ADD WARM-UP" and the LOG SET call-to-action. Those need
/// 522pt. Every phone we support gives it less — an iPhone 16 Pro gives 393pt
/// — so LOG SET, the primary action of the whole app, was clipped off the
/// right edge and painted underneath the "Add Exercise" floating button.
///
/// It survived because every other widget test runs on the default 800x600
/// test surface, which is wider than any phone we ship to. It was found by a
/// screenshot taken for the user documentation, not by this suite.
void main() {
  testWidgets(
      'the action row fits a 393pt phone when a warm-up ramp is offered',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SetInputCard(
            onLogSet: ({
              required double weight,
              required int reps,
              double? rpe,
              bool isWarmUp = false,
            }) {},
            // A non-null callback is what adds "+ ADD WARM-UP" to the row.
            // It is supplied for every warm-up-rampable exercise — which is
            // every barbell lift — so this is the common case, not an edge.
            onAddWarmup: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    // Belt and braces: the exception above proves the row overflowed, this
    // proves the button a user must reach is actually on the screen.
    final logSet = find.text('LOG SET');
    expect(logSet, findsOneWidget);
    expect(
      tester.getBottomRight(logSet).dx,
      lessThanOrEqualTo(393.0),
      reason: 'LOG SET is clipped off the right edge of a 393pt phone',
    );
  });
}
