import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../heart_rate/presentation/providers/health_profile_provider.dart';

/// Derived provider — delegates to [healthProfileProvider] for the age value.
///
/// Existing consumers continue to read age via this provider. Writes should go
/// through [healthProfileProvider] directly.
class UserAgeNotifier extends Notifier<int?> {
  @override
  int? build() {
    // Reactively watch age from HealthProfile so this provider stays in sync.
    return ref.watch(healthProfileProvider.select((p) => p.age));
  }

  Future<void> setAge(int? age) async {
    await ref.read(healthProfileProvider.notifier).updateAge(age);
  }
}

final userAgeProvider = NotifierProvider<UserAgeNotifier, int?>(
  UserAgeNotifier.new,
);
