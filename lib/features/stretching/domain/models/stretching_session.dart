import 'package:uuid/uuid.dart';

/// How a stretching session's duration was captured.
enum StretchingEntryMethod {
  /// User started a stopwatch and stopped it when finished.
  timer,

  /// User typed in a duration directly.
  manual,
}

/// Optional side-of-body label for unilateral stretches.
enum StretchingSide {
  left,
  right,
  both,
  notApplicable,
}

/// Optional body-area label, kept loose so users can pick from a short
/// preset list without forcing a taxonomy.
enum StretchingBodyArea {
  neck,
  shoulders,
  chest,
  back,
  hips,
  hipFlexors,
  glutes,
  hamstrings,
  quadriceps,
  adductors,
  calves,
  ankles,
  wrists,
  fullBody,
}

/// A single stretching entry attached to a workout. Stored as its own
/// activity type — not a strength set or a cardio session — so reports,
/// PRs, and volume calculations are untouched by stretching.
class StretchingSession {
  final String id;
  final String workoutId;

  /// Either a preset key from [defaultStretches] or `'custom'` when the
  /// user typed in their own name (in which case [customName] is set).
  final String type;

  /// User-provided name when [type] is `'custom'`. Trimmed, max 60 chars.
  final String? customName;

  final StretchingBodyArea? bodyArea;
  final StretchingSide? side;
  final int durationSeconds;

  /// Wall-clock start of a timer-recorded session. Null for manual entries.
  final DateTime? startedAt;

  /// Wall-clock end of a timer-recorded session. Null for manual entries.
  final DateTime? endedAt;

  final StretchingEntryMethod entryMethod;
  final String? notes;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const StretchingSession({
    required this.id,
    required this.workoutId,
    required this.type,
    this.customName,
    this.bodyArea,
    this.side,
    required this.durationSeconds,
    this.startedAt,
    this.endedAt,
    required this.entryMethod,
    this.notes,
    required this.updatedAt,
    this.deletedAt,
  });

  Duration get duration => Duration(seconds: durationSeconds);

  bool get isDeleted => deletedAt != null;

