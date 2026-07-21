import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/providers.dart';
import '../../domain/models/client.dart';

/// Palette offered in the create-client colour picker.
const List<int> _clientColourChoices = [
  0xFF4C6EF5, // blue
  0xFF37B24D, // green
  0xFFF59F00, // amber
  0xFFE64980, // pink
  0xFF7048E8, // violet
  0xFFE03131, // red
];

class ClientRosterScreen extends ConsumerWidget {
  const ClientRosterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.clientsTitle)),
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (clients) => clients.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.noClientsYet,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return _ClientTile(
                    client: client,
                    onDelete: () => ref
                        .read(clientRepositoryProvider)
                        .softDeleteClient(client.id),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClientDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(s.newClient),
      ),
    );
  }

  Future<void> _showCreateClientDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final s = S.of(context)!;
    final nameController = TextEditingController();
    var selectedColour = _clientColourChoices.first;

    final result = await showDialog<({String name, int colour})?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(s.newClientTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: s.clientNameLabel,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final colour in _clientColourChoices)
                    GestureDetector(
                      onTap: () => setState(() => selectedColour = colour),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(colour),
                        child: selectedColour == colour
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                ],
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
                if (name.isNotEmpty) {
                  Navigator.pop(ctx, (name: name, colour: selectedColour));
                }
              },
              child: Text(s.create),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      final client = Client.create(name: result.name, colour: result.colour);
      await ref.read(clientRepositoryProvider).createClient(client);
    }
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({
    required this.client,
    required this.onDelete,
  });

  final Client client;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: () => context.push('/clients/${client.id}'),
        leading: CircleAvatar(backgroundColor: Color(client.colour)),
        title: Row(
          children: [
            Flexible(child: Text(client.name)),
            if (client.isSelf) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(s.selfClientBadge),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              context.push('/clients/${client.id}');
            } else if (value == 'delete') {
              _confirmDelete(context);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(s.editClient),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!client.isSelf)
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
        title: Text(s.deleteClientTitle),
        content: Text(s.deleteClientContent(client.name)),
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
