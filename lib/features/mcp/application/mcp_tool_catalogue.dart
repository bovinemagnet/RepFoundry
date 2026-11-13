import '../../body_metrics/domain/repositories/body_metric_repository.dart';
import '../../cardio/application/build_cardio_history_use_case.dart';
import '../../cardio/domain/repositories/cardio_session_repository.dart';
import '../../clients/domain/repositories/client_repository.dart';
import '../../clients/domain/repositories/health_profile_repository.dart';
import '../../exercises/domain/repositories/exercise_repository.dart';
import '../../heart_rate/application/build_weekly_heart_report_use_case.dart';
import '../../history/application/calculate_progress_use_case.dart';
import '../../history/domain/repositories/personal_record_repository.dart';
import '../../programmes/domain/repositories/programme_repository.dart';
import '../../stretching/domain/repositories/stretching_session_repository.dart';
import '../../templates/domain/repositories/workout_template_repository.dart';
import '../../workout/domain/repositories/workout_repository.dart';
import '../domain/mcp_settings.dart';
import 'mcp_scope.dart';
import 'mcp_tool.dart';
import 'tools/cardio_tools.dart';
import 'tools/client_tools.dart';
import 'tools/exercise_tools.dart';
import 'tools/library_tools.dart';
import 'tools/summary_tools.dart';
import 'tools/workout_tools.dart';

/// What the server tells a connecting assistant about every tool's data.
const String kMcpServerInstructions =
    'RepFoundry training log, read-only. Nothing you call can change data.\n'
    '- Weights are kg, distances km, durations seconds, heart rate bpm; '
    'field names carry the unit (weight_kg).\n'
    '- Timestamps are ISO 8601 in the user\'s local time with its offset. '
    'Weeks are local weeks starting on Monday.\n'
    '- Deleted records are never returned.\n'
    '- List tools take `limit` (default 20, at most 100) and return '
    '`next_cursor` while more remain; pass it back as `cursor`.\n'
    '- Data is the user\'s own unless client data access is on, in which '
    'case list_clients and a `client_id` argument are available.\n'
    '- Warm-up sets are excluded from volume and set counts.';

/// Everything the tools read from.
class McpToolDeps {
  const McpToolDeps({
    required this.workouts,
    required this.exercises,
    required this.cardio,
    required this.stretching,
    required this.records,
    required this.bodyMetrics,
    required this.templates,
    required this.programmes,
    required this.clients,
    required this.healthProfiles,
    required this.calculateProgress,
    required this.cardioHistory,
    required this.weeklyHeartReport,
    required this.now,
  });

  final WorkoutRepository workouts;
  final ExerciseRepository exercises;
  final CardioSessionRepository cardio;
  final StretchingSessionRepository stretching;
  final PersonalRecordRepository records;
  final BodyMetricRepository bodyMetrics;
  final WorkoutTemplateRepository templates;
  final ProgrammeRepository programmes;
  final ClientRepository clients;
  final HealthProfileRepository healthProfiles;
  final CalculateProgressUseCase calculateProgress;
  final BuildCardioHistoryUseCase cardioHistory;
  final BuildWeeklyHeartReportUseCase weeklyHeartReport;
  final DateTime Function() now;
}

/// The tools offered under [settings]. Tools behind a switched-off toggle
/// are left out entirely rather than listed and refusing.
List<McpTool> buildMcpTools(McpToolDeps d, McpSettings settings) {
  final scope =
      McpScope(includeClients: settings.includeClients, clients: d.clients);
  return [
    ListWorkoutsTool(d.workouts, d.exercises, scope),
    GetWorkoutTool(d.workouts, d.exercises, d.cardio, d.stretching, scope),
    ListExercisesTool(d.exercises, d.workouts, scope),
    GetExerciseHistoryTool(d.exercises, d.calculateProgress, scope),
    ListPersonalRecordsTool(d.records, d.exercises, scope),
    GetTrainingSummaryTool(d.workouts, d.exercises, scope, d.now),
    ListCardioSessionsTool(d.cardioHistory, scope),
    GetCardioProgressTool(d.cardioHistory, scope, d.now),
    GetWeeklyHeartReportTool(
        d.weeklyHeartReport, d.healthProfiles, scope, d.now),
    ListBodyMetricsTool(d.bodyMetrics, scope),
    ListTemplatesTool(d.templates),
    ListProgrammesTool(d.programmes, d.exercises),
    if (settings.includeClients) ListClientsTool(d.clients),
    if (settings.includeHealthProfile)
      GetHealthProfileTool(d.healthProfiles, scope),
  ];
}
