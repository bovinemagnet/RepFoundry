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
import '../features/trainer/presentation/providers/hr_event_source.dart';
import '../features/trainer/presentation/screens/trainer_settings_screen.dart';
import '../core/entitlements/entitlement.dart';
import '../core/entitlements/entitlement_provider.dart';
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
            // `coachBridgeProvider` is a single non-family instance; pushing
            // the localisations instance in via the setter on every build
            // (rather than keying the provider on it) means a locale change
            // updates the existing subscription instead of leaking a second,
            // still-listening bridge.
            ref.read(coachBridgeProvider).strings = S.of(context)!;
            // Mounted alongside the bridge, for the same reason and with
            // the same non-family Provider shape: it turns heart-rate
            // readings into trainer events for the life of the app shell,
            // regardless of which tab is active, and reading it again on
            // rebuild returns the same instance rather than leaking a
            // second, still-subscribed source (see hrEventSourceProvider's
            // lifecycle tests).
            ref.read(hrEventSourceProvider);
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
                // The settings tile is entitlement-gated, but the route must
                // be too: a deep link or a restored location would otherwise
                // reach the screen without the entitlement being held.
                redirect: (context, state) {
                  final entitled = ref
                      .read(entitlementServiceProvider)
                      .has(Entitlement.virtualTrainer);
                  return entitled ? null : '/settings';
                },
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