  /// Resolves a human-readable label: [customName] when `type == 'custom'`,
  /// otherwise the preset display name, falling back to [type].
  String displayName({String Function(String key)? localiseKey}) {
    if (type == customStretchType) {
      final name = customName?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    if (localiseKey != null) return localiseKey(type);
    return defaultStretches
            .where((p) => p.key == type)
            .map((p) => p.englishName)
            .firstOrNull ??
        type;
  }

  static const String customStretchType = 'custom';

  static StretchingSession create({
    required String workoutId,
    required String type,
    required int durationSeconds,
    required StretchingEntryMethod entryMethod,
    String? customName,
    StretchingBodyArea? bodyArea,
    StretchingSide? side,
    DateTime? startedAt,
    DateTime? endedAt,
    String? notes,
  }) {
    final now = DateTime.now().toUtc();
    return StretchingSession(
      id: const Uuid().v4(),
      workoutId: workoutId,
      type: type,
      customName: customName,
      bodyArea: bodyArea,
      side: side,
      durationSeconds: durationSeconds,
      entryMethod: entryMethod,
      startedAt: startedAt,
      endedAt: endedAt,
      notes: notes,
      updatedAt: now,
    );
  }

  StretchingSession copyWith({
    String? type,
    String? customName,
    bool clearCustomName = false,
    StretchingBodyArea? bodyArea,
    bool clearBodyArea = false,
    StretchingSide? side,
    bool clearSide = false,
    int? durationSeconds,
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? endedAt,
    bool clearEndedAt = false,
    StretchingEntryMethod? entryMethod,
    String? notes,
    bool clearNotes = false,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return StretchingSession(
      id: id,
      workoutId: workoutId,
      type: type ?? this.type,
      customName: clearCustomName ? null : (customName ?? this.customName),
      bodyArea: clearBodyArea ? null : (bodyArea ?? this.bodyArea),
      side: clearSide ? null : (side ?? this.side),
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      entryMethod: entryMethod ?? this.entryMethod,
      notes: clearNotes ? null : (notes ?? this.notes),
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StretchingSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A curated stretch preset shown in the picker UI.
class StretchPreset {
  final String key;
  final String englishName;
  final StretchingBodyArea bodyArea;

  const StretchPreset({
    required this.key,
    required this.englishName,
    required this.bodyArea,
  });
}

/// 20 common stretches, drawn from publicly-known stretches catalogued by
/// Mayo Clinic, Self magazine and Pliability. Includes front splits and
/// side splits per the issue brief. The [key] is what's stored in the
/// database — display names can be localised separately.
const List<StretchPreset> defaultStretches = [
  StretchPreset(
    key: 'standingHamstring',
    englishName: 'Standing Hamstring Stretch',
    bodyArea: StretchingBodyArea.hamstrings,
  ),
  StretchPreset(
    key: 'seatedForwardFold',
    englishName: 'Seated Forward Fold',
    bodyArea: StretchingBodyArea.hamstrings,
  ),
  StretchPreset(
    key: 'standingQuad',
    englishName: 'Standing Quadriceps Stretch',
    bodyArea: StretchingBodyArea.quadriceps,
  ),
  StretchPreset(
    key: 'lowLungeHipFlexor',
    englishName: 'Low Lunge Hip Flexor',
    bodyArea: StretchingBodyArea.hipFlexors,
  ),
  StretchPreset(
    key: 'pigeon',
    englishName: 'Pigeon Pose',
    bodyArea: StretchingBodyArea.hips,
  ),
  StretchPreset(
    key: 'butterfly',
    englishName: 'Butterfly Stretch',
    bodyArea: StretchingBodyArea.hips,
  ),
  StretchPreset(
    key: 'childsPose',
    englishName: "Child's Pose",
    bodyArea: StretchingBodyArea.back,
  ),
  StretchPreset(
    key: 'cobra',
    englishName: 'Cobra Stretch',
    bodyArea: StretchingBodyArea.back,
  ),
  StretchPreset(
    key: 'catCow',
    englishName: 'Cat–Cow',
    bodyArea: StretchingBodyArea.back,
  ),
  StretchPreset(
    key: 'downwardDog',
    englishName: 'Downward-Facing Dog',
    bodyArea: StretchingBodyArea.fullBody,
  ),
  StretchPreset(
    key: 'crossBodyShoulder',
    englishName: 'Cross-Body Shoulder Stretch',
    bodyArea: StretchingBodyArea.shoulders,
  ),
  StretchPreset(
    key: 'doorwayChest',
    englishName: 'Doorway Chest Stretch',
    bodyArea: StretchingBodyArea.chest,
  ),
  StretchPreset(
    key: 'standingCalf',
    englishName: 'Standing Calf Stretch',
    bodyArea: StretchingBodyArea.calves,
  ),
  StretchPreset(
    key: 'supineSpinalTwist',
    englishName: 'Supine Spinal Twist',
    bodyArea: StretchingBodyArea.back,
  ),
  StretchPreset(
    key: 'neckSideStretch',
    englishName: 'Neck Side Stretch',
    bodyArea: StretchingBodyArea.neck,
  ),
  StretchPreset(
    key: 'figureFourGlute',
    englishName: 'Figure-4 Glute Stretch',
    bodyArea: StretchingBodyArea.glutes,
  ),
  StretchPreset(
    key: 'ninetyNinety',
    englishName: '90/90 Hip Stretch',
    bodyArea: StretchingBodyArea.hips,
  ),
  StretchPreset(
    key: 'frogPose',
    englishName: 'Frog Pose',
    bodyArea: StretchingBodyArea.adductors,
  ),
  StretchPreset(
    key: 'frontSplits',
    englishName: 'Front Splits',
    bodyArea: StretchingBodyArea.hamstrings,
  ),
  StretchPreset(
    key: 'sideSplits',
    englishName: 'Side Splits (Middle Splits)',
    bodyArea: StretchingBodyArea.adductors,
  ),
];
