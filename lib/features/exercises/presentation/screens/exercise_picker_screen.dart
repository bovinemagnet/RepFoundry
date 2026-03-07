import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../domain/models/exercise.dart';
import '../screens/create_exercise_screen.dart';
import '../widgets/exercise_list_tile.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/loading_widget.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');
final _selectedMuscleGroupProvider = StateProvider<MuscleGroup?>((ref) => null);

final _filteredExercisesProvider =
    FutureProvider.autoDispose<List<Exercise>>((ref) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  final query = ref.watch(_searchQueryProvider);
  final group = ref.watch(_selectedMuscleGroupProvider);

  if (query.isNotEmpty) {
    return repo.searchExercises(query);
  }
  if (group != null) {
    return repo.getExercisesByMuscleGroup(group);
  }
  return repo.getAllExercises();
});

class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final exercisesAsync = ref.watch(_filteredExercisesProvider);
    final selectedGroup = ref.watch(_selectedMuscleGroupProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.chooseExercise),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: s.searchExercisesHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(_searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
                filled: true,
              ),
              onChanged: (value) {
                ref.read(_searchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _MuscleGroupFilterBar(selectedGroup: selectedGroup),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) => exercises.isEmpty
                  ? Center(child: Text(s.noExercisesFound))
                  : ListView.builder(
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return ExerciseListTile(
                          exercise: exercise,
                          onTap: () => Navigator.of(context).pop(exercise),
                          trailing: const Icon(Icons.chevron_right),
                        );
                      },
                    ),
              loading: () => LoadingWidget(message: s.loadingExercises),
              error: (e, _) => Center(child: Text(s.errorPrefix(e.toString()))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateExerciseDialog(context),
        icon: const Icon(Icons.add),
        label: Text(s.customExercise),
      ),
    );
  }

  Future<void> _showCreateExerciseDialog(BuildContext context) async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => const CreateExerciseScreen(),
      ),
    );

    if (exercise != null && mounted) {
      Navigator.of(this.context).pop(exercise);
    }
  }
}

class _MuscleGroupFilterBar extends ConsumerWidget {
  const _MuscleGroupFilterBar({required this.selectedGroup});

  final MuscleGroup? selectedGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    const groups = MuscleGroup.values;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: groups.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return FilterChip(
              label: Text(s.filterAll),
              selected: selectedGroup == null,
              onSelected: (_) {
                ref.read(_selectedMuscleGroupProvider.notifier).state = null;
              },
            );
          }
          final group = groups[index - 1];
          return FilterChip(
            label: Text(group.name),
            selected: selectedGroup == group,
            onSelected: (_) {
              ref.read(_selectedMuscleGroupProvider.notifier).state = group;
            },
          );
        },
      ),
    );
  }
}
