// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Deskmate';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String hoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get errorStorage =>
      'We couldn\'t check your saved room. Check again to continue safely.';

  @override
  String get errorAlerts =>
      'We couldn\'t schedule the reminder. The timer will recover when you come back.';

  @override
  String get retryCheck => 'Check again';

  @override
  String get restoringRoom => 'Checking your saved room.';

  @override
  String get errorSoundPlay =>
      'We couldn\'t play the sound. Please pick it again in sound settings.';

  @override
  String get errorSoundStop =>
      'We couldn\'t turn the sound off. Please try again in sound settings.';

  @override
  String get errorSoundStatus =>
      'We couldn\'t check the sound. Please pick it again.';

  @override
  String get stopTitle => 'End this session?';

  @override
  String get stopSheetTitle => 'End this\nsession?';

  @override
  String get stopFocusBody =>
      'Time so far is saved as an early stop. It won\'t count toward unlocking items.';

  @override
  String get stopFocusSummary => 'Time so far is saved as an early stop.';

  @override
  String get stopFocusRewardsHint => 'It won\'t count toward unlocking items.';

  @override
  String get stopOtherBody =>
      'Trials and breaks aren\'t saved to your focus records.';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get endSession => 'End';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Shape a focus time that fits you';

  @override
  String get goalTitle => 'Goal & promise';

  @override
  String get goalEmpty => 'Set a goal and a D-day';

  @override
  String get soundDefaults => 'Default sound';

  @override
  String get soundOff => 'Sound is off';

  @override
  String get alertsTitle => 'Focus complete alerts';

  @override
  String get alertsOn => 'Alerts are on';

  @override
  String get alertsOff => 'We\'ll let you know when time is up';

  @override
  String get keepScreenTitle => 'Keep screen on during timer';

  @override
  String get keepScreenOn => 'The screen stays on while you focus or rest';

  @override
  String get keepScreenOff => 'Turns off as usual · the timer keeps going';

  @override
  String get collectionTitle => 'Collected items';

  @override
  String collectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count little gifts',
      one: '1 little gift',
    );
    return '$_temp0';
  }

  @override
  String get quickFocusTitle => 'Quick focus';

  @override
  String quickFocusStart(int minutes) {
    return 'Start $minutes-minute focus';
  }

  @override
  String quickFocusLabel(int minutes) {
    return '$minutes min focus';
  }

  @override
  String get demoButton =>
      '1-minute trial · look around without records or rewards';

  @override
  String get soundCreditsTile => 'Sound sources & licenses';

  @override
  String get soundCreditsTitle => 'Sound sources';

  @override
  String get soundCreditsIntro =>
      'All three sounds are released under CC0 1.0. They ship with the app and play offline.';

  @override
  String get close => 'Close';

  @override
  String get propPlant => 'Little plant';

  @override
  String get propMug => 'Warm mug';

  @override
  String get propLamp => 'Cozy lamp';

  @override
  String get collectionHeading => 'Filling the room, slowly';

  @override
  String get collectionSubtitle => 'Three set spots, filled by your focus.';

  @override
  String get unlockFirstFocus => 'First completed focus';

  @override
  String unlockAfterMinutes(int minutes) {
    return '$minutes min of completed focus in total';
  }

  @override
  String get collectionFootnote =>
      'Items find their place on their own.\nEarly stops, 1-minute trials and breaks don\'t count toward unlocks.';

  @override
  String get captionReady => 'Time to focus together';

  @override
  String get captionDemoDone => 'Trial complete';

  @override
  String get captionRestDone => 'Break complete';

  @override
  String get captionFocusDone => 'Focus complete';

  @override
  String get captionPaused => 'Paused';

  @override
  String get captionDemo => '1-minute trial · not recorded';

  @override
  String get captionRest => 'Time to rest';

  @override
  String captionFocusing(int minutes) {
    return '$minutes-minute focus';
  }

  @override
  String get messageFirstPlant =>
      'A gift for your first focus: a little plant is on the desk.';

  @override
  String messageNewProps(String items) {
    return 'New item: $items';
  }

  @override
  String get messageDemoDone =>
      'Trial finished. Thanks for spending time together';

  @override
  String get messageRestDone => 'Nicely rested. Let\'s ease back in';

  @override
  String get messageFocusDone =>
      'Well done. Your focus is piling up on the desk';

  @override
  String get messagePaused => 'It\'s okay to take a moment';

  @override
  String get messageRest => 'A cup of tea, nice and slow';

  @override
  String get messageFocus => 'Step by step, let\'s write it down together';

  @override
  String get randomTooltip => 'Let your friend pick a time';

  @override
  String get deskTitle => 'My desk';

  @override
  String get focusSound => 'Focus sounds';

  @override
  String get todayFocus => 'Today\'s focus';

  @override
  String get startFocus => 'Start focus';

  @override
  String get confirm => 'OK';

  @override
  String get startRest => 'Start 5-min break';

  @override
  String get nextFocus => 'Start next focus';

  @override
  String get resumeRest => 'Resume break';

  @override
  String get resumeFocus => 'Resume focus';

  @override
  String get pause => 'Pause';

  @override
  String get endThisSession => 'End this session';

  @override
  String get navDesk => 'Desk';

  @override
  String get navRecords => 'Records';

  @override
  String get navSettings => 'Settings';

  @override
  String get recordsTitle => 'Little by little';

  @override
  String get recordsSubtitle => 'The days we focused together';

  @override
  String get thisMonth => 'This month';

  @override
  String get focusedDays => 'Focus days';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get dayFocusDone => 'focus done';

  @override
  String get today => 'Today';

  @override
  String dayFocusMinutes(int minutes) {
    return '$minutes min focused';
  }

  @override
  String daySessions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions done',
      one: '1 session done',
    );
    return '$_temp0';
  }

  @override
  String get recordsArchived =>
      'We keep this day\'s total and stamp.\nDetails are kept for your last 100 sessions.';

  @override
  String get recordsFuture => 'A day we\'ll fill together.';

  @override
  String get recordsEmpty => 'No records yet.\nShall we start with 25 minutes?';

  @override
  String sessionCompleted(int minutes) {
    return '$minutes min focus complete';
  }

  @override
  String get sessionStoppedShort => 'Under 1 min · stopped early';

  @override
  String sessionStopped(int minutes) {
    return '$minutes min · stopped early';
  }

  @override
  String get goalDefaultMessage => 'One small step today';

  @override
  String get saveError => 'Couldn\'t save. Please try again.';

  @override
  String get deleteGoalTitle => 'Delete this goal?';

  @override
  String get deleteGoalBody =>
      'Your focus records and collected items stay as they are.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteGoalTooltip => 'Delete goal';

  @override
  String get back => 'Back';

  @override
  String get saving => 'Saving…';

  @override
  String get goalSaving => 'Safely saving your changes';

  @override
  String get saveGoal => 'Save goal';

  @override
  String get goalSubtitle => 'Add a small reason to today\'s focus';

  @override
  String get preview => 'Preview';

  @override
  String get goalPlaceholderName => 'My little goal';

  @override
  String get goalNameLabel => 'Goal';

  @override
  String get goalNameHint => 'e.g. Certification exam';

  @override
  String get goalNameRequired => 'Please write a goal.';

  @override
  String get goalDateLabel => 'Goal date';

  @override
  String get select => 'Select';

  @override
  String get goalMessageLabel => 'A note to myself';

  @override
  String get goalMessageHint => 'Words of cheer for yourself';

  @override
  String get showOnHome => 'Show on home';

  @override
  String get showOnHomeSubtitle => 'Shows your goal small on the desk';

  @override
  String get goalChangeAnytime => 'You can change your goal anytime';

  @override
  String get soundRainTitle => 'Rain outside';

  @override
  String get soundRainSubtitle => 'Raindrops tapping on the window';

  @override
  String get soundForestTitle => 'Forest breeze';

  @override
  String get soundForestSubtitle => 'Wind drifting through the leaves';

  @override
  String get soundFireTitle => 'Warm fire';

  @override
  String get soundFireSubtitle => 'A cozy, crackling fire';

  @override
  String get soundSheetSubtitle => 'Pick a sound that suits your room';

  @override
  String get volume => 'Volume';

  @override
  String volumeValue(int percent) {
    return 'Volume $percent%';
  }

  @override
  String get mute => 'Turn sound off';

  @override
  String get unmute => 'Turn sound on';

  @override
  String get stopSoundAtEnd => 'Turn sound off when focus ends';

  @override
  String get soundDone => 'Done';

  @override
  String get soundPreviewError =>
      'We couldn\'t play the sound. Please pick it again.';

  @override
  String get soundSaveError =>
      'Couldn\'t save your settings. Please try again.';

  @override
  String get ambienceMorning => 'Morning';

  @override
  String get ambienceDay => 'Daytime';

  @override
  String get ambienceEvening => 'Evening';

  @override
  String get ambienceNight => 'Night';

  @override
  String get poseRestPaused => 'pausing with a teacup';

  @override
  String get poseTea => 'sipping tea';

  @override
  String get posePaused => 'taking a short break';

  @override
  String get poseWriting => 'writing in a notebook';

  @override
  String get poseWaiting => 'waiting at the desk';

  @override
  String get propShortPlant => 'plant';

  @override
  String get propShortMug => 'mug';

  @override
  String get propShortLamp => 'lamp';

  @override
  String sceneLabel(String ambience, String pose, String props) {
    return '$ambience desk. A red panda $pose. Earned items: $props';
  }

  @override
  String get navFriends => 'Friends';

  @override
  String get friendsTitle => 'Choose a friend';

  @override
  String get friendsSubtitle => 'Find a friend and a room you love';

  @override
  String get friendCurrent => 'In use';

  @override
  String get friendPreviewTitle => 'Friend’s room';

  @override
  String get friendApply => 'Join this friend';

  @override
  String get friendApplyHint => 'Your friend and room change together';

  @override
  String get friendRestAnimated =>
      'Rests with tea while looking out the window';

  @override
  String get friendAnimated => 'Writing and tea-break animations';

  @override
  String get friendStill => 'This friend joins you as a still illustration';

  @override
  String get friendRedpanda => 'Red panda';

  @override
  String get friendPenguin => 'Penguin';

  @override
  String get friendOtter => 'Sea otter';

  @override
  String get friendSquirrel => 'Squirrel';

  @override
  String get friendFennec => 'Fennec fox';

  @override
  String get roomRedpanda => 'A cozy evening desk';

  @override
  String get roomPenguin => 'A snowy winter study';

  @override
  String get roomOtter => 'A sunlit seaside room';

  @override
  String get roomSquirrel => 'A green forest journal room';

  @override
  String get roomFennec => 'A desert study at sunset';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSheetTitle => 'Language';

  @override
  String get languageSheetSubtitle => 'Pick the language for this app';

  @override
  String get followSystem => 'Use phone setting';

  @override
  String languageNow(String language) {
    return 'Phone language: $language';
  }

  @override
  String get languageFallbackNote =>
      'Phone languages not listed here show in English';

  @override
  String languageChanged(String language) {
    return 'Language changed to $language';
  }

  @override
  String get languageNameKo => 'Korean';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameJa => 'Japanese';

  @override
  String get languageNameEs => 'Spanish';

  @override
  String get recordsTabCalendar => 'Calendar';

  @override
  String get recordsTabWeek => 'Week';

  @override
  String get recordsTabMonth => 'Month';

  @override
  String get thisWeek => 'This week';

  @override
  String get previousWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String statsMoreThanLastWeek(String duration) {
    return '$duration more than last week';
  }

  @override
  String statsLessThanLastWeek(String duration) {
    return '$duration less than last week';
  }

  @override
  String get statsSameAsLastWeek => 'Same as last week';

  @override
  String statsMoreThanLastMonth(String duration) {
    return '$duration more than last month';
  }

  @override
  String statsLessThanLastMonth(String duration) {
    return '$duration less than last month';
  }

  @override
  String get statsSameAsLastMonth => 'Same as last month';

  @override
  String statsBestDay(String day, String duration) {
    return 'Best day · $day $duration';
  }

  @override
  String get statsTimeOfDay => 'Time of day';

  @override
  String statsTopBand(String band) {
    return 'Most focus: $band';
  }

  @override
  String get statsAverage => 'Daily average';

  @override
  String get statsStreak => 'Longest streak';

  @override
  String get statsRecentMonths => 'Last 6 months';

  @override
  String get statsEmptyWeek => 'No focus this week yet.';

  @override
  String get statsEmptyMonth => 'No focus this month yet.';

  @override
  String hoursShort(String hours) {
    return '$hours h';
  }
}
