import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../features/body_metrics/presentation/screens/body_metrics_screen.dart';
import '../features/workout/presentation/screens/active_workout_screen.dart';
import '../features/history/presentation/screens/history_list_screen.dart';
import '../features/history/presentation/screens/workout_detail_screen.dart';
import '../features/history/presentation/screens/exercise_progress_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/about_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/templates/presentation/screens/template_list_screen.dart';
import '../features/templates/presentation/screens/template_edit_screen.dart';
import '../features/exercises/presentation/screens/exercise_picker_screen.dart';
import '../features/cardio/presentation/screens/cardio_tracking_screen.dart';
import '../features/heart_rate/presentation/screens/heart_rate_panel_screen.dart';
import '../features/history/presentation/screens/pr_history_screen.dart';
import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/programmes/presentation/screens/programme_list_screen.dart';
import '../features/programmes/presentation/screens/programme_edit_screen.dart';
import '../features/clients/presentation/screens/client_roster_screen.dart';
import '../features/clients/presentation/widgets/client_switcher.dart';
import '../features/clients/presentation/screens/client_detail_screen.dart';
import '../features/trainer/presentation/providers/coach_bridge.dart';
import '../features/trainer/presentation/screens/trainer_settings_screen.dart';
import '../core/widgets/scaffold_with_nav_bar.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/workout',
    routes: [
      // Primary destinations live inside the adaptive nav shell so the desktop
      // side-rail stays visible across all of them. On mobile only the five
      // core tabs surface the bottom nav (see [ScaffoldWithNavBar]); the others
      // keep their original full-screen presentation.
      ShellRoute(
        builder: (context, state, child) => Consumer(
          builder: (context, ref, _) {
            // Keeps the coach alive for the life of the app shell, so it
            // hears every trainer event regardless of which tab is active.
            ref.watch(coachBridgeProvider(S.of(context)!));
            return ScaffoldWithNavBar(
              railFooter: const ClientSwitcher(),
              child: child,
            );
          },
        ),
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
            path: '/heart-rate',
            builder: (context, state) => const HeartRatePanelScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/templates',
            builder: (context, state) => const TemplateListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => TemplateEditScreen(
                  templateId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/programmes',
            builder: (context, state) => const ProgrammeListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ProgrammeEditScreen(
                  programmeId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientRosterScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ClientDetailScreen(
                  clientId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'about',
                builder: (context, state) => const AboutScreen(),
              ),
              GoRoute(
                path: 'notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: 'trainer',
                builder: (context, state) => const TrainerSettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Deep / contextual routes that sit outside the nav shell.
      GoRoute(
        path: '/exercises',
        builder: (context, state) => const ExercisePickerScreen(),
      ),
      GoRoute(
        path: '/pr-history',
        builder: (context, state) => const PrHistoryScreen(),
      ),
      GoRoute(
        path: '/history/exercise/:id',
        builder: (context, state) => ExerciseProgressScreen(
          exerciseId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/body-metrics',
        builder: (context, state) => const BodyMetricsScreen(),
      ),
    ],
  );
});
