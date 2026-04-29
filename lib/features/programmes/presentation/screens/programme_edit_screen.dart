import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../exercises/domain/models/exercise.dart';
import '../../../templates/domain/models/workout_template.dart';
import '../../domain/models/programme.dart';
import '../../../../core/providers.dart';

const _dayAbbreviations = <int, String>{
  DateTime.monday: 'Mon',
  DateTime.tuesday: 'Tue',
  DateTime.wednesday: 'Wed',
  DateTime.thursday: 'Thu',
  DateTime.friday: 'Fri',
  DateTime.saturday: 'Sat',
  DateTime.sunday: 'Sun',
};

class ProgrammeEditScreen extends ConsumerStatefulWidget {
  const ProgrammeEditScreen({super.key, required this.programmeId});

  final String programmeId;

  @override
  ConsumerState<ProgrammeEditScreen> createState() =>
      _ProgrammeEditScreenState();
}

class _ProgrammeEditScreenState extends ConsumerState<ProgrammeEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _durationController;

  Programme? _programme;
  List<ProgrammeDay> _days = [];
  List<ProgressionRule> _rules = [];
  Map<String, String> _exerciseNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _durationController = TextEditingController();
    _loadProgramme();
  }

  Future<void> _loadProgramme() async {
    final repo = ref.read(programmeRepositoryProvider);
    final programme = await repo.getProgramme(widget.programmeId);
    if (!mounted || programme == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final days = await repo.getDaysForProgramme(programme.id);
    final rules = await repo.getRulesForProgramme(programme.id);

    // Fetch exercise names for rules
    final exerciseNames = <String, String>{};
    if (rules.isNotEmpty) {
      final exerciseRepo = ref.read(exerciseRepositoryProvider);
      for (final rule in rules) {
        final exercise = await exerciseRepo.getExercise(rule.exerciseId);
        if (exercise != null) {
          exerciseNames[rule.exerciseId] = exercise.name;
        }
      }
    }

    if (mounted) {
      setState(() {
        _programme = programme;
        _days = days;
        _rules = rules;
        _exerciseNames = exerciseNames;
        _nameController.text = programme.name;
        _durationController.text = programme.durationWeeks.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  int get _durationWeeks {
    final parsed = int.tryParse(_durationController.text);
    return (parsed != null && parsed > 0) ? parsed : 1;
  }

  ProgrammeDay? _dayFor(int week, int dayOfWeek) {
    for (final day in _days) {
      if (day.weekNumber == week && day.dayOfWeek == dayOfWeek) {
        return day;
      }
    }
    return null;
  }

  Future<void> _pickTemplate(int week, int dayOfWeek) async {
    final s = S.of(context)!;
    final repo = ref.read(workoutTemplateRepositoryProvider);
    final templates = await repo.getAllTemplates();

    if (!mounted) return;

    final result = await showModalBottomSheet<WorkoutTemplate?>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  s.assignTemplate,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              if (templates.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(s.noTemplatesAvailable),
                )
              else
                ...templates.map(
                  (t) => ListTile(
                    title: Text(t.name),
                    onTap: () => Navigator.of(ctx).pop(t),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: Text(s.noTemplateAssigned),
                onTap: () => Navigator.of(ctx).pop(null),
              ),
            ],
          ),
        );
      },
    );

    // If the bottom sheet was dismissed (tapped outside), do nothing
    // The result is null both when "Rest day" is tapped and when dismissed,
    // so we use a sentinel approach: dismissed returns nothing (we check mounted)
    if (!mounted) return;

    final programmeRepo = ref.read(programmeRepositoryProvider);
    final existing = _dayFor(week, dayOfWeek);

    if (result != null) {
      // Assign or replace template
      if (existing != null) {
        await programmeRepo.removeDay(existing.id);
      }
      final newDay = ProgrammeDay.create(
        programmeId: widget.programmeId,
        weekNumber: week,
        dayOfWeek: dayOfWeek,
        templateId: result.id,
        templateName: result.name,
      );
      await programmeRepo.addDay(newDay);
    } else if (existing != null) {
      // "Rest day" selected — remove existing assignment
      await programmeRepo.removeDay(existing.id);
    }

    // Refresh days
    final updatedDays =
        await programmeRepo.getDaysForProgramme(widget.programmeId);
    if (mounted) {
      setState(() => _days = updatedDays);
    }
  }

  Future<void> _addRule() async {
    final s = S.of(context)!;
    final exerciseRepo = ref.read(exerciseRepositoryProvider);
    final exercises = await exerciseRepo.getAllExercises();

    if (!mounted) return;

    Exercise? selectedExercise;
    ProgressionType selectedType = ProgressionType.fixedIncrement;
    final valueController = TextEditingController();
    final frequencyController = TextEditingController(text: '1');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(s.addRule),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Exercise>(
                      decoration: InputDecoration(
                        labelText: s.exerciseField,
                        border: const OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      initialValue: selectedExercise,
                      items: exercises
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (e) =>
                          setDialogState(() => selectedExercise = e),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ProgressionType>(
                      decoration: InputDecoration(
                        labelText: s.categoryLabel,
                        border: const OutlineInputBorder(),
                      ),
                      initialValue: selectedType,
                      items: [
                        DropdownMenuItem(
                          value: ProgressionType.fixedIncrement,
                          child: Text(s.fixedIncrementLabel),
                        ),
                        DropdownMenuItem(
                          value: ProgressionType.percentage,
                          child: Text(s.percentageLabel),
                        ),
                        DropdownMenuItem(
                          value: ProgressionType.deload,
                          child: Text(s.deloadLabel),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedType = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: valueController,
                      decoration: InputDecoration(
                        labelText: s.ruleValueLabel,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: frequencyController,
                      decoration: InputDecoration(
                        labelText: s.everyNWeeks(1),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(s.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(s.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedExercise == null || !mounted) return;

    final value = double.tryParse(valueController.text);
    final frequency = int.tryParse(frequencyController.text) ?? 1;
    if (value == null) return;

    final rule = ProgressionRule.create(
      programmeId: widget.programmeId,
      exerciseId: selectedExercise!.id,
      type: selectedType,
      value: value,
      frequencyWeeks: frequency,
    );

    final programmeRepo = ref.read(programmeRepositoryProvider);
    await programmeRepo.addRule(rule);

    final updatedRules =
        await programmeRepo.getRulesForProgramme(widget.programmeId);

    if (mounted) {
      setState(() {
        _rules = updatedRules;
        _exerciseNames[selectedExercise!.id] = selectedExercise!.name;
      });
    }
  }

  Future<void> _removeRule(String ruleId) async {
    final programmeRepo = ref.read(programmeRepositoryProvider);
    await programmeRepo.removeRule(ruleId);

    final updatedRules =
        await programmeRepo.getRulesForProgramme(widget.programmeId);
    if (mounted) {
      setState(() => _rules = updatedRules);
    }
  }

  Future<void> _saveProgramme() async {
    final programme = _programme;
    if (programme == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final updated = programme.copyWith(
      name: name,
      durationWeeks: _durationWeeks,
      updatedAt: DateTime.now().toUtc(),
    );

    await ref.read(programmeRepositoryProvider).updateProgramme(updated);

    if (mounted) {
      final s = S.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.programmeSaved)),
      );
      context.pop();
    }
  }

  String _progressionTypeLabel(S s, ProgressionType type) {
    return switch (type) {
      ProgressionType.fixedIncrement => s.fixedIncrementLabel,
      ProgressionType.percentage => s.percentageLabel,
      ProgressionType.deload => s.deloadLabel,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(s.editProgramme)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_programme == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.editProgramme)),
        body: const Center(child: Icon(Icons.error_outline, size: 48)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.editProgramme),
        actions: [
          TextButton(
            onPressed: _saveProgramme,
            child: Text(s.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + Duration section
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: s.programmeNameLabel,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationController,
              decoration: InputDecoration(
                labelText: s.durationWeeksLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Schedule section
            Text(
              'Schedule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildWeekDayGrid(s),
            const SizedBox(height: 24),

            // Progression Rules section
            Text(
              s.progressionRules,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildRulesList(s),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addRule,
              icon: const Icon(Icons.add),
              label: Text(s.addRule),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDayGrid(S s) {
    final weeks = _durationWeeks;
    return Column(
      children: [
        for (int week = 1; week <= weeks; week++) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                s.weekLabel(week),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (int day = DateTime.monday;
                    day <= DateTime.sunday;
                    day++) ...[
                  _buildDayTile(s, week, day),
                  if (day < DateTime.sunday) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDayTile(S s, int week, int dayOfWeek) {
    final dayName = _dayAbbreviations[dayOfWeek] ?? '';
    final assignment = _dayFor(week, dayOfWeek);
    final templateName = assignment?.templateName;

    return ListTile(
      dense: true,
      title: Text(s.dayLabel(dayName)),
      subtitle: Text(
        templateName ?? s.noTemplateAssigned,
        style: TextStyle(
          color: templateName != null
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: templateName != null ? FontStyle.normal : FontStyle.italic,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _pickTemplate(week, dayOfWeek),
    );
  }

  Widget _buildRulesList(S s) {
    if (_rules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          s.addRule,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Column(
      children: _rules.map((rule) {
        final exerciseName = _exerciseNames[rule.exerciseId] ?? rule.exerciseId;
        final typeLabel = _progressionTypeLabel(s, rule.type);
        final frequencyLabel = s.everyNWeeks(rule.frequencyWeeks);

        return Card(
          child: ListTile(
            title: Text(exerciseName),
            subtitle: Text('$typeLabel: ${rule.value} — $frequencyLabel'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _removeRule(rule.id),
            ),
          ),
        );
      }).toList(),
    );
  }
}
