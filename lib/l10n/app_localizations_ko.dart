// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Deskmate';

  @override
  String minutesShort(int minutes) {
    return '$minutes분';
  }

  @override
  String hoursMinutes(int hours, int minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String get errorStorage => '저장 상태를 확인할 수 없어요. 다시 확인하면 안전하게 이어집니다.';

  @override
  String get errorAlerts => '알림을 예약하지 못했어요. 앱에 돌아오면 타이머는 복구됩니다.';

  @override
  String get retryCheck => '다시 확인';

  @override
  String get restoringRoom => '저장된 방을 확인하고 있어요.';

  @override
  String get errorSoundPlay => '소리를 재생하지 못했어요. 사운드 설정에서 다시 선택해 주세요.';

  @override
  String get errorSoundStop => '소리를 끄지 못했어요. 사운드 설정에서 다시 시도해 주세요.';

  @override
  String get errorSoundStatus => '사운드 상태를 확인하지 못했어요. 다시 선택해 주세요.';

  @override
  String get stopTitle => '이번 집중을 마칠까요?';

  @override
  String get stopSheetTitle => '이번 집중을\n마칠까요?';

  @override
  String get stopFocusBody => '지금까지의 시간은 중도 종료 기록으로 남아요. 소품 해금 시간에는 더하지 않아요.';

  @override
  String get stopFocusSummary => '지금까지의 시간은 중도 종료 기록으로 남아요.';

  @override
  String get stopFocusRewardsHint => '소품 해금 시간에는 더하지 않아요.';

  @override
  String get stopOtherBody => '체험과 휴식은 집중 기록에 남지 않아요.';

  @override
  String get keepGoing => '계속하기';

  @override
  String get endSession => '종료하기';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSubtitle => '내게 맞는 집중 시간을 만들어요';

  @override
  String get goalTitle => '목표와 다짐';

  @override
  String get goalEmpty => '목표와 D-day를 정해 보세요';

  @override
  String get soundDefaults => '소리 기본 설정';

  @override
  String get soundOff => '현재 소리 꺼짐';

  @override
  String get alertsTitle => '집중 완료 알림';

  @override
  String get alertsOn => '알림이 켜져 있어요';

  @override
  String get alertsOff => '완료 시간을 알려드려요';

  @override
  String get keepScreenTitle => '타이머 중 화면 켜두기';

  @override
  String get keepScreenOn => '집중·휴식 중에는 화면을 켜 둬요';

  @override
  String get keepScreenOff => '평소처럼 꺼져요 · 타이머는 계속 가요';

  @override
  String get collectionTitle => '모은 소품';

  @override
  String collectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 작은 선물',
    );
    return '$_temp0';
  }

  @override
  String get quickFocusTitle => '짧게 집중하기';

  @override
  String quickFocusStart(int minutes) {
    return '$minutes분 집중 시작';
  }

  @override
  String quickFocusLabel(int minutes) {
    return '$minutes분 집중';
  }

  @override
  String get demoButton => '1분 체험 · 기록과 보상 없이 둘러보기';

  @override
  String get soundCreditsTile => '사운드 출처와 라이선스';

  @override
  String get soundCreditsTitle => '사운드 출처';

  @override
  String get soundCreditsIntro =>
      '세 음원은 CC0 1.0으로 공개되었습니다. 앱에 포함되어 오프라인에서도 재생돼요.';

  @override
  String get close => '닫기';

  @override
  String get propPlant => '작은 화분';

  @override
  String get propMug => '따뜻한 머그컵';

  @override
  String get propLamp => '포근한 조명';

  @override
  String get collectionHeading => '방을 채우는 시간';

  @override
  String get collectionSubtitle => '정해진 세 자리에, 나의 집중이 남아요.';

  @override
  String get unlockFirstFocus => '첫 정상 집중 완료';

  @override
  String unlockAfterMinutes(int minutes) {
    return '정상 완료 누적 $minutes분';
  }

  @override
  String get collectionFootnote =>
      '소품은 자동으로 자리에 놓여요.\n중도 종료·1분 체험·휴식은 해금에 포함되지 않아요.';

  @override
  String get captionReady => '함께 집중할 시간';

  @override
  String get captionDemoDone => '체험 완료';

  @override
  String get captionRestDone => '휴식 완료';

  @override
  String get captionFocusDone => '집중 완료';

  @override
  String get captionPaused => '일시정지';

  @override
  String get captionDemo => '1분 체험 · 기록 없이';

  @override
  String get captionRest => '쉬어가는 시간';

  @override
  String captionFocusing(int minutes) {
    return '$minutes분 집중 중';
  }

  @override
  String get messageFirstPlant => '첫 집중의 선물, 작은 화분을 놓았어요.';

  @override
  String messageNewProps(String items) {
    return '새 소품: $items';
  }

  @override
  String get messageDemoDone => '체험을 마쳤어요. 함께해 줘서 고마워요';

  @override
  String get messageRestDone => '잘 쉬었어요. 다시 천천히 시작해요';

  @override
  String get messageFocusDone => '잘했어요. 책상에 집중이 쌓였어요';

  @override
  String get messagePaused => '잠시 쉬어가도 괜찮아요';

  @override
  String get messageRest => '차 한 잔, 천천히 쉬어가요';

  @override
  String get messageFocus => '차근차근, 함께 써 내려가요';

  @override
  String get randomTooltip => '친구가 시간 골라주기';

  @override
  String get deskTitle => '나의 책상';

  @override
  String get focusSound => '집중 사운드';

  @override
  String get todayFocus => '오늘의 집중';

  @override
  String get startFocus => '집중 시작';

  @override
  String get confirm => '확인';

  @override
  String get startRest => '5분 휴식 시작';

  @override
  String get nextFocus => '다음 집중 시작';

  @override
  String get resumeRest => '이어서 쉬기';

  @override
  String get resumeFocus => '이어서 집중';

  @override
  String get pause => '잠시 멈추기';

  @override
  String get endThisSession => '이번 시간 종료';

  @override
  String get navDesk => '책상';

  @override
  String get navRecords => '기록';

  @override
  String get navSettings => '설정';

  @override
  String get recordsTitle => '차곡차곡 기록';

  @override
  String get recordsSubtitle => '함께 집중한 날을 모았어요';

  @override
  String get thisMonth => '이번 달';

  @override
  String get focusedDays => '집중한 날';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
    );
    return '$_temp0';
  }

  @override
  String get previousMonth => '이전 달';

  @override
  String get nextMonth => '다음 달';

  @override
  String get dayFocusDone => '집중 완료';

  @override
  String get today => '오늘';

  @override
  String dayFocusMinutes(int minutes) {
    return '$minutes분 집중';
  }

  @override
  String daySessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count회 완료',
    );
    return '$_temp0';
  }

  @override
  String get recordsArchived =>
      '이날의 합계와 스탬프를 보관하고 있어요.\n상세 내역은 최근 100회까지 볼 수 있어요.';

  @override
  String get recordsFuture => '앞으로 함께 채워갈 하루예요.';

  @override
  String get recordsEmpty => '아직 기록이 없어요.\n25분부터 함께 시작해 볼까요?';

  @override
  String sessionCompleted(int minutes) {
    return '$minutes분 집중 완료';
  }

  @override
  String get sessionStoppedShort => '1분 미만 · 중도 종료';

  @override
  String sessionStopped(int minutes) {
    return '$minutes분 · 중도 종료';
  }

  @override
  String get goalDefaultMessage => '오늘도 한 걸음씩';

  @override
  String get saveError => '저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String get deleteGoalTitle => '목표를 삭제할까요?';

  @override
  String get deleteGoalBody => '집중 기록과 모은 소품은 그대로 남아요.';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get deleteGoalTooltip => '목표 삭제';

  @override
  String get back => '뒤로';

  @override
  String get saving => '저장 중…';

  @override
  String get goalSaving => '변경 내용을 안전하게 저장하고 있어요';

  @override
  String get saveGoal => '목표 저장';

  @override
  String get goalSubtitle => '오늘의 집중에 작은 이유를 더해요';

  @override
  String get preview => '미리보기';

  @override
  String get goalPlaceholderName => '나의 작은 목표';

  @override
  String get goalNameLabel => '목표 이름';

  @override
  String get goalNameHint => '예: 자격증 시험';

  @override
  String get goalNameRequired => '목표 이름을 적어 주세요.';

  @override
  String get goalDateLabel => '목표 날짜';

  @override
  String get select => '선택';

  @override
  String get goalMessageLabel => '나에게 한마디';

  @override
  String get goalMessageHint => '나에게 전하고 싶은 응원';

  @override
  String get showOnHome => '홈 화면에 표시';

  @override
  String get showOnHomeSubtitle => '책상 위에 목표를 작게 보여줘요';

  @override
  String get goalChangeAnytime => '목표는 언제든 바꿔도 괜찮아요';

  @override
  String get soundRainTitle => '창밖의 비';

  @override
  String get soundRainSubtitle => '창가에 톡톡 내리는 빗소리';

  @override
  String get soundForestTitle => '숲의 바람';

  @override
  String get soundForestSubtitle => '나뭇잎 사이로 스치는 바람';

  @override
  String get soundFireTitle => '따뜻한 장작';

  @override
  String get soundFireSubtitle => '포근하게 타닥이는 소리';

  @override
  String get soundSheetSubtitle => '내 방에 어울리는 소리를 골라요';

  @override
  String get volume => '음량';

  @override
  String volumeValue(int percent) {
    return '음량 $percent%';
  }

  @override
  String get mute => '소리 끄기';

  @override
  String get unmute => '소리 켜기';

  @override
  String get stopSoundAtEnd => '집중이 끝나면 소리 끄기';

  @override
  String get soundDone => '선택 완료';

  @override
  String get soundPreviewError => '소리를 재생하지 못했어요. 다시 선택해 주세요.';

  @override
  String get soundSaveError => '설정을 저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String get ambienceMorning => '아침';

  @override
  String get ambienceDay => '낮';

  @override
  String get ambienceEvening => '저녁';

  @override
  String get ambienceNight => '밤';

  @override
  String get poseRestPaused => '찻잔을 들고 잠시 쉬는';

  @override
  String get poseTea => '차를 마시는';

  @override
  String get posePaused => '잠시 쉬는';

  @override
  String get poseWriting => '노트에 필기하는';

  @override
  String get poseWaiting => '책상에서 기다리는';

  @override
  String get propShortPlant => '화분';

  @override
  String get propShortMug => '머그컵';

  @override
  String get propShortLamp => '조명';

  @override
  String sceneLabel(String ambience, String pose, String props) {
    return '$ambience의 책상. $pose 랫서팬더. 얻은 소품 $props';
  }

  @override
  String get navFriends => '친구';

  @override
  String get friendsTitle => '함께할 친구';

  @override
  String get friendsSubtitle => '마음에 드는 친구의 방을 만나보세요';

  @override
  String get friendCurrent => '사용 중';

  @override
  String get friendPreviewTitle => '친구의 방';

  @override
  String get friendApply => '이 친구와 함께하기';

  @override
  String get friendApplyHint => '캐릭터와 방이 함께 바뀌어요';

  @override
  String get friendRestAnimated => '창밖을 보며 차를 마시는 휴식 동작이 있어요';

  @override
  String get friendAnimated => '필기와 휴식 동작으로 함께해요';

  @override
  String get friendStill => '이 친구는 정지된 그림으로 함께해요';

  @override
  String get friendRedpanda => '랫서팬더';

  @override
  String get friendPenguin => '펭귄';

  @override
  String get friendOtter => '해달';

  @override
  String get friendSquirrel => '다람쥐';

  @override
  String get friendFennec => '사막여우';

  @override
  String get roomRedpanda => '따뜻한 저녁 책상';

  @override
  String get roomPenguin => '눈 내리는 겨울 서재';

  @override
  String get roomOtter => '햇살 가득한 바닷가';

  @override
  String get roomSquirrel => '초록 숲속 기록방';

  @override
  String get roomFennec => '노을빛 사막 서재';

  @override
  String get languageTitle => '언어 · Language';

  @override
  String get languageSheetTitle => '언어 · Language';

  @override
  String get languageSheetSubtitle => '앱에서 쓸 언어를 골라요';

  @override
  String get followSystem => '시스템 설정 따르기';

  @override
  String languageNow(String language) {
    return '지금 휴대폰 언어: $language';
  }

  @override
  String get languageFallbackNote => '목록에 없는 휴대폰 언어는 영어로 보여요';

  @override
  String languageChanged(String language) {
    return '언어를 바꿨어요 · $language';
  }

  @override
  String get languageNameKo => '한국어';

  @override
  String get languageNameEn => '영어';

  @override
  String get languageNameJa => '일본어';

  @override
  String get languageNameEs => '스페인어';
}
