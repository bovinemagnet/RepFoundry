import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';
import '../../../../core/providers.dart';
import '../../../../core/units/weight_unit.dart';
import '../../../../core/units/weight_unit_provider.dart';
import '../../../../core/widgets/progress_chart_widget.dart';
import '../../../clients/domain/models/client.dart';
import '../../../clients/presentation/providers/active_client_provider.dart';
import '../../../health_sync/data/health_sync_service.dart';
import '../../../health_sync/presentation/providers/health_sync_settings_provider.dart';
import '../../../health_sync/presentation/providers/health_weight_import_provider.dart';
import '../../domain/models/body_metric.dart';

class BodyMetricsScreen extends ConsumerWidget {
  const BodyMetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final metricsAsync = ref.watch(bodyMetricsStreamProvider);

    ref.listen<AsyncValue<WeightSample?>>(healthWeightCheckProvider,
        (previous, next) {
      if (previous is AsyncLoading && next is AsyncData<WeightSample?>) {
        final sample = next.value;
        if (sample != null) {
          final unit = ref.read(weightUnitProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.importWeightPrompt(
                  unit.formatFromKg(sample.weightKg), unit.label(s))),
              action: SnackBarAction(
                label: s.importWeightAction,
                onPressed: () async {
                  // Platform health data (Apple Health / Google Fit) belongs
                  // to the device owner — the coach — so it always imports
                  // to the Me client, regardless of which client is active.
                  final metric = BodyMetric.create(
                    weight: sample.weightKg,
                    date: sample.date,
                    clientId: kSelfClientId,
                  );
                  await ref.read(bodyMetricRepositoryProvider).create(metric);
                },
              ),
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    });

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
              for (final metric in metrics) _MetricTile(metric: metric),
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
    final result = await showDialog<BodyMetric>(
      context: context,
      builder: (ctx) => const _AddBodyMetricDialog(),
    );

    if (result != null) {
      await ref.read(bodyMetricRepositoryProvider).create(result);

      // Sync to health store if enabled
      try {
        final healthSettings = ref.read(healthSyncSettingsProvider);
        if (healthSettings.enabled && healthSettings.writeWeight) {
          final healthService = ref.read(healthSyncServiceProvider);
          await healthService.writeWeight(
            weightKg: result.weight,
            dateTime: result.date,
          );
          if (result.bodyFatPercent != null) {
            await healthService.writeBodyFat(
              percent: result.bodyFatPercent!,
              dateTime: result.date,
            );
          }
        }
      } catch (_) {
        // Health sync is best-effort
      }
    }
  }
}

/// Add-measurement dialog. Owns its [TextEditingController]s in [State] so they
/// are disposed only after the dialog route is removed — disposing them inline
/// after `showDialog` returns triggers a "used after disposed" error when the
/// dialog rebuilds during its exit transition.
class _AddBodyMetricDialog extends ConsumerStatefulWidget {
  const _AddBodyMetricDialog();

  @override
  ConsumerState<_AddBodyMetricDialog> createState() =>
      _AddBodyMetricDialogState();
}

class _AddBodyMetricDialogState extends ConsumerState<_AddBodyMetricDialog> {
  final _weightController = TextEditingController();
  final _bfController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _weightController.dispose();
    _bfController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final unit = ref.watch(weightUnitProvider);
    return AlertDialog(
      title: Text(s.addBodyMetric),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: s.bodyWeightLabel,
                border: const OutlineInputBorder(),
                suffixText: unit.label(s),
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
              controller: _bfController,
              decoration: InputDecoration(
                labelText: s.bodyFatPercentLabel,
                border: const OutlineInputBorder(),
                suffixText: s.percentSuffix,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
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
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final weight = ref
                .read(weightUnitProvider)
                .toKg(double.parse(_weightController.text));
            final bf = _bfController.text.isNotEmpty
                ? double.tryParse(_bfController.text)
                : null;
            final notes =
                _notesController.text.isNotEmpty ? _notesController.text : null;
            Navigator.pop(
              context,
              BodyMetric.create(
                weight: weight,
                bodyFatPercent: bf,
                notes: notes,
                clientId:
                    ref.read(activeClientProvider).value?.id ?? kSelfClientId,
              ),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _WeightChart extends ConsumerWidget {
  const _WeightChart({required this.metrics});

  final List<BodyMetric> metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final unit = ref.watch(weightUnitProvider);
    // Metrics arrive newest-first; reverse for chronological order.
    final points = metrics.reversed
        .map((m) =>
            ProgressDataPoint(date: m.date, value: unit.fromKg(m.weight)))
        .toList();
    return ProgressChartWidget(
        label: s.bodyWeightTrendTitle, dataPoints: points);
  }
}

class _LatestCard extends ConsumerWidget {
  const _LatestCard({required this.metric});

  final BodyMetric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    final unit = ref.watch(weightUnitProvider);

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
                    '${unit.formatFromKg(metric.weight)} ${unit.label(s)}',
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
    final s = S.of(context)!;
    final unit = ref.watch(weightUnitProvider);
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
        title: Text('${unit.formatFromKg(metric.weight)} ${unit.label(s)}'),
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
