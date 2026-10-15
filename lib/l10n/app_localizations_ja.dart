// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Deskmate';

  @override
  String minutesShort(int minutes) {
    return '$minutes分';
  }

  @override
  String hoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String get errorStorage => '保存状態を確認できませんでした。もう一度確認すると、安全に続けられます。';

  @override
  String get errorAlerts => '通知を予約できませんでした。アプリに戻るとタイマーは復元されます。';

  @override
  String get retryCheck => 'もう一度確認';

  @override
  String get restoringRoom => '保存された部屋を確認しています。';

  @override
  String get errorSoundPlay => 'サウンドを再生できませんでした。サウンド設定からもう一度選んでください。';

  @override
  String get errorSoundStop => 'サウンドを止められませんでした。サウンド設定からもう一度お試しください。';

  @override
  String get errorSoundStatus => 'サウンドの状態を確認できませんでした。もう一度選んでください。';

  @override
  String get stopTitle => '今回の集中を終えますか？';

  @override
  String get stopSheetTitle => '今回の集中を\n終えますか？';

  @override
  String get stopFocusBody => 'ここまでの時間は途中終了として記録されます。小物の解放時間には加算されません。';

  @override
  String get stopFocusSummary => 'ここまでの時間は途中終了として記録されます。';

  @override
  String get stopFocusRewardsHint => '小物の解放時間には加算されません。';

  @override
  String get stopOtherBody => 'お試しと休憩は集中記録に残りません。';

  @override
  String get keepGoing => '続ける';

  @override
  String get endSession => '終了する';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSubtitle => '自分に合う集中時間をつくろう';

  @override
  String get goalTitle => '目標とひとこと';

  @override
  String get goalEmpty => '目標と目標日を決めてみましょう';

  @override
  String get soundDefaults => 'サウンドの基本設定';

  @override
  String get soundOff => 'サウンドはオフです';

  @override
  String get alertsTitle => '集中完了の通知';

  @override
  String get alertsOn => '通知はオンです';

  @override
  String get alertsOff => '終わる時間をお知らせします';

  @override
  String get keepScreenTitle => 'タイマー中は画面をつけておく';

  @override
  String get keepScreenOn => '集中・休憩中は画面をつけておきます';

  @override
  String get keepScreenOff => 'いつも通り消えます・タイマーは動き続けます';

  @override
  String get collectionTitle => '集めた小物';

  @override
  String collectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '小さなおくりもの$count個',
    );
    return '$_temp0';
  }

  @override
  String get quickFocusTitle => '短く集中する';

  @override
  String quickFocusStart(int minutes) {
    return '$minutes分の集中を始める';
  }

  @override
  String quickFocusLabel(int minutes) {
    return '$minutes分集中';
  }

  @override
  String get demoButton => '1分お試し・記録とごほうびなしでのぞいてみる';

  @override
  String get soundCreditsTile => 'サウンドの出典とライセンス';

  @override
  String get soundCreditsTitle => 'サウンドの出典';

  @override
  String get soundCreditsIntro =>
      '3つの音源はCC0 1.0で公開されています。アプリに含まれているので、オフラインでも再生できます。';

  @override
  String get close => '閉じる';

  @override
  String get propPlant => '小さな植木鉢';

  @override
  String get propMug => 'あたたかいマグカップ';

  @override
  String get propLamp => 'やさしい明かり';

  @override
  String get collectionHeading => '部屋が満ちていく時間';

  @override
  String get collectionSubtitle => '決まった3つの場所に、わたしの集中が残ります。';

  @override
  String get unlockFirstFocus => 'はじめての集中を完了';

  @override
  String unlockAfterMinutes(int minutes) {
    return '集中完了の合計$minutes分';
  }

  @override
  String get collectionFootnote => '小物は自動で置かれます。\n途中終了・1分お試し・休憩は解放に含まれません。';

  @override
  String get captionReady => 'いっしょに集中する時間';

  @override
  String get captionDemoDone => 'お試し完了';

  @override
  String get captionRestDone => '休憩完了';

  @override
  String get captionFocusDone => '集中完了';

  @override
  String get captionPaused => '一時停止中';

  @override
  String get captionDemo => '1分お試し・記録なし';

  @override
  String get captionRest => 'ひと休みの時間';

  @override
  String captionFocusing(int minutes) {
    return '$minutes分の集中中';
  }

  @override
  String get messageFirstPlant => 'はじめての集中のおくりもの。小さな植木鉢を置きました。';

  @override
  String messageNewProps(String items) {
    return '新しい小物: $items';
  }

  @override
  String get messageDemoDone => 'お試しが終わりました。いっしょにいてくれてありがとう';

  @override
  String get messageRestDone => 'よく休めました。またゆっくり始めましょう';

  @override
  String get messageFocusDone => 'よくできました。机に集中が積み重なりました';

  @override
  String get messagePaused => 'ちょっとひと休みしても大丈夫';

  @override
  String get messageRest => 'お茶を一杯、ゆっくり休みましょう';

  @override
  String get messageFocus => '一歩ずつ、いっしょに書き進めよう';

  @override
  String get randomTooltip => '友だちに時間を選んでもらう';

  @override
  String get deskTitle => 'わたしの机';

  @override
  String get focusSound => '集中サウンド';

  @override
  String get todayFocus => '今日の集中';

  @override
  String get startFocus => '集中スタート';

  @override
  String get confirm => '確認';

  @override
  String get startRest => '5分休憩する';

  @override
  String get nextFocus => '次の集中を始める';

  @override
  String get resumeRest => '休憩を再開';

  @override
  String get resumeFocus => '集中を再開';

  @override
  String get pause => '一時停止';

  @override
  String get endThisSession => '今回を終了';

  @override
  String get navDesk => '机';

  @override
  String get navRecords => '記録';

  @override
  String get navSettings => '設定';

  @override
  String get recordsTitle => 'コツコツ記録';

  @override
  String get recordsSubtitle => 'いっしょに集中した日を集めました';

  @override
  String get thisMonth => '今月';

  @override
  String get focusedDays => '集中した日';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日',
    );
    return '$_temp0';
  }

  @override
  String get previousMonth => '前の月';

  @override
  String get nextMonth => '次の月';

  @override
  String get dayFocusDone => '集中完了';

  @override
  String get today => '今日';

  @override
  String dayFocusMinutes(int minutes) {
    return '$minutes分集中';
  }

  @override
  String daySessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count回完了',
    );
    return '$_temp0';
  }

  @override
  String get recordsArchived => 'この日の合計とスタンプを保管しています。\n詳しい内容は直近100回まで見られます。';

  @override
  String get recordsFuture => 'これからいっしょに埋めていく一日です。';

  @override
  String get recordsEmpty => 'まだ記録がありません。\n25分からいっしょに始めてみませんか？';

  @override
  String sessionCompleted(int minutes) {
    return '$minutes分の集中を完了';
  }

  @override
  String get sessionStoppedShort => '1分未満・途中終了';

  @override
  String sessionStopped(int minutes) {
    return '$minutes分・途中終了';
  }

  @override
  String get goalDefaultMessage => '今日も一歩ずつ';

  @override
  String get saveError => '保存できませんでした。もう一度お試しください。';

  @override
  String get deleteGoalTitle => '目標を削除しますか？';

  @override
  String get deleteGoalBody => '集中記録と集めた小物はそのまま残ります。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get deleteGoalTooltip => '目標を削除';

  @override
  String get back => '戻る';

  @override
  String get saving => '保存中…';

  @override
  String get goalSaving => '変更内容を安全に保存しています';

  @override
  String get saveGoal => '目標を保存';

  @override
  String get goalSubtitle => '今日の集中に、小さな理由をそえて';

  @override
  String get preview => 'プレビュー';

  @override
  String get goalPlaceholderName => 'わたしの小さな目標';

  @override
  String get goalNameLabel => '目標の名前';

  @override
  String get goalNameHint => '例: 資格試験';

  @override
  String get goalNameRequired => '目標の名前を入力してください。';

  @override
  String get goalDateLabel => '目標の日付';

  @override
  String get select => '選択';

  @override
  String get goalMessageLabel => '自分へのひとこと';

  @override
  String get goalMessageHint => '自分に伝えたい応援';

  @override
  String get showOnHome => 'ホーム画面に表示';

  @override
  String get showOnHomeSubtitle => '机の上に目標を小さく表示します';

  @override
  String get goalChangeAnytime => '目標はいつでも変えて大丈夫';

  @override
  String get soundRainTitle => '窓の外の雨';

  @override
  String get soundRainSubtitle => '窓辺にぽつぽつ降る雨の音';

  @override
  String get soundForestTitle => '森の風';

  @override
  String get soundForestSubtitle => '木の葉のあいだを抜ける風';

  @override
  String get soundFireTitle => 'あたたかい薪';

  @override
  String get soundFireSubtitle => 'パチパチとやさしく燃える音';

  @override
  String get soundSheetSubtitle => '部屋に合う音を選ぼう';

  @override
  String get volume => '音量';

  @override
  String volumeValue(int percent) {
    return '音量 $percent%';
  }

  @override
  String get mute => 'サウンドをオフ';

  @override
  String get unmute => 'サウンドをオン';

  @override
  String get stopSoundAtEnd => '集中が終わったらサウンドをオフ';

  @override
  String get soundDone => '決定';

  @override
  String get soundPreviewError => 'サウンドを再生できませんでした。もう一度選んでください。';

  @override
  String get soundSaveError => '設定を保存できませんでした。もう一度お試しください。';

  @override
  String get ambienceMorning => '朝';

  @override
  String get ambienceDay => '昼';

  @override
  String get ambienceEvening => '夕方';

  @override
  String get ambienceNight => '夜';

  @override
  String get poseRestPaused => 'ティーカップを持ってひと休みしている';

  @override
  String get poseTea => 'お茶を飲んでいる';

  @override
  String get posePaused => 'ひと休みしている';

  @override
  String get poseWriting => 'ノートに書きこんでいる';

  @override
  String get poseWaiting => '机で待っている';

  @override
  String get propShortPlant => '植木鉢';

  @override
  String get propShortMug => 'マグカップ';

  @override
  String get propShortLamp => '明かり';

  @override
  String sceneLabel(String ambience, String pose, String props) {
    return '$ambienceの机。$poseレッサーパンダ。手に入れた小物: $props';
  }

  @override
  String get navFriends => 'ともだち';

  @override
  String get friendsTitle => 'いっしょに過ごす友だち';

  @override
  String get friendsSubtitle => 'お気に入りの友だちの部屋を見つけよう';

  @override
  String get friendCurrent => '使用中';

  @override
  String get friendPreviewTitle => '友だちの部屋';

  @override
  String get friendApply => 'この友だちと過ごす';

  @override
  String get friendApplyHint => '友だちと部屋がいっしょに変わります';

  @override
  String get friendRestAnimated => '窓の外を眺めながら、お茶でひと休みします';

  @override
  String get friendAnimated => '書く動作とお茶の休憩で寄り添います';

  @override
  String get friendStill => 'この友だちは静止画で寄り添います';

  @override
  String get friendRedpanda => 'レッサーパンダ';

  @override
  String get friendPenguin => 'ペンギン';

  @override
  String get friendOtter => 'ラッコ';

  @override
  String get friendSquirrel => 'リス';

  @override
  String get friendFennec => 'フェネック';

  @override
  String get roomRedpanda => 'あたたかな夕方の机';

  @override
  String get roomPenguin => '雪の降る冬の書斎';

  @override
  String get roomOtter => '陽だまりの海辺';

  @override
  String get roomSquirrel => '緑の森の記録部屋';

  @override
  String get roomFennec => '夕焼けの砂漠の書斎';

  @override
  String get languageTitle => '言語 · Language';

  @override
  String get languageSheetTitle => '言語 · Language';

  @override
  String get languageSheetSubtitle => 'アプリで使う言語を選びます';

  @override
  String get followSystem => '端末の設定に合わせる';

  @override
  String languageNow(String language) {
    return 'いまの端末の言語: $language';
  }

  @override
  String get languageFallbackNote => '一覧にない端末の言語は英語で表示されます';

  @override
  String languageChanged(String language) {
    return '言語を$languageに変更しました';
  }

  @override
  String get languageNameKo => '韓国語';

  @override
  String get languageNameEn => '英語';

  @override
  String get languageNameJa => '日本語';

  @override
  String get languageNameEs => 'スペイン語';
}
