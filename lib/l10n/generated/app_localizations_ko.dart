// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class SKo extends S {
  SKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'RepFoundry';

  @override
  String get navWorkout => '운동';

  @override
  String get navHistory => '기록';

  @override
  String get navCardio => '유산소';

  @override
  String get navHeartRate => '심박수';

  @override
  String get navSettings => '설정';

  @override
  String get start => '시작';

  @override
  String get pause => '일시정지';

  @override
  String get resume => '재개';

  @override
  String get reset => '초기화';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get create => '생성';

  @override
  String get finish => '완료';

  @override
  String get next => '다음';

  @override
  String get back => '뒤로';

  @override
  String get skip => '건너뛰기';

  @override
  String get done => '완료';

  @override
  String get retry => '재시도';

  @override
  String get bpmSuffix => 'bpm';

  @override
  String get yearsSuffix => '세';

  @override
  String get kgUnit => 'kg';

  @override
  String get lbsUnit => 'lbs';

  @override
  String get settingsTitle => '설정';

  @override
  String get sectionHealthProfile => '건강 프로필';

  @override
  String get sectionAppearance => '외관';

  @override
  String get sectionUnits => '단위';

  @override
  String get sectionRestTimer => '휴식 타이머';

  @override
  String get sectionData => '데이터';

  @override
  String get sectionAbout => '정보';

  @override
  String get ageLabel => '나이';

  @override
  String ageSubtitleSet(int age, int maxHr) {
    return '$age세 (최대 심박수: $maxHr bpm)';
  }

  @override
  String get ageSubtitleEmpty => '심박수 구간 계산을 위해 나이를 설정하세요';

  @override
  String get setYourAge => '나이 설정';

  @override
  String get ageHint => '예: 30';

  @override
  String get restingHeartRate => '안정 시 심박수';

  @override
  String restingHrSubtitleSet(int bpm) {
    return '$bpm bpm';
  }

  @override
  String get restingHrSubtitleEmpty => '선택 — Karvonen 구간 활성화';

  @override
  String get restingHrHint => '예: 60';

  @override
  String get measuredMaxHeartRate => '측정 최대 심박수';

  @override
  String measuredMaxHrSubtitleSet(int bpm) {
    return '$bpm bpm';
  }

  @override
  String get measuredMaxHrSubtitleEmpty => '선택 — 운동 부하 검사에서';

  @override
  String get measuredMaxHrHint => '예: 185';

  @override
  String get betaBlockerMedication => '베타 차단제 복용';

  @override
  String get betaBlockerSubtitle => '심박수 구간 정확도에 영향';

  @override
  String get heartConditionLabel => '심장 질환';

  @override
  String get heartConditionSubtitle => '구간에 주의 모드 활성화';

  @override
  String get clinicianMaxHeartRate => '의사 지정 최대 심박수';

  @override
  String clinicianMaxHrSubtitleSet(int bpm) {
    return '$bpm bpm — 추정값 대체';
  }

  @override
  String get clinicianMaxHrSubtitleEmpty => '선택 — 의사 제공';

  @override
  String get clinicianMaxHrHint => '예: 150';

  @override
  String get zoneMethod => '구간 계산 방식';

  @override
  String zoneMethodAndReliability(String method, String reliability) {
    return '$method · $reliability 신뢰도';
  }

  @override
  String get zoneMethodCustom => '맞춤 구간';

  @override
  String get zoneMethodClinicianCap => '의사 상한';

  @override
  String get zoneMethodHrr => '심박수 예비능 (Karvonen)';

  @override
  String get zoneMethodLthrFriel => '젖산 역치 (Friel)';

  @override
  String get zoneMethodMeasuredMax => '측정 최대 심박수';

  @override
  String get zoneMethodEstimatedMax => '나이 추정 최대 심박수';

  @override
  String get reliabilityHigh => '높음';

  @override
  String get reliabilityMedium => '보통';

  @override
  String get reliabilityLow => '낮음';

  @override
  String get setUpHeartRateZones => '심박수 구간 설정';

  @override
  String get stepByStepGuidedSetup => '단계별 가이드 설정';

  @override
  String get zoneColourBands => '구간 색상 밴드';

  @override
  String get zoneColourBandsSubtitle => '심박수 차트에 색상 구간 밴드 표시';

  @override
  String get sectionMaxHrAlert => '최대 심박수 알림';

  @override
  String get maxHrAlertVibration => '최대 심박수 도달 시 진동';

  @override
  String get maxHrAlertVibrationSubtitle => '심박수가 권장 최대치에 도달하면 진동으로 알림';

  @override
  String get maxHrAlertSound => '최대 심박수 도달 시 소리';

  @override
  String get maxHrAlertSoundSubtitle => '심박수가 권장 최대치에 도달하면 경고음 재생';

  @override
  String get maxHrAlertCooldown => '알림 쿨다운';

  @override
  String get maxHrAlertCooldownSubtitle => '반복 알림 간 최소 간격(초)';

  @override
  String maxHrAlertCooldownValue(int seconds) {
    return '$seconds초';
  }

  @override
  String get maxHrReached => '심박수가 권장 최대치에 도달했습니다';

  @override
  String get disclaimerLabel => '면책 조항';

  @override
  String get settingsShowExerciseImages => '운동 이미지 표시';

  @override
  String get settingsShowExerciseImagesSubtitle => '목록에 운동 일러스트 표시';

  @override
  String get themeLabel => '테마';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get themeAuto => '자동';

  @override
  String get weightUnitLabel => '무게 단위';

  @override
  String get vibrationAlert => '진동 알림';

  @override
  String get vibrationAlertSubtitle => '휴식 타이머 종료 시 진동';

  @override
  String get soundAlert => '소리 알림';

  @override
  String get soundAlertSubtitle => '휴식 타이머 종료 시 소리 재생';

  @override
  String get clearAllData => '모든 데이터 삭제';

  @override
  String get clearAllDataSubtitle => '모든 운동 기록과 설정을 영구 삭제합니다.';

  @override
  String get clearAllDataConfirmTitle => '모든 데이터를 삭제하시겠습니까?';

  @override
  String get clearAllDataConfirmContent => '모든 운동 기록이 영구 삭제되며 되돌릴 수 없습니다.';

  @override
  String get allDataCleared => '모든 데이터가 삭제되었습니다.';

  @override
  String get aboutAppName => 'RepFoundry';

  @override
  String aboutVersion(String version) {
    return '버전 $version';
  }

  @override
  String get aboutScreenTitle => 'RepFoundry 정보';

  @override
  String get aboutDescription => '헬스장 이용자를 위한 간편하고 빠른 운동 기록 앱.';

  @override
  String get aboutAuthorLabel => '개발자';

  @override
  String get aboutAuthor => 'Paul Snow';

  @override
  String get aboutGitHub => 'GitHub 저장소';

  @override
  String get aboutFeatures => '기능';

  @override
  String get aboutFeatureOffline => '오프라인 우선 — 데이터가 기기에 저장됩니다';

  @override
  String get aboutFeatureHeartRate => '블루투스 심박수 모니터 지원';

  @override
  String get aboutFeatureTemplates => '빠른 세션 시작을 위한 운동 템플릿';

  @override
  String get aboutFeatureProgress => '개인 기록으로 진행 상황 추적';

  @override
  String get aboutFeatureExport => 'JSON 또는 CSV로 데이터 내보내기';

  @override
  String get aboutFeatureCardio => 'GPS 추적 유산소 세션';

  @override
  String get aboutBuiltWith => 'Flutter로 개발';

  @override
  String get aboutViewLicences => '오픈소스 라이선스';

  @override
  String get heartRateTitle => '심박수';

  @override
  String get connectHrMonitor => '심박수 모니터 연결';

  @override
  String get disconnect => '연결 해제';

  @override
  String get setupGuide => '설정 가이드';

  @override
  String get reconnecting => '재연결 중...';

  @override
  String get recentChart => '최근';

  @override
  String get fullSessionChart => '전체 세션';

  @override
  String get setAgeInSettings => '설정에서 나이를 입력하세요';

  @override
  String get setAgeInSettingsSubtitle => '나이를 설정하면 심박수 트레이닝 구간이 표시됩니다.';

  @override
  String get statsAvg => '평균';

  @override
  String get statsMin => '최소';

  @override
  String get statsMax => '최대';

  @override
  String get statsReadings => '판독 수';

  @override
  String get timeInZone => '구간 체류 시간';

  @override
  String moderateOrHigher(String duration) {
    return '중간 이상: $duration';
  }

  @override
  String recoveryHrDrop(int bpm) {
    return '회복 심박수 감소: $bpm bpm';
  }

  @override
  String get bluetoothNotAvailable => '블루투스를 사용할 수 없습니다. 블루투스가 켜져 있는지 확인하세요.';

  @override
  String chartWindowSeconds(int seconds) {
    return '$seconds초';
  }

  @override
  String chartWindowMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String get onboardingTitle => '심박수 구간 설정';

  @override
  String onboardingStepOf(int current, int total) {
    return '$current / $total 단계';
  }

  @override
  String get onboardingAgeExplanation => '나이는 최대 심박수 추정 및 트레이닝 구간 맞춤화에 사용됩니다.';

  @override
  String get onboardingRestingHrExplanation =>
      '안정 시 심박수를 입력하면 Karvonen(심박수 예비능) 방법으로 더 정확한 구간 계산이 가능합니다.';

  @override
  String get onboardingRestingHrLabel => '안정 시 심박수 (선택)';

  @override
  String get onboardingMeasuredMaxHrLabel => '측정 최대 심박수 (선택)';

  @override
  String get onboardingRestingHrHint => '예: 60';

  @override
  String get onboardingMeasuredMaxHrHint => '예: 185';

  @override
  String get onboardingMedicalExplanation =>
      '아래 항목 중 해당사항이 있으면 심박수 구간이 주의 모드로 표시되며 신뢰도가 낮아집니다. 개인 맞춤 상한은 의료 전문가에게 문의하세요.';

  @override
  String get onboardingBetaBlockerLabel => '베타 차단제 복용 중';

  @override
  String get onboardingHeartConditionLabel => '심장 질환';

  @override
  String get onboardingClinicianWithFlags =>
      '의료적 요인이 있으므로 의사가 제공한 최대 심박수를 입력하시기를 강력히 권합니다. 이 값이 다른 모든 추정값을 대체합니다.';

  @override
  String get onboardingClinicianWithoutFlags =>
      '의사 또는 운동생리학자로부터 최대 심박수를 제공받은 경우 여기에 입력하여 추정값을 대체하세요.';

  @override
  String get onboardingClinicianMaxHrLabel => '의사 지정 최대 심박수 (선택)';

  @override
  String get disclaimerDialogTitle => '심박수 모니터링';

  @override
  String get disclaimerDialogButton => '이해했습니다';

  @override
  String get cautionModeTitle => '주의 모드';

  @override
  String get symptomReportButton => '증상 보고';

  @override
  String get symptomReportTitle => '증상 보고';

  @override
  String get stopExerciseTitle => '운동 중지';

  @override
  String get stopExerciseOk => '괜찮습니다, 운동을 중지합니다';

  @override
  String get stopExerciseHelp => '도움이 필요합니다';

  @override
  String get warningGeneralDisclaimer =>
      '심박수 구간 추정은 참고용이며 의학적 조언이 아닙니다. 특히 기저 질환이 있는 경우, 운동 프로그램을 시작하거나 변경하기 전에 반드시 의료 전문가와 상담하세요.';

  @override
  String get warningBetaBlocker =>
      '베타 차단제는 최대 심박수를 크게 낮출 수 있습니다. 표준 구간 계산이 정확하지 않을 수 있습니다. 의사 제공 최대 심박수를 설정하거나 주관적 운동 강도(RPE)와 말하기 테스트로 강도를 판단하는 것을 권장합니다.';

  @override
  String get warningHeartCondition =>
      '심장 질환이 있는 것으로 표시되어 있습니다. 표준 심박수 구간 계산이 적합하지 않을 수 있습니다. 강도 기반 트레이닝 가이드를 사용하기 전에 의사 제공 최대 심박수를 얻는 것을 강력히 권장합니다.';

  @override
  String get warningClinicianCap =>
      '심박수 구간이 의사 제공 최대 심박수를 기반으로 계산됩니다. 이 값이 나이 기반 또는 측정 추정값을 대체합니다.';

  @override
  String get warningStopExercise =>
      '흉통, 심한 어지러움, 실신 또는 비정상적 호흡곤란이 있으면 즉시 운동을 중지하세요. 증상이 지속되면 응급 의료 처치를 받으세요.';

  @override
  String get warningSymptomIntro => '다음 증상을 경험하고 있습니까?';

  @override
  String get symptomChestPain => '흉통 또는 가슴 조임';

  @override
  String get symptomDizziness => '심한 어지러움 또는 현기증';

  @override
  String get symptomFainting => '실신 또는 실신 직전 느낌';

  @override
  String get symptomBreathing => '비정상적 호흡곤란';

  @override
  String get clinicianLimitsInUse => '의사 제공 제한값 사용 중';

  @override
  String get workoutTitle => '운동';

  @override
  String workoutTitleWithTime(String time) {
    return '운동  •  $time';
  }

  @override
  String get loadingWorkout => '운동 로딩 중…';

  @override
  String get addExercise => '운동 추가';

  @override
  String get startWorkout => '운동 시작';

  @override
  String get noActiveWorkout => '진행 중인 운동이 없습니다';

  @override
  String get noActiveWorkoutSubtitle => '새 운동을 시작하여 세트를 기록하세요.';

  @override
  String get addExercisesHint => '아래 버튼으로 운동을 추가하세요';

  @override
  String get finishWorkoutTitle => '운동을 종료하시겠습니까?';

  @override
  String get finishWorkoutContent => '운동을 저장하고 세션을 종료합니다.';

  @override
  String get tableHeaderHash => '#';

  @override
  String get tableHeaderWeight => '무게';

  @override
  String get tableHeaderReps => '횟수';

  @override
  String get tableHeaderE1rm => 'e1RM';

  @override
  String get weightKgLabel => '무게 (kg)';

  @override
  String get repsLabel => '횟수';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get addRpe => 'RPE 추가';

  @override
  String get hideRpe => 'RPE 숨기기';

  @override
  String get logSet => '세트 기록';

  @override
  String get validationRequired => '필수';

  @override
  String get validationInvalid => '유효하지 않음';

  @override
  String get validationMinZero => '≥ 0';

  @override
  String get validationRpeRange => '1–10';

  @override
  String get restTimer => '휴식 타이머';

  @override
  String get stopTimer => '타이머 중지';

  @override
  String get newPersonalRecord => '새로운 개인 기록!';

  @override
  String e1rmValue(String value) {
    return 'e1RM: $value kg';
  }

  @override
  String get historyTitle => '기록';

  @override
  String get noWorkoutsYet => '아직 운동 기록이 없습니다';

  @override
  String get noWorkoutsYetSubtitle => '완료된 운동이 여기에 표시됩니다.';

  @override
  String get loadingHistory => '기록 로딩 중…';

  @override
  String errorPrefix(String error) {
    return '오류: $error';
  }

  @override
  String volumeTrend(int count) {
    return '볼륨 추세 (최근 $count회 운동)';
  }

  @override
  String setsCount(int count) {
    return '$count 세트';
  }

  @override
  String get prBadge => 'PR!';

  @override
  String get workoutDetailTitle => '운동 상세';

  @override
  String get workoutNotFound => '운동을 찾을 수 없습니다';

  @override
  String get durationLabel => '시간';

  @override
  String get setsLabel => '세트';

  @override
  String get volumeLabel => '볼륨';

  @override
  String get exerciseProgressTitle => '운동 진행';

  @override
  String get noDataYet => '아직 데이터가 없습니다';

  @override
  String get noDataYetSubtitle => '이 운동의 세트를 기록하면 진행 상황을 볼 수 있습니다.';

  @override
  String get loadingProgress => '진행 상황 로딩 중…';

  @override
  String get bestE1rm => '최고 e1RM';

  @override
  String get totalVolume => '총 볼륨';

  @override
  String get totalSets => '총 세트';

  @override
  String get e1rmTrend => '추정 1RM 추세';

  @override
  String get recentSets => '최근 세트';

  @override
  String get tableHeaderDate => '날짜';

  @override
  String get chooseExercise => '운동 선택';

  @override
  String get searchExercisesHint => '운동 검색…';

  @override
  String get filterAll => '전체';

  @override
  String get noExercisesFound => '운동을 찾을 수 없습니다';

  @override
  String get loadingExercises => '운동 로딩 중…';

  @override
  String get customExercise => '맞춤';

  @override
  String get newExerciseTitle => '새 운동';

  @override
  String get exerciseNameLabel => '운동 이름';

  @override
  String get categoryLabel => '카테고리';

  @override
  String get muscleGroupLabel => '근육 그룹';

  @override
  String get equipmentLabel => '장비';

  @override
  String get exerciseNameRequired => '운동 이름을 입력하세요';

  @override
  String get cardioTitle => '유산소';

  @override
  String get exerciseField => '종목';

  @override
  String get distanceMetresLabel => '거리 (미터)';

  @override
  String get inclineLabel => '경사 (%)';

  @override
  String get avgHeartRateLabel => '평균 심박수 (bpm)';

  @override
  String get lastSession => '이전 세션';

  @override
  String get gpsDistanceTracking => 'GPS 거리 추적';

  @override
  String get gpsAcquiring => '신호 수신 중...';

  @override
  String gpsMetresTracked(String metres) {
    return '$metres m 추적 중';
  }

  @override
  String get gpsSubtitle => '실외 런닝 거리를 GPS로 추적';

  @override
  String get saveSession => '세션 저장';

  @override
  String get cardioSessionSaved => '유산소 세션이 저장되었습니다';

  @override
  String get heartRateMonitorCard => '심박수 모니터';

  @override
  String get heartRateMonitorSubtitle => 'BLE 심박 스트랩 또는 워치 연결';

  @override
  String get connect => '연결';

  @override
  String connectingTo(String device) {
    return '$device에 연결 중...';
  }

  @override
  String reconnectingTo(String device) {
    return '$device에 재연결 중...';
  }

  @override
  String paceLabel(String pace) {
    return '페이스: $pace';
  }

  @override
  String get hrSetupGuideTitle => '심박수 설정 가이드';

  @override
  String get appleWatchTitle => 'Apple Watch';

  @override
  String get samsungWatchTitle => 'Samsung Galaxy Watch';

  @override
  String get chestStrapsTitle => '가슴 스트랩 및 팔 밴드';

  @override
  String get appleWatchStep1 => 'Apple Watch에서 설정 → 운동 → 심박수를 엽니다.';

  @override
  String get appleWatchStep2 => '\"심박수 브로드캐스트\"를 활성화합니다.';

  @override
  String get appleWatchStep3 => 'Apple Watch에서 아무 운동이나 시작합니다.';

  @override
  String get appleWatchStep4 => 'RepFoundry에서 \"연결\"을 탭하고 Apple Watch를 선택합니다.';

  @override
  String get samsungWatchStep1 => '워치에서 Samsung Health를 엽니다.';

  @override
  String get samsungWatchStep2 => '설정 → 심박수 브로드캐스트로 이동합니다.';

  @override
  String get samsungWatchStep3 => 'BLE 브로드캐스트를 활성화합니다.';

  @override
  String get samsungWatchStep4 =>
      'RepFoundry에서 \"연결\"을 탭하고 Galaxy Watch를 선택합니다.';

  @override
  String get chestStrapStep1 =>
      '모든 BLE 심박 기기(Polar, Garmin, Wahoo 등)가 자동으로 작동합니다.';

  @override
  String get chestStrapStep2 => '스트랩이나 밴드를 착용하고 \"연결\"을 탭하세요.';

  @override
  String get chestStrapStep3 => '기기가 스캔 목록에 나타납니다.';

  @override
  String get hrDevicePickerTitle => '심박수 모니터';

  @override
  String get scanning => '기기 스캔 중...';

  @override
  String get noDevicesFound =>
      '심박수 모니터를 찾을 수 없습니다. 기기가 브로드캐스트 중인지 확인하세요. Apple Watch의 경우 심박수 브로드캐스트를 활성화하고 운동을 시작하세요.';

  @override
  String get scanAgain => '다시 스캔';

  @override
  String get setupHelp => '설정 도움말';

  @override
  String get templatesTitle => '템플릿';

  @override
  String get noTemplatesYet => '아직 템플릿이 없습니다';

  @override
  String get noTemplatesYetSubtitle => '템플릿을 만들어 빠르게 운동을 시작하세요.';

  @override
  String failedToLoadTemplates(String error) {
    return '템플릿 로딩 실패: $error';
  }

  @override
  String get newTemplate => '새 템플릿';

  @override
  String get newTemplateTitle => '새 템플릿';

  @override
  String get templateNameLabel => '템플릿 이름';

  @override
  String get deleteTemplateTitle => '템플릿을 삭제하시겠습니까?';

  @override
  String deleteTemplateContent(String name) {
    return '\"$name\"을(를) 삭제하시겠습니까?';
  }

  @override
  String exerciseCount(int count) {
    return '$count개 운동';
  }

  @override
  String get editTemplate => '템플릿 편집';

  @override
  String get targetSets => '세트';

  @override
  String get targetReps => '횟수';

  @override
  String get addExerciseToTemplate => '운동 추가';

  @override
  String get saveTemplate => '저장';

  @override
  String get removeExercise => '운동 제거';

  @override
  String get reorderHint => '드래그하여 순서 변경';

  @override
  String get templateSaved => '템플릿이 저장되었습니다';

  @override
  String get prTypeWeight => '새 무게 기록!';

  @override
  String get prTypeReps => '새 횟수 기록!';

  @override
  String get prTypeVolume => '새 볼륨 기록!';

  @override
  String get prTypeE1rm => '새 e1RM 기록!';

  @override
  String get prHistoryTitle => '개인 기록';

  @override
  String get prHistoryEmpty => '아직 개인 기록이 없습니다';

  @override
  String get prHistoryEmptySubtitle => '운동에서 세트를 기록하여 새 기록을 세우세요.';

  @override
  String prAchievedOn(String date) {
    return '$date에 달성';
  }

  @override
  String prValueWeight(String value) {
    return '$value kg';
  }

  @override
  String prValueReps(String value) {
    return '$value회';
  }

  @override
  String prValueVolume(String value) {
    return '$value kg 볼륨';
  }

  @override
  String prValueE1rm(String value) {
    return '$value kg e1RM';
  }

  @override
  String get historyTab => '기록';

  @override
  String get progressTab => '진행';

  @override
  String get volumeTrendTitle => '볼륨 추세';

  @override
  String get frequencyTitle => '주간 운동 횟수';

  @override
  String get workoutsPerWeek => '회';

  @override
  String get startFromTemplate => '템플릿에서 시작';

  @override
  String get chooseTemplate => '템플릿 선택';

  @override
  String get noTemplatesAvailable => '사용 가능한 템플릿이 없습니다';

  @override
  String get muscleGroupDistributionTitle => '근육 그룹 분포';

  @override
  String get exerciseProgressListTitle => '운동 진행';

  @override
  String setsLogged(int count) {
    return '$count 세트 기록됨';
  }

  @override
  String get exportAsJson => 'JSON으로 내보내기';

  @override
  String get exportAsJsonSubtitle => '전체 운동 데이터를 JSON 형식으로';

  @override
  String get exportAsCsv => 'CSV로 내보내기';

  @override
  String get exportAsCsvSubtitle => '세트, 유산소, 개인 기록을 CSV 파일로';

  @override
  String get exportingData => '데이터 내보내기 중…';

  @override
  String get exportComplete => '내보내기 완료';

  @override
  String exportFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String get editSet => '세트 편집';

  @override
  String get editExerciseTitle => '운동 편집';

  @override
  String get calendarHeatmapTitle => '운동 캘린더';

  @override
  String get calendarHeatmapLess => '적음';

  @override
  String get calendarHeatmapMore => '많음';

  @override
  String currentStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 연속',
      one: '1일 연속',
      zero: '연속 기록 없음',
    );
    return '$_temp0';
  }

  @override
  String longestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '일',
      one: '일',
    );
    return '최장: $count $_temp0';
  }

  @override
  String get durationTrendTitle => '운동 시간 (분)';

  @override
  String get warmUpLabel => '워밍업';

  @override
  String get bodyMetricsTitle => '신체 측정';

  @override
  String get bodyMetricsSubtitle => '체중과 체성분 추적';

  @override
  String get noBodyMetricsYet => '아직 신체 측정 데이터가 없습니다';

  @override
  String get noBodyMetricsYetSubtitle => '+ 를 탭하여 첫 측정을 기록하세요.';

  @override
  String get addBodyMetric => '측정 추가';

  @override
  String get bodyWeightLabel => '체중';

  @override
  String get bodyFatPercentLabel => '체지방률 %';

  @override
  String get bodyFatLabel => '체지방';

  @override
  String get notesLabel => '메모';

  @override
  String get bodyWeightTrendTitle => '체중 추세';

  @override
  String get latestWeight => '최근 체중';

  @override
  String get bodyMetricsHistory => '기록';

  @override
  String get importFromJson => 'JSON에서 가져오기';

  @override
  String get importFromJsonSubtitle => '이전 내보내기에서 데이터 복원';

  @override
  String get importDataTitle => '데이터 가져오기';

  @override
  String get importDataConfirmContent =>
      'JSON 내보내기의 데이터를 기존 데이터에 추가합니다. 중복은 건너뜁니다.';

  @override
  String get importDataButton => '가져오기';

  @override
  String get importPasteJsonTitle => 'JSON 데이터 붙여넣기';

  @override
  String get importPasteJsonHint => '내보낸 JSON을 여기에 붙여넣으세요…';

  @override
  String importComplete(int workouts, int sets) {
    return '가져오기 완료: $workouts회 운동, $sets 세트';
  }

  @override
  String importFailed(String error) {
    return '가져오기 실패: $error';
  }

  @override
  String get duplicateTemplate => '복제';

  @override
  String get copyLabel => '복사';

  @override
  String get supersetLabel => '슈퍼세트';

  @override
  String get linkAsSuperset => '슈퍼세트로 연결';

  @override
  String get breakSuperset => '슈퍼세트 해제';

  @override
  String supersetWith(String name) {
    return '$name과(와) 슈퍼세트';
  }

  @override
  String get selectSupersetPartner => '연결할 운동 선택';

  @override
  String get noOtherExercises => '먼저 다른 운동을 추가하세요';

  @override
  String get sectionReminders => '알림';

  @override
  String get workoutReminders => '운동 알림';

  @override
  String get workoutRemindersSubtitle => '운동일에 알림 받기';

  @override
  String get reminderTime => '알림 시간';

  @override
  String get reminderTimeSubtitle => '운동 알림을 받을 시간';

  @override
  String get reminderDays => '운동일';

  @override
  String get streakReminder => '연속 기록 알림';

  @override
  String get streakReminderSubtitle => '오늘 아직 운동하지 않은 경우 알림';

  @override
  String get mondayShort => '월';

  @override
  String get tuesdayShort => '화';

  @override
  String get wednesdayShort => '수';

  @override
  String get thursdayShort => '목';

  @override
  String get fridayShort => '금';

  @override
  String get saturdayShort => '토';

  @override
  String get sundayShort => '일';

  @override
  String get notificationPermissionRequired => '알림에는 알림 권한이 필요합니다';

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
  String get analyticsTitle => '분석';

  @override
  String get weeklyVolumeTitle => '주간 볼륨 추세';

  @override
  String weeklyVolumeChange(String change) {
    return '전주 대비 $change%';
  }

  @override
  String get muscleBalanceTitle => '근육 그룹 밸런스';

  @override
  String get prTimelineTitle => '개인 기록 타임라인';

  @override
  String get trainingLoadTitle => '주간 트레이닝 부하';

  @override
  String get trainingLoadSubtitle => '세트 × 평균 RPE';

  @override
  String get noAnalyticsData => '데이터가 부족합니다';

  @override
  String get noAnalyticsDataSubtitle => '몇 번의 운동을 완료하면 분석이 표시됩니다.';

  @override
  String get volumeCategory => '카테고리별 볼륨';

  @override
  String loadScore(String score) {
    return '부하: $score';
  }

  @override
  String get viewAdvancedAnalytics => '상세 분석 보기';

  @override
  String get programmesTitle => '프로그램';

  @override
  String get noProgrammesYet => '아직 프로그램이 없습니다';

  @override
  String get noProgrammesYetSubtitle => '트레이닝 프로그램을 만들어 운동을 계획하세요.';

  @override
  String get newProgramme => '새 프로그램';

  @override
  String get newProgrammeTitle => '새 프로그램';

  @override
  String get programmeNameLabel => '프로그램 이름';

  @override
  String get durationWeeksLabel => '기간 (주)';

  @override
  String get editProgramme => '프로그램 편집';

  @override
  String get deleteProgrammeTitle => '프로그램을 삭제하시겠습니까?';

  @override
  String deleteProgrammeContent(String name) {
    return '\"$name\"을(를) 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get programmeDashboard => '대시보드';

  @override
  String currentWeek(int current, int total) {
    return '$current / $total 주차';
  }

  @override
  String get assignTemplate => '템플릿 할당';

  @override
  String get noTemplateAssigned => '휴식일';

  @override
  String get progressionRules => '점진 규칙';

  @override
  String get addRule => '규칙 추가';

  @override
  String get fixedIncrementLabel => '고정 증가';

  @override
  String get percentageLabel => '백분율';

  @override
  String get deloadLabel => '디로드';

  @override
  String get ruleValueLabel => '값';

  @override
  String everyNWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '주',
      one: '주',
    );
    return '$count $_temp0마다';
  }

  @override
  String get startFromProgramme => '프로그램에서 시작';

  @override
  String targetWeight(String weight) {
    return '목표: $weight kg';
  }

  @override
  String get programmeSaved => '프로그램이 저장되었습니다';

  @override
  String failedToLoadProgrammes(String error) {
    return '프로그램 로딩 실패: $error';
  }

  @override
  String programmeWeeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '주',
      one: '주',
    );
    return '$count $_temp0';
  }

  @override
  String programmeDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '일',
      one: '일',
    );
    return '$count $_temp0 할당됨';
  }

  @override
  String weekLabel(int number) {
    return '$number주차';
  }

  @override
  String dayLabel(String day) {
    return '$day';
  }

  @override
  String get chooseProgramme => '프로그램 선택';

  @override
  String get noProgrammesAvailable => '사용 가능한 프로그램이 없습니다';

  @override
  String get noWorkoutScheduledForToday => '오늘 예정된 운동이 없습니다';

  @override
  String get healthSyncTitle => '건강 동기화';

  @override
  String get healthSyncSubtitle => 'Apple Health 또는 Health Connect와 데이터 동기화';

  @override
  String get healthSyncEnabled => '건강 동기화 활성화';

  @override
  String get writeWorkoutsLabel => '운동 기록 쓰기';

  @override
  String get writeWorkoutsSubtitle => '완료된 운동을 건강 스토어에 기록';

  @override
  String get writeWeightLabel => '체중 쓰기';

  @override
  String get writeWeightSubtitle => '신체 측정 데이터를 건강 스토어에 전송';

  @override
  String get writeHeartRateLabel => '심박수 쓰기';

  @override
  String get writeHeartRateSubtitle => '유산소 운동 중 심박수 데이터 전송';

  @override
  String get readWeightLabel => '체중 읽기';

  @override
  String get readWeightSubtitle => '건강 스토어에서 체중 측정값 가져오기';

  @override
  String get healthSyncPermissionDenied => '건강 권한이 부여되지 않았습니다';

  @override
  String get healthSyncSuccess => '건강에 동기화되었습니다';

  @override
  String importWeightPrompt(String weight) {
    return '건강에서 $weight kg을 가져오시겠습니까?';
  }

  @override
  String get importWeightAction => '가져오기';

  @override
  String get healthSyncNoNewData => '건강에 새 데이터가 없습니다';

  @override
  String get syncSectionTitle => '기기 간 동기화';

  @override
  String get syncEnabled => '기기 간 동기화 활성화';

  @override
  String get syncEnabledSubtitle => '기기 간 운동 데이터 동기화';

  @override
  String syncLastSynced(String time) {
    return '마지막 동기화: $time';
  }

  @override
  String get syncNeverSynced => '동기화한 적 없음';

  @override
  String get syncNow => '지금 동기화';

  @override
  String get syncSyncing => '동기화 중…';

  @override
  String get syncSuccess => '동기화 완료';

  @override
  String syncError(String error) {
    return '동기화 실패: $error';
  }

  @override
  String get syncDisableAndDelete => '동기화 비활성화 및 클라우드 데이터 삭제';

  @override
  String get syncDisableConfirmTitle => '동기화를 비활성화하시겠습니까?';

  @override
  String get syncDisableConfirmBody =>
      '동기화를 비활성화하고 클라우드 스토리지의 데이터를 영구 삭제합니다. 로컬 데이터는 영향을 받지 않습니다.';

  @override
  String get syncDisableConfirmAction => '비활성화 및 삭제';

  @override
  String get syncConsentTitle => '기기 간 동기화';

  @override
  String get syncConsentBody =>
      '운동 데이터가 본인의 Google Drive 또는 iCloud 계정에 저장됩니다. RepFoundry는 이 데이터에 접근할 수 없습니다. 설정이나 클라우드 계정에서 언제든지 삭제할 수 있습니다.';

  @override
  String get syncConsentCancel => '취소';

  @override
  String get syncConsentAccept => '이해했습니다 — 계속';

  @override
  String get trainingHistoryTitle => '트레이닝 기록';

  @override
  String get trainingHistorySubtitle => '진화와 기계적 장력 증가를 추적하세요.';

  @override
  String get searchSessionsHint => '세션 또는 운동 검색…';

  @override
  String get thisWeek => '이번 주';

  @override
  String get lastWeek => '지난 주';

  @override
  String get volumeProgress => '볼륨 진행';

  @override
  String totalVolumeKg(String value) {
    return '$value kg';
  }

  @override
  String get workoutFallbackName => '운동';

  @override
  String get liveSensor => '라이브 센서';

  @override
  String get restingHrLabel => '안정 시 심박수';

  @override
  String get maxHrLabel => '최대 심박수';

  @override
  String get recoveryLabel => '회복';

  @override
  String get hrvLabel => '심박변이도';

  @override
  String get excellent => '우수';

  @override
  String get reachedAgo => '세션 최대';

  @override
  String get toBaseline => '기준선으로';

  @override
  String get highReadiness => '높은 준비도';

  @override
  String get workoutIntensityZones => '운동 강도 구간';

  @override
  String sessionDuration(String duration) {
    return '세션: $duration';
  }

  @override
  String get zonePeak => '피크';

  @override
  String get zoneAnaerobic => '무산소';

  @override
  String get zoneAerobic => '유산소';

  @override
  String get zoneFatBurn => '지방 연소';

  @override
  String get zoneWarmup => '워밍업';

  @override
  String get heartRateTrend => '심박수 추세';

  @override
  String get heartRateTrendSubtitle => '현재 운동 세션';

  @override
  String get todayLabel => '오늘';

  @override
  String get avgLabel => '평균';

  @override
  String get activeDuration => '활동 시간';

  @override
  String get avgPaceLabel => '평균 페이스';

  @override
  String get distanceLabel => '거리';

  @override
  String get startSession => '세션 시작';

  @override
  String get liveTracking => '실시간 추적';
}
