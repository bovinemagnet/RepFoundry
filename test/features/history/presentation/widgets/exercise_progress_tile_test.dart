import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/exercises/presentation/providers/exercise_sparkline_provider.dart';
import 'package:rep_foundry/features/history/presentation/providers/trained_exercises_provider.dart';
import 'package:rep_foundry/features/history/presentation/widgets/exercise_progress_tile.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Exercise exerciseFor(String id, String name) => Exercise.create(
        name: name,
        category: ExerciseCategory.strength,
        muscleGroup: MuscleGroup.chest,
        equipmentType: EquipmentType.barbell,
      ).copyWith(id: id);

  ({Widget app, GoRouter router, List<String> visited}) buildHost({
    required TrainedExercise trained,
    List<double> sparklineData = const [],
  }) {
    final visited = <String>[];
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: ExerciseProgressTile(trainedExercise: trained),
          ),
        ),
        GoRoute(
          path: '/history/exercise/:id',
          builder: (_, state) {
            visited.add(state.uri.toString());
            return Scaffold(body: Text('Detail ${state.pathParameters['id']}'));
          },
        ),
      ],
    );

    return (
      app: ProviderScope(
        overrides: [
          exerciseSparklineProvider(trained.exercise.id)
              .overrideWith((ref) async => sparklineData),
        ],
        child: MaterialApp.router(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          routerConfig: router,
        ),
      ),
      router: router,
      visited: visited,
    );
  }

  group('ExerciseProgressTile', () {
    testWidgets('renders exercise name and "N sets logged" subtitle',
        (tester) async {
      final trained = TrainedExercise(
        exercise: exerciseFor('ex-1', 'Bench Press'),
        setCount: 24,
      );
      final scaffolding = buildHost(trained: trained);
      await tester.pumpWidget(scaffolding.app);
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('24 sets logged'), findsOneWidget);
    });

    testWidgets('tapping the tile pushes the exercise detail route',
        (tester) async {
      final trained = TrainedExercise(
        exercise: exerciseFor('ex-42', 'Row'),
        setCount: 5,
      );
      final scaffolding = buildHost(trained: trained);
      await tester.pumpWidget(scaffolding.app);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(scaffolding.visited, contains('/history/exercise/ex-42'));
      expect(find.text('Detail ex-42'), findsOneWidget);
    });
  });
}
