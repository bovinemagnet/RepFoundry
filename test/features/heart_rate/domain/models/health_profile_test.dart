import 'package:flutter_test/flutter_test.dart';
import 'package:rep_foundry/features/heart_rate/domain/models/health_profile.dart';

void main() {
  group('HealthProfile', () {
    test('estimatedMaxHr returns 220 minus age', () {
      const profile = HealthProfile(age: 49);
      expect(profile.estimatedMaxHr, 171);
    });

    test('estimatedMaxHr is null when age is null', () {
      const profile = HealthProfile();
      expect(profile.estimatedMaxHr, isNull);
    });

    test('isCautionMode is true when taking beta blocker', () {
      const profile = HealthProfile(takingBetaBlocker: true);
      expect(profile.isCautionMode, isTrue);
    });

    test('isCautionMode is true when has heart condition', () {
      const profile = HealthProfile(hasHeartCondition: true);
      expect(profile.isCautionMode, isTrue);
    });

    test('isCautionMode is true when both flags set', () {
      const profile = HealthProfile(
        takingBetaBlocker: true,
        hasHeartCondition: true,
      );
      expect(profile.isCautionMode, isTrue);
    });

    test('isCautionMode is false by default', () {
      const profile = HealthProfile(age: 30);
      expect(profile.isCautionMode, isFalse);
    });

    test('copyWith preserves values when no overrides given', () {
      const profile = HealthProfile(
        age: 40,
        restingHeartRate: 60,
        takingBetaBlocker: true,
      );
      final copy = profile.copyWith();
      expect(copy.age, 40);
      expect(copy.restingHeartRate, 60);
      expect(copy.takingBetaBlocker, isTrue);
    });

    test('copyWith clears fields when clear flags set', () {
      const profile = HealthProfile(
        age: 40,
        restingHeartRate: 60,
        clinicianMaxHr: 150,
      );
      final copy = profile.copyWith(
        clearAge: true,
        clearRestingHeartRate: true,
        clearClinicianMaxHr: true,
      );
      expect(copy.age, isNull);
      expect(copy.restingHeartRate, isNull);
      expect(copy.clinicianMaxHr, isNull);
    });
  });
}
