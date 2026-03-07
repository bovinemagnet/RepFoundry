import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../heart_rate/presentation/providers/health_profile_provider.dart';

/// Derived provider — delegates to [healthProfileProvider] for the age value.
///
/// Existing consumers continue to read age via this provider. Writes should go
/// through [healthProfileProvider] directly.
class UserAgeNotifier extends StateNotifier<int?> {
  UserAgeNotifier(this._ref) : super(null) {
    // Sync initial value and listen for changes from HealthProfile.
    state = _ref.read(healthProfileProvider).age;
    _ref.listen<int?>(
      healthProfileProvider.select((p) => p.age),
      (_, next) {
        if (mounted) state = next;
      },
    );
  }

  final Ref _ref;

  Future<void> setAge(int? age) async {
    await _ref.read(healthProfileProvider.notifier).updateAge(age);
  }
}

final userAgeProvider = StateNotifierProvider<UserAgeNotifier, int?>((ref) {
  return UserAgeNotifier(ref);
});
