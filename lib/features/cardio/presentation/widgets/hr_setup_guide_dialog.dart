import 'package:flutter/material.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

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
    final s = S.of(context)!;
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
                s.hrSetupGuideTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _DeviceSection(
                      icon: Icons.watch,
                      title: s.appleWatchTitle,
                      steps: [
                        s.appleWatchStep1,
                        s.appleWatchStep2,
                        s.appleWatchStep3,
                        s.appleWatchStep4,
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DeviceSection(
                      icon: Icons.watch,
                      title: s.samsungWatchTitle,
                      steps: [
                        s.samsungWatchStep1,
                        s.samsungWatchStep2,
                        s.samsungWatchStep3,
                        s.samsungWatchStep4,
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DeviceSection(
                      icon: Icons.monitor_heart,
                      title: s.chestStrapsTitle,
                      steps: [
                        s.chestStrapStep1,
                        s.chestStrapStep2,
                        s.chestStrapStep3,
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
