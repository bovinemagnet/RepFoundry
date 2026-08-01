import 'entitlement.dart';

/// The single seam every paid feature checks.
///
/// Feature code must never read a raw unlock flag: it asks this service.
/// Swapping [LocalEntitlementService] for a store-billing implementation
/// later then touches one provider rather than every call site.
abstract class EntitlementService {
  bool has(Entitlement entitlement);
}

/// Entitlements held on this device only, with no store involvement.
class LocalEntitlementService implements EntitlementService {
  const LocalEntitlementService(this._unlocked);

  final Set<Entitlement> _unlocked;

  @override
  bool has(Entitlement entitlement) => _unlocked.contains(entitlement);
}
