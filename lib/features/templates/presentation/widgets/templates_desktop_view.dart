import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../../../core/providers.dart';
import '../../../../core/widgets/desktop_top_bar.dart';
import '../../../../core/widgets/kinetic.dart';
import '../../domain/models/workout_template.dart';
import '../providers/template_list_provider.dart';

/// Desktop "power layout" for Templates — a library + canvas split: the
/// template library on the left and the selected template's exercise canvas on
/// the right. The canvas opens the full inline editor for deeper edits.
class TemplatesDesktopView extends ConsumerStatefulWidget {
  const TemplatesDesktopView({super.key});

  @override
  ConsumerState<TemplatesDesktopView> createState() =>
      _TemplatesDesktopViewState();
}

class _TemplatesDesktopViewState extends ConsumerState<TemplatesDesktopView> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final templatesAsync = ref.watch(templateListProvider);

    return Scaffold(
      body: Column(
        children: [
          DesktopTopBar(
            eyebrow: s.navGroupPlan,
            title: s.templatesTitle,
            actions: [
              _PrimaryButton(
                icon: Icons.add,
                label: s.newTemplate,
                onPressed: () => _createTemplate(context, ref),
              ),
            ],
          ),
          Expanded(
            child: templatesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(s.failedToLoadTemplates(e.toString()))),
              data: (templates) {
                if (templates.isEmpty) return _EmptyTemplates();

                final selected = templates.firstWhere(
                  (t) => t.id == _selectedId,
                  orElse: () => templates.first,
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final libraryWidth =
                        (constraints.maxWidth * 0.34).clamp(0.0, 320.0);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: libraryWidth,
                          child: _LibraryPane(
                            templates: templates,
                            selectedId: selected.id,
                            onSelect: (id) => setState(() => _selectedId = id),
                          ),
                        ),
                        Container(width: 1, color: cs.outlineVariant),
                        Expanded(child: _CanvasPane(template: selected)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createTemplate(BuildContext context, WidgetRef ref) async {
    final s = S.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.newTemplateTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: s.templateNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(s.create),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    final template = WorkoutTemplate.create(name: name);
    await ref.read(workoutTemplateRepositoryProvider).createTemplate(template);
    if (context.mounted) {
      setState(() => _selectedId = template.id);
      context.push('/templates/${template.id}');
    }
  }
}

// ── Left pane: library ────────────────────────────────────────────────────

class _LibraryPane extends StatelessWidget {
  const _LibraryPane({
    required this.templates,
    required this.selectedId,
    required this.onSelect,
  });

  final List<WorkoutTemplate> templates;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child:
              KineticSectionLabel('${s.templatesTitle} · ${templates.length}'),
        ),
        for (final template in templates)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LibraryRow(
              template: template,
              selected: template.id == selectedId,
              onTap: () => onSelect(template.id),
            ),
          ),
      ],
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final WorkoutTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.12)
          : cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary.withValues(alpha: 0.18)
                      : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.dashboard_outlined,
                  size: 18,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KineticText.display(
                        size: 15,
                        weight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.exerciseCount(template.exercises.length),
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Right pane: canvas ────────────────────────────────────────────────────

class _CanvasPane extends StatelessWidget {
  const _CanvasPane({required this.template});

  final WorkoutTemplate template;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final exercises = [...template.exercises]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return ListView(
      padding: const EdgeInsets.fromLTRB(30, 26, 30, 40),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: KineticText.display(
                      size: 24,
                      weight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.exerciseCount(exercises.length),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _OutlineButton(
              icon: Icons.edit_outlined,
              label: s.editTemplate,
              onPressed: () => context.push('/templates/${template.id}'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (exercises.isEmpty)
          _CanvasEmpty(
            onAdd: () => context.push('/templates/${template.id}'),
          )
        else
          for (var i = 0; i < exercises.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CanvasExerciseCard(
                index: i + 1,
                name: exercises[i].exerciseName,
                sets: exercises[i].targetSets,
                reps: exercises[i].targetReps,
              ),
            ),
      ],
    );
  }
}

class _CanvasExerciseCard extends StatelessWidget {
  const _CanvasExerciseCard({
    required this.index,
    required this.name,
    required this.sets,
    required this.reps,
  });

  final int index;
  final String name;
  final int sets;
  final int reps;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Text(
            index.toString().padLeft(2, '0'),
            style: KineticText.mono(
              size: 14,
              weight: FontWeight.w700,
              color: cs.outline,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: KineticText.display(
                size: 16,
                weight: FontWeight.w700,
                letterSpacing: -0.2,
                color: cs.onSurface,
              ),
            ),
          ),
          KineticPill(
            '$sets × $reps',
            variant: KineticPillVariant.accent,
          ),
        ],
      ),
    );
  }
}

class _CanvasEmpty extends StatelessWidget {
  const _CanvasEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 34, color: cs.outline),
            const SizedBox(height: 12),
            Text(
              s.noExercisesFound,
              style: GoogleFonts.manrope(
                fontSize: 13.5,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            _OutlineButton(
              icon: Icons.add,
              label: s.addExerciseToTemplate,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty library ─────────────────────────────────────────────────────────

class _EmptyTemplates extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.view_list, size: 72, color: cs.outline),
          const SizedBox(height: 16),
          Text(s.noTemplatesYet, style: tt.headlineSmall),
          const SizedBox(height: 8),
          Text(
            s.noTemplatesYetSubtitle,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: cs.onPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: KineticText.mono(
                  size: 12.5,
                  letterSpacing: 0.6,
                  color: cs.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: cs.onSurface),
              const SizedBox(width: 8),
              Text(
                label,
                style: KineticText.mono(
                  size: 12.5,
                  letterSpacing: 0.6,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
