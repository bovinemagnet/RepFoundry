import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../settings/presentation/providers/show_exercise_images_provider.dart';
import '../../domain/models/exercise.dart';
import '../helpers/exercise_labels.dart';

/// Exercise row for the picker screen (.exrow in rf.css).
///
/// Renders a 44 px circular avatar (muscle-group colour) containing either a
/// category icon or an image, the exercise name in Space Grotesk 16/700, and a
/// dim "Muscle · Equipment" subtitle.  When [isSelected] is true the row
/// receives the accent-soft background (.exrow--sel).
///
/// Built on [ListTile] so that widget tests can tap by type and the tapping
/// test passes without change.
class ExerciseListTile extends ConsumerWidget {
  const ExerciseListTile({
    super.key,
    required this.exercise,
    this.onTap,
    this.trailing,
    this.isSelected = false,
  });

  final Exercise exercise;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Whether this row should receive the accent-soft selection highlight.
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    // Per-muscle-group avatar colour — data colours, not theme tokens.
    final avatarColour = _avatarColourFor(exercise.muscleGroup);

    // Category icon used inside the avatar (tests assert on these icons).
    final categoryIconData = _iconForCategory(exercise.category);

    // Check whether an exercise image should be shown (existing settings logic).
    final showImages = ref.watch(showExerciseImagesProvider);
    final hasImage = showImages && exercise.imageAsset != null;

    // Avatar child: image (with icon fallback) or category icon.
    Widget avatarChild = Icon(
      categoryIconData,
      color: Colors.white,
      size: 20,
    );

    if (hasImage) {
      avatarChild = ClipOval(
        child: Image.asset(
          exercise.imageAsset!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          // Fall back to the category icon if the asset is missing.
          errorBuilder: (_, __, ___) => Icon(
            categoryIconData,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }

    // 44 px circular avatar (.exrow__av).
    final avatar = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: avatarColour, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: avatarChild,
    );

    // Selection highlight (.exrow--sel): accent-soft bg, slightly rounded.
    final bg =
        isSelected ? cs.primary.withValues(alpha: 0.14) : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isSelected ? 14 : 0),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12.0 : 4.0,
          vertical: 0,
        ),
        leading: avatar,
        title: Text(
          exercise.name,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.16,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          '${labelForMuscleGroup(exercise.muscleGroup)}  ·  ${labelForEquipment(exercise.equipmentType)}',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  /// Maps a category to its Material icon (asserted on by the widget tests).
  static IconData _iconForCategory(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.strength:
        return Icons.fitness_center;
      case ExerciseCategory.cardio:
        return Icons.directions_run;
      case ExerciseCategory.flexibility:
        return Icons.self_improvement;
      case ExerciseCategory.custom:
        return Icons.star;
    }
  }

  /// Returns a data colour for the muscle-group avatar.  These are fixed
  /// reference colours from the design spec (EX_LIB) and are intentionally
  /// not theme tokens.
  static Color _avatarColourFor(MuscleGroup group) {
    switch (group) {
      case MuscleGroup.chest:
        return const Color(0xff2f6f8f);
      case MuscleGroup.back:
        return const Color(0xff2f8f5b);
      case MuscleGroup.shoulders:
        return const Color(0xff5b7abf);
      case MuscleGroup.biceps:
        return const Color(0xffa14f9c);
      case MuscleGroup.triceps:
        return const Color(0xff9c6a2a);
      case MuscleGroup.forearms:
        return const Color(0xff7a6a3f);
      case MuscleGroup.core:
        return const Color(0xff5a8a4f);
      case MuscleGroup.quadriceps:
        return const Color(0xff8f5bbf);
      case MuscleGroup.hamstrings:
        return const Color(0xff7a4f8a);
      case MuscleGroup.glutes:
        return const Color(0xffb05a2a);
      case MuscleGroup.calves:
        return const Color(0xff4f7a6a);
      case MuscleGroup.fullBody:
        return const Color(0xff3a6a7a);
      case MuscleGroup.cardio:
        return const Color(0xff2f7a5a);
    }
  }
}
