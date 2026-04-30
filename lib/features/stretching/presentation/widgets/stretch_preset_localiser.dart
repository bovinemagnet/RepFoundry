import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../domain/models/stretching_session.dart';

/// Resolves a preset key (and custom name) to a localised display name.
String localiseStretch(S s, String type, {String? customName}) {
  if (type == StretchingSession.customStretchType) {
    final name = customName?.trim();
    if (name != null && name.isNotEmpty) return name;
  }
  switch (type) {
    case 'standingHamstring':
      return s.stretchPresetStandingHamstring;
    case 'seatedForwardFold':
      return s.stretchPresetSeatedForwardFold;
    case 'standingQuad':
      return s.stretchPresetStandingQuad;
    case 'lowLungeHipFlexor':
      return s.stretchPresetLowLungeHipFlexor;
    case 'pigeon':
      return s.stretchPresetPigeon;
    case 'butterfly':
      return s.stretchPresetButterfly;
    case 'childsPose':
      return s.stretchPresetChildsPose;
    case 'cobra':
      return s.stretchPresetCobra;
    case 'catCow':
      return s.stretchPresetCatCow;
    case 'downwardDog':
      return s.stretchPresetDownwardDog;
    case 'crossBodyShoulder':
      return s.stretchPresetCrossBodyShoulder;
    case 'doorwayChest':
      return s.stretchPresetDoorwayChest;
    case 'standingCalf':
      return s.stretchPresetStandingCalf;
    case 'supineSpinalTwist':
      return s.stretchPresetSupineSpinalTwist;
    case 'neckSideStretch':
      return s.stretchPresetNeckSideStretch;
    case 'figureFourGlute':
      return s.stretchPresetFigureFourGlute;
    case 'ninetyNinety':
      return s.stretchPresetNinetyNinety;
    case 'frogPose':
      return s.stretchPresetFrogPose;
    case 'frontSplits':
      return s.stretchPresetFrontSplits;
    case 'sideSplits':
      return s.stretchPresetSideSplits;
  }
  // Unknown preset key — fall back to the English defaults table.
  final preset = defaultStretches.where((p) => p.key == type).firstOrNull;
  return preset?.englishName ?? type;
}

String formatStretchDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final ss = seconds % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }
  return '$m:${ss.toString().padLeft(2, '0')}';
}
