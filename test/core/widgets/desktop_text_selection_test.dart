import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/desktop_text_selection.dart';

void main() {
  testWidgets('wraps child in SelectionArea on desktop', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    try {
      await tester.pumpWidget(const MaterialApp(
        home: DesktopTextSelection(child: Text('workout notes')),
      ));

      expect(find.byType(SelectionArea), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('passes child through untouched on mobile', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    try {
      await tester.pumpWidget(const MaterialApp(
        home: DesktopTextSelection(child: Text('workout notes')),
      ));

      expect(find.byType(SelectionArea), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
