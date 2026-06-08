import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../domain/models/workout_template.dart';

/// All workout templates, newest changes reflected live. Shared by the mobile
/// list and the desktop library + canvas layout.
final templateListProvider =
    StreamProvider.autoDispose<List<WorkoutTemplate>>((ref) {
  return ref.watch(workoutTemplateRepositoryProvider).watchAllTemplates();
});
