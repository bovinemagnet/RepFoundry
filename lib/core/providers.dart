import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/database_provider.dart';
import '../features/body_metrics/data/drift_body_metric_repository.dart';
import '../features/body_metrics/domain/models/body_metric.dart';
import '../features/body_metrics/domain/repositories/body_metric_repository.dart';
import '../features/exercises/data/drift_exercise_repository.dart';
import '../features/exercises/domain/repositories/exercise_repository.dart';
import '../features/workout/data/drift_workout_repository.dart';
import '../features/workout/domain/repositories/workout_repository.dart';
import '../features/workout/application/log_set_use_case.dart';
import '../features/workout/application/start_workout_use_case.dart';
import '../features/history/application/calculate_progress_use_case.dart';
import '../features/settings/application/export_data_use_case.dart';
import '../features/settings/application/import_data_use_case.dart';
import '../features/cardio/data/drift_cardio_session_repository.dart';
import '../features/cardio/data/flutter_blue_heart_rate_service.dart';
import '../features/cardio/data/heart_rate_service.dart';
import '../features/cardio/data/location_service.dart';
import '../features/cardio/domain/repositories/cardio_session_repository.dart';
import '../features/cardio/application/save_cardio_session_use_case.dart';
import '../features/health_sync/data/health_sync_service.dart';
import '../features/heart_rate/data/noop_analytics_reporter.dart';
import '../features/heart_rate/domain/analytics_events.dart';
import '../features/history/data/drift_personal_record_repository.dart';
import '../features/history/domain/repositories/personal_record_repository.dart';
import '../features/templates/data/drift_workout_template_repository.dart';
import '../features/templates/domain/repositories/workout_template_repository.dart';
import '../features/programmes/data/drift_programme_repository.dart';
import '../features/programmes/domain/repositories/programme_repository.dart';
import '../features/sync/application/sync_orchestrator.dart';
import '../features/sync/data/sync_service_factory.dart';
import '../features/sync/presentation/providers/sync_settings_provider.dart';

// Repositories
final bodyMetricRepositoryProvider = Provider<BodyMetricRepository>((ref) {
  return DriftBodyMetricRepository(ref.watch(databaseProvider));
});

final bodyMetricsStreamProvider =
    StreamProvider.autoDispose<List<BodyMetric>>((ref) {
  return ref.watch(bodyMetricRepositoryProvider).watchAll();
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return DriftExerciseRepository(ref.watch(databaseProvider));
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return DriftWorkoutRepository(ref.watch(databaseProvider));
});

final cardioSessionRepositoryProvider =
    Provider<CardioSessionRepository>((ref) {
  return DriftCardioSessionRepository(ref.watch(databaseProvider));
});

final personalRecordRepositoryProvider =
    Provider<PersonalRecordRepository>((ref) {
  return DriftPersonalRecordRepository(ref.watch(databaseProvider));
});

final workoutTemplateRepositoryProvider =
    Provider<WorkoutTemplateRepository>((ref) {
  return DriftWorkoutTemplateRepository(ref.watch(databaseProvider));
});

final programmeRepositoryProvider = Provider<ProgrammeRepository>((ref) {
  return DriftProgrammeRepository(ref.watch(databaseProvider));
});

// Services
final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationService();
});

final heartRateServiceProvider = Provider<HeartRateService>((ref) {
  return FlutterBlueHeartRateService();
});

final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
  return HealthSyncService();
});

final hrAnalyticsReporterProvider = Provider<HrAnalyticsReporter>((ref) {
  return NoopAnalyticsReporter();
});

// Use cases
final logSetUseCaseProvider = Provider<LogSetUseCase>((ref) {
  return LogSetUseCase(
    workoutRepository: ref.watch(workoutRepositoryProvider),
    personalRecordRepository: ref.watch(personalRecordRepositoryProvider),
  );
});

final startWorkoutUseCaseProvider = Provider<StartWorkoutUseCase>((ref) {
  return StartWorkoutUseCase(
    workoutRepository: ref.watch(workoutRepositoryProvider),
  );
});

final saveCardioSessionUseCaseProvider =
    Provider<SaveCardioSessionUseCase>((ref) {
  return SaveCardioSessionUseCase(
    cardioRepository: ref.watch(cardioSessionRepositoryProvider),
    workoutRepository: ref.watch(workoutRepositoryProvider),
  );
});

final calculateProgressUseCaseProvider =
    Provider<CalculateProgressUseCase>((ref) {
  return CalculateProgressUseCase(
    workoutRepository: ref.watch(workoutRepositoryProvider),
  );
});

final exportDataUseCaseProvider = Provider<ExportDataUseCase>((ref) {
  return ExportDataUseCase(
    workoutRepository: ref.watch(workoutRepositoryProvider),
    exerciseRepository: ref.watch(exerciseRepositoryProvider),
    cardioSessionRepository: ref.watch(cardioSessionRepositoryProvider),
    personalRecordRepository: ref.watch(personalRecordRepositoryProvider),
  );
});

final importDataUseCaseProvider = Provider<ImportDataUseCase>((ref) {
  return ImportDataUseCase(
    workoutRepository: ref.watch(workoutRepositoryProvider),
    exerciseRepository: ref.watch(exerciseRepositoryProvider),
    cardioSessionRepository: ref.watch(cardioSessionRepositoryProvider),
    personalRecordRepository: ref.watch(personalRecordRepositoryProvider),
  );
});

// Sync
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  final settings = ref.watch(syncSettingsProvider);
  return SyncOrchestrator(
    database: ref.watch(databaseProvider),
    cloudService: createCloudSyncService(),
    deviceId: settings.deviceId,
  );
});
