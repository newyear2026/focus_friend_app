import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('es'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// App name shown in the task switcher. Kept as the brand name in every language.
  ///
  /// In en, this message translates to:
  /// **'Deskmate'**
  String get appTitle;

  /// A duration in whole minutes, e.g. on the 25/50 buttons.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @hoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String hoursMinutes(int hours, int minutes);

  /// No description provided for @errorStorage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t check your saved room. Check again to continue safely.'**
  String get errorStorage;

  /// No description provided for @errorAlerts.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t schedule the reminder. The timer will recover when you come back.'**
  String get errorAlerts;

  /// No description provided for @retryCheck.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get retryCheck;

  /// No description provided for @restoringRoom.
  ///
  /// In en, this message translates to:
  /// **'Checking your saved room.'**
  String get restoringRoom;

  /// No description provided for @errorSoundPlay.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t play the sound. Please pick it again in sound settings.'**
  String get errorSoundPlay;

  /// No description provided for @errorSoundStop.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t turn the sound off. Please try again in sound settings.'**
  String get errorSoundStop;

  /// No description provided for @errorSoundStatus.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t check the sound. Please pick it again.'**
  String get errorSoundStatus;

  /// No description provided for @stopTitle.
  ///
  /// In en, this message translates to:
  /// **'End this session?'**
  String get stopTitle;

  /// Two-line heading beside the companion portrait in the stop confirmation sheet.
  ///
  /// In en, this message translates to:
  /// **'End this\nsession?'**
  String get stopSheetTitle;

  /// No description provided for @stopFocusBody.
  ///
  /// In en, this message translates to:
  /// **'Time so far is saved as an early stop. It won\'t count toward unlocking items.'**
  String get stopFocusBody;

  /// Main explanation in the focus stop confirmation sheet.
  ///
  /// In en, this message translates to:
  /// **'Time so far is saved as an early stop.'**
  String get stopFocusSummary;

  /// Secondary note below the early-stop explanation.
  ///
  /// In en, this message translates to:
  /// **'It won\'t count toward unlocking items.'**
  String get stopFocusRewardsHint;

  /// No description provided for @stopOtherBody.
  ///
  /// In en, this message translates to:
  /// **'Trials and breaks aren\'t saved to your focus records.'**
  String get stopOtherBody;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endSession;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shape a focus time that fits you'**
  String get settingsSubtitle;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal & promise'**
  String get goalTitle;

  /// No description provided for @goalEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set a goal and a D-day'**
  String get goalEmpty;

  /// No description provided for @soundDefaults.
  ///
  /// In en, this message translates to:
  /// **'Default sound'**
  String get soundDefaults;

  /// No description provided for @soundOff.
  ///
  /// In en, this message translates to:
  /// **'Sound is off'**
  String get soundOff;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus complete alerts'**
  String get alertsTitle;

  /// No description provided for @alertsOn.
  ///
  /// In en, this message translates to:
  /// **'Alerts are on'**
  String get alertsOn;

  /// No description provided for @alertsOff.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know when time is up'**
  String get alertsOff;

  /// No description provided for @keepScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on during timer'**
  String get keepScreenTitle;

  /// No description provided for @keepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'The screen stays on while you focus or rest'**
  String get keepScreenOn;

  /// No description provided for @keepScreenOff.
  ///
  /// In en, this message translates to:
  /// **'Turns off as usual · the timer keeps going'**
  String get keepScreenOff;

  /// No description provided for @collectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Collected items'**
  String get collectionTitle;

  /// No description provided for @collectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 little gift} other{{count} little gifts}}'**
  String collectionCount(int count);

  /// No description provided for @quickFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick focus'**
  String get quickFocusTitle;

  /// Screen reader label for a quick focus button.
  ///
  /// In en, this message translates to:
  /// **'Start {minutes}-minute focus'**
  String quickFocusStart(int minutes);

  /// No description provided for @quickFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min focus'**
  String quickFocusLabel(int minutes);

  /// No description provided for @demoButton.
  ///
  /// In en, this message translates to:
  /// **'1-minute trial · look around without records or rewards'**
  String get demoButton;

  /// No description provided for @soundCreditsTile.
  ///
  /// In en, this message translates to:
  /// **'Sound sources & licenses'**
  String get soundCreditsTile;

  /// No description provided for @soundCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound sources'**
  String get soundCreditsTitle;

  /// No description provided for @soundCreditsIntro.
  ///
  /// In en, this message translates to:
  /// **'All three sounds are released under CC0 1.0. They ship with the app and play offline.'**
  String get soundCreditsIntro;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @propPlant.
  ///
  /// In en, this message translates to:
  /// **'Little plant'**
  String get propPlant;

  /// No description provided for @propMug.
  ///
  /// In en, this message translates to:
  /// **'Warm mug'**
  String get propMug;

  /// No description provided for @propLamp.
  ///
  /// In en, this message translates to:
  /// **'Cozy lamp'**
  String get propLamp;

  /// No description provided for @collectionHeading.
  ///
  /// In en, this message translates to:
  /// **'Filling the room, slowly'**
  String get collectionHeading;

  /// No description provided for @collectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Three set spots, filled by your focus.'**
  String get collectionSubtitle;

  /// No description provided for @unlockFirstFocus.
  ///
  /// In en, this message translates to:
  /// **'First completed focus'**
  String get unlockFirstFocus;

  /// No description provided for @unlockAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min of completed focus in total'**
  String unlockAfterMinutes(int minutes);

  /// No description provided for @collectionFootnote.
  ///
  /// In en, this message translates to:
  /// **'Items find their place on their own.\nEarly stops, 1-minute trials and breaks don\'t count toward unlocks.'**
  String get collectionFootnote;

  /// No description provided for @captionReady.
  ///
  /// In en, this message translates to:
  /// **'Time to focus together'**
  String get captionReady;

  /// No description provided for @captionDemoDone.
  ///
  /// In en, this message translates to:
  /// **'Trial complete'**
  String get captionDemoDone;

  /// No description provided for @captionRestDone.
  ///
  /// In en, this message translates to:
  /// **'Break complete'**
  String get captionRestDone;

  /// No description provided for @captionFocusDone.
  ///
  /// In en, this message translates to:
  /// **'Focus complete'**
  String get captionFocusDone;

  /// No description provided for @captionPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get captionPaused;

  /// No description provided for @captionDemo.
  ///
  /// In en, this message translates to:
  /// **'1-minute trial · not recorded'**
  String get captionDemo;

  /// No description provided for @captionRest.
  ///
  /// In en, this message translates to:
  /// **'Time to rest'**
  String get captionRest;

  /// No description provided for @captionFocusing.
  ///
  /// In en, this message translates to:
  /// **'{minutes}-minute focus'**
  String captionFocusing(int minutes);

  /// No description provided for @messageFirstPlant.
  ///
  /// In en, this message translates to:
  /// **'A gift for your first focus: a little plant is on the desk.'**
  String get messageFirstPlant;

  /// No description provided for @messageNewProps.
  ///
  /// In en, this message translates to:
  /// **'New item: {items}'**
  String messageNewProps(String items);

  /// No description provided for @messageDemoDone.
  ///
  /// In en, this message translates to:
  /// **'Trial finished. Thanks for spending time together'**
  String get messageDemoDone;

  /// No description provided for @messageRestDone.
  ///
  /// In en, this message translates to:
  /// **'Nicely rested. Let\'s ease back in'**
  String get messageRestDone;

  /// No description provided for @messageFocusDone.
  ///
  /// In en, this message translates to:
  /// **'Well done. Your focus is piling up on the desk'**
  String get messageFocusDone;

  /// No description provided for @messagePaused.
  ///
  /// In en, this message translates to:
  /// **'It\'s okay to take a moment'**
  String get messagePaused;

  /// No description provided for @messageRest.
  ///
  /// In en, this message translates to:
  /// **'A cup of tea, nice and slow'**
  String get messageRest;

  /// No description provided for @messageFocus.
  ///
  /// In en, this message translates to:
  /// **'Step by step, let\'s write it down together'**
  String get messageFocus;

  /// No description provided for @randomTooltip.
  ///
  /// In en, this message translates to:
  /// **'Let your friend pick a time'**
  String get randomTooltip;

  /// No description provided for @deskTitle.
  ///
  /// In en, this message translates to:
  /// **'My desk'**
  String get deskTitle;

  /// No description provided for @focusSound.
  ///
  /// In en, this message translates to:
  /// **'Focus sounds'**
  String get focusSound;

  /// No description provided for @todayFocus.
  ///
  /// In en, this message translates to:
  /// **'Today\'s focus'**
  String get todayFocus;

  /// No description provided for @startFocus.
  ///
  /// In en, this message translates to:
  /// **'Start focus'**
  String get startFocus;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirm;

  /// No description provided for @startRest.
  ///
  /// In en, this message translates to:
  /// **'Start 5-min break'**
  String get startRest;

  /// No description provided for @nextFocus.
  ///
  /// In en, this message translates to:
  /// **'Start next focus'**
  String get nextFocus;

  /// No description provided for @resumeRest.
  ///
  /// In en, this message translates to:
  /// **'Resume break'**
  String get resumeRest;

  /// No description provided for @resumeFocus.
  ///
  /// In en, this message translates to:
  /// **'Resume focus'**
  String get resumeFocus;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @endThisSession.
  ///
  /// In en, this message translates to:
  /// **'End this session'**
  String get endThisSession;

  /// No description provided for @navDesk.
  ///
  /// In en, this message translates to:
  /// **'Desk'**
  String get navDesk;

  /// No description provided for @navRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get navRecords;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @recordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Little by little'**
  String get recordsTitle;

  /// No description provided for @recordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The days we focused together'**
  String get recordsSubtitle;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @focusedDays.
  ///
  /// In en, this message translates to:
  /// **'Focus days'**
  String get focusedDays;

  /// No description provided for @dayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String dayCount(int count);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @dayFocusDone.
  ///
  /// In en, this message translates to:
  /// **'focus done'**
  String get dayFocusDone;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @dayFocusMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min focused'**
  String dayFocusMinutes(int minutes);

  /// No description provided for @daySessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session done} other{{count} sessions done}}'**
  String daySessions(int count);

  /// No description provided for @recordsArchived.
  ///
  /// In en, this message translates to:
  /// **'We keep this day\'s total and stamp.\nDetails are kept for your last 100 sessions.'**
  String get recordsArchived;

  /// No description provided for @recordsFuture.
  ///
  /// In en, this message translates to:
  /// **'A day we\'ll fill together.'**
  String get recordsFuture;

  /// No description provided for @recordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet.\nShall we start with 25 minutes?'**
  String get recordsEmpty;

  /// No description provided for @sessionCompleted.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min focus complete'**
  String sessionCompleted(int minutes);

  /// No description provided for @sessionStoppedShort.
  ///
  /// In en, this message translates to:
  /// **'Under 1 min · stopped early'**
  String get sessionStoppedShort;

  /// No description provided for @sessionStopped.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · stopped early'**
  String sessionStopped(int minutes);

  /// Pre-filled cheer message for a new goal.
  ///
  /// In en, this message translates to:
  /// **'One small step today'**
  String get goalDefaultMessage;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get saveError;

  /// No description provided for @deleteGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this goal?'**
  String get deleteGoalTitle;

  /// No description provided for @deleteGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Your focus records and collected items stay as they are.'**
  String get deleteGoalBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteGoalTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get deleteGoalTooltip;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// Status shown while goal changes are waiting to be saved or being saved.
  ///
  /// In en, this message translates to:
  /// **'Safely saving your changes'**
  String get goalSaving;

  /// No description provided for @saveGoal.
  ///
  /// In en, this message translates to:
  /// **'Save goal'**
  String get saveGoal;

  /// No description provided for @goalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a small reason to today\'s focus'**
  String get goalSubtitle;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @goalPlaceholderName.
  ///
  /// In en, this message translates to:
  /// **'My little goal'**
  String get goalPlaceholderName;

  /// No description provided for @goalNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalNameLabel;

  /// No description provided for @goalNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Certification exam'**
  String get goalNameHint;

  /// No description provided for @goalNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please write a goal.'**
  String get goalNameRequired;

  /// No description provided for @goalDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal date'**
  String get goalDateLabel;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @goalMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'A note to myself'**
  String get goalMessageLabel;

  /// No description provided for @goalMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Words of cheer for yourself'**
  String get goalMessageHint;

  /// No description provided for @showOnHome.
  ///
  /// In en, this message translates to:
  /// **'Show on home'**
  String get showOnHome;

  /// No description provided for @showOnHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows your goal small on the desk'**
  String get showOnHomeSubtitle;

  /// No description provided for @goalChangeAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can change your goal anytime'**
  String get goalChangeAnytime;

  /// No description provided for @soundRainTitle.
  ///
  /// In en, this message translates to:
  /// **'Rain outside'**
  String get soundRainTitle;

  /// No description provided for @soundRainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Raindrops tapping on the window'**
  String get soundRainSubtitle;

  /// No description provided for @soundForestTitle.
  ///
  /// In en, this message translates to:
  /// **'Forest breeze'**
  String get soundForestTitle;

  /// No description provided for @soundForestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wind drifting through the leaves'**
  String get soundForestSubtitle;

  /// No description provided for @soundFireTitle.
  ///
  /// In en, this message translates to:
  /// **'Warm fire'**
  String get soundFireTitle;

  /// No description provided for @soundFireSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A cozy, crackling fire'**
  String get soundFireSubtitle;

  /// No description provided for @soundSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a sound that suits your room'**
  String get soundSheetSubtitle;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @volumeValue.
  ///
  /// In en, this message translates to:
  /// **'Volume {percent}%'**
  String volumeValue(int percent);

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Turn sound off'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Turn sound on'**
  String get unmute;

  /// No description provided for @stopSoundAtEnd.
  ///
  /// In en, this message translates to:
  /// **'Turn sound off when focus ends'**
  String get stopSoundAtEnd;

  /// No description provided for @soundDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get soundDone;

  /// No description provided for @soundPreviewError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t play the sound. Please pick it again.'**
  String get soundPreviewError;

  /// No description provided for @soundSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your settings. Please try again.'**
  String get soundSaveError;

  /// No description provided for @ambienceMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get ambienceMorning;

  /// No description provided for @ambienceDay.
  ///
  /// In en, this message translates to:
  /// **'Daytime'**
  String get ambienceDay;

  /// No description provided for @ambienceEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get ambienceEvening;

  /// No description provided for @ambienceNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get ambienceNight;

  /// No description provided for @poseRestPaused.
  ///
  /// In en, this message translates to:
  /// **'pausing with a teacup'**
  String get poseRestPaused;

  /// No description provided for @poseTea.
  ///
  /// In en, this message translates to:
  /// **'sipping tea'**
  String get poseTea;

  /// No description provided for @posePaused.
  ///
  /// In en, this message translates to:
  /// **'taking a short break'**
  String get posePaused;

  /// No description provided for @poseWriting.
  ///
  /// In en, this message translates to:
  /// **'writing in a notebook'**
  String get poseWriting;

  /// No description provided for @poseWaiting.
  ///
  /// In en, this message translates to:
  /// **'waiting at the desk'**
  String get poseWaiting;

  /// No description provided for @propShortPlant.
  ///
  /// In en, this message translates to:
  /// **'plant'**
  String get propShortPlant;

  /// No description provided for @propShortMug.
  ///
  /// In en, this message translates to:
  /// **'mug'**
  String get propShortMug;

  /// No description provided for @propShortLamp.
  ///
  /// In en, this message translates to:
  /// **'lamp'**
  String get propShortLamp;

  /// Screen reader description of the room illustration.
  ///
  /// In en, this message translates to:
  /// **'{ambience} desk. A red panda {pose}. Earned items: {props}'**
  String sceneLabel(String ambience, String pose, String props);

  /// No description provided for @navFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navFriends;

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a friend'**
  String get friendsTitle;

  /// No description provided for @friendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find a friend and a room you love'**
  String get friendsSubtitle;

  /// No description provided for @friendCurrent.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get friendCurrent;

  /// No description provided for @friendPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend’s room'**
  String get friendPreviewTitle;

  /// No description provided for @friendApply.
  ///
  /// In en, this message translates to:
  /// **'Join this friend'**
  String get friendApply;

  /// No description provided for @friendApplyHint.
  ///
  /// In en, this message translates to:
  /// **'Your friend and room change together'**
  String get friendApplyHint;

  /// No description provided for @friendRestAnimated.
  ///
  /// In en, this message translates to:
  /// **'Rests with tea while looking out the window'**
  String get friendRestAnimated;

  /// No description provided for @friendAnimated.
  ///
  /// In en, this message translates to:
  /// **'Writing and tea-break animations'**
  String get friendAnimated;

  /// No description provided for @friendStill.
  ///
  /// In en, this message translates to:
  /// **'This friend joins you as a still illustration'**
  String get friendStill;

  /// No description provided for @friendRedpanda.
  ///
  /// In en, this message translates to:
  /// **'Red panda'**
  String get friendRedpanda;

  /// No description provided for @friendPenguin.
  ///
  /// In en, this message translates to:
  /// **'Penguin'**
  String get friendPenguin;

  /// No description provided for @friendOtter.
  ///
  /// In en, this message translates to:
  /// **'Sea otter'**
  String get friendOtter;

  /// No description provided for @friendSquirrel.
  ///
  /// In en, this message translates to:
  /// **'Squirrel'**
  String get friendSquirrel;

  /// No description provided for @friendFennec.
  ///
  /// In en, this message translates to:
  /// **'Fennec fox'**
  String get friendFennec;

  /// No description provided for @roomRedpanda.
  ///
  /// In en, this message translates to:
  /// **'A cozy evening desk'**
  String get roomRedpanda;

  /// No description provided for @roomPenguin.
  ///
  /// In en, this message translates to:
  /// **'A snowy winter study'**
  String get roomPenguin;

  /// No description provided for @roomOtter.
  ///
  /// In en, this message translates to:
  /// **'A sunlit seaside room'**
  String get roomOtter;

  /// No description provided for @roomSquirrel.
  ///
  /// In en, this message translates to:
  /// **'A green forest journal room'**
  String get roomSquirrel;

  /// No description provided for @roomFennec.
  ///
  /// In en, this message translates to:
  /// **'A desert study at sunset'**
  String get roomFennec;

  /// Settings row. Non-English languages keep the English word so lost users can find it.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSheetTitle;

  /// No description provided for @languageSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the language for this app'**
  String get languageSheetSubtitle;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Use phone setting'**
  String get followSystem;

  /// Under 'Use phone setting': the language the phone would give this app.
  ///
  /// In en, this message translates to:
  /// **'Phone language: {language}'**
  String languageNow(String language);

  /// No description provided for @languageFallbackNote.
  ///
  /// In en, this message translates to:
  /// **'Phone languages not listed here show in English'**
  String get languageFallbackNote;

  /// Shown briefly after picking a language, written in the new language.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageChanged(String language);

  /// No description provided for @languageNameKo.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageNameKo;

  /// No description provided for @languageNameEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @languageNameJa.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageNameJa;

  /// No description provided for @languageNameEs.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageNameEs;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
