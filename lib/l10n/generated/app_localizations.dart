import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'RepFoundry'**
  String get appTitle;

  /// No description provided for @navWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get navWorkout;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get navCardio;

  /// No description provided for @navHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get navHeartRate;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @bpmSuffix.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get bpmSuffix;

  /// No description provided for @yearsSuffix.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get yearsSuffix;

  /// No description provided for @kgUnit.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kgUnit;

  /// No description provided for @lbsUnit.
  ///
  /// In en, this message translates to:
  /// **'lbs'**
  String get lbsUnit;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionHealthProfile.
  ///
  /// In en, this message translates to:
  /// **'Health Profile'**
  String get sectionHealthProfile;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get sectionUnits;

  /// No description provided for @sectionRestTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest Timer'**
  String get sectionRestTimer;

  /// No description provided for @sectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get sectionData;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @ageSubtitleSet.
  ///
  /// In en, this message translates to:
  /// **'{age} years (max HR: {maxHr} bpm)'**
  String ageSubtitleSet(int age, int maxHr);

  /// No description provided for @ageSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set your age for heart rate zones'**
  String get ageSubtitleEmpty;

  /// No description provided for @setYourAge.
  ///
  /// In en, this message translates to:
  /// **'Set Your Age'**
  String get setYourAge;

  /// No description provided for @ageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 30'**
  String get ageHint;

  /// No description provided for @restingHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Resting Heart Rate'**
  String get restingHeartRate;

  /// No description provided for @restingHrSubtitleSet.
  ///
  /// In en, this message translates to:
  /// **'{bpm} bpm'**
  String restingHrSubtitleSet(int bpm);

  /// No description provided for @restingHrSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Optional — enables Karvonen zones'**
  String get restingHrSubtitleEmpty;

  /// No description provided for @restingHrHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 60'**
  String get restingHrHint;

  /// No description provided for @measuredMaxHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Measured Max Heart Rate'**
  String get measuredMaxHeartRate;

  /// No description provided for @measuredMaxHrSubtitleSet.
  ///
  /// In en, this message translates to:
  /// **'{bpm} bpm'**
  String measuredMaxHrSubtitleSet(int bpm);

  /// No description provided for @measuredMaxHrSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Optional — from exercise testing'**
  String get measuredMaxHrSubtitleEmpty;

  /// No description provided for @measuredMaxHrHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 185'**
  String get measuredMaxHrHint;

  /// No description provided for @betaBlockerMedication.
  ///
  /// In en, this message translates to:
  /// **'Beta Blocker Medication'**
  String get betaBlockerMedication;

  /// No description provided for @betaBlockerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Affects heart rate zone accuracy'**
  String get betaBlockerSubtitle;

  /// No description provided for @heartConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Heart Condition'**
  String get heartConditionLabel;

  /// No description provided for @heartConditionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enables caution mode for zones'**
  String get heartConditionSubtitle;

  /// No description provided for @clinicianMaxHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Clinician Max Heart Rate'**
  String get clinicianMaxHeartRate;

  /// No description provided for @clinicianMaxHrSubtitleSet.
  ///
  /// In en, this message translates to:
  /// **'{bpm} bpm — overrides estimates'**
  String clinicianMaxHrSubtitleSet(int bpm);

  /// No description provided for @clinicianMaxHrSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Optional — from your doctor'**
  String get clinicianMaxHrSubtitleEmpty;

  /// No description provided for @clinicianMaxHrHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 150'**
  String get clinicianMaxHrHint;

  /// No description provided for @zoneMethod.
  ///
  /// In en, this message translates to:
  /// **'Zone Method'**
  String get zoneMethod;

  /// No description provided for @zoneMethodAndReliability.
  ///
  /// In en, this message translates to:
  /// **'{method} · {reliability} confidence'**
  String zoneMethodAndReliability(String method, String reliability);

  /// No description provided for @zoneMethodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom zones'**
  String get zoneMethodCustom;

  /// No description provided for @zoneMethodClinicianCap.
  ///
  /// In en, this message translates to:
  /// **'Clinician cap'**
  String get zoneMethodClinicianCap;

  /// No description provided for @zoneMethodHrr.
  ///
  /// In en, this message translates to:
  /// **'Heart rate reserve (Karvonen)'**
  String get zoneMethodHrr;

  /// No description provided for @zoneMethodMeasuredMax.
  ///
  /// In en, this message translates to:
  /// **'Measured max HR'**
  String get zoneMethodMeasuredMax;

  /// No description provided for @zoneMethodEstimatedMax.
  ///
  /// In en, this message translates to:
  /// **'Age-estimated max HR'**
  String get zoneMethodEstimatedMax;

  /// No description provided for @reliabilityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get reliabilityHigh;

  /// No description provided for @reliabilityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get reliabilityMedium;

  /// No description provided for @reliabilityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get reliabilityLow;

  /// No description provided for @setUpHeartRateZones.
  ///
  /// In en, this message translates to:
  /// **'Set Up Heart Rate Zones'**
  String get setUpHeartRateZones;

  /// No description provided for @stepByStepGuidedSetup.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step guided setup'**
  String get stepByStepGuidedSetup;

  /// No description provided for @zoneColourBands.
  ///
  /// In en, this message translates to:
  /// **'Zone Colour Bands'**
  String get zoneColourBands;

  /// No description provided for @zoneColourBandsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show coloured zone bands on HR chart'**
  String get zoneColourBandsSubtitle;

  /// No description provided for @sectionMaxHrAlert.
  ///
  /// In en, this message translates to:
  /// **'Max Heart Rate Alert'**
  String get sectionMaxHrAlert;

  /// No description provided for @maxHrAlertVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration on Max HR'**
  String get maxHrAlertVibration;

  /// No description provided for @maxHrAlertVibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate when heart rate reaches the recommended maximum'**
  String get maxHrAlertVibrationSubtitle;

  /// No description provided for @maxHrAlertSound.
  ///
  /// In en, this message translates to:
  /// **'Sound on Max HR'**
  String get maxHrAlertSound;

  /// No description provided for @maxHrAlertSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play a warning sound when heart rate reaches the recommended maximum'**
  String get maxHrAlertSoundSubtitle;

  /// No description provided for @maxHrAlertCooldown.
  ///
  /// In en, this message translates to:
  /// **'Alert Cooldown'**
  String get maxHrAlertCooldown;

  /// No description provided for @maxHrAlertCooldownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Minimum seconds between repeated alerts'**
  String get maxHrAlertCooldownSubtitle;

  /// No description provided for @maxHrAlertCooldownValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String maxHrAlertCooldownValue(int seconds);

  /// No description provided for @maxHrReached.
  ///
  /// In en, this message translates to:
  /// **'Heart rate at or above recommended maximum'**
  String get maxHrReached;

  /// No description provided for @disclaimerLabel.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get disclaimerLabel;

  /// No description provided for @settingsShowExerciseImages.
  ///
  /// In en, this message translates to:
  /// **'Show Exercise Images'**
  String get settingsShowExerciseImages;

  /// No description provided for @settingsShowExerciseImagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display exercise illustrations in lists'**
  String get settingsShowExerciseImagesSubtitle;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @weightUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight Unit'**
  String get weightUnitLabel;

  /// No description provided for @vibrationAlert.
  ///
  /// In en, this message translates to:
  /// **'Vibration Alert'**
  String get vibrationAlert;

  /// No description provided for @vibrationAlertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate when rest timer completes'**
  String get vibrationAlertSubtitle;

  /// No description provided for @soundAlert.
  ///
  /// In en, this message translates to:
  /// **'Sound Alert'**
  String get soundAlert;

  /// No description provided for @soundAlertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play a sound when rest timer completes'**
  String get soundAlertSubtitle;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @clearAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all workouts and settings.'**
  String get clearAllDataSubtitle;

  /// No description provided for @clearAllDataConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data?'**
  String get clearAllDataConfirmTitle;

  /// No description provided for @clearAllDataConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your workout history and cannot be undone.'**
  String get clearAllDataConfirmContent;

  /// No description provided for @allDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared.'**
  String get allDataCleared;

  /// No description provided for @aboutAppName.
  ///
  /// In en, this message translates to:
  /// **'RepFoundry'**
  String get aboutAppName;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get aboutVersion;

  /// No description provided for @heartRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get heartRateTitle;

  /// No description provided for @connectHrMonitor.
  ///
  /// In en, this message translates to:
  /// **'Connect HR Monitor'**
  String get connectHrMonitor;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @setupGuide.
  ///
  /// In en, this message translates to:
  /// **'Setup guide'**
  String get setupGuide;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @recentChart.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentChart;

  /// No description provided for @fullSessionChart.
  ///
  /// In en, this message translates to:
  /// **'Full Session'**
  String get fullSessionChart;

  /// No description provided for @setAgeInSettings.
  ///
  /// In en, this message translates to:
  /// **'Set your age in Settings'**
  String get setAgeInSettings;

  /// No description provided for @setAgeInSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Heart rate training zones will appear when your age is configured.'**
  String get setAgeInSettingsSubtitle;

  /// No description provided for @statsAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get statsAvg;

  /// No description provided for @statsMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get statsMin;

  /// No description provided for @statsMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get statsMax;

  /// No description provided for @statsReadings.
  ///
  /// In en, this message translates to:
  /// **'Readings'**
  String get statsReadings;

  /// No description provided for @timeInZone.
  ///
  /// In en, this message translates to:
  /// **'Time in Zone'**
  String get timeInZone;

  /// No description provided for @moderateOrHigher.
  ///
  /// In en, this message translates to:
  /// **'Moderate or higher: {duration}'**
  String moderateOrHigher(String duration);

  /// No description provided for @recoveryHrDrop.
  ///
  /// In en, this message translates to:
  /// **'Recovery HR drop: {bpm} bpm'**
  String recoveryHrDrop(int bpm);

  /// No description provided for @bluetoothNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is not available. Ensure Bluetooth is turned on.'**
  String get bluetoothNotAvailable;

  /// No description provided for @chartWindowSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String chartWindowSeconds(int seconds);

  /// No description provided for @chartWindowMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String chartWindowMinutes(int minutes);

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Up Heart Rate Zones'**
  String get onboardingTitle;

  /// No description provided for @onboardingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepOf(int current, int total);

  /// No description provided for @onboardingAgeExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your age is used to estimate your maximum heart rate and personalise training zones.'**
  String get onboardingAgeExplanation;

  /// No description provided for @onboardingRestingHrExplanation.
  ///
  /// In en, this message translates to:
  /// **'Providing your resting heart rate enables more accurate zone calculation using the Karvonen (heart rate reserve) method.'**
  String get onboardingRestingHrExplanation;

  /// No description provided for @onboardingRestingHrLabel.
  ///
  /// In en, this message translates to:
  /// **'Resting Heart Rate (optional)'**
  String get onboardingRestingHrLabel;

  /// No description provided for @onboardingMeasuredMaxHrLabel.
  ///
  /// In en, this message translates to:
  /// **'Measured Max Heart Rate (optional)'**
  String get onboardingMeasuredMaxHrLabel;

  /// No description provided for @onboardingRestingHrHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 60'**
  String get onboardingRestingHrHint;

  /// No description provided for @onboardingMeasuredMaxHrHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 185'**
  String get onboardingMeasuredMaxHrHint;

  /// No description provided for @onboardingMedicalExplanation.
  ///
  /// In en, this message translates to:
  /// **'If any of these apply, heart rate zones will be shown in caution mode with reduced confidence. We recommend consulting your healthcare provider for personalised limits.'**
  String get onboardingMedicalExplanation;

  /// No description provided for @onboardingBetaBlockerLabel.
  ///
  /// In en, this message translates to:
  /// **'Taking beta blocker medication'**
  String get onboardingBetaBlockerLabel;

  /// No description provided for @onboardingHeartConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Heart condition'**
  String get onboardingHeartConditionLabel;

  /// No description provided for @onboardingClinicianWithFlags.
  ///
  /// In en, this message translates to:
  /// **'Because you have medical factors, we strongly recommend entering a clinician-provided maximum heart rate. This will override all other estimates.'**
  String get onboardingClinicianWithFlags;

  /// No description provided for @onboardingClinicianWithoutFlags.
  ///
  /// In en, this message translates to:
  /// **'If your doctor or exercise physiologist has given you a maximum heart rate, enter it here to override the estimate.'**
  String get onboardingClinicianWithoutFlags;

  /// No description provided for @onboardingClinicianMaxHrLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinician Max Heart Rate (optional)'**
  String get onboardingClinicianMaxHrLabel;

  /// No description provided for @disclaimerDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate Monitoring'**
  String get disclaimerDialogTitle;

  /// No description provided for @disclaimerDialogButton.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get disclaimerDialogButton;

  /// No description provided for @cautionModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Caution Mode'**
  String get cautionModeTitle;

  /// No description provided for @symptomReportButton.
  ///
  /// In en, this message translates to:
  /// **'Report Symptom'**
  String get symptomReportButton;

  /// No description provided for @symptomReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Symptom Report'**
  String get symptomReportTitle;

  /// No description provided for @stopExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop Exercise'**
  String get stopExerciseTitle;

  /// No description provided for @stopExerciseOk.
  ///
  /// In en, this message translates to:
  /// **'I\'m OK, stopping exercise'**
  String get stopExerciseOk;

  /// No description provided for @stopExerciseHelp.
  ///
  /// In en, this message translates to:
  /// **'I need help'**
  String get stopExerciseHelp;

  /// No description provided for @warningGeneralDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Heart rate zone estimates are for informational purposes only and do not constitute medical advice. Always consult a healthcare professional before starting or modifying an exercise programme, especially if you have a pre-existing medical condition.'**
  String get warningGeneralDisclaimer;

  /// No description provided for @warningBetaBlocker.
  ///
  /// In en, this message translates to:
  /// **'Beta blocker medication can significantly reduce your maximum heart rate. Standard zone calculations may not be accurate. We recommend setting a clinician-provided maximum heart rate or using rate of perceived exertion (RPE) and the talk test to gauge intensity.'**
  String get warningBetaBlocker;

  /// No description provided for @warningHeartCondition.
  ///
  /// In en, this message translates to:
  /// **'You have indicated a heart condition. Standard heart rate zone calculations may not be appropriate. We strongly recommend obtaining a clinician-provided maximum heart rate before using intensity-based training guidance.'**
  String get warningHeartCondition;

  /// No description provided for @warningClinicianCap.
  ///
  /// In en, this message translates to:
  /// **'Heart rate zones are calculated using a clinician-provided maximum heart rate. This overrides any age-based or measured estimates.'**
  String get warningClinicianCap;

  /// No description provided for @warningStopExercise.
  ///
  /// In en, this message translates to:
  /// **'If you are experiencing chest pain, severe dizziness, fainting, or unusual shortness of breath, stop exercising immediately. If symptoms persist, seek urgent medical attention.'**
  String get warningStopExercise;

  /// No description provided for @warningSymptomIntro.
  ///
  /// In en, this message translates to:
  /// **'Are you experiencing any of the following symptoms?'**
  String get warningSymptomIntro;

  /// No description provided for @symptomChestPain.
  ///
  /// In en, this message translates to:
  /// **'Chest pain or tightness'**
  String get symptomChestPain;

  /// No description provided for @symptomDizziness.
  ///
  /// In en, this message translates to:
  /// **'Severe dizziness or light-headedness'**
  String get symptomDizziness;

  /// No description provided for @symptomFainting.
  ///
  /// In en, this message translates to:
  /// **'Feeling faint or about to faint'**
  String get symptomFainting;

  /// No description provided for @symptomBreathing.
  ///
  /// In en, this message translates to:
  /// **'Unusual shortness of breath'**
  String get symptomBreathing;

  /// No description provided for @clinicianLimitsInUse.
  ///
  /// In en, this message translates to:
  /// **'Clinician-provided limits in use'**
  String get clinicianLimitsInUse;

  /// No description provided for @workoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutTitle;

  /// No description provided for @workoutTitleWithTime.
  ///
  /// In en, this message translates to:
  /// **'Workout  •  {time}'**
  String workoutTitleWithTime(String time);

  /// No description provided for @loadingWorkout.
  ///
  /// In en, this message translates to:
  /// **'Loading workout…'**
  String get loadingWorkout;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get addExercise;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get startWorkout;

  /// No description provided for @noActiveWorkout.
  ///
  /// In en, this message translates to:
  /// **'No active workout'**
  String get noActiveWorkout;

  /// No description provided for @noActiveWorkoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new workout to begin logging sets.'**
  String get noActiveWorkoutSubtitle;

  /// No description provided for @addExercisesHint.
  ///
  /// In en, this message translates to:
  /// **'Add exercises using the button below'**
  String get addExercisesHint;

  /// No description provided for @finishWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish Workout?'**
  String get finishWorkoutTitle;

  /// No description provided for @finishWorkoutContent.
  ///
  /// In en, this message translates to:
  /// **'This will save your workout and end the session.'**
  String get finishWorkoutContent;

  /// No description provided for @tableHeaderHash.
  ///
  /// In en, this message translates to:
  /// **'#'**
  String get tableHeaderHash;

  /// No description provided for @tableHeaderWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get tableHeaderWeight;

  /// No description provided for @tableHeaderReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get tableHeaderReps;

  /// No description provided for @tableHeaderE1rm.
  ///
  /// In en, this message translates to:
  /// **'e1RM'**
  String get tableHeaderE1rm;

  /// No description provided for @weightKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKgLabel;

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsLabel;

  /// No description provided for @rpeLabel.
  ///
  /// In en, this message translates to:
  /// **'RPE'**
  String get rpeLabel;

  /// No description provided for @addRpe.
  ///
  /// In en, this message translates to:
  /// **'Add RPE'**
  String get addRpe;

  /// No description provided for @hideRpe.
  ///
  /// In en, this message translates to:
  /// **'Hide RPE'**
  String get hideRpe;

  /// No description provided for @logSet.
  ///
  /// In en, this message translates to:
  /// **'Log Set'**
  String get logSet;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get validationInvalid;

  /// No description provided for @validationMinZero.
  ///
  /// In en, this message translates to:
  /// **'≥ 0'**
  String get validationMinZero;

  /// No description provided for @validationRpeRange.
  ///
  /// In en, this message translates to:
  /// **'1–10'**
  String get validationRpeRange;

  /// No description provided for @restTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest Timer'**
  String get restTimer;

  /// No description provided for @stopTimer.
  ///
  /// In en, this message translates to:
  /// **'Stop timer'**
  String get stopTimer;

  /// No description provided for @newPersonalRecord.
  ///
  /// In en, this message translates to:
  /// **'New Personal Record!'**
  String get newPersonalRecord;

  /// No description provided for @e1rmValue.
  ///
  /// In en, this message translates to:
  /// **'e1RM: {value} kg'**
  String e1rmValue(String value);

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @noWorkoutsYet.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get noWorkoutsYet;

  /// No description provided for @noWorkoutsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed workouts will appear here.'**
  String get noWorkoutsYetSubtitle;

  /// No description provided for @loadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading history…'**
  String get loadingHistory;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// No description provided for @volumeTrend.
  ///
  /// In en, this message translates to:
  /// **'Volume trend (last {count} workouts)'**
  String volumeTrend(int count);

  /// No description provided for @setsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sets'**
  String setsCount(int count);

  /// No description provided for @prBadge.
  ///
  /// In en, this message translates to:
  /// **'PR!'**
  String get prBadge;

  /// No description provided for @workoutDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Detail'**
  String get workoutDetailTitle;

  /// No description provided for @workoutNotFound.
  ///
  /// In en, this message translates to:
  /// **'Workout not found'**
  String get workoutNotFound;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @setsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get setsLabel;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeLabel;

  /// No description provided for @exerciseProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise Progress'**
  String get exerciseProgressTitle;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @noDataYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log sets for this exercise to see your progress.'**
  String get noDataYetSubtitle;

  /// No description provided for @loadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Loading progress…'**
  String get loadingProgress;

  /// No description provided for @bestE1rm.
  ///
  /// In en, this message translates to:
  /// **'Best e1RM'**
  String get bestE1rm;

  /// No description provided for @totalVolume.
  ///
  /// In en, this message translates to:
  /// **'Total Volume'**
  String get totalVolume;

  /// No description provided for @totalSets.
  ///
  /// In en, this message translates to:
  /// **'Total Sets'**
  String get totalSets;

  /// No description provided for @e1rmTrend.
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM Trend'**
  String get e1rmTrend;

  /// No description provided for @recentSets.
  ///
  /// In en, this message translates to:
  /// **'Recent Sets'**
  String get recentSets;

  /// No description provided for @tableHeaderDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get tableHeaderDate;

  /// No description provided for @chooseExercise.
  ///
  /// In en, this message translates to:
  /// **'Choose Exercise'**
  String get chooseExercise;

  /// No description provided for @searchExercisesHint.
  ///
  /// In en, this message translates to:
  /// **'Search exercises…'**
  String get searchExercisesHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @noExercisesFound.
  ///
  /// In en, this message translates to:
  /// **'No exercises found'**
  String get noExercisesFound;

  /// No description provided for @loadingExercises.
  ///
  /// In en, this message translates to:
  /// **'Loading exercises…'**
  String get loadingExercises;

  /// No description provided for @customExercise.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customExercise;

  /// No description provided for @newExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'New Exercise'**
  String get newExerciseTitle;

  /// No description provided for @exerciseNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercise Name'**
  String get exerciseNameLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @muscleGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Muscle Group'**
  String get muscleGroupLabel;

  /// No description provided for @equipmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipmentLabel;

  /// No description provided for @exerciseNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an exercise name'**
  String get exerciseNameRequired;

  /// No description provided for @cardioTitle.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get cardioTitle;

  /// No description provided for @exerciseField.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exerciseField;

  /// No description provided for @distanceMetresLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance (metres)'**
  String get distanceMetresLabel;

  /// No description provided for @inclineLabel.
  ///
  /// In en, this message translates to:
  /// **'Incline (%)'**
  String get inclineLabel;

  /// No description provided for @avgHeartRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Heart Rate (bpm)'**
  String get avgHeartRateLabel;

  /// No description provided for @lastSession.
  ///
  /// In en, this message translates to:
  /// **'Last session'**
  String get lastSession;

  /// No description provided for @gpsDistanceTracking.
  ///
  /// In en, this message translates to:
  /// **'GPS Distance Tracking'**
  String get gpsDistanceTracking;

  /// No description provided for @gpsAcquiring.
  ///
  /// In en, this message translates to:
  /// **'Acquiring signal...'**
  String get gpsAcquiring;

  /// No description provided for @gpsMetresTracked.
  ///
  /// In en, this message translates to:
  /// **'{metres} m tracked'**
  String gpsMetresTracked(String metres);

  /// No description provided for @gpsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track distance via GPS for outdoor runs'**
  String get gpsSubtitle;

  /// No description provided for @saveSession.
  ///
  /// In en, this message translates to:
  /// **'Save Session'**
  String get saveSession;

  /// No description provided for @cardioSessionSaved.
  ///
  /// In en, this message translates to:
  /// **'Cardio session saved'**
  String get cardioSessionSaved;

  /// No description provided for @heartRateMonitorCard.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate Monitor'**
  String get heartRateMonitorCard;

  /// No description provided for @heartRateMonitorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect a BLE heart rate strap or watch'**
  String get heartRateMonitorSubtitle;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connectingTo.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {device}...'**
  String connectingTo(String device);

  /// No description provided for @reconnectingTo.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to {device}...'**
  String reconnectingTo(String device);

  /// No description provided for @paceLabel.
  ///
  /// In en, this message translates to:
  /// **'Pace: {pace}'**
  String paceLabel(String pace);

  /// No description provided for @hrSetupGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate Setup Guide'**
  String get hrSetupGuideTitle;

  /// No description provided for @appleWatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Apple Watch'**
  String get appleWatchTitle;

  /// No description provided for @samsungWatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Samsung Galaxy Watch'**
  String get samsungWatchTitle;

  /// No description provided for @chestStrapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chest Straps & Arm Bands'**
  String get chestStrapsTitle;

  /// No description provided for @appleWatchStep1.
  ///
  /// In en, this message translates to:
  /// **'On your Apple Watch, open Settings → Workout → Heart Rate.'**
  String get appleWatchStep1;

  /// No description provided for @appleWatchStep2.
  ///
  /// In en, this message translates to:
  /// **'Enable \"Broadcast Heart Rate\".'**
  String get appleWatchStep2;

  /// No description provided for @appleWatchStep3.
  ///
  /// In en, this message translates to:
  /// **'Start any workout on the Apple Watch.'**
  String get appleWatchStep3;

  /// No description provided for @appleWatchStep4.
  ///
  /// In en, this message translates to:
  /// **'In RepFoundry, tap \"Connect\" and select your Apple Watch.'**
  String get appleWatchStep4;

  /// No description provided for @samsungWatchStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Samsung Health on your watch.'**
  String get samsungWatchStep1;

  /// No description provided for @samsungWatchStep2.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings → Heart Rate Broadcast.'**
  String get samsungWatchStep2;

  /// No description provided for @samsungWatchStep3.
  ///
  /// In en, this message translates to:
  /// **'Enable BLE broadcasting.'**
  String get samsungWatchStep3;

  /// No description provided for @samsungWatchStep4.
  ///
  /// In en, this message translates to:
  /// **'In RepFoundry, tap \"Connect\" and select your Galaxy Watch.'**
  String get samsungWatchStep4;

  /// No description provided for @chestStrapStep1.
  ///
  /// In en, this message translates to:
  /// **'Any BLE heart rate device (Polar, Garmin, Wahoo, etc.) works automatically.'**
  String get chestStrapStep1;

  /// No description provided for @chestStrapStep2.
  ///
  /// In en, this message translates to:
  /// **'Simply wear your strap or band and tap \"Connect\".'**
  String get chestStrapStep2;

  /// No description provided for @chestStrapStep3.
  ///
  /// In en, this message translates to:
  /// **'Your device will appear in the scan list.'**
  String get chestStrapStep3;

  /// No description provided for @hrDevicePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate Monitors'**
  String get hrDevicePickerTitle;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning for devices...'**
  String get scanning;

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No heart rate monitors found. Ensure your device is broadcasting — for Apple Watch, start a workout with Broadcast Heart Rate enabled.'**
  String get noDevicesFound;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgain;

  /// No description provided for @setupHelp.
  ///
  /// In en, this message translates to:
  /// **'Setup Help'**
  String get setupHelp;

  /// No description provided for @templatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templatesTitle;

  /// No description provided for @noTemplatesYet.
  ///
  /// In en, this message translates to:
  /// **'No templates yet'**
  String get noTemplatesYet;

  /// No description provided for @noTemplatesYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a template to quickly start workouts.'**
  String get noTemplatesYetSubtitle;

  /// No description provided for @failedToLoadTemplates.
  ///
  /// In en, this message translates to:
  /// **'Failed to load templates: {error}'**
  String failedToLoadTemplates(String error);

  /// No description provided for @newTemplate.
  ///
  /// In en, this message translates to:
  /// **'New Template'**
  String get newTemplate;

  /// No description provided for @newTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'New Template'**
  String get newTemplateTitle;

  /// No description provided for @templateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get templateNameLabel;

  /// No description provided for @deleteTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Template?'**
  String get deleteTemplateTitle;

  /// No description provided for @deleteTemplateContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteTemplateContent(String name);

  /// No description provided for @exerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String exerciseCount(int count);
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return SZhHans();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
