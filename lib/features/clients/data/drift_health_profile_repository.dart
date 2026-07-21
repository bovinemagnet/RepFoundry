import 'package:drift/drift.dart';
import 'package:hr_zones/hr_zones.dart';

import '../../../core/database/app_database.dart' as db;
import '../domain/repositories/health_profile_repository.dart';

class DriftHealthProfileRepository implements HealthProfileRepository {
  DriftHealthProfileRepository(this._db);

  final db.AppDatabase _db;

  @override
  Future<HealthProfile> getForClient(String clientId) async {
    final row = await (_db.select(_db.healthProfiles)
          ..where((t) => t.clientId.equals(clientId)))
        .getSingleOrNull();
    if (row == null) return const HealthProfile();
    return HealthProfile(
      age: row.age,
      restingHr: row.restingHr,
      measuredMaxHr: row.measuredMaxHr,
      clinicianMaxHr: row.clinicianMaxHr,
      betaBlocker: row.betaBlocker,
      heartCondition: row.heartCondition,
    );
  }

  @override
  Future<void> saveForClient(String clientId, HealthProfile p) async {
    await _db.into(_db.healthProfiles).insertOnConflictUpdate(
          db.HealthProfilesCompanion.insert(
            clientId: clientId,
            age: Value(p.age),
            restingHr: Value(p.restingHr),
            measuredMaxHr: Value(p.measuredMaxHr),
            clinicianMaxHr: Value(p.clinicianMaxHr),
            betaBlocker: Value(p.betaBlocker),
            heartCondition: Value(p.heartCondition),
            updatedAt: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
          ),
        );
  }
}
