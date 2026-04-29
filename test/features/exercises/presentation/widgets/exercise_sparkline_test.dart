import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/core/widgets/sparkline_widget.dart';
import 'package:rep_foundry/features/exercises/presentation/providers/exercise_sparkline_provider.dart';
import 'package:rep_foundry/features/exercises/presentation/widgets/exercise_sparkline.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHost({required List<double> data, required String exerciseId}) {
    return ProviderScope(
      overrides: [
        exerciseSparklineProvider(exerciseId).overrideWith((ref) async => data),
      ],
      child: MaterialApp(
        home: Scaffold(body: ExerciseSparkline(exerciseId: exerciseId)),
      ),
    );
  }

  group('ExerciseSparkline', () {
    testWidgets('renders nothing when the provider returns an empty list',
        (tester) async {
      await tester.pumpWidget(buildHost(data: const [], exerciseId: 'ex-1'));
      await tester.pumpAndSettle();

      expect(find.byType(SparklineWidget), findsNothing);
    });

    testWidgets('renders a 60×30 SparklineWidget when data is present',
        (tester) async {
      await tester.pumpWidget(
        buildHost(data: const [80, 82.5, 85], exerciseId: 'ex-2'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SparklineWidget), findsOneWidget);
      final sized = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(SparklineWidget),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sized.width, 60);
      expect(sized.height, 30);
    });
  });
}
