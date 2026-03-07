import 'package:flutter/material.dart';

/// Shows a bottom sheet with device-specific setup instructions for
/// BLE heart rate broadcasting from watches and straps.
Future<void> showHrSetupGuide(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _HrSetupGuideSheet(),
  );
}

class _HrSetupGuideSheet extends StatelessWidget {
  const _HrSetupGuideSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Heart Rate Setup Guide',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    _DeviceSection(
                      icon: Icons.watch,
                      title: 'Apple Watch',
                      steps: [
                        'On your Apple Watch, open Settings \u2192 Workout \u2192 Heart Rate.',
                        'Enable "Broadcast Heart Rate".',
                        'Start any workout on the Apple Watch.',
                        'In RepFoundry, tap "Connect" and select your Apple Watch.',
                      ],
                    ),
                    SizedBox(height: 16),
                    _DeviceSection(
                      icon: Icons.watch,
                      title: 'Samsung Galaxy Watch',
                      steps: [
                        'Open Samsung Health on your watch.',
                        'Go to Settings \u2192 Heart Rate Broadcast.',
                        'Enable BLE broadcasting.',
                        'In RepFoundry, tap "Connect" and select your Galaxy Watch.',
                      ],
                    ),
                    SizedBox(height: 16),
                    _DeviceSection(
                      icon: Icons.monitor_heart,
                      title: 'Chest Straps & Arm Bands',
                      steps: [
                        'Any BLE heart rate device (Polar, Garmin, Wahoo, etc.) works automatically.',
                        'Simply wear your strap or band and tap "Connect".',
                        'Your device will appear in the scan list.',
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeviceSection extends StatelessWidget {
  const _DeviceSection({
    required this.icon,
    required this.title,
    required this.steps,
  });

  final IconData icon;
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...steps.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${entry.key + 1}.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
