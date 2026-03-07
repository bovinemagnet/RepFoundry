import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../domain/analytics_events.dart';
import '../providers/health_profile_provider.dart';

/// Shows a multi-step health profile onboarding bottom sheet.
Future<void> showHealthProfileOnboarding(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _HealthProfileOnboarding(),
  );
}

class _HealthProfileOnboarding extends ConsumerStatefulWidget {
  const _HealthProfileOnboarding();

  @override
  ConsumerState<_HealthProfileOnboarding> createState() =>
      _HealthProfileOnboardingState();
}

class _HealthProfileOnboardingState
    extends ConsumerState<_HealthProfileOnboarding> {
  int _step = 0;
  final _ageController = TextEditingController();
  final _restingHrController = TextEditingController();
  final _measuredMaxController = TextEditingController();
  final _clinicianMaxController = TextEditingController();
  bool _betaBlocker = false;
  bool _heartCondition = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(healthProfileProvider);
    _ageController.text = profile.age?.toString() ?? '';
    _restingHrController.text = profile.restingHeartRate?.toString() ?? '';
    _measuredMaxController.text =
        profile.measuredMaxHeartRate?.toString() ?? '';
    _clinicianMaxController.text = profile.clinicianMaxHr?.toString() ?? '';
    _betaBlocker = profile.takingBetaBlocker;
    _heartCondition = profile.hasHeartCondition;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _restingHrController.dispose();
    _measuredMaxController.dispose();
    _clinicianMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Set Up Heart Rate Zones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                'Step ${_step + 1} of 4',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: (_step + 1) / 4),
          const SizedBox(height: 20),
          _buildStep(),
          const SizedBox(height: 20),
          _buildNav(),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _ageStep();
      case 1:
        return _heartRateStep();
      case 2:
        return _medicalStep();
      case 3:
        return _clinicianStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _ageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your age is used to estimate your maximum heart rate and '
          'personalise training zones.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Age',
            hintText: 'e.g. 30',
            border: OutlineInputBorder(),
            suffixText: 'years',
          ),
        ),
      ],
    );
  }

  Widget _heartRateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Providing your resting heart rate enables more accurate zone '
          'calculation using the Karvonen (heart rate reserve) method.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _restingHrController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Resting Heart Rate (optional)',
            hintText: 'e.g. 60',
            border: OutlineInputBorder(),
            suffixText: 'bpm',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _measuredMaxController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Measured Max Heart Rate (optional)',
            hintText: 'e.g. 185',
            border: OutlineInputBorder(),
            suffixText: 'bpm',
          ),
        ),
      ],
    );
  }

  Widget _medicalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'If any of these apply, heart rate zones will be shown in caution '
          'mode with reduced confidence. We recommend consulting your '
          'healthcare provider for personalised limits.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Taking beta blocker medication'),
          value: _betaBlocker,
          onChanged: (v) => setState(() => _betaBlocker = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Heart condition'),
          value: _heartCondition,
          onChanged: (v) => setState(() => _heartCondition = v),
        ),
      ],
    );
  }

  Widget _clinicianStep() {
    final showEmphasis = _betaBlocker || _heartCondition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showEmphasis
              ? 'Because you have medical factors, we strongly recommend '
                  'entering a clinician-provided maximum heart rate. This will '
                  'override all other estimates.'
              : 'If your doctor or exercise physiologist has given you a '
                  'maximum heart rate, enter it here to override the estimate.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: showEmphasis ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _clinicianMaxController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Clinician Max Heart Rate (optional)',
            hintText: 'e.g. 150',
            border: OutlineInputBorder(),
            suffixText: 'bpm',
          ),
        ),
      ],
    );
  }

  Widget _buildNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: const Text('Back'),
          )
        else
          const SizedBox.shrink(),
        Row(
          children: [
            if (_step < 3)
              TextButton(
                onPressed: () => _advance(skip: true),
                child: const Text('Skip'),
              ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _advance(skip: false),
              child: Text(_step == 3 ? 'Done' : 'Next'),
            ),
          ],
        ),
      ],
    );
  }

  void _advance({required bool skip}) {
    if (!skip) {
      _saveCurrentStep();
    }
    if (_step < 3) {
      setState(() => _step++);
    } else {
      final reporter = ref.read(hrAnalyticsReporterProvider);
      reporter.trackEvent(HrAnalyticsEvent.onboardingCompleted);
      Navigator.pop(context);
    }
  }

  void _saveCurrentStep() {
    final notifier = ref.read(healthProfileProvider.notifier);
    switch (_step) {
      case 0:
        final age = int.tryParse(_ageController.text);
        if (age != null && age > 0 && age <= 120) {
          notifier.updateAge(age);
        }
      case 1:
        final restingHr = int.tryParse(_restingHrController.text);
        if (restingHr != null && restingHr > 20 && restingHr <= 220) {
          notifier.updateRestingHeartRate(restingHr);
        }
        final measuredMax = int.tryParse(_measuredMaxController.text);
        if (measuredMax != null && measuredMax > 60 && measuredMax <= 250) {
          notifier.updateMeasuredMaxHeartRate(measuredMax);
        }
      case 2:
        notifier.setTakingBetaBlocker(_betaBlocker);
        notifier.setHasHeartCondition(_heartCondition);
      case 3:
        final clinicianMax = int.tryParse(_clinicianMaxController.text);
        if (clinicianMax != null && clinicianMax > 60 && clinicianMax <= 250) {
          notifier.setClinicianMaxHr(clinicianMax);
        }
    }
  }
}
