// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'RepFoundry';

  @override
  String get navWorkout => '训练';

  @override
  String get navHistory => '历史';

  @override
  String get navCardio => '有氧';

  @override
  String get navHeartRate => '心率';

  @override
  String get navSettings => '设置';

  @override
  String get start => '开始';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get reset => '重置';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get create => '创建';

  @override
  String get finish => '完成';

  @override
  String get next => '下一步';

  @override
  String get back => '返回';

  @override
  String get skip => '跳过';

  @override
  String get done => '完成';

  @override
  String get retry => '重试';

  @override
  String get bpmSuffix => '次/分';

  @override
  String get yearsSuffix => '岁';

  @override
  String get kgUnit => '千克';

  @override
  String get lbsUnit => '磅';

  @override
  String get settingsTitle => '设置';

  @override
  String get sectionHealthProfile => '健康资料';

  @override
  String get sectionAppearance => '外观';

  @override
  String get sectionUnits => '单位';

  @override
  String get sectionRestTimer => '休息计时器';

  @override
  String get sectionData => '数据';

  @override
  String get sectionAbout => '关于';

  @override
  String get ageLabel => '年龄';

  @override
  String ageSubtitleSet(int age, int maxHr) {
    return '$age 岁（最大心率：$maxHr 次/分）';
  }

  @override
  String get ageSubtitleEmpty => '设置你的年龄以计算心率区间';

  @override
  String get setYourAge => '设置年龄';

  @override
  String get ageHint => '例如：30';

  @override
  String get restingHeartRate => '静息心率';

  @override
  String restingHrSubtitleSet(int bpm) {
    return '$bpm 次/分';
  }

  @override
  String get restingHrSubtitleEmpty => '可选——启用 Karvonen 区间';

  @override
  String get restingHrHint => '例如：60';

  @override
  String get measuredMaxHeartRate => '实测最大心率';

  @override
  String measuredMaxHrSubtitleSet(int bpm) {
    return '$bpm 次/分';
  }

  @override
  String get measuredMaxHrSubtitleEmpty => '可选——来自运动测试';

  @override
  String get measuredMaxHrHint => '例如：185';

  @override
  String get betaBlockerMedication => 'β受体阻滞剂用药';

  @override
  String get betaBlockerSubtitle => '会影响心率区间计算准确性';

  @override
  String get heartConditionLabel => '心脏疾病';

  @override
  String get heartConditionSubtitle => '为区间启用谨慎模式';

  @override
  String get clinicianMaxHeartRate => '医生建议最大心率';

  @override
  String clinicianMaxHrSubtitleSet(int bpm) {
    return '$bpm 次/分——覆盖估算值';
  }

  @override
  String get clinicianMaxHrSubtitleEmpty => '可选——由医生提供';

  @override
  String get clinicianMaxHrHint => '例如：150';

  @override
  String get zoneMethod => '区间计算方式';

  @override
  String zoneMethodAndReliability(String method, String reliability) {
    return '$method · 置信度$reliability';
  }

  @override
  String get zoneMethodCustom => '自定义区间';

  @override
  String get zoneMethodClinicianCap => '医生上限';

  @override
  String get zoneMethodHrr => '心率储备法（Karvonen）';

  @override
  String get zoneMethodMeasuredMax => '实测最大心率';

  @override
  String get zoneMethodEstimatedMax => '按年龄估算最大心率';

  @override
  String get reliabilityHigh => '高';

  @override
  String get reliabilityMedium => '中';

  @override
  String get reliabilityLow => '低';

  @override
  String get setUpHeartRateZones => '设置心率区间';

  @override
  String get stepByStepGuidedSetup => '分步引导设置';

  @override
  String get zoneColourBands => '区间颜色带';

  @override
  String get zoneColourBandsSubtitle => '在心率图表上显示彩色区间带';

  @override
  String get sectionMaxHrAlert => '最大心率提醒';

  @override
  String get maxHrAlertVibration => '达到最大心率时震动';

  @override
  String get maxHrAlertVibrationSubtitle => '当心率达到建议最大值时震动提醒';

  @override
  String get maxHrAlertSound => '达到最大心率时声音提醒';

  @override
  String get maxHrAlertSoundSubtitle => '当心率达到建议最大值时播放警告音';

  @override
  String get maxHrAlertCooldown => '提醒冷却时间';

  @override
  String get maxHrAlertCooldownSubtitle => '重复提醒之间的最短秒数';

  @override
  String maxHrAlertCooldownValue(int seconds) {
    return '$seconds秒';
  }

  @override
  String get maxHrReached => '心率已达到或超过建议最大值';

  @override
  String get disclaimerLabel => '免责声明';

  @override
  String get themeLabel => '主题';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeAuto => '自动';

  @override
  String get weightUnitLabel => '体重单位';

  @override
  String get vibrationAlert => '震动提醒';

  @override
  String get vibrationAlertSubtitle => '休息计时结束时震动';

  @override
  String get soundAlert => '声音提醒';

  @override
  String get soundAlertSubtitle => '休息计时结束时播放声音';

  @override
  String get clearAllData => '清除所有数据';

  @override
  String get clearAllDataSubtitle => '永久删除所有训练和设置。';

  @override
  String get clearAllDataConfirmTitle => '清除所有数据？';

  @override
  String get clearAllDataConfirmContent => '这将永久删除你所有的训练历史，且无法撤销。';

  @override
  String get allDataCleared => '所有数据已清除。';

  @override
  String get aboutAppName => 'RepFoundry';

  @override
  String get aboutVersion => '版本 1.0.0';

  @override
  String get heartRateTitle => '心率';

  @override
  String get connectHrMonitor => '连接心率监测器';

  @override
  String get disconnect => '断开连接';

  @override
  String get setupGuide => '设置指南';

  @override
  String get reconnecting => '正在重新连接...';

  @override
  String get recentChart => '最近';

  @override
  String get fullSessionChart => '完整训练';

  @override
  String get setAgeInSettings => '请在设置中填写年龄';

  @override
  String get setAgeInSettingsSubtitle => '配置年龄后，将显示心率训练区间。';

  @override
  String get statsAvg => '平均';

  @override
  String get statsMin => '最低';

  @override
  String get statsMax => '最高';

  @override
  String get statsReadings => '读数';

  @override
  String get timeInZone => '区间停留时间';

  @override
  String moderateOrHigher(String duration) {
    return '中等或以上强度：$duration';
  }

  @override
  String recoveryHrDrop(int bpm) {
    return '恢复心率下降：$bpm 次/分';
  }

  @override
  String get bluetoothNotAvailable => '蓝牙不可用。请确认蓝牙已开启。';

  @override
  String chartWindowSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String chartWindowMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get onboardingTitle => '设置心率区间';

  @override
  String onboardingStepOf(int current, int total) {
    return '第 $current / $total 步';
  }

  @override
  String get onboardingAgeExplanation => '你的年龄将用于估算最大心率并个性化训练区间。';

  @override
  String get onboardingRestingHrExplanation =>
      '提供静息心率后，可使用 Karvonen（心率储备）方法更准确地计算区间。';

  @override
  String get onboardingRestingHrLabel => '静息心率（可选）';

  @override
  String get onboardingMeasuredMaxHrLabel => '实测最大心率（可选）';

  @override
  String get onboardingRestingHrHint => '例如：60';

  @override
  String get onboardingMeasuredMaxHrHint => '例如：185';

  @override
  String get onboardingMedicalExplanation =>
      '如果以下任一情况适用于你，心率区间将以谨慎模式显示，并降低置信度。建议咨询医疗专业人士以获得个性化上限。';

  @override
  String get onboardingBetaBlockerLabel => '正在服用 β受体阻滞剂';

  @override
  String get onboardingHeartConditionLabel => '心脏疾病';

  @override
  String get onboardingClinicianWithFlags =>
      '由于你存在医疗相关因素，我们强烈建议输入医生提供的最大心率。该值将覆盖所有其他估算。';

  @override
  String get onboardingClinicianWithoutFlags =>
      '如果医生或运动生理师给了你最大心率，请在此输入以覆盖估算值。';

  @override
  String get onboardingClinicianMaxHrLabel => '医生建议最大心率（可选）';

  @override
  String get disclaimerDialogTitle => '心率监测';

  @override
  String get disclaimerDialogButton => '我已了解';

  @override
  String get cautionModeTitle => '谨慎模式';

  @override
  String get symptomReportButton => '报告症状';

  @override
  String get symptomReportTitle => '症状报告';

  @override
  String get stopExerciseTitle => '停止运动';

  @override
  String get stopExerciseOk => '我没事，正在停止运动';

  @override
  String get stopExerciseHelp => '我需要帮助';

  @override
  String get warningGeneralDisclaimer =>
      '心率区间估算仅供参考，不构成医疗建议。开始或调整运动计划前，请务必咨询医疗专业人士，尤其是在你已有既往疾病的情况下。';

  @override
  String get warningBetaBlocker =>
      'β受体阻滞剂可能会显著降低你的最大心率。标准区间计算可能不准确。建议设置医生提供的最大心率，或使用主观用力感（RPE）和谈话测试来判断强度。';

  @override
  String get warningHeartCondition =>
      '你已标明存在心脏疾病。标准心率区间计算可能并不适合你。强烈建议在使用基于强度的训练指导前，先获取医生提供的最大心率。';

  @override
  String get warningClinicianCap => '当前心率区间基于医生提供的最大心率计算。该值会覆盖基于年龄或实测的估算值。';

  @override
  String get warningStopExercise =>
      '如果你正在经历胸痛、严重头晕、昏厥，或异常呼吸困难，请立即停止运动。如症状持续，请尽快就医。';

  @override
  String get warningSymptomIntro => '你是否正在经历以下任一症状？';

  @override
  String get symptomChestPain => '胸痛或胸闷';

  @override
  String get symptomDizziness => '严重头晕或头昏';

  @override
  String get symptomFainting => '感觉快要昏倒或即将昏倒';

  @override
  String get symptomBreathing => '异常呼吸困难';

  @override
  String get clinicianLimitsInUse => '当前使用医生提供的限制';

  @override
  String get workoutTitle => '训练';

  @override
  String workoutTitleWithTime(String time) {
    return '训练  •  $time';
  }

  @override
  String get loadingWorkout => '正在加载训练…';

  @override
  String get addExercise => '添加动作';

  @override
  String get startWorkout => '开始训练';

  @override
  String get noActiveWorkout => '当前没有进行中的训练';

  @override
  String get noActiveWorkoutSubtitle => '开始新的训练以记录组数。';

  @override
  String get addExercisesHint => '使用下方按钮添加动作';

  @override
  String get finishWorkoutTitle => '完成训练？';

  @override
  String get finishWorkoutContent => '这将保存训练并结束本次会话。';

  @override
  String get tableHeaderHash => '#';

  @override
  String get tableHeaderWeight => '重量';

  @override
  String get tableHeaderReps => '次数';

  @override
  String get tableHeaderE1rm => '估算1RM';

  @override
  String get weightKgLabel => '重量（kg）';

  @override
  String get repsLabel => '次数';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get addRpe => '添加 RPE';

  @override
  String get hideRpe => '隐藏 RPE';

  @override
  String get logSet => '记录一组';

  @override
  String get validationRequired => '必填';

  @override
  String get validationInvalid => '无效';

  @override
  String get validationMinZero => '≥ 0';

  @override
  String get validationRpeRange => '1–10';

  @override
  String get restTimer => '休息计时器';

  @override
  String get stopTimer => '停止计时';

  @override
  String get newPersonalRecord => '新的个人纪录！';

  @override
  String e1rmValue(String value) {
    return '估算1RM：$value kg';
  }

  @override
  String get historyTitle => '历史';

  @override
  String get noWorkoutsYet => '还没有训练记录';

  @override
  String get noWorkoutsYetSubtitle => '已完成的训练会显示在这里。';

  @override
  String get loadingHistory => '正在加载历史…';

  @override
  String errorPrefix(String error) {
    return '错误：$error';
  }

  @override
  String volumeTrend(int count) {
    return '训练量趋势（最近 $count 次训练）';
  }

  @override
  String setsCount(int count) {
    return '$count 组';
  }

  @override
  String get prBadge => 'PR!';

  @override
  String get workoutDetailTitle => '训练详情';

  @override
  String get workoutNotFound => '未找到训练';

  @override
  String get durationLabel => '时长';

  @override
  String get setsLabel => '组数';

  @override
  String get volumeLabel => '训练量';

  @override
  String get exerciseProgressTitle => '动作进展';

  @override
  String get noDataYet => '暂无数据';

  @override
  String get noDataYetSubtitle => '记录该动作的组数后即可查看进展。';

  @override
  String get loadingProgress => '正在加载进展…';

  @override
  String get bestE1rm => '最佳估算1RM';

  @override
  String get totalVolume => '总训练量';

  @override
  String get totalSets => '总组数';

  @override
  String get e1rmTrend => '估算 1RM 趋势';

  @override
  String get recentSets => '最近组数';

  @override
  String get tableHeaderDate => '日期';

  @override
  String get chooseExercise => '选择动作';

  @override
  String get searchExercisesHint => '搜索动作…';

  @override
  String get filterAll => '全部';

  @override
  String get noExercisesFound => '未找到动作';

  @override
  String get loadingExercises => '正在加载动作…';

  @override
  String get customExercise => '自定义';

  @override
  String get newExerciseTitle => '新建动作';

  @override
  String get exerciseNameLabel => '动作名称';

  @override
  String get categoryLabel => '分类';

  @override
  String get muscleGroupLabel => '肌群';

  @override
  String get equipmentLabel => '器械';

  @override
  String get exerciseNameRequired => '请输入动作名称';

  @override
  String get cardioTitle => '有氧';

  @override
  String get exerciseField => '运动项目';

  @override
  String get distanceMetresLabel => '距离（米）';

  @override
  String get inclineLabel => '坡度（%）';

  @override
  String get avgHeartRateLabel => '平均心率（次/分）';

  @override
  String get lastSession => '上次训练';

  @override
  String get gpsDistanceTracking => 'GPS 距离追踪';

  @override
  String get gpsAcquiring => '正在获取信号...';

  @override
  String gpsMetresTracked(String metres) {
    return '已追踪 $metres 米';
  }

  @override
  String get gpsSubtitle => '通过 GPS 追踪户外跑步距离';

  @override
  String get saveSession => '保存会话';

  @override
  String get cardioSessionSaved => '有氧训练已保存';

  @override
  String get heartRateMonitorCard => '心率监测器';

  @override
  String get heartRateMonitorSubtitle => '连接 BLE 心率带或手表';

  @override
  String get connect => '连接';

  @override
  String connectingTo(String device) {
    return '正在连接到 $device...';
  }

  @override
  String reconnectingTo(String device) {
    return '正在重新连接到 $device...';
  }

  @override
  String paceLabel(String pace) {
    return '配速：$pace';
  }

  @override
  String get hrSetupGuideTitle => '心率设置指南';

  @override
  String get appleWatchTitle => 'Apple Watch';

  @override
  String get samsungWatchTitle => 'Samsung Galaxy Watch';

  @override
  String get chestStrapsTitle => '胸带与臂带';

  @override
  String get appleWatchStep1 => '在 Apple Watch 上，打开“设置”→“锻炼”→“心率”。';

  @override
  String get appleWatchStep2 => '启用“广播心率”。';

  @override
  String get appleWatchStep3 => '在 Apple Watch 上开始任意一次锻炼。';

  @override
  String get appleWatchStep4 => '在 RepFoundry 中点击“连接”，然后选择你的 Apple Watch。';

  @override
  String get samsungWatchStep1 => '在手表上打开 Samsung Health。';

  @override
  String get samsungWatchStep2 => '前往“设置”→“心率广播”。';

  @override
  String get samsungWatchStep3 => '启用 BLE 广播。';

  @override
  String get samsungWatchStep4 => '在 RepFoundry 中点击“连接”，然后选择你的 Galaxy Watch。';

  @override
  String get chestStrapStep1 => '任何 BLE 心率设备（Polar、Garmin、Wahoo 等）都可自动使用。';

  @override
  String get chestStrapStep2 => '只需佩戴胸带或臂带，然后点击“连接”。';

  @override
  String get chestStrapStep3 => '你的设备会显示在扫描列表中。';

  @override
  String get hrDevicePickerTitle => '心率监测设备';

  @override
  String get scanning => '正在扫描设备...';

  @override
  String get noDevicesFound =>
      '未找到心率监测设备。请确认设备正在广播——对于 Apple Watch，请在启用“广播心率”后开始一次锻炼。';

  @override
  String get scanAgain => '重新扫描';

  @override
  String get setupHelp => '设置帮助';

  @override
  String get templatesTitle => '模板';

  @override
  String get noTemplatesYet => '还没有模板';

  @override
  String get noTemplatesYetSubtitle => '创建模板以快速开始训练。';

  @override
  String failedToLoadTemplates(String error) {
    return '加载模板失败：$error';
  }

  @override
  String get newTemplate => '新建模板';

  @override
  String get newTemplateTitle => '新建模板';

  @override
  String get templateNameLabel => '模板名称';

  @override
  String get deleteTemplateTitle => '删除模板？';

  @override
  String deleteTemplateContent(String name) {
    return '你确定要删除“$name”吗？';
  }

  @override
  String exerciseCount(int count) {
    return '$count 个动作';
  }

  @override
  String get editTemplate => '编辑模板';

  @override
  String get targetSets => '组数';

  @override
  String get targetReps => '次数';

  @override
  String get addExerciseToTemplate => '添加动作';

  @override
  String get saveTemplate => '保存';

  @override
  String get removeExercise => '移除动作';

  @override
  String get reorderHint => '拖动以重新排序动作';

  @override
  String get templateSaved => '模板已保存';

  @override
  String get prTypeWeight => '新重量纪录！';

  @override
  String get prTypeReps => '新次数纪录！';

  @override
  String get prTypeVolume => '新容量纪录！';

  @override
  String get prTypeE1rm => '新e1RM纪录！';

  @override
  String get prHistoryTitle => '个人纪录';

  @override
  String get prHistoryEmpty => '暂无个人纪录';

  @override
  String get prHistoryEmptySubtitle => '在训练中记录组数来创建新纪录。';

  @override
  String prAchievedOn(String date) {
    return '达成于 $date';
  }

  @override
  String prValueWeight(String value) {
    return '$value kg';
  }

  @override
  String prValueReps(String value) {
    return '$value 次';
  }

  @override
  String prValueVolume(String value) {
    return '$value kg 容量';
  }

  @override
  String prValueE1rm(String value) {
    return '$value kg e1RM';
  }

  @override
  String get historyTab => '历史';

  @override
  String get progressTab => '进度';

  @override
  String get volumeTrendTitle => '训练量趋势';

  @override
  String get frequencyTitle => '每周训练次数';

  @override
  String get workoutsPerWeek => '次训练';

  @override
  String get startFromTemplate => '从模板开始';

  @override
  String get chooseTemplate => '选择模板';

  @override
  String get noTemplatesAvailable => '暂无可用模板';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class SZhHans extends SZh {
  SZhHans() : super('zh_Hans');

  @override
  String get appTitle => 'RepFoundry';

  @override
  String get navWorkout => '训练';

  @override
  String get navHistory => '历史';

  @override
  String get navCardio => '有氧';

  @override
  String get navHeartRate => '心率';

  @override
  String get navSettings => '设置';

  @override
  String get start => '开始';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get reset => '重置';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get create => '创建';

  @override
  String get finish => '完成';

  @override
  String get next => '下一步';

  @override
  String get back => '返回';

  @override
  String get skip => '跳过';

  @override
  String get done => '完成';

  @override
  String get retry => '重试';

  @override
  String get bpmSuffix => '次/分';

  @override
  String get yearsSuffix => '岁';

  @override
  String get kgUnit => '千克';

  @override
  String get lbsUnit => '磅';

  @override
  String get settingsTitle => '设置';

  @override
  String get sectionHealthProfile => '健康资料';

  @override
  String get sectionAppearance => '外观';

  @override
  String get sectionUnits => '单位';

  @override
  String get sectionRestTimer => '休息计时器';

  @override
  String get sectionData => '数据';

  @override
  String get sectionAbout => '关于';

  @override
  String get ageLabel => '年龄';

  @override
  String ageSubtitleSet(int age, int maxHr) {
    return '$age 岁（最大心率：$maxHr 次/分）';
  }

  @override
  String get ageSubtitleEmpty => '设置你的年龄以计算心率区间';

  @override
  String get setYourAge => '设置年龄';

  @override
  String get ageHint => '例如：30';

  @override
  String get restingHeartRate => '静息心率';

  @override
  String restingHrSubtitleSet(int bpm) {
    return '$bpm 次/分';
  }

  @override
  String get restingHrSubtitleEmpty => '可选——启用 Karvonen 区间';

  @override
  String get restingHrHint => '例如：60';

  @override
  String get measuredMaxHeartRate => '实测最大心率';

  @override
  String measuredMaxHrSubtitleSet(int bpm) {
    return '$bpm 次/分';
  }

  @override
  String get measuredMaxHrSubtitleEmpty => '可选——来自运动测试';

  @override
  String get measuredMaxHrHint => '例如：185';

  @override
  String get betaBlockerMedication => 'β受体阻滞剂用药';

  @override
  String get betaBlockerSubtitle => '会影响心率区间计算准确性';

  @override
  String get heartConditionLabel => '心脏疾病';

  @override
  String get heartConditionSubtitle => '为区间启用谨慎模式';

  @override
  String get clinicianMaxHeartRate => '医生建议最大心率';

  @override
  String clinicianMaxHrSubtitleSet(int bpm) {
    return '$bpm 次/分——覆盖估算值';
  }

  @override
  String get clinicianMaxHrSubtitleEmpty => '可选——由医生提供';

  @override
  String get clinicianMaxHrHint => '例如：150';

  @override
  String get zoneMethod => '区间计算方式';

  @override
  String zoneMethodAndReliability(String method, String reliability) {
    return '$method · 置信度$reliability';
  }

  @override
  String get zoneMethodCustom => '自定义区间';

  @override
  String get zoneMethodClinicianCap => '医生上限';

  @override
  String get zoneMethodHrr => '心率储备法（Karvonen）';

  @override
  String get zoneMethodMeasuredMax => '实测最大心率';

  @override
  String get zoneMethodEstimatedMax => '按年龄估算最大心率';

  @override
  String get reliabilityHigh => '高';

  @override
  String get reliabilityMedium => '中';

  @override
  String get reliabilityLow => '低';

  @override
  String get setUpHeartRateZones => '设置心率区间';

  @override
  String get stepByStepGuidedSetup => '分步引导设置';

  @override
  String get zoneColourBands => '区间颜色带';

  @override
  String get zoneColourBandsSubtitle => '在心率图表上显示彩色区间带';

  @override
  String get sectionMaxHrAlert => '最大心率提醒';

  @override
  String get maxHrAlertVibration => '达到最大心率时震动';

  @override
  String get maxHrAlertVibrationSubtitle => '当心率达到建议最大值时震动提醒';

  @override
  String get maxHrAlertSound => '达到最大心率时声音提醒';

  @override
  String get maxHrAlertSoundSubtitle => '当心率达到建议最大值时播放警告音';

  @override
  String get maxHrAlertCooldown => '提醒冷却时间';

  @override
  String get maxHrAlertCooldownSubtitle => '重复提醒之间的最短秒数';

  @override
  String maxHrAlertCooldownValue(int seconds) {
    return '$seconds秒';
  }

  @override
  String get maxHrReached => '心率已达到或超过建议最大值';

  @override
  String get disclaimerLabel => '免责声明';

  @override
  String get themeLabel => '主题';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeAuto => '自动';

  @override
  String get weightUnitLabel => '体重单位';

  @override
  String get vibrationAlert => '震动提醒';

  @override
  String get vibrationAlertSubtitle => '休息计时结束时震动';

  @override
  String get soundAlert => '声音提醒';

  @override
  String get soundAlertSubtitle => '休息计时结束时播放声音';

  @override
  String get clearAllData => '清除所有数据';

  @override
  String get clearAllDataSubtitle => '永久删除所有训练和设置。';

  @override
  String get clearAllDataConfirmTitle => '清除所有数据？';

  @override
  String get clearAllDataConfirmContent => '这将永久删除你所有的训练历史，且无法撤销。';

  @override
  String get allDataCleared => '所有数据已清除。';

  @override
  String get aboutAppName => 'RepFoundry';

  @override
  String get aboutVersion => '版本 1.0.0';

  @override
  String get heartRateTitle => '心率';

  @override
  String get connectHrMonitor => '连接心率监测器';

  @override
  String get disconnect => '断开连接';

  @override
  String get setupGuide => '设置指南';

  @override
  String get reconnecting => '正在重新连接...';

  @override
  String get recentChart => '最近';

  @override
  String get fullSessionChart => '完整训练';

  @override
  String get setAgeInSettings => '请在设置中填写年龄';

  @override
  String get setAgeInSettingsSubtitle => '配置年龄后，将显示心率训练区间。';

  @override
  String get statsAvg => '平均';

  @override
  String get statsMin => '最低';

  @override
  String get statsMax => '最高';

  @override
  String get statsReadings => '读数';

  @override
  String get timeInZone => '区间停留时间';

  @override
  String moderateOrHigher(String duration) {
    return '中等或以上强度：$duration';
  }

  @override
  String recoveryHrDrop(int bpm) {
    return '恢复心率下降：$bpm 次/分';
  }

  @override
  String get bluetoothNotAvailable => '蓝牙不可用。请确认蓝牙已开启。';

  @override
  String chartWindowSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String chartWindowMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get onboardingTitle => '设置心率区间';

  @override
  String onboardingStepOf(int current, int total) {
    return '第 $current / $total 步';
  }

  @override
  String get onboardingAgeExplanation => '你的年龄将用于估算最大心率并个性化训练区间。';

  @override
  String get onboardingRestingHrExplanation =>
      '提供静息心率后，可使用 Karvonen（心率储备）方法更准确地计算区间。';

  @override
  String get onboardingRestingHrLabel => '静息心率（可选）';

  @override
  String get onboardingMeasuredMaxHrLabel => '实测最大心率（可选）';

  @override
  String get onboardingRestingHrHint => '例如：60';

  @override
  String get onboardingMeasuredMaxHrHint => '例如：185';

  @override
  String get onboardingMedicalExplanation =>
      '如果以下任一情况适用于你，心率区间将以谨慎模式显示，并降低置信度。建议咨询医疗专业人士以获得个性化上限。';

  @override
  String get onboardingBetaBlockerLabel => '正在服用 β受体阻滞剂';

  @override
  String get onboardingHeartConditionLabel => '心脏疾病';

  @override
  String get onboardingClinicianWithFlags =>
      '由于你存在医疗相关因素，我们强烈建议输入医生提供的最大心率。该值将覆盖所有其他估算。';

  @override
  String get onboardingClinicianWithoutFlags =>
      '如果医生或运动生理师给了你最大心率，请在此输入以覆盖估算值。';

  @override
  String get onboardingClinicianMaxHrLabel => '医生建议最大心率（可选）';

  @override
  String get disclaimerDialogTitle => '心率监测';

  @override
  String get disclaimerDialogButton => '我已了解';

  @override
  String get cautionModeTitle => '谨慎模式';

  @override
  String get symptomReportButton => '报告症状';

  @override
  String get symptomReportTitle => '症状报告';

  @override
  String get stopExerciseTitle => '停止运动';

  @override
  String get stopExerciseOk => '我没事，正在停止运动';

  @override
  String get stopExerciseHelp => '我需要帮助';

  @override
  String get warningGeneralDisclaimer =>
      '心率区间估算仅供参考，不构成医疗建议。开始或调整运动计划前，请务必咨询医疗专业人士，尤其是在你已有既往疾病的情况下。';

  @override
  String get warningBetaBlocker =>
      'β受体阻滞剂可能会显著降低你的最大心率。标准区间计算可能不准确。建议设置医生提供的最大心率，或使用主观用力感（RPE）和谈话测试来判断强度。';

  @override
  String get warningHeartCondition =>
      '你已标明存在心脏疾病。标准心率区间计算可能并不适合你。强烈建议在使用基于强度的训练指导前，先获取医生提供的最大心率。';

  @override
  String get warningClinicianCap => '当前心率区间基于医生提供的最大心率计算。该值会覆盖基于年龄或实测的估算值。';

  @override
  String get warningStopExercise =>
      '如果你正在经历胸痛、严重头晕、昏厥，或异常呼吸困难，请立即停止运动。如症状持续，请尽快就医。';

  @override
  String get warningSymptomIntro => '你是否正在经历以下任一症状？';

  @override
  String get symptomChestPain => '胸痛或胸闷';

  @override
  String get symptomDizziness => '严重头晕或头昏';

  @override
  String get symptomFainting => '感觉快要昏倒或即将昏倒';

  @override
  String get symptomBreathing => '异常呼吸困难';

  @override
  String get clinicianLimitsInUse => '当前使用医生提供的限制';

  @override
  String get workoutTitle => '训练';

  @override
  String workoutTitleWithTime(String time) {
    return '训练  •  $time';
  }

  @override
  String get loadingWorkout => '正在加载训练…';

  @override
  String get addExercise => '添加动作';

  @override
  String get startWorkout => '开始训练';

  @override
  String get noActiveWorkout => '当前没有进行中的训练';

  @override
  String get noActiveWorkoutSubtitle => '开始新的训练以记录组数。';

  @override
  String get addExercisesHint => '使用下方按钮添加动作';

  @override
  String get finishWorkoutTitle => '完成训练？';

  @override
  String get finishWorkoutContent => '这将保存训练并结束本次会话。';

  @override
  String get tableHeaderHash => '#';

  @override
  String get tableHeaderWeight => '重量';

  @override
  String get tableHeaderReps => '次数';

  @override
  String get tableHeaderE1rm => '估算1RM';

  @override
  String get weightKgLabel => '重量（kg）';

  @override
  String get repsLabel => '次数';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get addRpe => '添加 RPE';

  @override
  String get hideRpe => '隐藏 RPE';

  @override
  String get logSet => '记录一组';

  @override
  String get validationRequired => '必填';

  @override
  String get validationInvalid => '无效';

  @override
  String get validationMinZero => '≥ 0';

  @override
  String get validationRpeRange => '1–10';

  @override
  String get restTimer => '休息计时器';

  @override
  String get stopTimer => '停止计时';

  @override
  String get newPersonalRecord => '新的个人纪录！';

  @override
  String e1rmValue(String value) {
    return '估算1RM：$value kg';
  }

  @override
  String get historyTitle => '历史';

  @override
  String get noWorkoutsYet => '还没有训练记录';

  @override
  String get noWorkoutsYetSubtitle => '已完成的训练会显示在这里。';

  @override
  String get loadingHistory => '正在加载历史…';

  @override
  String errorPrefix(String error) {
    return '错误：$error';
  }

  @override
  String volumeTrend(int count) {
    return '训练量趋势（最近 $count 次训练）';
  }

  @override
  String setsCount(int count) {
    return '$count 组';
  }

  @override
  String get prBadge => 'PR!';

  @override
  String get workoutDetailTitle => '训练详情';

  @override
  String get workoutNotFound => '未找到训练';

  @override
  String get durationLabel => '时长';

  @override
  String get setsLabel => '组数';

  @override
  String get volumeLabel => '训练量';

  @override
  String get exerciseProgressTitle => '动作进展';

  @override
  String get noDataYet => '暂无数据';

  @override
  String get noDataYetSubtitle => '记录该动作的组数后即可查看进展。';

  @override
  String get loadingProgress => '正在加载进展…';

  @override
  String get bestE1rm => '最佳估算1RM';

  @override
  String get totalVolume => '总训练量';

  @override
  String get totalSets => '总组数';

  @override
  String get e1rmTrend => '估算 1RM 趋势';

  @override
  String get recentSets => '最近组数';

  @override
  String get tableHeaderDate => '日期';

  @override
  String get chooseExercise => '选择动作';

  @override
  String get searchExercisesHint => '搜索动作…';

  @override
  String get filterAll => '全部';

  @override
  String get noExercisesFound => '未找到动作';

  @override
  String get loadingExercises => '正在加载动作…';

  @override
  String get customExercise => '自定义';

  @override
  String get newExerciseTitle => '新建动作';

  @override
  String get exerciseNameLabel => '动作名称';

  @override
  String get categoryLabel => '分类';

  @override
  String get muscleGroupLabel => '肌群';

  @override
  String get equipmentLabel => '器械';

  @override
  String get exerciseNameRequired => '请输入动作名称';

  @override
  String get cardioTitle => '有氧';

  @override
  String get exerciseField => '运动项目';

  @override
  String get distanceMetresLabel => '距离（米）';

  @override
  String get inclineLabel => '坡度（%）';

  @override
  String get avgHeartRateLabel => '平均心率（次/分）';

  @override
  String get lastSession => '上次训练';

  @override
  String get gpsDistanceTracking => 'GPS 距离追踪';

  @override
  String get gpsAcquiring => '正在获取信号...';

  @override
  String gpsMetresTracked(String metres) {
    return '已追踪 $metres 米';
  }

  @override
  String get gpsSubtitle => '通过 GPS 追踪户外跑步距离';

  @override
  String get saveSession => '保存会话';

  @override
  String get cardioSessionSaved => '有氧训练已保存';

  @override
  String get heartRateMonitorCard => '心率监测器';

  @override
  String get heartRateMonitorSubtitle => '连接 BLE 心率带或手表';

  @override
  String get connect => '连接';

  @override
  String connectingTo(String device) {
    return '正在连接到 $device...';
  }

  @override
  String reconnectingTo(String device) {
    return '正在重新连接到 $device...';
  }

  @override
  String paceLabel(String pace) {
    return '配速：$pace';
  }

  @override
  String get hrSetupGuideTitle => '心率设置指南';

  @override
  String get appleWatchTitle => 'Apple Watch';

  @override
  String get samsungWatchTitle => 'Samsung Galaxy Watch';

  @override
  String get chestStrapsTitle => '胸带与臂带';

  @override
  String get appleWatchStep1 => '在 Apple Watch 上，打开“设置”→“锻炼”→“心率”。';

  @override
  String get appleWatchStep2 => '启用“广播心率”。';

  @override
  String get appleWatchStep3 => '在 Apple Watch 上开始任意一次锻炼。';

  @override
  String get appleWatchStep4 => '在 RepFoundry 中点击“连接”，然后选择你的 Apple Watch。';

  @override
  String get samsungWatchStep1 => '在手表上打开 Samsung Health。';

  @override
  String get samsungWatchStep2 => '前往“设置”→“心率广播”。';

  @override
  String get samsungWatchStep3 => '启用 BLE 广播。';

  @override
  String get samsungWatchStep4 => '在 RepFoundry 中点击“连接”，然后选择你的 Galaxy Watch。';

  @override
  String get chestStrapStep1 => '任何 BLE 心率设备（Polar、Garmin、Wahoo 等）都可自动使用。';

  @override
  String get chestStrapStep2 => '只需佩戴胸带或臂带，然后点击“连接”。';

  @override
  String get chestStrapStep3 => '你的设备会显示在扫描列表中。';

  @override
  String get hrDevicePickerTitle => '心率监测设备';

  @override
  String get scanning => '正在扫描设备...';

  @override
  String get noDevicesFound =>
      '未找到心率监测设备。请确认设备正在广播——对于 Apple Watch，请在启用“广播心率”后开始一次锻炼。';

  @override
  String get scanAgain => '重新扫描';

  @override
  String get setupHelp => '设置帮助';

  @override
  String get templatesTitle => '模板';

  @override
  String get noTemplatesYet => '还没有模板';

  @override
  String get noTemplatesYetSubtitle => '创建模板以快速开始训练。';

  @override
  String failedToLoadTemplates(String error) {
    return '加载模板失败：$error';
  }

  @override
  String get newTemplate => '新建模板';

  @override
  String get newTemplateTitle => '新建模板';

  @override
  String get templateNameLabel => '模板名称';

  @override
  String get deleteTemplateTitle => '删除模板？';

  @override
  String deleteTemplateContent(String name) {
    return '你确定要删除“$name”吗？';
  }

  @override
  String exerciseCount(int count) {
    return '$count 个动作';
  }

  @override
  String get editTemplate => '编辑模板';

  @override
  String get targetSets => '组数';

  @override
  String get targetReps => '次数';

  @override
  String get addExerciseToTemplate => '添加动作';

  @override
  String get saveTemplate => '保存';

  @override
  String get removeExercise => '移除动作';

  @override
  String get reorderHint => '拖动以重新排序动作';

  @override
  String get templateSaved => '模板已保存';

  @override
  String get prTypeWeight => '新重量纪录！';

  @override
  String get prTypeReps => '新次数纪录！';

  @override
  String get prTypeVolume => '新容量纪录！';

  @override
  String get prTypeE1rm => '新e1RM纪录！';

  @override
  String get prHistoryTitle => '个人纪录';

  @override
  String get prHistoryEmpty => '暂无个人纪录';

  @override
  String get prHistoryEmptySubtitle => '在训练中记录组数来创建新纪录。';

  @override
  String prAchievedOn(String date) {
    return '达成于 $date';
  }

  @override
  String prValueWeight(String value) {
    return '$value kg';
  }

  @override
  String prValueReps(String value) {
    return '$value 次';
  }

  @override
  String prValueVolume(String value) {
    return '$value kg 容量';
  }

  @override
  String prValueE1rm(String value) {
    return '$value kg e1RM';
  }

  @override
  String get historyTab => '历史';

  @override
  String get progressTab => '进度';

  @override
  String get volumeTrendTitle => '训练量趋势';

  @override
  String get frequencyTitle => '每周训练次数';

  @override
  String get workoutsPerWeek => '次训练';

  @override
  String get startFromTemplate => '从模板开始';

  @override
  String get chooseTemplate => '选择模板';

  @override
  String get noTemplatesAvailable => '暂无可用模板';
}
