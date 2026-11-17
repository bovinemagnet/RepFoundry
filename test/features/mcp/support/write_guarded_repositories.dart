import 'package:rep_foundry/features/cardio/data/cardio_session_repository_impl.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_heart_rate_sample.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_session.dart';
import 'package:rep_foundry/features/cardio/domain/models/cardio_track_point.dart';
import 'package:rep_foundry/features/exercises/data/exercise_repository_impl.dart';
import 'package:rep_foundry/features/exercises/domain/models/exercise.dart';
import 'package:rep_foundry/features/history/data/personal_record_repository_impl.dart';
import 'package:rep_foundry/features/history/domain/models/personal_record.dart';
import 'package:rep_foundry/features/stretching/data/in_memory_stretching_session_repository.dart';
import 'package:rep_foundry/features/stretching/domain/models/stretching_session.dart';
import 'package:rep_foundry/features/templates/data/workout_template_repository_impl.dart';
import 'package:rep_foundry/features/templates/domain/models/workout_template.dart';
import 'package:rep_foundry/features/workout/data/workout_repository_impl.dart';
import 'package:rep_foundry/features/workout/domain/models/workout.dart';
import 'package:rep_foundry/features/workout/domain/models/workout_set.dart';

/// Shared switch: seed freely, then [seal] so any later write throws.
class WriteGuard {
  bool sealed = false;

  void seal() => sealed = true;

  void check(String method) {
    if (sealed) throw StateError('write attempted: $method');
  }
}

class GuardedWorkoutRepository extends InMemoryWorkoutRepository {
  GuardedWorkoutRepository(this.guard);
  final WriteGuard guard;

  @override
  Future<Workout> createWorkout(Workout workout) {
    guard.check('createWorkout');
    return super.createWorkout(workout);
  }

  @override
  Future<Workout> updateWorkout(Workout workout) {
    guard.check('updateWorkout');
    return super.updateWorkout(workout);
  }

  @override
  Future<void> deleteWorkout(String id) {
    guard.check('deleteWorkout');
    return super.deleteWorkout(id);
  }

  @override
  Future<WorkoutSet> addSet(WorkoutSet set) {
    guard.check('addSet');
    return super.addSet(set);
  }

  @override
  Future<WorkoutSet> updateSet(WorkoutSet set) {
    guard.check('updateSet');
    return super.updateSet(set);
  }

  @override
  Future<void> deleteSet(String setId) {
    guard.check('deleteSet');
    return super.deleteSet(setId);
  }
}

class GuardedExerciseRepository extends InMemoryExerciseRepository {
  GuardedExerciseRepository(this.guard);
  final WriteGuard guard;

  @override
  Future<Exercise> createExercise(Exercise exercise) {
    guard.check('createExercise');
    return super.createExercise(exercise);
  }

  @override
  Future<Exercise> updateExercise(Exercise exercise) {
    guard.check('updateExercise');
    return super.updateExercise(exercise);
  }

  @override
  Future<void> deleteExercise(String id) {
    guard.check('deleteExercise');
    return super.deleteExercise(id);
  }
}

class GuardedCardioSessionRepository extends InMemoryCardioSessionRepository {
  GuardedCardioSessionRepository(this.guard);
  final WriteGuard guard;

  @override
  Future<CardioSession> createSession(CardioSession session) {
    guard.check('createSession');
    return super.createSession(session);
  }

  @override
  Future<void> deleteSession(String id) {
    guard.check('deleteSession');
    return super.deleteSession(id);
  }

  @override
  Future<void> saveTrackPoints(
      String sessionId, List<CardioTrackPoint> points) {
    guard.check('saveTrackPoints');
    return super.saveTrackPoints(sessionId, points);
  }

  @override
  Future<void> saveHeartRateSamples(
      String sessionId, List<CardioHeartRateSample> samples) {
    guard.check('saveHeartRateSamples');
    return super.saveHeartRateSamples(sessionId, samples);
  }
}

class GuardedStretchingSessionRepository
    extends InMemoryStretchingSessionRepository {
  GuardedStretchingSessionRepository(this.guard);
  final WriteGuard guard;

  @override
  Future<StretchingSession> createSession(StretchingSession session) {
    guard.check('createSession');
    return super.createSession(session);
  }

  @override
  Future<StretchingSession> updateSession(StretchingSession session) {
    guard.check('updateSession');
    return super.updateSession(session);
  }

  @override
  Future<void> deleteSession(String id) {
    guard.check('deleteSession');
    return super.deleteSession(id);
  }
}

class GuardedPersonalRecordRepository extends InMemoryPersonalRecordRepository {
  GuardedPersonalRecordRepository(this.guard);
  final WriteGuard guard;

  @override
  Future<PersonalRecord> createRecord(PersonalRecord record) {
    guard.check('createRecord');
    return super.createRecord(record);
  }

  @override
  Future<void> deleteRecordsForSet(String workoutSetId) {
    guard.check('deleteRecordsForSet');
    return super.deleteRecordsForSet(workoutSetId);
  }
}

class GuardedWorkoutTemplateRepository
    extends InMemoryWorkoutTemplateRepository {
  GuardedWorkoutTemplateRepository(this.guard);
  final WriteGuard guard;

  @override
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) {
    guard.check('createTemplate');
    return super.createTemplate(template);
  }

  @override
  Future<WorkoutTemplate> updateTemplate(WorkoutTemplate template) {
    guard.check('updateTemplate');
    return super.updateTemplate(template);
  }

  @override
  Future<void> deleteTemplate(String id) {
    guard.check('deleteTemplate');
    return super.deleteTemplate(id);
  }
}
