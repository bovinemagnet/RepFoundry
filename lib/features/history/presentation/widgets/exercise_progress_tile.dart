import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/sparkline_widget.dart';
import '../../../exercises/presentation/providers/exercise_sparkline_provider.dart';
import '../providers/trained_exercises_provider.dart';

class ExerciseProgressTile extends ConsumerWidget {
  const ExerciseProgressTile({super.key, required this.trainedExercise});

  final TrainedExercise trainedExercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final sparkline = ref.watch(
      exerciseSparklineProvider(trainedExercise.exercise.id),
    );

    return ListTile(
      title: Text(trainedExercise.exercise.name),
      subtitle: Text(s.setsLogged(trainedExercise.setCount)),
      trailing: SizedBox(
        width: 60,
        height: 30,
        child: sparkline.when(
          data: (data) => SparklineWidget(data: data),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
      onTap: () =>
          context.push('/history/exercise/${trainedExercise.exercise.id}'),
    );
  }
}
