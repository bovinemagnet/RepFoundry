import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/sparkline_widget.dart';
import '../providers/exercise_sparkline_provider.dart';

/// Displays a small inline sparkline of recent e1RM values for an exercise.
///
/// Shows nothing while loading or if no data is available.
class ExerciseSparkline extends ConsumerWidget {
  const ExerciseSparkline({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sparklineAsync = ref.watch(exerciseSparklineProvider(exerciseId));

    return sparklineAsync.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          width: 60,
          height: 30,
          child: SparklineWidget(data: data),
        );
      },
      loading: () => const SizedBox(width: 60, height: 30),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
