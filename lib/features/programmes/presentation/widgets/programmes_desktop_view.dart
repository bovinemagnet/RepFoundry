import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/providers.dart';
import '../../domain/models/programme.dart';
import '../providers/programme_list_provider.dart';
import '../screens/programme_edit_screen.dart';

/// Desktop power layout for programmes: a master list on the left with the
/// programme editor embedded in the right-hand pane, mirroring the templates
/// library + canvas view.
class ProgrammesDesktopView extends ConsumerStatefulWidget {
  const ProgrammesDesktopView({super.key});

  @override
  ConsumerState<ProgrammesDesktopView> createState() =>
      _ProgrammesDesktopViewState();
}

class _ProgrammesDesktopViewState extends ConsumerState<ProgrammesDesktopView> {
  String? _selectedId;

  static const _masterWidth = 380.0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final programmesAsync = ref.watch(programmeListProvider);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _masterWidth,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.programmesTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _createProgramme(context),
                        icon: const Icon(Icons.add),
                        label: Text(s.newProgramme),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: programmesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text(s.failedToLoadProgrammes(error.toString())),
                    ),
                    data: (programmes) => programmes.isEmpty
                        ? Center(
                            child: Text(
                              s.noProgrammesYet,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: programmes.length,
                            itemBuilder: (context, index) => _masterTile(
                              context,
                              programmes[index],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedId == null
                ? Center(
                    child: Text(
                      s.selectProgrammeHint,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ProgrammeEditScreen(
                    key: ValueKey(_selectedId),
                    programmeId: _selectedId!,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _masterTile(BuildContext context, Programme programme) {
    final s = S.of(context)!;
    return ListTile(
      selected: programme.id == _selectedId,
      selectedTileColor:
          Theme.of(context).colorScheme.secondaryContainer.withValues(
                alpha: 0.4,
              ),
      leading: const Icon(Icons.calendar_month_outlined),
      title: Text(programme.name),
      subtitle: Text(
        '${s.programmeWeeksCount(programme.durationWeeks)}'
        ' · '
        '${s.programmeDaysCount(programme.days.length)}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'delete') _confirmDelete(context, programme);
        },
        itemBuilder: (_) => [
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
      onTap: () => setState(() => _selectedId = programme.id),
    );
  }

  Future<void> _createProgramme(BuildContext context) async {
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

    if (result != null && mounted) {
      final programme = Programme.create(
        name: result.name,
        durationWeeks: result.weeks,
      );
      await ref.read(programmeRepositoryProvider).createProgramme(programme);
      if (mounted) setState(() => _selectedId = programme.id);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Programme programme,
  ) async {
    final s = S.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteProgrammeTitle),
        content: Text(s.deleteProgrammeContent(programme.name)),
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
    if (confirmed == true && mounted) {
      await ref.read(programmeRepositoryProvider).deleteProgramme(programme.id);
      if (programme.id == _selectedId && mounted) {
        setState(() => _selectedId = null);
      }
    }
  }
}
