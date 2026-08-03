import 'package:hr_zones/hr_zones.dart';

/// The zone containing [bpm], or null when the reading sits below zone 1.
///
/// Delegates to the package's own boundary logic (`lowerBound` inclusive,
/// `upperBound` exclusive, top zone absorbs everything above it) so there is
/// exactly one owner of those rules rather than a second implementation that
/// could drift from it.
int? zoneNumberFor(ZoneConfiguration config, int bpm) =>
    currentZoneFromConfig(bpm, config)?.zoneNumber;
