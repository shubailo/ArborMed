import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hu.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('hu')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'ArborMed'**
  String get appTitle;

  /// No description provided for @quizStart.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get quizStart;

  /// No description provided for @quizContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get quizContinue;

  /// No description provided for @quizSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Answer'**
  String get quizSubmit;

  /// No description provided for @quizNext.
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get quizNext;

  /// No description provided for @quizFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish Quiz'**
  String get quizFinish;

  /// No description provided for @quizCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get quizCorrect;

  /// No description provided for @quizIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get quizIncorrect;

  /// No description provided for @quizScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get quizScore;

  /// No description provided for @quizResults.
  ///
  /// In en, this message translates to:
  /// **'Quiz Results'**
  String get quizResults;

  /// No description provided for @quizStudyBreak.
  ///
  /// In en, this message translates to:
  /// **'Study Break'**
  String get quizStudyBreak;

  /// No description provided for @quizStartSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get quizStartSession;

  /// No description provided for @quizSelectSubject.
  ///
  /// In en, this message translates to:
  /// **'Select Subject'**
  String get quizSelectSubject;

  /// No description provided for @quizComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon...'**
  String get quizComingSoon;

  /// No description provided for @quizSubjectPathophysiology.
  ///
  /// In en, this message translates to:
  /// **'Pathophysiology'**
  String get quizSubjectPathophysiology;

  /// No description provided for @quizSubjectPathology.
  ///
  /// In en, this message translates to:
  /// **'Pathology'**
  String get quizSubjectPathology;

  /// No description provided for @quizSubjectMicrobiology.
  ///
  /// In en, this message translates to:
  /// **'Microbiology'**
  String get quizSubjectMicrobiology;

  /// No description provided for @quizSubjectPharmacology.
  ///
  /// In en, this message translates to:
  /// **'Pharmacology'**
  String get quizSubjectPharmacology;

  /// No description provided for @quizLastStudied.
  ///
  /// In en, this message translates to:
  /// **'LAST STUDIED'**
  String get quizLastStudied;

  /// No description provided for @quizQuoteTopic.
  ///
  /// In en, this message translates to:
  /// **'Choose your focus for today.'**
  String get quizQuoteTopic;

  /// No description provided for @quizSubjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get quizSubjects;

  /// No description provided for @quizECG.
  ///
  /// In en, this message translates to:
  /// **'ECG'**
  String get quizECG;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHungarian.
  ///
  /// In en, this message translates to:
  /// **'Hungarian'**
  String get languageHungarian;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get stats;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

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

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @xp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @autoTranslate.
  ///
  /// In en, this message translates to:
  /// **'Auto-translate'**
  String get autoTranslate;

  /// No description provided for @reviewTranslation.
  ///
  /// In en, this message translates to:
  /// **'Review Translation'**
  String get reviewTranslation;

  /// No description provided for @translating.
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get translating;

  /// No description provided for @translationFailed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed'**
  String get translationFailed;

  /// No description provided for @questionText.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get questionText;

  /// No description provided for @explanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explanation;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer'**
  String get correctAnswer;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @topic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topic;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @createQuestion.
  ///
  /// In en, this message translates to:
  /// **'Create Question'**
  String get createQuestion;

  /// No description provided for @editQuestion.
  ///
  /// In en, this message translates to:
  /// **'Edit Question'**
  String get editQuestion;

  /// No description provided for @deleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Question'**
  String get deleteQuestion;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'ABOUT APP'**
  String get aboutApp;

  /// No description provided for @musicVolume.
  ///
  /// In en, this message translates to:
  /// **'Music Volume'**
  String get musicVolume;

  /// No description provided for @selectTrack.
  ///
  /// In en, this message translates to:
  /// **'Select Track'**
  String get selectTrack;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminPanel;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'v0.1.0 Beta'**
  String get appVersion;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'ArborMed is an educational companion designed for medical students to master theory through gamification.'**
  String get appDescription;

  /// No description provided for @appMission.
  ///
  /// In en, this message translates to:
  /// **'By blending evidence-based learning with a cozy, stress-free environment, we help students tackle complex core medical subjects effectively.'**
  String get appMission;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'CREATED BY'**
  String get createdBy;

  /// No description provided for @vision.
  ///
  /// In en, this message translates to:
  /// **'VISION'**
  String get vision;

  /// No description provided for @visionStatement.
  ///
  /// In en, this message translates to:
  /// **'Transforming medical education into a delightful, rewarding daily habit.'**
  String get visionStatement;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 ArborMed Team'**
  String get copyright;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT SETTINGS'**
  String get accountSettings;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmPassword;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get update;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @changeNickname.
  ///
  /// In en, this message translates to:
  /// **'Change Nickname'**
  String get changeNickname;

  /// No description provided for @nicknameHint.
  ///
  /// In en, this message translates to:
  /// **'This name will be visible to other doctors in the Medical Network.'**
  String get nicknameHint;

  /// No description provided for @enterNickname.
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname...'**
  String get enterNickname;

  /// No description provided for @nicknameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Nickname updated!'**
  String get nicknameUpdated;

  /// No description provided for @medicalId.
  ///
  /// In en, this message translates to:
  /// **'MEDICAL ID'**
  String get medicalId;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get streak;

  /// No description provided for @pager.
  ///
  /// In en, this message translates to:
  /// **'PAGER'**
  String get pager;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'NETWORK'**
  String get network;

  /// No description provided for @searchColleagues.
  ///
  /// In en, this message translates to:
  /// **'Search colleagues...'**
  String get searchColleagues;

  /// No description provided for @noDoctorsFound.
  ///
  /// In en, this message translates to:
  /// **'No doctors found'**
  String get noDoctorsFound;

  /// No description provided for @consultRequests.
  ///
  /// In en, this message translates to:
  /// **'CONSULT REQUESTS'**
  String get consultRequests;

  /// No description provided for @colleagues.
  ///
  /// In en, this message translates to:
  /// **'COLLEAGUES'**
  String get colleagues;

  /// No description provided for @noColleaguesYet.
  ///
  /// In en, this message translates to:
  /// **'No colleagues yet. Search for your peers!'**
  String get noColleaguesYet;

  /// No description provided for @removeColleague.
  ///
  /// In en, this message translates to:
  /// **'Remove Colleague?'**
  String get removeColleague;

  /// No description provided for @areYouSureRemove.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {username} from your network?'**
  String areYouSureRemove(Object username);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get remove;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'SENT'**
  String get sent;

  /// No description provided for @adminAlert.
  ///
  /// In en, this message translates to:
  /// **'ADMIN ALERT'**
  String get adminAlert;

  /// No description provided for @peerNote.
  ///
  /// In en, this message translates to:
  /// **'PEER NOTE'**
  String get peerNote;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete Message?'**
  String get deleteMessage;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In en, this message translates to:
  /// **'This record will be permanently removed from your pager.'**
  String get deleteMessageConfirm;

  /// No description provided for @yourPagerIsSilent.
  ///
  /// In en, this message translates to:
  /// **'Your pager is silent.'**
  String get yourPagerIsSilent;

  /// No description provided for @activityTrend.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY TREND'**
  String get activityTrend;

  /// No description provided for @dailyPrescription.
  ///
  /// In en, this message translates to:
  /// **'DAILY PRESCRIPTION'**
  String get dailyPrescription;

  /// No description provided for @goalAchieved.
  ///
  /// In en, this message translates to:
  /// **'GOAL ACHIEVED!'**
  String get goalAchieved;

  /// No description provided for @dailyDoseComplete.
  ///
  /// In en, this message translates to:
  /// **'Daily dose complete.'**
  String get dailyDoseComplete;

  /// No description provided for @needMoreToday.
  ///
  /// In en, this message translates to:
  /// **'Need {count} more today.'**
  String needMoreToday(Object count);

  /// No description provided for @mistakeReview.
  ///
  /// In en, this message translates to:
  /// **'MISTAKE REVIEW'**
  String get mistakeReview;

  /// No description provided for @reviewMistakes.
  ///
  /// In en, this message translates to:
  /// **'Review {count} failed questions.'**
  String reviewMistakes(Object count);

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @consistency.
  ///
  /// In en, this message translates to:
  /// **'CONSISTENCY'**
  String get consistency;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get day;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'WEEK'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'MONTH'**
  String get month;

  /// No description provided for @noMistakes.
  ///
  /// In en, this message translates to:
  /// **'No mistakes found to review in this period!'**
  String get noMistakes;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;
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
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hu':
      return AppLocalizationsHu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
