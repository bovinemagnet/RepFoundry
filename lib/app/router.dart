import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/workout/presentation/screens/active_workout_screen.dart';
import '../features/history/presentation/screens/history_list_screen.dart';
import '../features/history/presentation/screens/workout_detail_screen.dart';
import '../features/history/presentation/screens/exercise_progress_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/templates/presentation/screens/template_list_screen.dart';
import '../features/exercises/presentation/screens/exercise_picker_screen.dart';
import '../features/cardio/presentation/screens/cardio_tracking_screen.dart';
import '../core/widgets/scaffold_with_nav_bar.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/workout',
    routes: [
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/workout',
            builder: (context, state) => const ActiveWorkoutScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => WorkoutDetailScreen(
                  workoutId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/cardio',
            builder: (context, state) => const CardioTrackingScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/templates',
        builder: (context, state) => const TemplateListScreen(),
      ),
      GoRoute(
        path: '/exercises',
        builder: (context, state) => const ExercisePickerScreen(),
      ),
      GoRoute(
        path: '/history/exercise/:id',
        builder: (context, state) => ExerciseProgressScreen(
          exerciseId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
