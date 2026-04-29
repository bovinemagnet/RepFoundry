// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class SJa extends S {
  SJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'RepFoundry';

  @override
  String get navWorkout => 'ワークアウト';

  @override
  String get navHistory => '履歴';

  @override
  String get navCardio => '有酸素';

  @override
  String get navHeartRate => '心拍数';

  @override
  String get navSettings => '設定';

  @override
  String get start => 'スタート';

  @override
  String get pause => '一時停止';

  @override
  String get resume => '再開';

  @override
  String get reset => 'リセット';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get create => '作成';

  @override
  String get finish => '終了';

  @override
  String get next => '次へ';

  @override
  String get back => '戻る';

  @override
  String get skip => 'スキップ';

  @override
  String get done => '完了';

  @override
  String get retry => '再試行';

  @override
  String get bpmSuffix => 'bpm';

  @override
  String get yearsSuffix => '歳';

  @override
  String get kgUnit => 'kg';

  @override
  String get lbsUnit => 'lbs';

  @override
  String get settingsTitle => '設定';

  @override
  String get sectionHealthProfile => '健康プロフィール';

  @override
  String get sectionAppearance => '外観';

  @override
  String get sectionUnits => '単位';

  @override
  String get sectionRestTimer => 'レストタイマー';

  @override
  String get sectionData => 'データ';

  @override
  String get sectionAbout => 'このアプリについて';

  @override
  String get ageLabel => '年齢';

  @override
  String ageSubtitleSet(int age, int maxHr) {
    return '$age 歳（最大心拍数：$maxHr bpm）';
  }

  @override
  String get ageSubtitleEmpty => '心拍数ゾーンの計算に年齢を設定してください';

  @override
  String get setYourAge => '年齢を設定';

  @override
  String get ageHint => '例：30';

  @override
  String get restingHeartRate => '安静時心拍数';

  @override
  String restingHrSubtitleSet(int bpm) {
    return '$bpm bpm';
  }

  @override
  String get restingHrSubtitleEmpty => '任意 — Karvonen ゾーンを有効化';

  @override
  String get restingHrHint => '例：60';

  @override
  String get measuredMaxHeartRate => '実測最大心拍数';

  @override
  String measuredMaxHrSubtitleSet(int bpm) {
    return '$bpm bpm';
  }

  @override
  String get measuredMaxHrSubtitleEmpty => '任意 — 運動負荷試験より';

  @override
  String get measuredMaxHrHint => '例：185';

  @override
  String get betaBlockerMedication => 'β遮断薬の服用';

  @override
  String get betaBlockerSubtitle => '心拍数ゾーンの精度に影響します';

  @override
  String get heartConditionLabel => '心疾患';

  @override
  String get heartConditionSubtitle => 'ゾーンの注意モードを有効化';

  @override
  String get clinicianMaxHeartRate => '医師指定の最大心拍数';

  @override
  String clinicianMaxHrSubtitleSet(int bpm) {
    return '$bpm bpm — 推定値を上書き';
  }

  @override
  String get clinicianMaxHrSubtitleEmpty => '任意 — 医師が提供';

  @override
  String get clinicianMaxHrHint => '例：150';

  @override
  String get zoneMethod => 'ゾーン計算方式';

  @override
  String zoneMethodAndReliability(String method, String reliability) {
    return '$method · 信頼度$reliability';
  }

  @override
  String get zoneMethodCustom => 'カスタムゾーン';

  @override
  String get zoneMethodClinicianCap => '医師上限';

  @override
  String get zoneMethodHrr => '心拍予備能（Karvonen）';

  @override
  String get zoneMethodLthrFriel => '乳酸閾値（Friel）';

  @override
  String get zoneMethodMeasuredMax => '実測最大心拍数';

  @override
  String get zoneMethodEstimatedMax => '年齢推定最大心拍数';

  @override
  String get reliabilityHigh => '高';

  @override
  String get reliabilityMedium => '中';

  @override
  String get reliabilityLow => '低';

  @override
  String get setUpHeartRateZones => '心拍数ゾーンの設定';

  @override
  String get stepByStepGuidedSetup => 'ステップバイステップのガイド設定';

  @override
  String get zoneColourBands => 'ゾーンカラーバンド';

  @override
  String get zoneColourBandsSubtitle => '心拍数チャートにカラーゾーンバンドを表示';

  @override
  String get sectionMaxHrAlert => '最大心拍数アラート';

  @override
  String get maxHrAlertVibration => '最大心拍数到達時の振動';

  @override
  String get maxHrAlertVibrationSubtitle => '心拍数が推奨最大値に達したとき振動で通知';

  @override
  String get maxHrAlertSound => '最大心拍数到達時のサウンド';

  @override
  String get maxHrAlertSoundSubtitle => '心拍数が推奨最大値に達したとき警告音を再生';

  @override
  String get maxHrAlertCooldown => 'アラートクールダウン';

  @override
  String get maxHrAlertCooldownSubtitle => '繰り返しアラートの最小間隔（秒）';

  @override
  String maxHrAlertCooldownValue(int seconds) {
    return '$seconds秒';
  }

  @override
  String get maxHrReached => '心拍数が推奨最大値に達しました';

  @override
  String get disclaimerLabel => '免責事項';

  @override
  String get settingsShowExerciseImages => 'エクササイズ画像を表示';

  @override
  String get settingsShowExerciseImagesSubtitle => 'リストにエクササイズのイラストを表示';

  @override
  String get themeLabel => 'テーマ';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeAuto => '自動';

  @override
  String get weightUnitLabel => '重量単位';

  @override
  String get vibrationAlert => '振動アラート';

  @override
  String get vibrationAlertSubtitle => 'レストタイマー終了時に振動';

  @override
  String get soundAlert => 'サウンドアラート';

  @override
  String get soundAlertSubtitle => 'レストタイマー終了時にサウンドを再生';

  @override
  String get clearAllData => 'すべてのデータを消去';

  @override
  String get clearAllDataSubtitle => 'すべてのワークアウトと設定を完全に削除します。';

  @override
  String get clearAllDataConfirmTitle => 'すべてのデータを消去しますか？';

  @override
  String get clearAllDataConfirmContent =>
      'すべてのワークアウト履歴が完全に削除されます。この操作は元に戻せません。';

  @override
  String get allDataCleared => 'すべてのデータが消去されました。';

  @override
  String get aboutAppName => 'RepFoundry';

  @override
  String aboutVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String get aboutScreenTitle => 'RepFoundry について';

  @override
  String get aboutDescription => 'ジムユーザーのためのシンプルで高速なワークアウト記録アプリ。';

  @override
  String get aboutAuthorLabel => '作者';

  @override
  String get aboutAuthor => 'Paul Snow';

  @override
  String get aboutGitHub => 'GitHub リポジトリ';

  @override
  String get aboutFeatures => '機能';

  @override
  String get aboutFeatureOffline => 'オフラインファースト — データはデバイスに保存';

  @override
  String get aboutFeatureHeartRate => 'Bluetooth 心拍数モニター対応';

  @override
  String get aboutFeatureTemplates => 'ワークアウトテンプレートで素早くセッション開始';

  @override
  String get aboutFeatureProgress => '個人記録による進捗トラッキング';

  @override
  String get aboutFeatureExport => 'JSON または CSV でデータをエクスポート';

  @override
  String get aboutFeatureCardio => 'GPS 対応の有酸素セッション';

  @override
  String get aboutBuiltWith => 'Flutter で構築';

  @override
  String get aboutViewLicences => 'オープンソースライセンス';

  @override
  String get heartRateTitle => '心拍数';

  @override
  String get connectHrMonitor => '心拍数モニターを接続';

  @override
  String get disconnect => '切断';

  @override
  String get setupGuide => 'セットアップガイド';

  @override
  String get reconnecting => '再接続中...';

  @override
  String get recentChart => '最近';

  @override
  String get fullSessionChart => 'フルセッション';

  @override
  String get setAgeInSettings => '設定で年齢を入力してください';

  @override
  String get setAgeInSettingsSubtitle => '年齢を設定すると、心拍トレーニングゾーンが表示されます。';

  @override
  String get statsAvg => '平均';

  @override
  String get statsMin => '最小';

  @override
  String get statsMax => '最大';

  @override
  String get statsReadings => '読み取り数';

  @override
  String get timeInZone => 'ゾーン滞在時間';

  @override
  String moderateOrHigher(String duration) {
    return '中等度以上：$duration';
  }

  @override
  String recoveryHrDrop(int bpm) {
    return '回復心拍数低下：$bpm bpm';
  }

  @override
  String get bluetoothNotAvailable =>
      'Bluetooth が利用できません。Bluetooth がオンになっていることを確認してください。';

  @override
  String chartWindowSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String chartWindowMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get onboardingTitle => '心拍数ゾーンの設定';

  @override
  String onboardingStepOf(int current, int total) {
    return 'ステップ $current / $total';
  }

  @override
  String get onboardingAgeExplanation => '年齢は最大心拍数の推定とトレーニングゾーンのカスタマイズに使用されます。';

  @override
  String get onboardingRestingHrExplanation =>
      '安静時心拍数を入力すると、Karvonen（心拍予備能）法でより正確なゾーン計算が可能になります。';

  @override
  String get onboardingRestingHrLabel => '安静時心拍数（任意）';

  @override
  String get onboardingMeasuredMaxHrLabel => '実測最大心拍数（任意）';

  @override
  String get onboardingRestingHrHint => '例：60';

  @override
  String get onboardingMeasuredMaxHrHint => '例：185';

  @override
  String get onboardingMedicalExplanation =>
      '以下のいずれかに該当する場合、心拍数ゾーンは注意モードで表示され、信頼度が低下します。個別の上限については医療専門家にご相談ください。';

  @override
  String get onboardingBetaBlockerLabel => 'β遮断薬を服用中';

  @override
  String get onboardingHeartConditionLabel => '心疾患';

  @override
  String get onboardingClinicianWithFlags =>
      '医療的要因があるため、医師が提供する最大心拍数の入力を強くお勧めします。この値は他のすべての推定値を上書きします。';

  @override
  String get onboardingClinicianWithoutFlags =>
      '医師または運動生理学者から最大心拍数を提供されている場合は、ここに入力して推定値を上書きしてください。';

  @override
  String get onboardingClinicianMaxHrLabel => '医師指定の最大心拍数（任意）';

  @override
  String get disclaimerDialogTitle => '心拍数モニタリング';

  @override
  String get disclaimerDialogButton => '了解しました';

  @override
  String get cautionModeTitle => '注意モード';

  @override
  String get symptomReportButton => '症状を報告';

  @override
  String get symptomReportTitle => '症状レポート';

  @override
  String get stopExerciseTitle => '運動を中止';

  @override
  String get stopExerciseOk => '大丈夫です、運動を中止します';

  @override
  String get stopExerciseHelp => '助けが必要です';

  @override
  String get warningGeneralDisclaimer =>
      '心拍数ゾーンの推定は参考情報であり、医学的アドバイスではありません。特に既往症がある場合は、運動プログラムを開始または変更する前に必ず医療専門家にご相談ください。';

  @override
  String get warningBetaBlocker =>
      'β遮断薬は最大心拍数を大幅に低下させる場合があります。標準的なゾーン計算が正確でない可能性があります。医師提供の最大心拍数を設定するか、主観的運動強度（RPE）とトークテストで強度を判断することをお勧めします。';

  @override
  String get warningHeartCondition =>
      '心疾患があることを示されています。標準的な心拍数ゾーン計算が適切でない場合があります。強度ベースのトレーニングガイダンスを使用する前に、医師提供の最大心拍数を取得することを強くお勧めします。';

  @override
  String get warningClinicianCap =>
      '心拍数ゾーンは医師提供の最大心拍数に基づいて計算されています。この値は年齢ベースまたは実測の推定値を上書きします。';

  @override
  String get warningStopExercise =>
      '胸痛、激しいめまい、失神、または異常な息切れを経験している場合は、直ちに運動を中止してください。症状が続く場合は、緊急の医療を受けてください。';

  @override
  String get warningSymptomIntro => '以下のいずれかの症状を経験していますか？';

  @override
  String get symptomChestPain => '胸の痛みまたは圧迫感';

  @override
  String get symptomDizziness => '激しいめまいまたはふらつき';

  @override
  String get symptomFainting => '失神しそうな感覚';

  @override
  String get symptomBreathing => '異常な息切れ';

  @override
  String get clinicianLimitsInUse => '医師提供の制限値を使用中';

  @override
  String get workoutTitle => 'ワークアウト';

  @override
  String workoutTitleWithTime(String time) {
    return 'ワークアウト  •  $time';
  }

  @override
  String get loadingWorkout => 'ワークアウトを読み込み中…';

  @override
  String get addExercise => 'エクササイズを追加';

  @override
  String get startWorkout => 'ワークアウトを開始';

  @override
  String get noActiveWorkout => 'アクティブなワークアウトがありません';

  @override
  String get noActiveWorkoutSubtitle => '新しいワークアウトを開始してセットを記録しましょう。';

  @override
  String get addExercisesHint => '下のボタンでエクササイズを追加';

  @override
  String get finishWorkoutTitle => 'ワークアウトを終了しますか？';

  @override
  String get finishWorkoutContent => 'ワークアウトを保存してセッションを終了します。';

  @override
  String get tableHeaderHash => '#';

  @override
  String get tableHeaderWeight => '重量';

  @override
  String get tableHeaderReps => 'レップ数';

  @override
  String get tableHeaderE1rm => 'e1RM';

  @override
  String get weightKgLabel => '重量（kg）';

  @override
  String get repsLabel => 'レップ数';

  @override
  String get rpeLabel => 'RPE';

  @override
  String get addRpe => 'RPE を追加';

  @override
  String get hideRpe => 'RPE を非表示';

  @override
  String get logSet => 'セットを記録';

  @override
  String get validationRequired => '必須';

  @override
  String get validationInvalid => '無効';

  @override
  String get validationMinZero => '≥ 0';

  @override
  String get validationRpeRange => '1–10';

  @override
  String get restTimer => 'レストタイマー';

  @override
  String get stopTimer => 'タイマーを停止';

  @override
  String get newPersonalRecord => '新しい自己記録！';

  @override
  String e1rmValue(String value) {
    return 'e1RM：$value kg';
  }

  @override
  String get historyTitle => '履歴';

  @override
  String get noWorkoutsYet => 'ワークアウトがまだありません';

  @override
  String get noWorkoutsYetSubtitle => '完了したワークアウトがここに表示されます。';

  @override
  String get loadingHistory => '履歴を読み込み中…';

  @override
  String errorPrefix(String error) {
    return 'エラー：$error';
  }

  @override
  String volumeTrend(int count) {
    return 'ボリュームトレンド（直近 $count 回）';
  }

  @override
  String setsCount(int count) {
    return '$count セット';
  }

  @override
  String get prBadge => 'PR!';

  @override
  String get workoutDetailTitle => 'ワークアウト詳細';

  @override
  String get workoutNotFound => 'ワークアウトが見つかりません';

  @override
  String get durationLabel => '時間';

  @override
  String get setsLabel => 'セット数';

  @override
  String get volumeLabel => 'ボリューム';

  @override
  String get exerciseProgressTitle => 'エクササイズ進捗';

  @override
  String get noDataYet => 'データがまだありません';

  @override
  String get noDataYetSubtitle => 'このエクササイズのセットを記録すると進捗が表示されます。';

  @override
  String get loadingProgress => '進捗を読み込み中…';

  @override
  String get bestE1rm => 'ベスト e1RM';

  @override
  String get totalVolume => '総ボリューム';

  @override
  String get totalSets => '総セット数';

  @override
  String get e1rmTrend => '推定 1RM トレンド';

  @override
  String get recentSets => '最近のセット';

  @override
  String get tableHeaderDate => '日付';

  @override
  String get chooseExercise => 'エクササイズを選択';

  @override
  String get searchExercisesHint => 'エクササイズを検索…';

  @override
  String get filterAll => 'すべて';

  @override
  String get noExercisesFound => 'エクササイズが見つかりません';

  @override
  String get loadingExercises => 'エクササイズを読み込み中…';

  @override
  String get customExercise => 'カスタム';

  @override
  String get newExerciseTitle => '新しいエクササイズ';

  @override
  String get exerciseNameLabel => 'エクササイズ名';

  @override
  String get categoryLabel => 'カテゴリ';

  @override
  String get muscleGroupLabel => '筋肉群';

  @override
  String get equipmentLabel => '器具';

  @override
  String get exerciseNameRequired => 'エクササイズ名を入力してください';

  @override
  String get cardioTitle => '有酸素';

  @override
  String get exerciseField => '種目';

  @override
  String get distanceMetresLabel => '距離（メートル）';

  @override
  String get inclineLabel => '傾斜（%）';

  @override
  String get avgHeartRateLabel => '平均心拍数（bpm）';

  @override
  String get lastSession => '前回のセッション';

  @override
  String get gpsDistanceTracking => 'GPS 距離トラッキング';

  @override
  String get gpsAcquiring => '信号を取得中...';

  @override
  String gpsMetresTracked(String metres) {
    return '$metres m トラッキング中';
  }

  @override
  String get gpsSubtitle => '屋外ランニングの距離を GPS でトラッキング';

  @override
  String get saveSession => 'セッションを保存';

  @override
  String get cardioSessionSaved => '有酸素セッションを保存しました';

  @override
  String get heartRateMonitorCard => '心拍数モニター';

  @override
  String get heartRateMonitorSubtitle => 'BLE 心拍ストラップまたはウォッチを接続';

  @override
  String get connect => '接続';

  @override
  String connectingTo(String device) {
    return '$device に接続中...';
  }

  @override
  String reconnectingTo(String device) {
    return '$device に再接続中...';
  }

  @override
  String paceLabel(String pace) {
    return 'ペース：$pace';
  }

  @override
  String get hrSetupGuideTitle => '心拍数セットアップガイド';

  @override
  String get appleWatchTitle => 'Apple Watch';

  @override
  String get samsungWatchTitle => 'Samsung Galaxy Watch';

  @override
  String get chestStrapsTitle => 'チェストストラップ＆アームバンド';

  @override
  String get appleWatchStep1 => 'Apple Watch で「設定」→「ワークアウト」→「心拍数」を開きます。';

  @override
  String get appleWatchStep2 => '「心拍数をブロードキャスト」を有効にします。';

  @override
  String get appleWatchStep3 => 'Apple Watch で任意のワークアウトを開始します。';

  @override
  String get appleWatchStep4 => 'RepFoundry で「接続」をタップし、Apple Watch を選択します。';

  @override
  String get samsungWatchStep1 => 'ウォッチで Samsung Health を開きます。';

  @override
  String get samsungWatchStep2 => '「設定」→「心拍数ブロードキャスト」に移動します。';

  @override
  String get samsungWatchStep3 => 'BLE ブロードキャストを有効にします。';

  @override
  String get samsungWatchStep4 => 'RepFoundry で「接続」をタップし、Galaxy Watch を選択します。';

  @override
  String get chestStrapStep1 => 'BLE 心拍デバイス（Polar、Garmin、Wahoo など）は自動的に動作します。';

  @override
  String get chestStrapStep2 => 'ストラップまたはバンドを装着して「接続」をタップするだけです。';

  @override
  String get chestStrapStep3 => 'デバイスがスキャンリストに表示されます。';

  @override
  String get hrDevicePickerTitle => '心拍数モニター';

  @override
  String get scanning => 'デバイスをスキャン中...';

  @override
  String get noDevicesFound =>
      '心拍数モニターが見つかりません。デバイスがブロードキャスト中であることを確認してください。Apple Watch の場合は、心拍数ブロードキャストを有効にしてワークアウトを開始してください。';

  @override
  String get scanAgain => '再スキャン';

  @override
  String get setupHelp => 'セットアップヘルプ';

  @override
  String get templatesTitle => 'テンプレート';

  @override
  String get noTemplatesYet => 'テンプレートがまだありません';

  @override
  String get noTemplatesYetSubtitle => 'テンプレートを作成してワークアウトを素早く開始しましょう。';

  @override
  String failedToLoadTemplates(String error) {
    return 'テンプレートの読み込みに失敗：$error';
  }

  @override
  String get newTemplate => '新しいテンプレート';

  @override
  String get newTemplateTitle => '新しいテンプレート';

  @override
  String get templateNameLabel => 'テンプレート名';

  @override
  String get deleteTemplateTitle => 'テンプレートを削除しますか？';

  @override
  String deleteTemplateContent(String name) {
    return '「$name」を削除してもよろしいですか？';
  }

  @override
  String exerciseCount(int count) {
    return '$count エクササイズ';
  }

  @override
  String get editTemplate => 'テンプレートを編集';

  @override
  String get targetSets => 'セット数';

  @override
  String get targetReps => 'レップ数';

  @override
  String get addExerciseToTemplate => 'エクササイズを追加';

  @override
  String get saveTemplate => '保存';

  @override
  String get removeExercise => 'エクササイズを削除';

  @override
  String get reorderHint => 'ドラッグして並べ替え';

  @override
  String get templateSaved => 'テンプレートを保存しました';

  @override
  String get prTypeWeight => '新重量記録！';

  @override
  String get prTypeReps => '新レップ記録！';

  @override
  String get prTypeVolume => '新ボリューム記録！';

  @override
  String get prTypeE1rm => '新 e1RM 記録！';

  @override
  String get prHistoryTitle => '自己記録';

  @override
  String get prHistoryEmpty => '自己記録がまだありません';

  @override
  String get prHistoryEmptySubtitle => 'ワークアウトでセットを記録して新記録を達成しましょう。';

  @override
  String prAchievedOn(String date) {
    return '$date に達成';
  }

  @override
  String prValueWeight(String value) {
    return '$value kg';
  }

  @override
  String prValueReps(String value) {
    return '$value レップ';
  }

  @override
  String prValueVolume(String value) {
    return '$value kg ボリューム';
  }

  @override
  String prValueE1rm(String value) {
    return '$value kg e1RM';
  }

  @override
  String get historyTab => '履歴';

  @override
  String get progressTab => '進捗';

  @override
  String get volumeTrendTitle => 'ボリュームトレンド';

  @override
  String get frequencyTitle => '週あたりのワークアウト数';

  @override
  String get workoutsPerWeek => '回';

  @override
  String get startFromTemplate => 'テンプレートから開始';

  @override
  String get chooseTemplate => 'テンプレートを選択';

  @override
  String get noTemplatesAvailable => '利用可能なテンプレートがありません';

  @override
  String get muscleGroupDistributionTitle => '筋肉群の分布';

  @override
  String get exerciseProgressListTitle => 'エクササイズ進捗';

  @override
  String setsLogged(int count) {
    return '$count セット記録済み';
  }

  @override
  String get exportAsJson => 'JSON でエクスポート';

  @override
  String get exportAsJsonSubtitle => '完全なワークアウトデータを JSON 形式で';

  @override
  String get exportAsCsv => 'CSV でエクスポート';

  @override
  String get exportAsCsvSubtitle => 'セット、有酸素、自己記録を CSV ファイルで';

  @override
  String get exportingData => 'データをエクスポート中…';

  @override
  String get exportComplete => 'エクスポート完了';

  @override
  String exportFailed(String error) {
    return 'エクスポートに失敗：$error';
  }

  @override
  String get editSet => 'セットを編集';

  @override
  String get editExerciseTitle => 'エクササイズを編集';

  @override
  String get calendarHeatmapTitle => 'ワークアウトカレンダー';

  @override
  String get calendarHeatmapLess => '少';

  @override
  String get calendarHeatmapMore => '多';

  @override
  String currentStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 日連続',
      one: '1 日連続',
      zero: '連続記録なし',
    );
    return '$_temp0';
  }

  @override
  String longestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '日',
      one: '日',
    );
    return '最長：$count $_temp0';
  }

  @override
  String get durationTrendTitle => 'ワークアウト時間（分）';

  @override
  String get warmUpLabel => 'ウォームアップ';

  @override
  String get bodyMetricsTitle => '身体計測';

  @override
  String get bodyMetricsSubtitle => '体重と体組成をトラッキング';

  @override
  String get noBodyMetricsYet => '身体計測データがまだありません';

  @override
  String get noBodyMetricsYetSubtitle => '+ をタップして最初の計測を記録しましょう。';

  @override
  String get addBodyMetric => '計測を追加';

  @override
  String get bodyWeightLabel => '体重';

  @override
  String get bodyFatPercentLabel => '体脂肪率 %';

  @override
  String get bodyFatLabel => '体脂肪';

  @override
  String get notesLabel => 'メモ';

  @override
  String get bodyWeightTrendTitle => '体重トレンド';

  @override
  String get latestWeight => '最新の体重';

  @override
  String get bodyMetricsHistory => '履歴';

  @override
  String get importFromJson => 'JSON からインポート';

  @override
  String get importFromJsonSubtitle => '以前のエクスポートからデータを復元';

  @override
  String get importDataTitle => 'データをインポート';

  @override
  String get importDataConfirmContent =>
      'JSON エクスポートのデータを既存のデータに追加します。重複はスキップされます。';

  @override
  String get importDataButton => 'インポート';

  @override
  String get importPasteJsonTitle => 'JSON データを貼り付け';

  @override
  String get importPasteJsonHint => 'エクスポートした JSON をここに貼り付け…';

  @override
  String importComplete(int workouts, int sets, int cardio) {
    return 'インポート完了：$workouts ワークアウト、$sets セット、$cardio カーディオセッション';
  }

  @override
  String importFailed(String error) {
    return 'インポートに失敗：$error';
  }

  @override
  String get duplicateTemplate => '複製';

  @override
  String get copyLabel => 'コピー';

  @override
  String get supersetLabel => 'スーパーセット';

  @override
  String get linkAsSuperset => 'スーパーセットとしてリンク';

  @override
  String get breakSuperset => 'スーパーセットを解除';

  @override
  String supersetWith(String name) {
    return '$name とスーパーセット';
  }

  @override
  String get selectSupersetPartner => 'リンクするエクササイズを選択';

  @override
  String get noOtherExercises => '先に別のエクササイズを追加してください';

  @override
  String get sectionReminders => 'リマインダー';

  @override
  String get workoutReminders => 'ワークアウトリマインダー';

  @override
  String get workoutRemindersSubtitle => 'トレーニング日に通知を受け取る';

  @override
  String get reminderTime => 'リマインダー時刻';

  @override
  String get reminderTimeSubtitle => 'ワークアウトリマインダーを受け取る時刻';

  @override
  String get reminderDays => 'トレーニング日';

  @override
  String get streakReminder => '連続記録リマインダー';

  @override
  String get streakReminderSubtitle => '今日まだワークアウトしていない場合に通知';

  @override
  String get mondayShort => '月';

  @override
  String get tuesdayShort => '火';

  @override
  String get wednesdayShort => '水';

  @override
  String get thursdayShort => '木';

  @override
  String get fridayShort => '金';

  @override
  String get saturdayShort => '土';

  @override
  String get sundayShort => '日';

  @override
  String get notificationPermissionRequired => 'リマインダーには通知の許可が必要です';

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
  String get analyticsTitle => '分析';

  @override
  String get weeklyVolumeTitle => '週間ボリュームトレンド';

  @override
  String weeklyVolumeChange(String change) {
    return '前週比 $change%';
  }

  @override
  String get muscleBalanceTitle => '筋肉群バランス';

  @override
  String get prTimelineTitle => '自己記録タイムライン';

  @override
  String get trainingLoadTitle => '週間トレーニング負荷';

  @override
  String get trainingLoadSubtitle => 'セット数 × 平均 RPE';

  @override
  String get noAnalyticsData => 'データが不足しています';

  @override
  String get noAnalyticsDataSubtitle => 'いくつかのワークアウトを完了すると分析が表示されます。';

  @override
  String get volumeCategory => 'カテゴリ別ボリューム';

  @override
  String loadScore(String score) {
    return '負荷：$score';
  }

  @override
  String get viewAdvancedAnalytics => '詳細分析を表示';

  @override
  String get programmesTitle => 'プログラム';

  @override
  String get noProgrammesYet => 'プログラムがまだありません';

  @override
  String get noProgrammesYetSubtitle => 'トレーニングプログラムを作成してワークアウトを計画しましょう。';

  @override
  String get newProgramme => '新しいプログラム';

  @override
  String get newProgrammeTitle => '新しいプログラム';

  @override
  String get programmeNameLabel => 'プログラム名';

  @override
  String get durationWeeksLabel => '期間（週）';

  @override
  String get editProgramme => 'プログラムを編集';

  @override
  String get deleteProgrammeTitle => 'プログラムを削除しますか？';

  @override
  String deleteProgrammeContent(String name) {
    return '「$name」を削除してもよろしいですか？この操作は元に戻せません。';
  }

  @override
  String get programmeDashboard => 'ダッシュボード';

  @override
  String currentWeek(int current, int total) {
    return '第 $current / $total 週';
  }

  @override
  String get assignTemplate => 'テンプレートを割り当て';

  @override
  String get noTemplateAssigned => '休息日';

  @override
  String get progressionRules => 'プログレッションルール';

  @override
  String get addRule => 'ルールを追加';

  @override
  String get fixedIncrementLabel => '固定増加';

  @override
  String get percentageLabel => 'パーセンテージ';

  @override
  String get deloadLabel => 'ディロード';

  @override
  String get ruleValueLabel => '値';

  @override
  String everyNWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '週',
      one: '週',
    );
    return '$count $_temp0ごと';
  }

  @override
  String get startFromProgramme => 'プログラムから開始';

  @override
  String targetWeight(String weight) {
    return '目標：$weight kg';
  }

  @override
  String get programmeSaved => 'プログラムを保存しました';

  @override
  String failedToLoadProgrammes(String error) {
    return 'プログラムの読み込みに失敗：$error';
  }

  @override
  String programmeWeeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '週',
      one: '週',
    );
    return '$count $_temp0';
  }

  @override
  String programmeDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '日',
      one: '日',
    );
    return '$count $_temp0割り当て済み';
  }

  @override
  String weekLabel(int number) {
    return '第 $number 週';
  }

  @override
  String programmeWeekOf(int current, int total) {
    return '$total 週中 $current 週目';
  }

  @override
  String get programmeNotStarted => '未開始';

  @override
  String dayLabel(String day) {
    return '$day';
  }

  @override
  String get chooseProgramme => 'プログラムを選択';

  @override
  String get noProgrammesAvailable => '利用可能なプログラムがありません';

  @override
  String get noWorkoutScheduledForToday => '今日のワークアウト予定はありません';

  @override
  String get healthSyncTitle => 'ヘルス同期';

  @override
  String get healthSyncSubtitle => 'Apple Health または Health Connect とデータを同期';

  @override
  String get healthSyncEnabled => 'ヘルス同期を有効化';

  @override
  String get writeWorkoutsLabel => 'ワークアウトを書き込み';

  @override
  String get writeWorkoutsSubtitle => '完了したワークアウトをヘルスストアに記録';

  @override
  String get writeWeightLabel => '体重を書き込み';

  @override
  String get writeWeightSubtitle => '身体計測データをヘルスストアに送信';

  @override
  String get writeHeartRateLabel => '心拍数を書き込み';

  @override
  String get writeHeartRateSubtitle => '有酸素運動中の心拍数データを送信';

  @override
  String get readWeightLabel => '体重を読み込み';

  @override
  String get readWeightSubtitle => 'ヘルスストアから体重データをインポート';

  @override
  String get healthSyncPermissionDenied => 'ヘルスの権限が付与されていません';

  @override
  String get healthSyncSuccess => 'ヘルスに同期しました';

  @override
  String importWeightPrompt(String weight) {
    return 'ヘルスから $weight kg をインポートしますか？';
  }

  @override
  String get importWeightAction => 'インポート';

  @override
  String get healthSyncNoNewData => 'ヘルスに新しいデータがありません';

  @override
  String get syncSectionTitle => 'クロスデバイス同期';

  @override
  String get syncEnabled => 'クロスデバイス同期を有効化';

  @override
  String get syncEnabledSubtitle => 'デバイス間でワークアウトデータを同期';

  @override
  String syncLastSynced(String time) {
    return '最終同期：$time';
  }

  @override
  String get syncNeverSynced => '未同期';

  @override
  String get syncNow => '今すぐ同期';

  @override
  String get syncSyncing => '同期中…';

  @override
  String get syncSuccess => '同期完了';

  @override
  String syncError(String error) {
    return '同期に失敗：$error';
  }

  @override
  String get syncDisableAndDelete => '同期を無効化しクラウドデータを削除';

  @override
  String get syncDisableConfirmTitle => '同期を無効化しますか？';

  @override
  String get syncDisableConfirmBody =>
      '同期を無効化し、クラウドストレージのデータを完全に削除します。ローカルデータには影響しません。';

  @override
  String get syncDisableConfirmAction => '無効化して削除';

  @override
  String get syncConsentTitle => 'クロスデバイス同期';

  @override
  String get syncConsentBody =>
      'ワークアウトデータはご自身の Google Drive または iCloud アカウントに保存されます。RepFoundry はこのデータにアクセスできません。設定またはクラウドアカウントからいつでも削除できます。';

  @override
  String get syncConsentCancel => 'キャンセル';

  @override
  String get syncConsentAccept => '了解しました — 続行';

  @override
  String get trainingHistoryTitle => 'トレーニング履歴';

  @override
  String get trainingHistorySubtitle => '進化と機械的張力の向上を追跡しましょう。';

  @override
  String get searchSessionsHint => 'セッションまたはエクササイズを検索…';

  @override
  String get thisWeek => '今週';

  @override
  String get lastWeek => '先週';

  @override
  String get volumeProgress => 'ボリューム進捗';

  @override
  String totalVolumeKg(String value) {
    return '$value kg';
  }

  @override
  String get workoutFallbackName => 'ワークアウト';

  @override
  String get liveSensor => 'ライブセンサー';

  @override
  String get restingHrLabel => '安静時心拍数';

  @override
  String get maxHrLabel => '最大心拍数';

  @override
  String get recoveryLabel => '回復';

  @override
  String get hrvLabel => '心拍変動';

  @override
  String get excellent => '優秀';

  @override
  String get reachedAgo => 'セッション最大';

  @override
  String get toBaseline => 'ベースラインへ';

  @override
  String get highReadiness => '高準備度';

  @override
  String get workoutIntensityZones => 'ワークアウト強度ゾーン';

  @override
  String sessionDuration(String duration) {
    return 'セッション：$duration';
  }

  @override
  String get zonePeak => 'ピーク';

  @override
  String get zoneAnaerobic => '無酸素';

  @override
  String get zoneAerobic => '有酸素';

  @override
  String get zoneFatBurn => '脂肪燃焼';

  @override
  String get zoneWarmup => 'ウォームアップ';

  @override
  String get heartRateTrend => '心拍数トレンド';

  @override
  String get heartRateTrendSubtitle => '現在のワークアウトセッション';

  @override
  String get todayLabel => '今日';

  @override
  String get avgLabel => '平均';

  @override
  String get activeDuration => '活動時間';

  @override
  String get avgPaceLabel => '平均ペース';

  @override
  String get distanceLabel => '距離';

  @override
  String get startSession => 'セッションを開始';

  @override
  String get liveTracking => 'ライブトラッキング';

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
}
