import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/features/clients/domain/repositories/health_profile_repository.dart';

class FakeHealthProfileRepository implements HealthProfileRepository {
  FakeHealthProfileRepository([Map<String, HealthProfile> profiles = const {}])
      : _profiles = {...profiles};

  final Map<String, HealthProfile> _profiles;

  @override
  Future<HealthProfile> getForClient(String clientId) async =>
      _profiles[clientId] ?? const HealthProfile();

  @override
  Future<void> saveForClient(String clientId, HealthProfile profile) =>
      throw StateError('write');
}
