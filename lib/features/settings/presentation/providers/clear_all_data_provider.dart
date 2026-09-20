import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/entitlements/entitlement_provider.dart';
import '../../../../core/units/weight_unit_provider.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';
import '../../../health_sync/presentation/providers/health_sync_settings_provider.dart';
import '../../../heart_rate/presentation/providers/chart_window_provider.dart';
import '../../../heart_rate/presentation/providers/heart_rate_panel_visibility_provider.dart';
import '../../../heart_rate/presentation/providers/max_hr_alert_provider.dart';
import '../../../heart_rate/presentation/providers/zone_bands_provider.dart';
import '../../../notifications/presentation/providers/reminder_settings_provider.dart';
import '../../../sync/presentation/providers/sync_settings_provider.dart';
import '../../../trainer/presentation/providers/trainer_settings_provider.dart';
import '../../../workout/presentation/controllers/active_workout_controller.dart';
import 'layout_mode_provider.dart';
import 'rest_timer_settings_provider.dart';
import 'show_exercise_images_provider.dart';
import 'theme_mode_provider.dart';

/// Wipes the database and SharedPreferences, then rebuilds every provider
/// whose in-memory state was derived from them. Without the rebuild the app
/// keeps referencing the deleted active client and in-progress workout, and
/// the next write fails its foreign key.
final clearAllDataProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(databaseProvider).clearAllData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    ref.invalidate(activeClientProvider);
    ref.invalidate(activeWorkoutControllerProvider);

    ref.invalidate(unlockedEntitlementsProvider);
    ref.invalidate(weightUnitProvider);
    ref.invalidate(healthSyncSettingsProvider);
    ref.invalidate(chartWindowProvider);
    ref.invalidate(heartRatePanelVisibleProvider);
    ref.invalidate(maxHrAlertProvider);
    ref.invalidate(zoneBandsProvider);
    ref.invalidate(reminderSettingsProvider);
    ref.invalidate(syncSettingsProvider);
    ref.invalidate(trainerSettingsProvider);
    ref.invalidate(layoutModeProvider);
    ref.invalidate(restTimerSettingsProvider);
    ref.invalidate(showExerciseImagesProvider);
    ref.invalidate(themeModeProvider);
  };
});
