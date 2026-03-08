import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../../core/providers.dart';
import '../../../../core/widgets/progress_chart_widget.dart';
import '../../domain/models/body_metric.dart';

class BodyMetricsScreen extends ConsumerWidget {
  const BodyMetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final metricsAsync = ref.watch(bodyMetricsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.bodyMetricsTitle)),
      body: metricsAsync.when(
        data: (metrics) {
          if (metrics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monitor_weight_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(s.noBodyMetricsYet),
                  const SizedBox(height: 8),
                  Text(
                    s.noBodyMetricsYetSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (metrics.length >= 2) ...[
                _WeightChart(metrics: metrics),
                const SizedBox(height: 24),
              ],
              if (metrics.isNotEmpty) ...[
                _LatestCard(metric: metrics.first),
                const SizedBox(height: 16),
              ],
              Text(
                s.bodyMetricsHistory,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              for (final metric in metrics)
                _MetricTile(metric: metric),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(s.addBodyMetric),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final s = S.of(context)!;
    final weightController = TextEditingController();
    final bfController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<BodyMetric>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.addBodyMetric),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: s.bodyWeightLabel,
                  border: const OutlineInputBorder(),
                  suffixText: 'kg',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return s.validationRequired;
                  if (double.tryParse(v) == null) return s.validationInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bfController,
                decoration: InputDecoration(
                  labelText: s.bodyFatPercentLabel,
                  border: const OutlineInputBorder(),
                  suffixText: '%',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: s.notesLabel,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final weight = double.parse(weightController.text);
              final bf = bfController.text.isNotEmpty
                  ? double.tryParse(bfController.text)
                  : null;
              final notes = notesController.text.isNotEmpty
                  ? notesController.text
                  : null;
              Navigator.pop(
                ctx,
                BodyMetric.create(
                  weight: weight,
                  bodyFatPercent: bf,
                  notes: notes,
                ),
              );
            },
            child: Text(s.save),
          ),
        ],
      ),
    );

    weightController.dispose();
    bfController.dispose();
    notesController.dispose();

    if (result != null) {
      await ref.read(bodyMetricRepositoryProvider).create(result);
    }
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.metrics});

  final List<BodyMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    // Metrics arrive newest-first; reverse for chronological order.
    final points = metrics.reversed
        .map((m) => ProgressDataPoint(date: m.date, value: m.weight))
        .toList();
    return ProgressChartWidget(label: s.bodyWeightTrendTitle, dataPoints: points);
  }
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.metric});

  final BodyMetric metric;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.latestWeight,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${metric.weight} kg',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (metric.bodyFatPercent != null)
                    Text(
                      '${metric.bodyFatPercent}% ${s.bodyFatLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              DateFormat.MMMd().format(metric.date.toLocal()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends ConsumerWidget {
  const _MetricTile({required this.metric});

  final BodyMetric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat.yMMMd().format(metric.date.toLocal());

    return Dismissible(
      key: ValueKey(metric.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(bodyMetricRepositoryProvider).delete(metric.id);
      },
      child: ListTile(
        title: Text('${metric.weight} kg'),
        subtitle: Text(
          [
            dateStr,
            if (metric.bodyFatPercent != null) '${metric.bodyFatPercent}% BF',
            if (metric.notes != null) metric.notes!,
          ].join(' · '),
        ),
        leading: const Icon(Icons.monitor_weight_outlined),
      ),
    );
  }
}
