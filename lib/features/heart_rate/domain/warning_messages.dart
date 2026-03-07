/// Warning and disclaimer text constants for the heart rate feature.
///
/// All text uses British spelling and is suitable for localisation.
class WarningMessages {
  WarningMessages._();

  static const generalDisclaimer =
      'Heart rate zone estimates are for informational purposes only and do not '
      'constitute medical advice. Always consult a healthcare professional '
      'before starting or modifying an exercise programme, especially if you '
      'have a pre-existing medical condition.';

  static const betaBlockerWarning =
      'Beta blocker medication can significantly reduce your maximum heart '
      'rate. Standard zone calculations may not be accurate. We recommend '
      'setting a clinician-provided maximum heart rate or using rate of '
      'perceived exertion (RPE) and the talk test to gauge intensity.';

  static const heartConditionWarning =
      'You have indicated a heart condition. Standard heart rate zone '
      'calculations may not be appropriate. We strongly recommend obtaining '
      'a clinician-provided maximum heart rate before using intensity-based '
      'training guidance.';

  static const clinicianCapNotice =
      'Heart rate zones are calculated using a clinician-provided maximum '
      'heart rate. This overrides any age-based or measured estimates.';

  static const stopExercisePrompt =
      'If you are experiencing chest pain, severe dizziness, fainting, or '
      'unusual shortness of breath, stop exercising immediately. If symptoms '
      'persist, seek urgent medical attention.';

  static const symptomListIntro =
      'Are you experiencing any of the following symptoms?';

  static const List<String> symptomOptions = [
    'Chest pain or tightness',
    'Severe dizziness or light-headedness',
    'Feeling faint or about to faint',
    'Unusual shortness of breath',
  ];
}
