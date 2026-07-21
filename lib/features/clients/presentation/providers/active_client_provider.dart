import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers.dart';
import '../../domain/models/client.dart';

const _activeClientKey = 'active_client_id';

class ActiveClientNotifier extends AsyncNotifier<Client> {
  @override
  Future<Client> build() async {
    final repo = ref.watch(clientRepositoryProvider);
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_activeClientKey);
    if (savedId != null) {
      final saved = await repo.getClient(savedId);
      if (saved != null && saved.deletedAt == null) return saved;
    }
    return repo.getSelfClient();
  }

  Future<void> setActive(Client client) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeClientKey, client.id);
    state = AsyncData(client);
  }
}

final activeClientProvider =
    AsyncNotifierProvider<ActiveClientNotifier, Client>(
        ActiveClientNotifier.new);
