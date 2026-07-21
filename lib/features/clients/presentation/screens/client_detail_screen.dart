import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_zones/hr_zones.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/providers.dart';
import '../../../programmes/domain/models/programme.dart';
import '../../../templates/domain/models/workout_template.dart';
import '../../domain/models/client.dart';
import '../../domain/models/client_plan_assignment.dart';

/// Assignments for one client, resolved to the plan's display name.
///
/// Exposed (not file-private) so widget tests can override it with an
/// in-memory double instead of driving the real Drift watch stream.
final clientAssignmentsProvider = StreamProvider.autoDispose
    .family<List<ClientPlanAssignment>, String>((ref, clientId) {
  return ref
      .watch(clientPlanAssignmentRepositoryProvider)
      .watchAssignments(clientId);
});

/// Library plans (templates + programmes) offered by the assign picker.
///
/// Exposed for the same test-override reason as [clientAssignmentsProvider].
final clientDetailTemplatesProvider =
    StreamProvider.autoDispose<List<WorkoutTemplate>>((ref) {
  return ref.watch(workoutTemplateRepositoryProvider).watchAllTemplates();
});

final clientDetailProgrammesProvider =
    StreamProvider.autoDispose<List<Programme>>((ref) {
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
          _HealthProfileEditor(clientId: clientId),
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
    final assignments = ref.watch(clientAssignmentsProvider(clientId));

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
      final programmes = ref.watch(clientDetailProgrammesProvider).value;
      for (final programme in programmes ?? const <Programme>[]) {
        if (programme.id == assignment.planId) return programme.name;
      }
      return null;
    }
    final templates = ref.watch(clientDetailTemplatesProvider).value;
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
    final templates =
        ref.watch(clientDetailTemplatesProvider).value ?? const [];
    final programmes =
        ref.watch(clientDetailProgrammesProvider).value ?? const [];

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

/// Loads the client's stored profile, then hands it to [_HealthProfileForm]
/// to edit. Editing here always targets [clientId], regardless of which
/// client is active elsewhere in the app.
class _HealthProfileEditor extends ConsumerWidget {
  const _HealthProfileEditor({required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clientHealthProfileProvider(clientId));

    return profile.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error.toString()),
      ),
      data: (value) => _HealthProfileForm(
        key: ValueKey(clientId),
        clientId: clientId,
        initialProfile: value,
      ),
    );
  }
}

final clientHealthProfileProvider =
    FutureProvider.autoDispose.family<HealthProfile, String>((ref, clientId) {
  return ref.watch(healthProfileRepositoryProvider).getForClient(clientId);
});

/// Editable form for a single client's health profile. Saves directly via
/// [healthProfileRepositoryProvider] rather than [healthProfileProvider],
/// which is hard-wired to the active client.
class _HealthProfileForm extends ConsumerStatefulWidget {
  const _HealthProfileForm({
    super.key,
    required this.clientId,
    required this.initialProfile,
  });

  final String clientId;
  final HealthProfile initialProfile;

  @override
  ConsumerState<_HealthProfileForm> createState() => _HealthProfileFormState();
}

class _HealthProfileFormState extends ConsumerState<_HealthProfileForm> {
  late final TextEditingController _ageController;
  late final TextEditingController _restingHrController;
  late final TextEditingController _measuredMaxHrController;
  late final TextEditingController _clinicianMaxHrController;
  late bool _betaBlocker;
  late bool _heartCondition;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _ageController = TextEditingController(text: profile.age?.toString() ?? '');
    _restingHrController =
        TextEditingController(text: profile.restingHr?.toString() ?? '');
    _measuredMaxHrController =
        TextEditingController(text: profile.measuredMaxHr?.toString() ?? '');
    _clinicianMaxHrController =
        TextEditingController(text: profile.clinicianMaxHr?.toString() ?? '');
    _betaBlocker = profile.betaBlocker;
    _heartCondition = profile.heartCondition;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _restingHrController.dispose();
    _measuredMaxHrController.dispose();
    _clinicianMaxHrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: s.ageLabel,
              hintText: s.ageHint,
              suffixText: s.yearsSuffix,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _restingHrController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: s.restingHeartRate,
              hintText: s.restingHrHint,
              suffixText: s.bpmSuffix,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _measuredMaxHrController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: s.measuredMaxHeartRate,
              hintText: s.measuredMaxHrHint,
              suffixText: s.bpmSuffix,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _clinicianMaxHrController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: s.clinicianMaxHeartRate,
              hintText: s.clinicianMaxHrHint,
              suffixText: s.bpmSuffix,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.betaBlockerMedication),
            value: _betaBlocker,
            onChanged: (value) => setState(() => _betaBlocker = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.heartConditionLabel),
            value: _heartCondition,
            onChanged: (value) => setState(() => _heartCondition = value),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _save,
              child: Text(s.save),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final s = S.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final profile = HealthProfile(
      age: int.tryParse(_ageController.text),
      restingHr: int.tryParse(_restingHrController.text),
      measuredMaxHr: int.tryParse(_measuredMaxHrController.text),
      clinicianMaxHr: int.tryParse(_clinicianMaxHrController.text),
      betaBlocker: _betaBlocker,
      heartCondition: _heartCondition,
    );
    await ref
        .read(healthProfileRepositoryProvider)
        .saveForClient(widget.clientId, profile);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(s.healthProfileSaved)));
  }
}
