/// A custom zone boundary defined by the user or clinician.
class CustomZoneBoundary {
  final int lowerBpm;
  final int upperBpm;
  final String label;

  const CustomZoneBoundary({
    required this.lowerBpm,
    required this.upperBpm,
    required this.label,
  });
}

/// Health profile used for heart rate zone calculation.
class HealthProfile {
  final int? age;
  final int? restingHeartRate;
  final int? measuredMaxHeartRate;
  final int? clinicianMaxHr;
  final bool takingBetaBlocker;
  final bool hasHeartCondition;
  final List<CustomZoneBoundary>? customZones;

  const HealthProfile({
    this.age,
    this.restingHeartRate,
    this.measuredMaxHeartRate,
    this.clinicianMaxHr,
    this.takingBetaBlocker = false,
    this.hasHeartCondition = false,
    this.customZones,
  });

  /// Whether caution mode should be activated due to medical flags.
  bool get isCautionMode => takingBetaBlocker || hasHeartCondition;

  /// Estimated maximum heart rate using the standard formula (220 − age).
  int? get estimatedMaxHr => age != null ? 220 - age! : null;

  HealthProfile copyWith({
    int? age,
    bool clearAge = false,
    int? restingHeartRate,
    bool clearRestingHeartRate = false,
    int? measuredMaxHeartRate,
    bool clearMeasuredMaxHeartRate = false,
    int? clinicianMaxHr,
    bool clearClinicianMaxHr = false,
    bool? takingBetaBlocker,
    bool? hasHeartCondition,
    List<CustomZoneBoundary>? customZones,
    bool clearCustomZones = false,
  }) {
    return HealthProfile(
      age: clearAge ? null : (age ?? this.age),
      restingHeartRate: clearRestingHeartRate
          ? null
          : (restingHeartRate ?? this.restingHeartRate),
      measuredMaxHeartRate: clearMeasuredMaxHeartRate
          ? null
          : (measuredMaxHeartRate ?? this.measuredMaxHeartRate),
      clinicianMaxHr:
          clearClinicianMaxHr ? null : (clinicianMaxHr ?? this.clinicianMaxHr),
      takingBetaBlocker: takingBetaBlocker ?? this.takingBetaBlocker,
      hasHeartCondition: hasHeartCondition ?? this.hasHeartCondition,
      customZones: clearCustomZones ? null : (customZones ?? this.customZones),
    );
  }
}
