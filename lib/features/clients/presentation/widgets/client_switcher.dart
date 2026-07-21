import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/providers.dart';
import '../../domain/models/client.dart';
import '../providers/active_client_provider.dart';

/// Tappable chip showing the active client (coloured dot + name, or the
/// "You" badge when self); tapping opens a sheet listing every client so the
/// coach can switch who they're viewing/logging for. Hosted in the
/// [DesktopNavRail] footer.
class ClientSwitcher extends ConsumerWidget {
  const ClientSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeClient = ref.watch(activeClientProvider).value;
    if (activeClient == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final s = S.of(context)!;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showClientSwitcherSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _ColourDot(colour: activeClient.colour),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _clientLabel(activeClient, s),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(Icons.unfold_more, size: 16, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact, always-visible badge for logging surfaces (active workout,
/// cardio tracking) so the coach can't log a set under the wrong client.
/// Tapping opens the same switcher sheet as [ClientSwitcher].
class ActiveClientIndicator extends ConsumerWidget {
  const ActiveClientIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeClient = ref.watch(activeClientProvider).value;
    if (activeClient == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final s = S.of(context)!;
    final label = _clientLabel(activeClient, s);

    return Tooltip(
      message: s.viewingClient(label),
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showClientSwitcherSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ColourDot(colour: activeClient.colour, size: 8),
                const SizedBox(width: 6),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Label shown in the chip/badge: the "You" badge for the self client,
/// otherwise the client's name.
String _clientLabel(Client client, S s) =>
    client.isSelf ? s.selfClientBadge : client.name;

/// Opens the modal bottom sheet listing every client; selecting one makes
/// it active. Shared by [ClientSwitcher] and [ActiveClientIndicator].
Future<void> showClientSwitcherSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _ClientSwitcherSheet(),
  );
}

class _ClientSwitcherSheet extends ConsumerWidget {
  const _ClientSwitcherSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final clientsAsync = ref.watch(clientsProvider);
    final activeClient = ref.watch(activeClientProvider).value;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                s.switchClient,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Flexible(
            child: clientsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error.toString()),
              ),
              data: (clients) => ListView.builder(
                shrinkWrap: true,
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  final selected = activeClient?.id == client.id;
                  return ListTile(
                    leading: _ColourDot(colour: client.colour, size: 14),
                    title: Row(
                      children: [
                        Flexible(child: Text(client.name)),
                        if (client.isSelf) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(s.selfClientBadge),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ],
                    ),
                    trailing: selected
                        ? Icon(Icons.check,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      ref.read(activeClientProvider.notifier).setActive(
                            client,
                          );
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColourDot extends StatelessWidget {
  const _ColourDot({required this.colour, this.size = 10});

  final int colour;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Color(colour), shape: BoxShape.circle),
    );
  }
}
