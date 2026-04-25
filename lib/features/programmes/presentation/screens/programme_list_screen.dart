import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../domain/models/programme.dart';
import '../../../../core/providers.dart';

final _programmeListProvider =
    StreamProvider.autoDispose<List<Programme>>((ref) {
  return ref.watch(programmeRepositoryProvider).watchAllProgrammes();
});

class ProgrammeListScreen extends ConsumerWidget {
  const ProgrammeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final programmesAsync = ref.watch(_programmeListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.programmesTitle)),
      body: programmesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(s.failedToLoadProgrammes(error.toString())),
        ),
        data: (programmes) => programmes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.noProgrammesYet,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.noProgrammesYetSubtitle,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: programmes.length,
                itemBuilder: (context, index) {
                  final programme = programmes[index];
                  return _ProgrammeTile(
                    programme: programme,
                    onDelete: () => ref
                        .read(programmeRepositoryProvider)
                        .deleteProgramme(programme.id),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProgrammeDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(s.newProgramme),
      ),
    );
  }

  Future<void> _showCreateProgrammeDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final s = S.of(context)!;
    final nameController = TextEditingController();
    final weeksController = TextEditingController();
    final result = await showDialog<({String name, int weeks})?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.newProgrammeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: s.programmeNameLabel,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weeksController,
              decoration: InputDecoration(
                labelText: s.durationWeeksLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final weeks = int.tryParse(weeksController.text.trim());
              if (name.isNotEmpty && weeks != null && weeks > 0) {
                Navigator.pop(ctx, (name: name, weeks: weeks));
              }
            },
            child: Text(s.create),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      final programme = Programme.create(
        name: result.name,
        durationWeeks: result.weeks,
      );
      await ref
          .read(programmeRepositoryProvider)
          .createProgramme(programme);
      if (context.mounted) {
        context.push('/programmes/${programme.id}');
      }
    }
  }
}

class _ProgrammeTile extends StatelessWidget {
  const _ProgrammeTile({
    required this.programme,
    required this.onDelete,
  });

  final Programme programme;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: () => context.push('/programmes/${programme.id}'),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            Icons.calendar_month_outlined,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(programme.name),
        subtitle: Text(
          '${s.programmeWeeksCount(programme.durationWeeks)}'
          ' · '
          '${s.programmeDaysCount(programme.days.length)}'
          ' · '
          '${programme.isStarted ? s.programmeWeekOf(programme.currentWeek(), programme.durationWeeks) : s.programmeNotStarted}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              context.push('/programmes/${programme.id}');
            } else if (value == 'delete') {
              _confirmDelete(context);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(s.editProgramme),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(s.delete),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final s = S.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteProgrammeTitle),
        content: Text(
          s.deleteProgrammeContent(programme.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }
}
