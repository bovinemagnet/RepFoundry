import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../domain/models/workout_template.dart';
import '../../../../core/providers.dart';

final _templateListProvider =
    StreamProvider.autoDispose<List<WorkoutTemplate>>((ref) {
  return ref.watch(workoutTemplateRepositoryProvider).watchAllTemplates();
});

class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final templatesAsync = ref.watch(_templateListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.templatesTitle)),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(s.failedToLoadTemplates(error.toString())),
        ),
        data: (templates) => templates.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.view_list,
                      size: 80,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.noTemplatesYet,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.noTemplatesYetSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return _TemplateTile(
                    template: template,
                    onDelete: () => ref
                        .read(workoutTemplateRepositoryProvider)
                        .deleteTemplate(template.id),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTemplateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(s.newTemplate),
      ),
    );
  }

  Future<void> _showCreateTemplateDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final s = S.of(context)!;
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.newTemplateTitle),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: s.templateNameLabel,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: Text(s.create),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref
          .read(workoutTemplateRepositoryProvider)
          .createTemplate(WorkoutTemplate.create(name: result));
    }
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.onDelete,
  });

  final WorkoutTemplate template;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            Icons.view_list,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(template.name),
        subtitle: Text(
          s.exerciseCount(template.exercises.length),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDelete(context);
            }
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
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final s = S.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteTemplateTitle),
        content: Text(
          s.deleteTemplateContent(template.name),
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
