import 'package:hr_zones/hr_zones.dart';

abstract class HealthProfileRepository {
  Future<HealthProfile> getForClient(String clientId);
  Future<void> saveForClient(String clientId, HealthProfile profile);
}
