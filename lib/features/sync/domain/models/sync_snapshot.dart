import '../../../body_metrics/domain/models/body_metric.dart';
import '../../../cardio/domain/models/cardio_session.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../history/domain/models/personal_record.dart';
import '../../../programmes/domain/models/programme.dart';
import '../../../stretching/domain/models/stretching_session.dart';
import '../../../templates/domain/models/workout_template.dart';
import '../../../workout/domain/models/workout.dart';
import '../../../workout/domain/models/workout_set.dart';

class SyncSnapshot {
  final DateTime snapshotAt;
  final String deviceId;
  final int schemaVersion;
  final List<Exercise> exercises;
  final List<Workout> workouts;
  final List<WorkoutSet> workoutSets;
  final List<CardioSession> cardioSessions;
  final List<PersonalRecord> personalRecords;
  final List<WorkoutTemplate> workoutTemplates;
  final List<TemplateExercise> templateExercises;
  final List<BodyMetric> bodyMetrics;
  final List<Programme> programmes;
  final List<ProgrammeDay> programmeDays;
  final List<ProgressionRule> progressionRules;
  final List<StretchingSession> stretchingSessions;

  const SyncSnapshot({
    required this.snapshotAt,
    required this.deviceId,
    required this.schemaVersion,
    this.exercises = const [],
    this.workouts = const [],
    this.workoutSets = const [],
    this.cardioSessions = const [],
    this.personalRecords = const [],
    this.workoutTemplates = const [],
    this.templateExercises = const [],
    this.bodyMetrics = const [],
    this.programmes = const [],
    this.programmeDays = const [],
    this.progressionRules = const [],
    this.stretchingSessions = const [],
  });
}
