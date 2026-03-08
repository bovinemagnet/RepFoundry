// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RepFoundry';

  @override
  String get navWorkout => 'Workout';

  @override
  String get navHistory => 'History';

  @override
  String get navCardio => 'Cardio';

  @override
  String get navHeartRate => 'Heart Rate';

  @override
  String get navSettings => 'Settings';

  @override
  String get start => 'Start';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get reset => 'Reset';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get finish => 'Finish';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get bpmSuffix => 'bpm';

  @override
  String get yearsSuffix => 'years';

  @override
  String get kgUnit => 'kg';

  @override
  String get lbsUnit => 'lbs';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionHealthProfile => 'Health Profile';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionUnits => 'Units';

  @override
  String get sectionRestTimer => 'Rest Timer';

  @override
  String get sectionData => 'Data';

  @override
  String get sectionAbout => 'About';

  @override
  String get ageLabel => 'Age';

  @override
  String ageSubtitleSet(int age, int maxHr) {
    return '$age years (max HR: $maxHr bpm)';
  }

  @override
  String get ageSubtitleEmpty => 'Set your age for heart rate zones';

  @override
  String get setYourAge => 'Set Your Age';

  @override
  String get ageHint => 'e.g. 30';

  @override
  String get restingHeartRate => 'Resting Heart Rate';

  @override
  String restingHrSubtitleSet(int bpm) {
    return '$bpm bpm';
  }

  @override
  String get restingHrSubtitleEmpty => 'Optional — enables Karvonen zones';

  @override
  String get restingHrHint => 'e.g. 60';

  @override
  String get measuredMaxHeartRate => 'Measured Max Heart Rate';

  @override
  String measuredMaxHrSubtitleSet(int bpm) {
    return '$bpm bpm';
  }

  @override
  String get measuredMaxHrSubtitleEmpty => 'Optional — from exercise testing';

  @override
  String get measuredMaxHrHint => 'e.g. 185';

  @override
  String get betaBlockerMedication => 'Beta Blocker Medication';

  @override
  String get betaBlockerSubtitle => 'Affects heart rate zone accuracy';

  @override
  String get heartConditionLabel => 'Heart Condition';

  @override
  String get heartConditionSubtitle => 'Enables caution mode for zones';

  @override
  String get clinicianMaxHeartRate => 'Clinician Max Heart Rate';

  @override
  String clinicianMaxHrSubtitleSet(int bpm) {
    return '$bpm bpm — overrides estimates';
  }

  @override
  String get clinicianMaxHrSubtitleEmpty => 'Optional — from your doctor';

  @override
  String get clinicianMaxHrHint => 'e.g. 150';

  @override
  String get zoneMethod => 'Zone Method';

  @override
  String zoneMethodAndReliability(String method, String reliability) {
    return '$method · $reliability confidence';
  }

  @override
  String get zoneMethodCustom => 'Custom zones';

  @override
  String get zoneMethodClinicianCap => 'Clinician cap';

  @override
  String get zoneMethodHrr => 'Heart rate reserve (Karvonen)';

  @override
  String get zoneMethodMeasuredMax => 'Measured max HR';

  @override
  String get zoneMethodEstimatedMax => 'Age-estimated max HR';

  @override
  String get reliabilityHigh => 'High';

  @override
  String get reliabilityMedium => 'Medium';

  @override
  String get reliabilityLow => 'Low';

  @override
  String get setUpHeartRateZones => 'Set Up Heart Rate Zones';

  @override
  String get stepByStepGuidedSetup => 'Step-by-step guided setup';

  @override
  String get zoneColourBands => 'Zone Colour Bands';

  @override
  String get zoneColourBandsSubtitle => 'Show coloured zone bands on HR chart';

  @override
  String get sectionMaxHrAlert => 'Max Heart Rate Alert';

  @override
  String get maxHrAlertVibration => 'Vibration on Max HR';

  @override
  String get maxHrAlertVibrationSubtitle =>
      'Vibrate when heart rate reaches the recommended maximum';

  @override
  String get maxHrAlertSound => 'Sound on Max HR';

  @override
  String get maxHrAlertSoundSubtitle =>
      'Play a warning sound when heart rate reaches the recommended maximum';

  @override
  String get maxHrAlertCooldown => 'Alert Cooldown';

  @override
  String get maxHrAlertCooldownSubtitle =>
      'Minimum seconds between repeated alerts';

  @override
  String maxHrAlertCooldownValue(int seconds) {
    return '${seconds}s';
  }

  @override
  String get maxHrReached => 'Heart rate at or above recommended maximum';

  @override
  String get disclaimerLabel => 'Disclaimer';

  @override
  String get settingsShowExerciseImages => 'Show Exercise Images';

  @override
  String get settingsShowExerciseImagesSubtitle =>
      'Display exercise illustrations in lists';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeAuto => 'Auto';

  @override
  String get weightUnitLabel => 'Weight Unit';

  @override
  String get vibrationAlert => 'Vibration Alert';

  @override
  String get vibrationAlertSubtitle => 'Vibrate when rest timer completes';

  @override
  String get soundAlert => 'Sound Alert';

  @override
  String get soundAlertSubtitle => 'Play a sound when rest timer completes';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get clearAllDataSubtitle =>
      'Permanently delete all workouts and settings.';

  @override
  String get clearAllDataConfirmTitle => 'Clear All Data?';

  @override
  String get clearAllDataConfirmContent =>
      'This will permanently delete all your workout history and cannot be undone.';

  @override
  String get allDataCleared => 'All data cleared.';

  @override
  String get aboutAppName => 'RepFoundry';

  @override
  String get aboutVersion => 'Version 1.0.0';

  @override
  String get heartRateTitle => 'Heart Rate';

  @override
  String get connectHrMonitor => 'Connect HR Monitor';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get setupGuide => 'Setup guide';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get recentChart => 'Recent';

  @override
  String get fullSessionChart => 'Full Session';

  @override
  String get setAgeInSettings => 'Set your age in Settings';

  @override
  String get setAgeInSettingsSubtitle =>
      'Heart rate training zones will appear when your age is configured.';

  @override
  String get statsAvg => 'Avg';

  @override
  String get statsMin => 'Min';

  @override
  String get statsMax => 'Max';

  @override
  String get statsReadings => 'Readings';

  @override
  String get timeInZone => 'Time in Zone';

  @override
  String moderateOrHigher(String duration) {
    return 'Moderate or higher: $duration';
  }

  @override
  String recoveryHrDrop(int bpm) {
    return 'Recovery HR drop: $bpm bpm';
  }

  @override
  String get bluetoothNotAvailable =>
      'Bluetooth is not available. Ensure Bluetooth is turned on.';

  @override
  String chartWindowSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String chartWindowMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String get onboardingTitle => 'Set Up Heart Rate Zones';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingAgeExplanation =>
      'Your age is used to estimate your maximum heart rate and personalise training zones.';

  @override
  String get onboardingRestingHrExplanation =>
      'Providing your resting heart rate enables more accurate zone calculation using the Karvonen (heart rate reserve) method.';

  @override
  String get onboardingRestingHrLabel => 'Resting Heart Rate (optional)';

  @override
  String get onboardingMeasuredMaxHrLabel =>
      'Measured Max Heart Rate (optional)';

  @override
  String get onboardingRestingHrHint => 'e.g. 60';

  @override
  String get onboardingMeasuredMaxHrHint => 'e.g. 185';

  @override
  String get onboardingMedicalExplanation =>
      'If any of these apply, heart rate zones will be shown in caution mode with reduced confidence. We recommend consulting your healthcare provider for personalised limits.';

  @override
  String get onboardingBetaBlockerLabel => 'Taking beta blocker medication';

  @override
  String get onboardingHeartConditionLabel => 'Heart condition';

  @override
  String get onboardingClinicianWithFlags =>
      'Because you have medical factors, we strongly recommend entering a clinician-provided maximum heart rate. This will override all other estimates.';

  @override
  String get onboardingClinicianWithoutFlags =>
      'If your doctor or exercise physiologist has given you a maximum heart rate, enter it here to override the estimate.';

  @override
  String get onboardingClinicianMaxHrLabel =>
      'Clinician Max Heart Rate (optional)';

  @override
  String get disclaimerDialogTitle => 'Heart Rate Monitoring';

  @override
  String get disclaimerDialogButton => 'I understand';

  @override
  String get cautionModeTitle => 'Caution Mode';

  @override
  String get symptomReportButton => 'Report Symptom';

  @override
  String get symptomReportTitle => 'Symptom Report';

  @override
  String get stopExerciseTitle => 'Stop Exercise';

  @override
  String get stopExerciseOk => 'I\'m OK, stopping exercise';

  @override
  String get stopExerciseHelp => 'I need help';

  @override
  String get warningGeneralDisclaimer =>
      'Heart rate zone estimates are for informational purposes only and do not constitute medical advice. Always consult a healthcare professional before starting or modifying an exercise programme, especially if you have a pre-existing medical condition.';

  @override
  String get warningBetaBlocker =>
      'Beta blocker medication can significantly reduce your maximum heart rate. Standard zone calculations may not be accurate. We recommend setting a clinician-provided maximum heart rate or using rate of perceived exertion (RPE) and the talk test to gauge intensity.';

  @override
  String get warningHeartCondition =>
      'You have indicated a heart condition. Standard heart rate zone calculations may not be appropriate. We strongly recommend obtaining a clinician-provided maximum heart rate before using intensity-based training guidance.';

  @override
  String get warningClinicianCap =>
      'Heart rate zones are calculated using a clinician-provided maximum heart rate. This overrides any age-based or measured estimates.';

  @override
  String get warningStopExercise =>
      'If you are experiencing chest pain, severe dizziness, fainting, or unusual shortness of breath, stop exercising immediately. If symptoms persist, seek urgent medical attention.';

  @override
  String get warningSymptomIntro =>
      'Are you experiencing any of the following symptoms?';

  @override
  String get symptomChestPain => 'Chest pain or tightness';

  @override
  String get symptomDizziness => 'Severe dizziness or light-headedness';

  @override
  String get symptomFainting => 'Feeling faint or about to faint';

  @override
  String get symptomBreathing => 'Unusual shortness of breath';

  @override
  String get clinicianLimitsInUse => 'Clinician-provided limits in use';

  @override
  String get workoutTitle => 'Workout';

  @override
  String workoutTitleWithTime(String time) {
    return 'Workout  •  $time';
  }

  @override
  String get loadingWorkout => 'Loading workout…';

  @override
  String get addExercise => 'Add Exercise';

  @override
  String get startWorkout => 'Start Workout';

  @override
  String get noActiveWorkout => 'No active workout';

  @override
  String get noActiveWorkoutSubtitle =>
      'Start a new workout to begin logging sets.';

  @override
  String get addExercisesHint => 'Add exercises using the button below';

  @override
  String get finishWorkoutTitle => 'Finish Workout?';

  @override
  String get finishWorkoutContent =>
      'This will save your workout and end the session.';

  @override
  String get tableHeaderHash => '#';

  @override
  String get tableHeaderWeight => 'Weight';

  @override
  String get tableHeaderReps => 'Reps';

  @override
  String get tableHeaderE1rm => 'e1RM';

  @override
  String get weightKgLabel => 'Weight (kg)';

  @override
  String get repsLabel => 'Reps';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get addRpe => 'Add RPE';

  @override
  String get hideRpe => 'Hide RPE';

  @override
  String get logSet => 'Log Set';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationInvalid => 'Invalid';

  @override
  String get validationMinZero => '≥ 0';

  @override
  String get validationRpeRange => '1–10';

  @override
  String get restTimer => 'Rest Timer';

  @override
  String get stopTimer => 'Stop timer';

  @override
  String get newPersonalRecord => 'New Personal Record!';

  @override
  String e1rmValue(String value) {
    return 'e1RM: $value kg';
  }

  @override
  String get historyTitle => 'History';

  @override
  String get noWorkoutsYet => 'No workouts yet';

  @override
  String get noWorkoutsYetSubtitle => 'Completed workouts will appear here.';

  @override
  String get loadingHistory => 'Loading history…';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String volumeTrend(int count) {
    return 'Volume trend (last $count workouts)';
  }

  @override
  String setsCount(int count) {
    return '$count sets';
  }

  @override
  String get prBadge => 'PR!';

  @override
  String get workoutDetailTitle => 'Workout Detail';

  @override
  String get workoutNotFound => 'Workout not found';

  @override
  String get durationLabel => 'Duration';

  @override
  String get setsLabel => 'Sets';

  @override
  String get volumeLabel => 'Volume';

  @override
  String get exerciseProgressTitle => 'Exercise Progress';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get noDataYetSubtitle =>
      'Log sets for this exercise to see your progress.';

  @override
  String get loadingProgress => 'Loading progress…';

  @override
  String get bestE1rm => 'Best e1RM';

  @override
  String get totalVolume => 'Total Volume';

  @override
  String get totalSets => 'Total Sets';

  @override
  String get e1rmTrend => 'Estimated 1RM Trend';

  @override
  String get recentSets => 'Recent Sets';

  @override
  String get tableHeaderDate => 'Date';

  @override
  String get chooseExercise => 'Choose Exercise';

  @override
  String get searchExercisesHint => 'Search exercises…';

  @override
  String get filterAll => 'All';

  @override
  String get noExercisesFound => 'No exercises found';

  @override
  String get loadingExercises => 'Loading exercises…';

  @override
  String get customExercise => 'Custom';

  @override
  String get newExerciseTitle => 'New Exercise';

  @override
  String get exerciseNameLabel => 'Exercise Name';

  @override
  String get categoryLabel => 'Category';

  @override
  String get muscleGroupLabel => 'Muscle Group';

  @override
  String get equipmentLabel => 'Equipment';

  @override
  String get exerciseNameRequired => 'Please enter an exercise name';

  @override
  String get cardioTitle => 'Cardio';

  @override
  String get exerciseField => 'Exercise';

  @override
  String get distanceMetresLabel => 'Distance (metres)';

  @override
  String get inclineLabel => 'Incline (%)';

  @override
  String get avgHeartRateLabel => 'Avg Heart Rate (bpm)';

  @override
  String get lastSession => 'Last session';

  @override
  String get gpsDistanceTracking => 'GPS Distance Tracking';

  @override
  String get gpsAcquiring => 'Acquiring signal...';

  @override
  String gpsMetresTracked(String metres) {
    return '$metres m tracked';
  }

  @override
  String get gpsSubtitle => 'Track distance via GPS for outdoor runs';

  @override
  String get saveSession => 'Save Session';

  @override
  String get cardioSessionSaved => 'Cardio session saved';

  @override
  String get heartRateMonitorCard => 'Heart Rate Monitor';

  @override
  String get heartRateMonitorSubtitle =>
      'Connect a BLE heart rate strap or watch';

  @override
  String get connect => 'Connect';

  @override
  String connectingTo(String device) {
    return 'Connecting to $device...';
  }

  @override
  String reconnectingTo(String device) {
    return 'Reconnecting to $device...';
  }

  @override
  String paceLabel(String pace) {
    return 'Pace: $pace';
  }

  @override
  String get hrSetupGuideTitle => 'Heart Rate Setup Guide';

  @override
  String get appleWatchTitle => 'Apple Watch';

  @override
  String get samsungWatchTitle => 'Samsung Galaxy Watch';

  @override
  String get chestStrapsTitle => 'Chest Straps & Arm Bands';

  @override
  String get appleWatchStep1 =>
      'On your Apple Watch, open Settings → Workout → Heart Rate.';

  @override
  String get appleWatchStep2 => 'Enable \"Broadcast Heart Rate\".';

  @override
  String get appleWatchStep3 => 'Start any workout on the Apple Watch.';

  @override
  String get appleWatchStep4 =>
      'In RepFoundry, tap \"Connect\" and select your Apple Watch.';

  @override
  String get samsungWatchStep1 => 'Open Samsung Health on your watch.';

  @override
  String get samsungWatchStep2 => 'Go to Settings → Heart Rate Broadcast.';

  @override
  String get samsungWatchStep3 => 'Enable BLE broadcasting.';

  @override
  String get samsungWatchStep4 =>
      'In RepFoundry, tap \"Connect\" and select your Galaxy Watch.';

  @override
  String get chestStrapStep1 =>
      'Any BLE heart rate device (Polar, Garmin, Wahoo, etc.) works automatically.';

  @override
  String get chestStrapStep2 =>
      'Simply wear your strap or band and tap \"Connect\".';

  @override
  String get chestStrapStep3 => 'Your device will appear in the scan list.';

  @override
  String get hrDevicePickerTitle => 'Heart Rate Monitors';

  @override
  String get scanning => 'Scanning for devices...';

  @override
  String get noDevicesFound =>
      'No heart rate monitors found. Ensure your device is broadcasting — for Apple Watch, start a workout with Broadcast Heart Rate enabled.';

  @override
  String get scanAgain => 'Scan Again';

  @override
  String get setupHelp => 'Setup Help';

  @override
  String get templatesTitle => 'Templates';

  @override
  String get noTemplatesYet => 'No templates yet';

  @override
  String get noTemplatesYetSubtitle =>
      'Create a template to quickly start workouts.';

  @override
  String failedToLoadTemplates(String error) {
    return 'Failed to load templates: $error';
  }

  @override
  String get newTemplate => 'New Template';

  @override
  String get newTemplateTitle => 'New Template';

  @override
  String get templateNameLabel => 'Template Name';

  @override
  String get deleteTemplateTitle => 'Delete Template?';

  @override
  String deleteTemplateContent(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String exerciseCount(int count) {
    return '$count exercises';
  }

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get targetSets => 'Sets';

  @override
  String get targetReps => 'Reps';

  @override
  String get addExerciseToTemplate => 'Add Exercise';

  @override
  String get saveTemplate => 'Save';

  @override
  String get removeExercise => 'Remove Exercise';

  @override
  String get reorderHint => 'Drag to reorder exercises';

  @override
  String get templateSaved => 'Template saved';

  @override
  String get prTypeWeight => 'New Weight PR!';

  @override
  String get prTypeReps => 'New Rep PR!';

  @override
  String get prTypeVolume => 'New Volume PR!';

  @override
  String get prTypeE1rm => 'New e1RM PR!';

  @override
  String get prHistoryTitle => 'Personal Records';

  @override
  String get prHistoryEmpty => 'No personal records yet';

  @override
  String get prHistoryEmptySubtitle =>
      'Set new records by logging sets in your workouts.';

  @override
  String prAchievedOn(String date) {
    return 'Achieved $date';
  }

  @override
  String prValueWeight(String value) {
    return '$value kg';
  }

  @override
  String prValueReps(String value) {
    return '$value reps';
  }

  @override
  String prValueVolume(String value) {
    return '$value kg volume';
  }

  @override
  String prValueE1rm(String value) {
    return '$value kg e1RM';
  }

  @override
  String get historyTab => 'History';

  @override
  String get progressTab => 'Progress';

  @override
  String get volumeTrendTitle => 'Volume Trend';

  @override
  String get frequencyTitle => 'Workouts per Week';

  @override
  String get workoutsPerWeek => 'workouts';

  @override
  String get startFromTemplate => 'Start from Template';

  @override
  String get chooseTemplate => 'Choose Template';

  @override
  String get noTemplatesAvailable => 'No templates available';

  @override
  String get muscleGroupDistributionTitle => 'Muscle Group Distribution';

  @override
  String get exerciseProgressListTitle => 'Exercise Progress';

  @override
  String setsLogged(int count) {
    return '$count sets logged';
  }

  @override
  String get exportAsJson => 'Export as JSON';

  @override
  String get exportAsJsonSubtitle => 'Full workout data in JSON format';

  @override
  String get exportAsCsv => 'Export as CSV';

  @override
  String get exportAsCsvSubtitle =>
      'Sets, cardio, and personal records as CSV files';

  @override
  String get exportingData => 'Exporting data…';

  @override
  String get exportComplete => 'Export complete';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get editSet => 'Edit Set';

  @override
  String get editExerciseTitle => 'Edit Exercise';

  @override
  String get calendarHeatmapTitle => 'Workout Calendar';

  @override
  String get calendarHeatmapLess => 'Less';

  @override
  String get calendarHeatmapMore => 'More';

  @override
  String currentStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '1 day streak',
      zero: 'No current streak',
    );
    return '$_temp0';
  }

  @override
  String longestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return 'Longest: $count $_temp0';
  }

  @override
  String get durationTrendTitle => 'Workout Duration (mins)';

  @override
  String get warmUpLabel => 'Warm-up';

  @override
  String get bodyMetricsTitle => 'Body Metrics';

  @override
  String get bodyMetricsSubtitle => 'Track body weight and composition';

  @override
  String get noBodyMetricsYet => 'No body metrics yet';

  @override
  String get noBodyMetricsYetSubtitle =>
      'Tap + to record your first measurement.';

  @override
  String get addBodyMetric => 'Add Measurement';

  @override
  String get bodyWeightLabel => 'Body Weight';

  @override
  String get bodyFatPercentLabel => 'Body Fat %';

  @override
  String get bodyFatLabel => 'body fat';

  @override
  String get notesLabel => 'Notes';

  @override
  String get bodyWeightTrendTitle => 'Body Weight Trend';

  @override
  String get latestWeight => 'Latest Weight';

  @override
  String get bodyMetricsHistory => 'History';

  @override
  String get importFromJson => 'Import from JSON';

  @override
  String get importFromJsonSubtitle => 'Restore data from a previous export';

  @override
  String get importDataTitle => 'Import Data';

  @override
  String get importDataConfirmContent =>
      'This will add data from a JSON export to your existing data. Duplicates will be skipped.';

  @override
  String get importDataButton => 'Import';

  @override
  String get importPasteJsonTitle => 'Paste JSON Data';

  @override
  String get importPasteJsonHint => 'Paste your exported JSON here…';

  @override
  String importComplete(int workouts, int sets) {
    return 'Import complete: $workouts workouts, $sets sets';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get duplicateTemplate => 'Duplicate';

  @override
  String get copyLabel => 'Copy';
}
