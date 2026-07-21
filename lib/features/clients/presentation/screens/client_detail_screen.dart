import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/providers.dart';
import '../../../programmes/domain/models/programme.dart';
import '../../../templates/domain/models/workout_template.dart';
import '../../domain/models/client.dart';
import '../../domain/models/client_plan_assignment.dart';

/// Assignments for one client, resolved to the plan's display name.
final _assignmentsProvider = StreamProvider.autoDispose
    .family<List<ClientPlanAssignment>, String>((ref, clientId) {
  return ref
      .watch(clientPlanAssignmentRepositoryProvider)
      .watchAssignments(clientId);
});

/// Library plans (templates + programmes) offered by the assign picker.
final _templatesProvider =
    StreamProvider.autoDispose<List<WorkoutTemplate>>((ref) {
  return ref.watch(workoutTemplateRepositoryProvider).watchAllTemplates();
});

final _programmesProvider = StreamProvider.autoDispose<List<Programme>>((ref) {
  return ref.watch(programmeRepositoryProvider).watchAllProgrammes();
});

/// A client's plan assignments and their stored health profile.
class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final clients = ref.watch(clientsProvider).value ?? const <Client>[];
    Client? client;
    for (final candidate in clients) {
      if (candidate.id == clientId) {
        client = candidate;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(client?.name ?? s.clientsTitle),
        leading: client == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 16),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(client.colour),
                ),
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeading(s.assignedPlans),
          _AssignedPlans(clientId: clientId),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => _showAssignPicker(context, ref),
                icon: const Icon(Icons.playlist_add),
                label: Text(s.assignPlan),
              ),
            ),
          ),
          const Divider(height: 1),
          _SectionHeading(s.clientHealthProfile),
          _HealthProfileSummary(clientId: clientId),
        ],
      ),
    );
  }

  Future<void> _showAssignPicker(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _AssignPlanSheet(clientId: clientId),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _AssignedPlans extends ConsumerWidget {
  const _AssignedPlans({required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final assignments = ref.watch(_assignmentsProvider(clientId));

    return assignments.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error.toString()),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              s.noPlansAssigned,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return Column(
          children: [
            for (final assignment in rows)
              ListTile(
                leading: Icon(assignment.planType == PlanType.programme
                    ? Icons.calendar_month_outlined
                    : Icons.list_alt_outlined),
                title: Text(_planName(ref, assignment) ?? assignment.planId),
                trailing: IconButton(
                  tooltip: s.unassignPlan,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => ref
                      .read(clientPlanAssignmentRepositoryProvider)
                      .unassign(assignment.id),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Resolves a plan id to its library name, or null while the lists load.
  String? _planName(WidgetRef ref, ClientPlanAssignment assignment) {
    if (assignment.planType == PlanType.programme) {
      final programmes = ref.watch(_programmesProvider).value;
      for (final programme in programmes ?? const <Programme>[]) {
        if (programme.id == assignment.planId) return programme.name;
      }
      return null;
    }
    final templates = ref.watch(_templatesProvider).value;
    for (final template in templates ?? const <WorkoutTemplate>[]) {
      if (template.id == assignment.planId) return template.name;
    }
    return null;
  }
}

class _AssignPlanSheet extends ConsumerWidget {
  const _AssignPlanSheet({required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final templates = ref.watch(_templatesProvider).value ?? const [];
    final programmes = ref.watch(_programmesProvider).value ?? const [];

    Future<void> assign(PlanType type, String planId) async {
      Navigator.of(context).pop();
      await ref
          .read(clientPlanAssignmentRepositoryProvider)
          .assign(clientId, type, planId);
    }

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              s.assignPlan,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final template in templates)
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: Text(template.name),
              onTap: () => assign(PlanType.template, template.id),
            ),
          for (final programme in programmes)
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(programme.name),
              onTap: () => assign(PlanType.programme, programme.id),
            ),
        ],
      ),
    );
  }
}

/// Read-only view of the client's stored profile. Editing still happens
/// through the heart-rate screens, which are scoped to the active client.
class _HealthProfileSummary extends ConsumerWidget {
  const _HealthProfileSummary({required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context)!;
    final profile = ref.watch(_healthProfileProvider(clientId));

    return profile.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error.toString()),
      ),
      data: (value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileRow(label: s.ageLabel, value: value.age?.toString()),
          _ProfileRow(
            label: s.restingHrLabel,
            value: value.restingHr?.toString(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              s.healthProfileEditHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

final _healthProfileProvider =
    FutureProvider.autoDispose.family<HealthProfile, String>((ref, clientId) {
  return ref.watch(healthProfileRepositoryProvider).getForClient(clientId);
});

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value ?? s.healthProfileNotSet),
        ],
      ),
    );
  }
}
