import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/providers.dart';
import '../../domain/models/client.dart';

/// Minimal placeholder for a client's detail screen. Task 13 fleshes this out
/// with the client's plan assignment, health profile, and history.
class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final clients = ref.watch(clientsProvider).value ?? const <Client>[];
    Client? client;
    for (final candidate in clients) {
      if (candidate.id == clientId) {
        client = candidate;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(client?.name ?? s.clientsTitle)),
      body: Center(child: Text(s.clientDetailComingSoon)),
    );
  }
}
