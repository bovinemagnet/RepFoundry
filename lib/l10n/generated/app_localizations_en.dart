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
  String get navGroupTrain => 'Train';

  @override
  String get navGroupReview => 'Review';

  @override
  String get navGroupPlan => 'Plan';

  @override
  String get desktopSessionsLabel => 'Sessions';

  @override
  String get desktopVolumeLabel => 'Volume';

  @override
  String get desktopDurationLabel => 'Duration';

  @override
  String get desktopSetsLabel => 'Sets';

  @override
  String get desktopExercisesLabel => 'Exercises';

  @override
  String get desktopPerSetVolume => 'Per-set volume';

  @override
  String get desktopExerciseBreakdown => 'Exercise breakdown';

  @override
  String get desktopSelectSession =>
      'Select a session to view its full breakdown.';

  @override
  String get desktopSelectTemplate =>
      'Select a template to view its exercises.';

  @override
  String get desktopTotalVolume => 'Total volume';

  @override
  String get desktopWorkoutsLabel => 'Workouts';

  @override
  String get desktopAvgSessionLabel => 'Avg session';

  @override
  String get desktopPrsLabel => 'PRs';

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
  String get sectionCoach => 'Coach';

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
  String get zoneMethodLthrFriel => 'Lactate threshold (Friel)';

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
  String get layoutLabel => 'Layout';

  @override
  String get layoutMobile => 'Mobile';

  @override
  String get layoutDesktop => 'Desktop';

  @override
  String get layoutSubtitle =>
      'Auto follows window size · applies on tablets and larger';

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
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutScreenTitle => 'About RepFoundry';

  @override
  String get aboutDescription =>
      'A simple, fast workout tracking app for gym-goers.';

  @override
  String get aboutAuthorLabel => 'Author';

  @override
  String get aboutAuthor => 'Paul Snow';

  @override
  String get aboutGitHub => 'GitHub Repository';

  @override
  String get aboutFeatures => 'Features';

  @override
  String get aboutFeatureOffline =>
      'Offline-first — your data stays on your device';

  @override
  String get aboutFeatureHeartRate => 'Bluetooth heart rate monitor support';

  @override
  String get aboutFeatureTemplates =>
      'Workout templates for quick session setup';

  @override
  String get aboutFeatureProgress => 'Progress tracking with personal records';

  @override
  String get aboutFeatureExport => 'Export your data as JSON or CSV';

  @override
  String get aboutFeatureCardio => 'GPS-tracked cardio sessions';

  @override
  String get aboutBuiltWith => 'Built with Flutter';

  @override
  String get aboutViewLicences => 'Open-source licences';

  @override
  String get betaUnlockVirtualTrainer => 'Unlock Virtual Trainer (beta)';

  @override
  String get betaUnlockVirtualTrainerSubtitle =>
      'Enables the audio coaching companion while it is in beta.';

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
  String get startStretching => 'Start Stretching';

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
  String get continueWorkout => 'Continue Workout';

  @override
  String get continueWorkoutBlocked =>
      'Finish your current workout before continuing this one.';

  @override
  String get saveAsTemplate => 'Save as Template';

  @override
  String get saveAsTemplateTitle => 'Save as Template';

  @override
  String get saveAsTemplateHint => 'Template name';

  @override
  String saveAsTemplateSuccess(String name) {
    return 'Saved \"$name\" as a template';
  }

  @override
  String get saveAsTemplateEmpty =>
      'Add some sets before saving as a template.';

  @override
  String get tableHeaderHash => '#';

  @override
  String get tableHeaderWeight => 'Weight';

  @override
  String get tableHeaderReps => 'Reps';

  @override
  String get tableHeaderE1rm => 'e1RM';

  @override
  String get tableHeaderHr => 'HR';

  @override
  String weightFieldLabel(String unit) {
    return 'Weight ($unit)';
  }

  @override
  String get percentSuffix => '%';

  @override
  String get repsLabel => 'Reps';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get addWarmup => 'Add warm-up';

  @override
  String get warmupRampTitle => 'Warm-up ramp';

  @override
  String addWarmupSets(int count) {
    return 'Add $count warm-up sets';
  }

  @override
  String get addRpe => 'Add RPE';

  @override
  String get hideRpe => 'Hide RPE';

  @override
  String get logSet => 'Log Set';

  @override
  String get addSet => 'Add Set';

  @override
  String get collapse => 'Collapse';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationInvalid => 'Invalid';

  @override
  String get validationMinZero => '≥ 0';

  @override
  String get validationMinOne => '≥ 1';

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
      'No heart rate monitors found. Ensure your device is broadcasting — for Apple Watch, start a workout with Broadcast Heart Rate enabled. Chest straps only broadcast while worn.';

  @override
  String get scanAgain => 'Scan Again';

  @override
  String get setupHelp => 'Setup Help';

  @override
  String get hrScanPermissionDenied =>
      'Location permission is needed to scan for Bluetooth devices — an Android requirement. Allow it in App Settings.';

  @override
  String get hrScanLocationOff =>
      'Turn on Location services to scan for Bluetooth devices — an Android requirement.';

  @override
  String get hrScanBluetoothOff =>
      'Bluetooth is turned off. Turn it on and scan again.';

  @override
  String get hrScanFailed =>
      'Couldn\'t scan for heart rate monitors. Try again.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get templatesTitle => 'Templates';

  @override
  String get templatesSubtitle =>
      'Manage workout templates for quick session setup';

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
  String prValueWeight(String value, String unit) {
    return '$value $unit';
  }

  @override
  String prValueReps(String value) {
    return '$value reps';
  }

  @override
  String prValueVolume(String value, String unit) {
    return '$value $unit volume';
  }

  @override
  String prValueE1rm(String value, String unit) {
    return '$value $unit e1RM';
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
  String get notesLabel => 'Notes (optional)';

  @override
  String get bodyWeightTrendTitle => 'Body Weight Trend';

  @override
  String get latestWeight => 'Latest Weight';

  @override
  String get bodyMetricsHistory => 'History';

  @override
  String get importFromFile => 'Import from File';

  @override
  String get importFromFileSubtitle =>
      'Migrate history from a CSV or JSON file (RepFoundry, Strong, Hevy)';

  @override
  String importDetectedFormat(String format) {
    return 'Detected format: $format. Import this file into your history?';
  }

  @override
  String get importUnitQuestion =>
      'This file does not declare a weight unit. Which unit was it exported in?';

  @override
  String get importAsKg => 'Import as kg';

  @override
  String get importAsLbs => 'Import as lbs';

  @override
  String get importUnsupportedFormat =>
      'Unsupported file format. Supported: RepFoundry JSON⁄CSV, Strong CSV, Hevy CSV.';

  @override
  String importCsvComplete(int workouts, int sets, int created, int skipped) {
    return 'Imported $workouts workouts and $sets sets ($created new exercises, $skipped rows skipped)';
  }

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
  String importComplete(int workouts, int sets, int cardio) {
    return 'Import complete: $workouts workouts, $sets sets, $cardio cardio sessions';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get duplicateTemplate => 'Duplicate';

  @override
  String get copyLabel => 'Copy';

  @override
  String get supersetLabel => 'Superset';

  @override
  String get linkAsSuperset => 'Link as Superset';

  @override
  String get breakSuperset => 'Break Superset';

  @override
  String supersetWith(String name) {
    return 'Superset with $name';
  }

  @override
  String get selectSupersetPartner => 'Select Exercise to Link';

  @override
  String get noOtherExercises => 'Add another exercise first';

  @override
  String get sectionReminders => 'Reminders';

  @override
  String get workoutReminders => 'Workout Reminders';

  @override
  String get workoutRemindersSubtitle => 'Get notified on your training days';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get reminderTimeSubtitle => 'Time to receive workout reminders';

  @override
  String get reminderDays => 'Training Days';

  @override
  String get streakReminder => 'Streak Reminder';

  @override
  String get streakReminderSubtitle =>
      'Remind me if I haven\'t worked out today';

  @override
  String get mondayShort => 'Mon';

  @override
  String get tuesdayShort => 'Tue';

  @override
  String get wednesdayShort => 'Wed';

  @override
  String get thursdayShort => 'Thu';

  @override
  String get fridayShort => 'Fri';

  @override
  String get saturdayShort => 'Sat';

  @override
  String get sundayShort => 'Sun';

  @override
  String get notificationPermissionRequired =>
      'Notification permission is required for reminders';

  @override
  String reminderTimeOfDay(String hour, String minute) {
    return '$hour:$minute';
  }

  @override
  String get notificationsScreenTitle => 'Notifications';

  @override
  String get notificationsTileTitle => 'Notifications';

  @override
  String get notificationsTileSubtitleEmpty => 'No reminders configured';

  @override
  String notificationsTileSubtitleSummary(String days, String time) {
    return '$days at $time';
  }

  @override
  String get permissionDeniedBanner =>
      'Notifications are blocked. Reminders won\'t fire until you enable them in system settings.';

  @override
  String get openSystemSettings => 'Open settings';

  @override
  String get sendTestNotification => 'Send test notification';

  @override
  String get sendTestNotificationSubtitle =>
      'Show a sample notification now to verify setup';

  @override
  String get testNotificationTitle => 'RepFoundry test notification';

  @override
  String get testNotificationBody =>
      'If you can see this, reminders will work.';

  @override
  String get testNotificationSentSnack => 'Test notification sent';

  @override
  String get testNotificationBlockedSnack =>
      'Notifications are blocked — enable them in system settings first';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get weeklyVolumeTitle => 'Weekly Volume Trend';

  @override
  String weeklyVolumeChange(String change) {
    return '$change% vs previous week';
  }

  @override
  String get muscleBalanceTitle => 'Muscle Group Balance';

  @override
  String get muscleBalanceNeedsMore =>
      'Train at least 3 muscle groups to see your balance.';

  @override
  String get prTimelineTitle => 'PR Timeline';

  @override
  String get trainingLoadTitle => 'Weekly Training Load';

  @override
  String get trainingLoadSubtitle => 'Sets × avg RPE';

  @override
  String get noAnalyticsData => 'Not enough data yet';

  @override
  String get noAnalyticsDataSubtitle =>
      'Complete a few workouts to see your analytics.';

  @override
  String get volumeCategory => 'Volume by Category';

  @override
  String loadScore(String score) {
    return 'Load: $score';
  }

  @override
  String get viewAdvancedAnalytics => 'View Advanced Analytics';

  @override
  String get programmesTitle => 'Programmes';

  @override
  String get noProgrammesYet => 'No programmes yet';

  @override
  String get noProgrammesYetSubtitle =>
      'Create a training programme to plan your workouts.';

  @override
  String get newProgramme => 'New Programme';

  @override
  String get newProgrammeTitle => 'New Programme';

  @override
  String get programmeNameLabel => 'Programme Name';

  @override
  String get durationWeeksLabel => 'Duration (weeks)';

  @override
  String get editProgramme => 'Edit Programme';

  @override
  String get deleteProgrammeTitle => 'Delete Programme?';

  @override
  String deleteProgrammeContent(String name) {
    return 'Are you sure you want to delete \"$name\"? This cannot be undone.';
  }

  @override
  String get programmeDashboard => 'Dashboard';

  @override
  String currentWeek(int current, int total) {
    return 'Week $current of $total';
  }

  @override
  String get assignTemplate => 'Assign Template';

  @override
  String get noTemplateAssigned => 'Rest day';

  @override
  String get progressionRules => 'Progression Rules';

  @override
  String get addRule => 'Add Rule';

  @override
  String get fixedIncrementLabel => 'Fixed increment';

  @override
  String get percentageLabel => 'Percentage';

  @override
  String get deloadLabel => 'Deload';

  @override
  String get ruleValueLabel => 'Value';

  @override
  String everyNWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'weeks',
      one: 'week',
    );
    return 'Every $count $_temp0';
  }

  @override
  String get startFromProgramme => 'Start from Programme';

  @override
  String targetWeight(String weight, Object unit) {
    return 'Target: $weight kg';
  }

  @override
  String get programmeSaved => 'Programme saved';

  @override
  String failedToLoadProgrammes(String error) {
    return 'Failed to load programmes: $error';
  }

  @override
  String programmeWeeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'weeks',
      one: 'week',
    );
    return '$count $_temp0';
  }

  @override
  String programmeDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$count $_temp0 assigned';
  }

  @override
  String get selectProgrammeHint =>
      'Select a programme to edit, or create a new one';

  @override
  String weekLabel(int number) {
    return 'Week $number';
  }

  @override
  String programmeWeekOf(int current, int total) {
    return 'Week $current of $total';
  }

  @override
  String get programmeNotStarted => 'Not started';

  @override
  String dayLabel(String day) {
    return '$day';
  }

  @override
  String get chooseProgramme => 'Choose Programme';

  @override
  String get noProgrammesAvailable => 'No programmes available';

  @override
  String get noWorkoutScheduledForToday => 'No workout scheduled for today';

  @override
  String get healthSyncTitle => 'Health Sync';

  @override
  String get healthSyncSubtitle =>
      'Sync data with Apple Health or Health Connect';

  @override
  String get healthSyncEnabled => 'Enable Health Sync';

  @override
  String get writeWorkoutsLabel => 'Write workouts';

  @override
  String get writeWorkoutsSubtitle =>
      'Log completed workouts to the health store';

  @override
  String get writeWeightLabel => 'Write body weight';

  @override
  String get writeWeightSubtitle => 'Send body metrics to the health store';

  @override
  String get writeHeartRateLabel => 'Write heart rate';

  @override
  String get writeHeartRateSubtitle => 'Send heart rate data during cardio';

  @override
  String get readWeightLabel => 'Read body weight';

  @override
  String get readWeightSubtitle =>
      'Import weight measurements from the health store';

  @override
  String get healthSyncPermissionDenied =>
      'Health permissions were not granted';

  @override
  String get healthSyncSuccess => 'Synced to Health';

  @override
  String importWeightPrompt(String weight, String unit) {
    return 'Import $weight $unit from Health?';
  }

  @override
  String get importWeightAction => 'Import';

  @override
  String get healthSyncNoNewData => 'No new data from Health';

  @override
  String get syncSectionTitle => 'Cross-Device Sync';

  @override
  String get syncEnabled => 'Enable Cross-Device Sync';

  @override
  String get syncEnabledSubtitle => 'Sync your workout data across devices';

  @override
  String syncLastSynced(String time) {
    return 'Last synced: $time';
  }

  @override
  String get syncNeverSynced => 'Never synced';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncSyncing => 'Syncing…';

  @override
  String get syncSuccess => 'Sync complete';

  @override
  String syncError(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get syncDisableAndDelete => 'Disable Sync & Delete Cloud Data';

  @override
  String get syncDisableConfirmTitle => 'Disable Sync?';

  @override
  String get syncDisableConfirmBody =>
      'This will disable sync and permanently delete your data from cloud storage. Your local data will not be affected.';

  @override
  String get syncDisableConfirmAction => 'Disable & Delete';

  @override
  String get syncConsentTitle => 'Cross-Device Sync';

  @override
  String get syncConsentBody =>
      'Your workout data will be saved to your own Google Drive or iCloud account. RepFoundry cannot access this data. You can delete it at any time from Settings or directly from your cloud account.';

  @override
  String get syncConsentCancel => 'Cancel';

  @override
  String get syncConsentAccept => 'I Understand — Continue';

  @override
  String get trainingHistoryTitle => 'Training History';

  @override
  String get trainingHistorySubtitle =>
      'Track your evolution and mechanical tension gains.';

  @override
  String get searchSessionsHint => 'Search sessions or exercises…';

  @override
  String get thisWeek => 'This Week';

  @override
  String get lastWeek => 'Last Week';

  @override
  String get volumeProgress => 'Volume Progress';

  @override
  String totalVolumeKg(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get workoutFallbackName => 'Workout';

  @override
  String get liveSensor => 'Live Sensor';

  @override
  String get restingHrLabel => 'Resting HR';

  @override
  String get maxHrLabel => 'Max HR';

  @override
  String get recoveryLabel => 'Recovery';

  @override
  String get hrvLabel => 'HRV';

  @override
  String get excellent => 'Excellent';

  @override
  String get reachedAgo => 'Session max';

  @override
  String get toBaseline => 'To baseline';

  @override
  String get highReadiness => 'High Readiness';

  @override
  String get workoutIntensityZones => 'Workout Intensity Zones';

  @override
  String sessionDuration(String duration) {
    return 'Session: $duration';
  }

  @override
  String get zonePeak => 'Peak';

  @override
  String get zoneAnaerobic => 'Anaerobic';

  @override
  String get zoneAerobic => 'Aerobic';

  @override
  String get zoneFatBurn => 'Fat Burn';

  @override
  String get zoneWarmup => 'Warmup';

  @override
  String get heartRateTrend => 'Heart Rate Trend';

  @override
  String get heartRateTrendSubtitle => 'Current workout session';

  @override
  String get todayLabel => 'Today';

  @override
  String get avgLabel => 'Avg';

  @override
  String get activeDuration => 'Active Duration';

  @override
  String get avgPaceLabel => 'Avg Pace';

  @override
  String get distanceLabel => 'Distance';

  @override
  String get startSession => 'Start Session';

  @override
  String get liveTracking => 'Live Tracking';

  @override
  String get stretchingSectionTitle => 'Stretching';

  @override
  String get stretchingEmptySubtitle =>
      'Add mobility, warm-up, or cool-down stretching.';

  @override
  String get addStretching => 'Add Stretching';

  @override
  String get addStretchingShort => 'Add';

  @override
  String stretchingTotalMinutes(String minutes) {
    return '$minutes min total';
  }

  @override
  String stretchingEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get addStretchingTitle => 'Add Stretching';

  @override
  String get stretchTypeLabel => 'Stretch type';

  @override
  String get customStretchLabel => 'Custom…';

  @override
  String get customStretchHint => 'Stretch name';

  @override
  String get recordTimeLabel => 'Record time';

  @override
  String get recordTimer => 'Timer';

  @override
  String get recordManual => 'Manual';

  @override
  String get recordUntimed => 'Untimed';

  @override
  String get untimedEntryHint =>
      'Just record that you did this stretch — no duration tracked.';

  @override
  String get quickAddDurations => 'Quick add';

  @override
  String get minutesAbbrev => 'min';

  @override
  String get secondsAbbrev => 'sec';

  @override
  String get stretchingEntryMethodTimer => 'Timer';

  @override
  String get stretchingEntryMethodManual => 'Manual';

  @override
  String get deleteStretchingTitle => 'Delete stretching entry?';

  @override
  String get deleteStretchingMessage =>
      'This will remove this stretching entry from the workout.';

  @override
  String get stretchPresetStandingHamstring => 'Standing Hamstring Stretch';

  @override
  String get stretchPresetSeatedForwardFold => 'Seated Forward Fold';

  @override
  String get stretchPresetStandingQuad => 'Standing Quadriceps Stretch';

  @override
  String get stretchPresetLowLungeHipFlexor => 'Low Lunge Hip Flexor';

  @override
  String get stretchPresetPigeon => 'Pigeon Pose';

  @override
  String get stretchPresetButterfly => 'Butterfly Stretch';

  @override
  String get stretchPresetChildsPose => 'Child\'s Pose';

  @override
  String get stretchPresetCobra => 'Cobra Stretch';

  @override
  String get stretchPresetCatCow => 'Cat–Cow';

  @override
  String get stretchPresetDownwardDog => 'Downward-Facing Dog';

  @override
  String get stretchPresetCrossBodyShoulder => 'Cross-Body Shoulder Stretch';

  @override
  String get stretchPresetDoorwayChest => 'Doorway Chest Stretch';

  @override
  String get stretchPresetStandingCalf => 'Standing Calf Stretch';

  @override
  String get stretchPresetSupineSpinalTwist => 'Supine Spinal Twist';

  @override
  String get stretchPresetNeckSideStretch => 'Neck Side Stretch';

  @override
  String get stretchPresetFigureFourGlute => 'Figure-4 Glute Stretch';

  @override
  String get stretchPresetNinetyNinety => '90/90 Hip Stretch';

  @override
  String get stretchPresetFrogPose => 'Frog Pose';

  @override
  String get stretchPresetFrontSplits => 'Front Splits';

  @override
  String get stretchPresetSideSplits => 'Side Splits (Middle Splits)';

  @override
  String get clientsTitle => 'Clients';

  @override
  String get newClient => 'New client';

  @override
  String get newClientTitle => 'New client';

  @override
  String get clientNameLabel => 'Name';

  @override
  String get editClient => 'Edit client';

  @override
  String get deleteClientTitle => 'Delete client?';

  @override
  String deleteClientContent(String name) {
    return 'Delete $name? Their logged data is kept but hidden.';
  }

  @override
  String get noClientsYet => 'No clients yet';

  @override
  String get selfClientBadge => 'You';

  @override
  String get switchClient => 'Switch client';

  @override
  String viewingClient(String name) {
    return 'Viewing $name';
  }

  @override
  String get assignedPlans => 'Assigned plans';

  @override
  String get assignPlan => 'Assign plan';

  @override
  String get unassignPlan => 'Unassign';

  @override
  String get noPlansAssigned => 'No plans assigned yet';

  @override
  String get clientHealthProfile => 'Health profile';

  @override
  String get healthProfileSaved => 'Health profile saved';

  @override
  String get coachSteadyStart1 =>
      'Let\'s get to work. Take your time and move well.';

  @override
  String get coachSteadyStart2 => 'Session started. Nice and steady.';

  @override
  String get coachSteadyStart3 =>
      'Good to see you. Let\'s make this one count.';

  @override
  String get coachSteadySet1 =>
      'Good set. Breathe, reset, go again when you\'re ready.';

  @override
  String get coachSteadySet2 => 'That\'s logged. Nice control.';

  @override
  String get coachSteadySet3 => 'Steady work. Keep that form.';

  @override
  String get coachSteadySet4 => 'Well done. Take the rest you need.';

  @override
  String get coachSteadyPr1 => 'That\'s a personal record. Excellent work.';

  @override
  String get coachSteadyPr2 => 'New best. All that consistency is paying off.';

  @override
  String get coachSteadyPr3 =>
      'Personal record. Take a moment — you earned it.';

  @override
  String coachSteadyCountdown1(int secondsLeft) {
    return '$secondsLeft';
  }

  @override
  String coachSteadyCountdown2(int secondsLeft) {
    return '$secondsLeft…';
  }

  @override
  String coachSteadyCountdown3(int secondsLeft) {
    return '$secondsLeft.';
  }

  @override
  String get coachSteadyRestDone1 => 'Rest is up. Go when you\'re ready.';

  @override
  String get coachSteadyRestDone2 => 'Time. Take your position.';

  @override
  String get coachSteadyRestDone3 =>
      'That\'s your rest. Next set when you\'re set.';

  @override
  String coachSteadyFinish1(int totalSets) {
    return 'Session complete. $totalSets sets logged. Well done.';
  }

  @override
  String coachSteadyFinish2(int totalSets) {
    return 'That\'s the work done — $totalSets sets. Good session.';
  }

  @override
  String coachSteadyFinish3(int totalSets) {
    return 'Finished. $totalSets sets in the bank.';
  }

  @override
  String coachSteadyZone(int zoneNumber, String effortLabel) {
    return 'Zone $zoneNumber — $effortLabel.';
  }

  @override
  String get coachSteadyAboveCap1 =>
      'Your heart rate is above your maximum. Ease off and bring it down.';

  @override
  String get coachSteadyAboveCap2 =>
      'Still above your maximum. Slow down, breathe.';

  @override
  String get coachSteadyBackBelowCap =>
      'Good — you\'re back under your maximum.';

  @override
  String get coachHypeStart1 => 'Let\'s go! Great to have you here.';

  @override
  String get coachHypeStart2 => 'Session\'s live — let\'s make it count.';

  @override
  String get coachHypeStart3 => 'Here we go! Loving the energy already.';

  @override
  String get coachHypeSet1 => 'Yes! That\'s another one in the books.';

  @override
  String get coachHypeSet2 => 'Nice work — that\'s logged and done.';

  @override
  String get coachHypeSet3 => 'Love it! On to the next when you\'re ready.';

  @override
  String get coachHypePr1 => 'New personal record! That is brilliant.';

  @override
  String get coachHypePr2 => 'PR alert! All that consistency just paid off.';

  @override
  String get coachHypePr3 => 'Personal best! Take a second to enjoy that.';

  @override
  String coachHypeCountdown1(int secondsLeft) {
    return '$secondsLeft!';
  }

  @override
  String coachHypeCountdown2(int secondsLeft) {
    return '$secondsLeft — nearly there!';
  }

  @override
  String coachHypeCountdown3(int secondsLeft) {
    return '$secondsLeft, let\'s go!';
  }

  @override
  String get coachHypeRestDone1 => 'Rest\'s done — let\'s get back to it!';

  @override
  String get coachHypeRestDone2 => 'Time\'s up! Whenever you\'re ready.';

  @override
  String get coachHypeRestDone3 => 'Back at it! Great pace so far.';

  @override
  String coachHypeFinish1(int totalSets) {
    return 'That\'s a wrap! $totalSets sets — brilliant session.';
  }

  @override
  String coachHypeFinish2(int totalSets) {
    return 'Session complete! $totalSets sets down. Well done, seriously.';
  }

  @override
  String coachHypeFinish3(int totalSets) {
    return 'All done! $totalSets sets logged — great consistency.';
  }

  @override
  String coachHypeZone(int zoneNumber, String effortLabel) {
    return 'Zone $zoneNumber — $effortLabel.';
  }

  @override
  String get coachHypeAboveCap1 =>
      'Your heart rate is above your max. Let\'s ease off and bring it down.';

  @override
  String get coachHypeAboveCap2 =>
      'Still above your max — slow it down, breathe.';

  @override
  String get coachHypeBackBelowCap => 'Good — you\'re back under your max.';

  @override
  String get coachSergeantStart1 => 'Time to work. Let\'s move.';

  @override
  String get coachSergeantStart2 => 'Session\'s on. Get set.';

  @override
  String get coachSergeantStart3 => 'Eyes up. Let\'s begin.';

  @override
  String get coachSergeantSet1 => 'Set logged. Next.';

  @override
  String get coachSergeantSet2 => 'Good. Reset and go again.';

  @override
  String get coachSergeantSet3 => 'Done. Keep moving.';

  @override
  String get coachSergeantPr1 => 'Personal record. Well earned.';

  @override
  String get coachSergeantPr2 => 'New best. Good work.';

  @override
  String get coachSergeantPr3 => 'That\'s a PR. Earned, noted.';

  @override
  String coachSergeantCountdown1(int secondsLeft) {
    return '$secondsLeft.';
  }

  @override
  String coachSergeantCountdown2(int secondsLeft) {
    return '$secondsLeft. Get ready.';
  }

  @override
  String coachSergeantCountdown3(int secondsLeft) {
    return '$secondsLeft. Stand by.';
  }

  @override
  String get coachSergeantRestDone1 => 'Rest\'s over. Bar\'s waiting. Move.';

  @override
  String get coachSergeantRestDone2 => 'Time\'s up. Back to it.';

  @override
  String get coachSergeantRestDone3 => 'Rest done. Take your position.';

  @override
  String coachSergeantFinish1(int totalSets) {
    return 'Session complete. $totalSets sets. Good work.';
  }

  @override
  String coachSergeantFinish2(int totalSets) {
    return 'That\'s $totalSets sets done. Solid session.';
  }

  @override
  String coachSergeantFinish3(int totalSets) {
    return 'Finished. $totalSets sets logged. Well earned.';
  }

  @override
  String coachSergeantZone(int zoneNumber, String effortLabel) {
    return 'Zone $zoneNumber. $effortLabel.';
  }

  @override
  String get coachSergeantAboveCap1 =>
      'Heart rate\'s above your max. Ease off now.';

  @override
  String get coachSergeantAboveCap2 =>
      'Still above your max. Slow down and breathe.';

  @override
  String get coachSergeantBackBelowCap => 'Good. Back under your max.';

  @override
  String get coachQuote1 =>
      'No longer talk at all about the kind of man that a good man ought to be, but be such. — Marcus Aurelius';

  @override
  String get coachQuote2 =>
      'If it is not right, do not do it. If it is not true, do not say it. — Marcus Aurelius';

  @override
  String get coachQuote3 =>
      'We do not receive a short life, but we make it a short one, and we are not poor in days, but wasteful of them. — Seneca';

  @override
  String get coachQuote5 =>
      'It is not the things themselves that disturb men, but their judgements about these things. — Epictetus';

  @override
  String get coachQuote6 =>
      'First say to yourself who you wish to be: then do accordingly what you are doing. — Epictetus';

  @override
  String get coachQuote7 =>
      'The journey of a thousand li commenced with a single step. — Lao Tzu';

  @override
  String get coachQuote8 =>
      'The life which is unexamined is not worth living. — Socrates';

  @override
  String get coachQuote9 => 'I neither know nor think that I know. — Socrates';

  @override
  String get coachQuote10 => 'Well begun is half done. — Aristotle';

  @override
  String get coachQuote11 =>
      'I will not follow where the path may lead, but I will go where there is no path, and I will leave a trail. — Muriel Strode';

  @override
  String get coachQuote12 =>
      'Nothing great was ever achieved without enthusiasm. — Ralph Waldo Emerson';

  @override
  String get coachQuote13 =>
      'Adopt the pace of Nature. Her secret is patience. — Ralph Waldo Emerson';

  @override
  String get coachQuote14 =>
      'If one advances confidently in the direction of his dreams, and endeavors to live the life which he has imagined, he will meet with a success unexpected in common hours. — Henry David Thoreau';

  @override
  String get coachQuote15 =>
      'The question is not what you look at, but what you see. — Henry David Thoreau';

  @override
  String get coachQuote16 =>
      'Energy and persistence conquer all things. — Benjamin Franklin';

  @override
  String get coachQuote17 =>
      'Well done is better than well said. — Benjamin Franklin';

  @override
  String get coachQuote18 =>
      'Our greatest glory is not in never falling, but in rising every time we fall. — Oliver Goldsmith';

  @override
  String get coachQuote19 =>
      'The credit belongs to the man who is actually in the arena. — Theodore Roosevelt';

  @override
  String get coachQuote20 =>
      'Do what you can, with what you\'ve got, where you are. — Theodore Roosevelt';

  @override
  String get coachQuote21 => 'Action is eloquence. — William Shakespeare';

  @override
  String get coachQuote22 =>
      'Diligence is the mother of good fortune. — Miguel de Cervantes';

  @override
  String get coachQuote23 =>
      'Obstacles cannot crush me. Every obstacle yields to stern resolve. — Leonardo da Vinci';

  @override
  String get trainerDisclaimerTitle => 'Before your coach speaks';

  @override
  String get trainerDisclaimerBody =>
      'The coach is a companion to help you stay on track — not a personal trainer, and not medical advice. It does not know your form, your injuries, or your limits. Stop exercising and seek medical help if you feel pain, dizziness, or chest discomfort.';

  @override
  String get trainerDisclaimerAccept => 'I understand';

  @override
  String get trainerDisclaimerDecline => 'Not now';

  @override
  String get trainerSettingsTitle => 'Virtual Trainer';

  @override
  String get trainerEnable => 'Enable coach';

  @override
  String get trainerEnableSubtitle =>
      'Speaks encouragement and rest countdowns through your headphones.';

  @override
  String get trainerPersona => 'Coaching voice';

  @override
  String get trainerPersonaSteady => 'Steady';

  @override
  String get trainerPersonaSteadyDescription => 'Calm and measured';

  @override
  String get trainerPersonaHype => 'Hype';

  @override
  String get trainerPersonaHypeDescription => 'Energetic and celebratory';

  @override
  String get trainerPersonaSergeant => 'Sergeant';

  @override
  String get trainerPersonaSergeantDescription => 'Firm and to the point';

  @override
  String get trainerSpeechRate => 'Speech rate';

  @override
  String get trainerTestVoice => 'Test voice';

  @override
  String get trainerTestPhrase =>
      'This is your coach. Good set — take your rest.';

  @override
  String get trainerCountdowns => 'Rest countdowns';

  @override
  String get trainerEncouragement => 'Encouragement';

  @override
  String get trainerHrCallouts => 'Heart rate zone callouts';

  @override
  String get trainerHrCalloutsSubtitle =>
      'Announces your training zone as it changes, when a heart rate monitor is connected.';

  @override
  String get trainerHrSafetyWarnings => 'Heart rate safety warnings';

  @override
  String get trainerHrSafetyWarningsSubtitle =>
      'Speaks a calm reminder if your heart rate goes above your safe maximum. Recommended to leave switched on.';

  @override
  String get trainerReviewDisclaimer => 'Review safety notice';

  @override
  String get trainerVoiceUnavailable =>
      'No speech engine found on this device, so the coach cannot speak.';

  @override
  String get trainerWithdrawConsent => 'Withdraw consent';

  @override
  String get trainerWithdrawConsentConfirmTitle => 'Withdraw consent?';

  @override
  String get trainerWithdrawConsentConfirmContent =>
      'This turns the coach off and clears your acceptance of the safety notice. You\'ll need to accept it again before the coach can speak.';

  @override
  String get trainerWithdrawConsentAction => 'Withdraw';

  @override
  String get trainerSettingsEntrySubtitle =>
      'Your coach\'s voice, persona, and safety notice.';
}
