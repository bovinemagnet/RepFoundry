import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'entitlement.dart';
import 'entitlement_service.dart';

const String _prefsKey = 'unlocked_entitlements';

/// The entitlements unlocked on this device.
///
/// Loading is asynchronous, so the initial state is empty and widens once
/// preferences arrive. Features must therefore react to this provider rather
/// than reading it once at start-up.
class UnlockedEntitlementsNotifier extends Notifier<Set<Entitlement>> {
  Future<void>? _loading;

  @override
  Set<Entitlement> build() {
    _loading = reload();
    return const {};
  }

  Future<void> reload() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(_prefsKey) ?? const <String>[];
    final unlocked = <Entitlement>{};
    for (final name in names) {
      for (final entitlement in Entitlement.values) {
        if (entitlement.name == name) {
          unlocked.add(entitlement);
          break;
        }
      }
    }
    if (!ref.mounted) return;
    state = unlocked;
  }

  Future<void> toggle(Entitlement entitlement) async {
    // Wait for any in-flight initial load so it cannot clobber this toggle.
    await _loading;

    final next = Set<Entitlement>.from(state);
    if (!next.remove(entitlement)) next.add(entitlement);
    state = next;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      next.map((e) => e.name).toList(),
    );
  }
}

final unlockedEntitlementsProvider =
    NotifierProvider<UnlockedEntitlementsNotifier, Set<Entitlement>>(
  UnlockedEntitlementsNotifier.new,
);

final entitlementServiceProvider = Provider<EntitlementService>((ref) {
  return LocalEntitlementService(ref.watch(unlockedEntitlementsProvider));
});
