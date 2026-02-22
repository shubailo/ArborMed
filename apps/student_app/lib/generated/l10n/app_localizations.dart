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
  /// **'Appearance'**
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

  /// No description provided for @logoutOfflineWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE LOGOUT'**
  String get logoutOfflineWarningTitle;

  /// No description provided for @logoutOfflineWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'You are offline and have unsynced data. Logging out now will permanently clear these local changes. Continue?'**
  String get logoutOfflineWarningMessage;

  /// No description provided for @confirmLogoutLabel.
  ///
  /// In en, this message translates to:
  /// **'LOGOUT ANYWAY'**
  String get confirmLogoutLabel;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminDashboard;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminQuotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get adminQuotes;

  /// No description provided for @adminQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get adminQuestions;

  /// No description provided for @adminSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminSettings;

  /// No description provided for @adminSemester.
  ///
  /// In en, this message translates to:
  /// **'Autumn Semester 2026'**
  String get adminSemester;

  /// No description provided for @adminTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'TOTAL USERS'**
  String get adminTotalUsers;

  /// No description provided for @adminRegisteredStudents.
  ///
  /// In en, this message translates to:
  /// **'Registered students'**
  String get adminRegisteredStudents;

  /// No description provided for @adminClassAvg.
  ///
  /// In en, this message translates to:
  /// **'CLASS AVG'**
  String get adminClassAvg;

  /// No description provided for @adminOverallCorrectness.
  ///
  /// In en, this message translates to:
  /// **'Overall correctness'**
  String get adminOverallCorrectness;

  /// No description provided for @adminAvgBloom.
  ///
  /// In en, this message translates to:
  /// **'AVG BLOOM LEVEL'**
  String get adminAvgBloom;

  /// No description provided for @adminPedagogicalDepth.
  ///
  /// In en, this message translates to:
  /// **'Pedagogical depth'**
  String get adminPedagogicalDepth;

  /// No description provided for @adminTopicProficiency.
  ///
  /// In en, this message translates to:
  /// **'Topic Proficiency'**
  String get adminTopicProficiency;

  /// No description provided for @adminDetails.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get adminDetails;

  /// No description provided for @adminNoDataSubject.
  ///
  /// In en, this message translates to:
  /// **'No data available for this subject'**
  String get adminNoDataSubject;

  /// No description provided for @adminSuccessRate.
  ///
  /// In en, this message translates to:
  /// **'Success Rate'**
  String get adminSuccessRate;

  /// No description provided for @adminAvgTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Time'**
  String get adminAvgTime;

  /// No description provided for @adminSuccessRatePercent.
  ///
  /// In en, this message translates to:
  /// **'Success Rate (%)'**
  String get adminSuccessRatePercent;

  /// No description provided for @adminAvgTimeSec.
  ///
  /// In en, this message translates to:
  /// **'Avg Time Spent (sec)'**
  String get adminAvgTimeSec;

  /// No description provided for @adminQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get adminQuickActions;

  /// No description provided for @adminImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get adminImport;

  /// No description provided for @adminReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get adminReport;

  /// No description provided for @adminNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get adminNotification;

  /// No description provided for @adminStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get adminStudents;

  /// No description provided for @adminAdministrators.
  ///
  /// In en, this message translates to:
  /// **'Administrators'**
  String get adminAdministrators;

  /// No description provided for @adminMedicalRegistry.
  ///
  /// In en, this message translates to:
  /// **'Medical Student Registry & Performance'**
  String get adminMedicalRegistry;

  /// No description provided for @adminQuestionsUploaded.
  ///
  /// In en, this message translates to:
  /// **'Questions Uploaded'**
  String get adminQuestionsUploaded;

  /// No description provided for @adminByAdmins.
  ///
  /// In en, this message translates to:
  /// **'by {count} Admins'**
  String adminByAdmins(Object count);

  /// No description provided for @adminActiveUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get adminActiveUsers;

  /// No description provided for @adminNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get adminNoUsersFound;

  /// No description provided for @adminSearchById.
  ///
  /// In en, this message translates to:
  /// **'Search by ID'**
  String get adminSearchById;

  /// No description provided for @adminStudentAccount.
  ///
  /// In en, this message translates to:
  /// **'Student Account'**
  String get adminStudentAccount;

  /// No description provided for @adminNoSubjectAssigned.
  ///
  /// In en, this message translates to:
  /// **'No Subject Assigned'**
  String get adminNoSubjectAssigned;

  /// No description provided for @adminViewPerformance.
  ///
  /// In en, this message translates to:
  /// **'View Performance History'**
  String get adminViewPerformance;

  /// No description provided for @adminTableActivity.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY'**
  String get adminTableActivity;

  /// No description provided for @adminTableActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get adminTableActions;

  /// No description provided for @adminSendPager.
  ///
  /// In en, this message translates to:
  /// **'Send Pager Message'**
  String get adminSendPager;

  /// No description provided for @adminPromoteAdmin.
  ///
  /// In en, this message translates to:
  /// **'Promote to Admin'**
  String get adminPromoteAdmin;

  /// No description provided for @adminDemoteStudent.
  ///
  /// In en, this message translates to:
  /// **'Demote to Student'**
  String get adminDemoteStudent;

  /// No description provided for @adminDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get adminDeleteUser;

  /// No description provided for @adminPagerTitle.
  ///
  /// In en, this message translates to:
  /// **'PAGER: {identifier}'**
  String adminPagerTitle(Object identifier);

  /// No description provided for @adminTypePagerMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message to the student...'**
  String get adminTypePagerMessage;

  /// No description provided for @adminMessageDispatched.
  ///
  /// In en, this message translates to:
  /// **'Message dispatched!'**
  String get adminMessageDispatched;

  /// No description provided for @adminChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role?'**
  String get adminChangeRole;

  /// No description provided for @adminConfirmRoleChange.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change {identifier}\'s role to {role}?'**
  String adminConfirmRoleChange(Object identifier, Object role);

  /// No description provided for @adminUserRoleUpdated.
  ///
  /// In en, this message translates to:
  /// **'User role updated!'**
  String get adminUserRoleUpdated;

  /// No description provided for @adminDeleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete User?'**
  String get adminDeleteUserTitle;

  /// No description provided for @adminDeleteUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will erase ALL progress for {identifier}. This action cannot be undone.'**
  String adminDeleteUserConfirm(Object identifier);

  /// No description provided for @adminDoctorRemoved.
  ///
  /// In en, this message translates to:
  /// **'Doctor removed from registry.'**
  String get adminDoctorRemoved;

  /// No description provided for @adminClickHistory.
  ///
  /// In en, this message translates to:
  /// **'Click for history'**
  String get adminClickHistory;

  /// No description provided for @adminNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get adminNever;

  /// No description provided for @adminPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String adminPageOf(Object current, Object total);

  /// No description provided for @adminAddQuote.
  ///
  /// In en, this message translates to:
  /// **'Add New Quote'**
  String get adminAddQuote;

  /// No description provided for @adminEditQuote.
  ///
  /// In en, this message translates to:
  /// **'Edit Quote'**
  String get adminEditQuote;

  /// No description provided for @adminDeleteQuote.
  ///
  /// In en, this message translates to:
  /// **'Delete Quote?'**
  String get adminDeleteQuote;

  /// No description provided for @adminQuoteGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get adminQuoteGallery;

  /// No description provided for @adminQuoteRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get adminQuoteRandom;

  /// No description provided for @adminQuoteTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title (e.g. Study Break)'**
  String get adminQuoteTitleLabel;

  /// No description provided for @adminQuoteTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Quote Text'**
  String get adminQuoteTextLabel;

  /// No description provided for @adminAuthorOptional.
  ///
  /// In en, this message translates to:
  /// **'Author (Optional)'**
  String get adminAuthorOptional;

  /// No description provided for @adminQuoteUpdated.
  ///
  /// In en, this message translates to:
  /// **'Quote updated successfully'**
  String get adminQuoteUpdated;

  /// No description provided for @adminNoQuotesFound.
  ///
  /// In en, this message translates to:
  /// **'No quotes found. Add some to start the rotation!'**
  String get adminNoQuotesFound;

  /// No description provided for @adminMotivationalLibrary.
  ///
  /// In en, this message translates to:
  /// **'Motivational Content & Library'**
  String get adminMotivationalLibrary;

  /// No description provided for @adminQuestionBank.
  ///
  /// In en, this message translates to:
  /// **'Question Bank Management'**
  String get adminQuestionBank;

  /// No description provided for @adminSearchQuestions.
  ///
  /// In en, this message translates to:
  /// **'Search questions or topics...'**
  String get adminSearchQuestions;

  /// No description provided for @adminAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get adminAllTypes;

  /// No description provided for @adminSingleChoice.
  ///
  /// In en, this message translates to:
  /// **'Single choice'**
  String get adminSingleChoice;

  /// No description provided for @adminMultipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get adminMultipleChoice;

  /// No description provided for @adminTrueFalse.
  ///
  /// In en, this message translates to:
  /// **'True/False'**
  String get adminTrueFalse;

  /// No description provided for @adminMatching.
  ///
  /// In en, this message translates to:
  /// **'Matching'**
  String get adminMatching;

  /// No description provided for @adminRelational.
  ///
  /// In en, this message translates to:
  /// **'Relational'**
  String get adminRelational;

  /// No description provided for @adminLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get adminLevel;

  /// No description provided for @adminAllLevels.
  ///
  /// In en, this message translates to:
  /// **'All Levels'**
  String get adminAllLevels;

  /// No description provided for @adminAllSections.
  ///
  /// In en, this message translates to:
  /// **'All Sections'**
  String get adminAllSections;

  /// No description provided for @adminUnnamedSection.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Section'**
  String get adminUnnamedSection;

  /// No description provided for @adminManageSections.
  ///
  /// In en, this message translates to:
  /// **'Manage Sections'**
  String get adminManageSections;

  /// No description provided for @adminBatchUpload.
  ///
  /// In en, this message translates to:
  /// **'Batch Upload'**
  String get adminBatchUpload;

  /// No description provided for @adminNewEcg.
  ///
  /// In en, this message translates to:
  /// **'New ECG'**
  String get adminNewEcg;

  /// No description provided for @adminNewQuestion.
  ///
  /// In en, this message translates to:
  /// **'New Question'**
  String get adminNewQuestion;

  /// No description provided for @adminTableQuestionText.
  ///
  /// In en, this message translates to:
  /// **'Question Text'**
  String get adminTableQuestionText;

  /// No description provided for @adminTableBloom.
  ///
  /// In en, this message translates to:
  /// **'Bloom'**
  String get adminTableBloom;

  /// No description provided for @adminTableAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get adminTableAttempts;

  /// No description provided for @adminTableAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get adminTableAccuracy;

  /// No description provided for @adminTableId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get adminTableId;

  /// No description provided for @adminTableImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get adminTableImage;

  /// No description provided for @adminTableDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get adminTableDiagnosis;

  /// No description provided for @adminTableDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get adminTableDifficulty;

  /// No description provided for @adminQuestionDetails.
  ///
  /// In en, this message translates to:
  /// **'Question Details'**
  String get adminQuestionDetails;

  /// No description provided for @adminUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get adminUnknown;

  /// No description provided for @adminUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get adminUntitled;

  /// No description provided for @adminSubjectFallback.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get adminSubjectFallback;

  /// No description provided for @adminSectionFallback.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get adminSectionFallback;

  /// No description provided for @adminExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get adminExit;

  /// No description provided for @adminGoToGame.
  ///
  /// In en, this message translates to:
  /// **'GO TO GAME'**
  String get adminGoToGame;

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

  /// No description provided for @adminEcgTemplateApplied.
  ///
  /// In en, this message translates to:
  /// **'Template Applied! Autofilled fields are highlighted.'**
  String get adminEcgTemplateApplied;

  /// No description provided for @adminEcgDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get adminEcgDifficulty;

  /// No description provided for @adminEcgPrimaryDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Primary Diagnosis'**
  String get adminEcgPrimaryDiagnosis;

  /// No description provided for @adminEcgSecondaryDiagnoses.
  ///
  /// In en, this message translates to:
  /// **'Secondary Diagnoses'**
  String get adminEcgSecondaryDiagnoses;

  /// No description provided for @adminEcgPatientHistory.
  ///
  /// In en, this message translates to:
  /// **'0. Patient History (Optional)'**
  String get adminEcgPatientHistory;

  /// No description provided for @adminEcgSignalmentHistory.
  ///
  /// In en, this message translates to:
  /// **'Patient Signalment / History'**
  String get adminEcgSignalmentHistory;

  /// No description provided for @adminEcgHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 55M, chest pain for 2 hours...'**
  String get adminEcgHistoryHint;

  /// No description provided for @adminEcgRhythm.
  ///
  /// In en, this message translates to:
  /// **'1. Rhythm'**
  String get adminEcgRhythm;

  /// No description provided for @adminEcgRegularity.
  ///
  /// In en, this message translates to:
  /// **'Regularity'**
  String get adminEcgRegularity;

  /// No description provided for @adminEcgRatio.
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get adminEcgRatio;

  /// No description provided for @adminEcgSinusRhythm.
  ///
  /// In en, this message translates to:
  /// **'Sinus Rhythm?'**
  String get adminEcgSinusRhythm;

  /// No description provided for @adminEcgSinusHint.
  ///
  /// In en, this message translates to:
  /// **'P before QRS, positive in II'**
  String get adminEcgSinusHint;

  /// No description provided for @adminEcgHeartRate.
  ///
  /// In en, this message translates to:
  /// **'2. Heart Rate'**
  String get adminEcgHeartRate;

  /// No description provided for @adminEcgBpm.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate (BPM)'**
  String get adminEcgBpm;

  /// No description provided for @adminEcgRateHint.
  ///
  /// In en, this message translates to:
  /// **'Students get +/- 5 BPM grace zone'**
  String get adminEcgRateHint;

  /// No description provided for @adminEcgConduction.
  ///
  /// In en, this message translates to:
  /// **'3. Conduction'**
  String get adminEcgConduction;

  /// No description provided for @adminEcgPrInterval.
  ///
  /// In en, this message translates to:
  /// **'PR Interval'**
  String get adminEcgPrInterval;

  /// No description provided for @adminEcgQrsWidth.
  ///
  /// In en, this message translates to:
  /// **'QRS Width'**
  String get adminEcgQrsWidth;

  /// No description provided for @adminEcgQtInterval.
  ///
  /// In en, this message translates to:
  /// **'QT Interval'**
  String get adminEcgQtInterval;

  /// No description provided for @adminEcgAvBlock.
  ///
  /// In en, this message translates to:
  /// **'AV Block'**
  String get adminEcgAvBlock;

  /// No description provided for @adminEcgSaBlock.
  ///
  /// In en, this message translates to:
  /// **'SA Block'**
  String get adminEcgSaBlock;

  /// No description provided for @adminEcgBbb.
  ///
  /// In en, this message translates to:
  /// **'Bundle Branch Block'**
  String get adminEcgBbb;

  /// No description provided for @adminEcgAxis.
  ///
  /// In en, this message translates to:
  /// **'4. Axis'**
  String get adminEcgAxis;

  /// No description provided for @adminEcgHeartAxis.
  ///
  /// In en, this message translates to:
  /// **'Heart Axis'**
  String get adminEcgHeartAxis;

  /// No description provided for @adminEcgPwaveMorph.
  ///
  /// In en, this message translates to:
  /// **'5. P-Wave Morphology'**
  String get adminEcgPwaveMorph;

  /// No description provided for @adminEcgMorphology.
  ///
  /// In en, this message translates to:
  /// **'Morphology'**
  String get adminEcgMorphology;

  /// No description provided for @adminEcgAtrialEnlargement.
  ///
  /// In en, this message translates to:
  /// **'Atrial Enlargement'**
  String get adminEcgAtrialEnlargement;

  /// No description provided for @adminEcgQrsMorph.
  ///
  /// In en, this message translates to:
  /// **'6. QRS Morphology'**
  String get adminEcgQrsMorph;

  /// No description provided for @adminEcgHypertrophy.
  ///
  /// In en, this message translates to:
  /// **'Hypertrophy'**
  String get adminEcgHypertrophy;

  /// No description provided for @adminEcgPathQWaves.
  ///
  /// In en, this message translates to:
  /// **'Pathological Q Waves'**
  String get adminEcgPathQWaves;

  /// No description provided for @adminEcgStTMorph.
  ///
  /// In en, this message translates to:
  /// **'7. ST-T Morphology'**
  String get adminEcgStTMorph;

  /// No description provided for @adminEcgIschemia.
  ///
  /// In en, this message translates to:
  /// **'Ischemia/Infarction'**
  String get adminEcgIschemia;

  /// No description provided for @adminEcgTWave.
  ///
  /// In en, this message translates to:
  /// **'T-Wave'**
  String get adminEcgTWave;

  /// No description provided for @adminEcgIncludeManagement.
  ///
  /// In en, this message translates to:
  /// **'Include Step +2: Management & Urgency?'**
  String get adminEcgIncludeManagement;

  /// No description provided for @adminEcgIntermediateAdvancedOnly.
  ///
  /// In en, this message translates to:
  /// **'Only for intermediate/advanced cases'**
  String get adminEcgIntermediateAdvancedOnly;

  /// No description provided for @adminEcgUrgencyLevel.
  ///
  /// In en, this message translates to:
  /// **'Urgency Level'**
  String get adminEcgUrgencyLevel;

  /// No description provided for @adminEcgNotesNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Notes / Next Steps'**
  String get adminEcgNotesNextSteps;

  /// No description provided for @adminEcgManagementHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., Refer to Cardiology, Start Beta Blocker'**
  String get adminEcgManagementHint;

  /// No description provided for @adminEcgClickToUpload.
  ///
  /// In en, this message translates to:
  /// **'Click to upload ECG Strip'**
  String get adminEcgClickToUpload;

  /// No description provided for @adminEcgAddSecondaryDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Add Secondary Diagnosis'**
  String get adminEcgAddSecondaryDiagnosis;

  /// No description provided for @adminEcgSaveCase.
  ///
  /// In en, this message translates to:
  /// **'Save 7+2 Case'**
  String get adminEcgSaveCase;

  /// No description provided for @adminEcgNoneTapToAdd.
  ///
  /// In en, this message translates to:
  /// **'None (Tap to add)'**
  String get adminEcgNoneTapToAdd;

  /// No description provided for @adminEcgRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get adminEcgRegular;

  /// No description provided for @adminEcgIrregular.
  ///
  /// In en, this message translates to:
  /// **'Irregular'**
  String get adminEcgIrregular;

  /// No description provided for @adminEcgIrregularlyIrregular.
  ///
  /// In en, this message translates to:
  /// **'Irregularly Irregular'**
  String get adminEcgIrregularlyIrregular;

  /// No description provided for @adminEcgNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get adminEcgNormal;

  /// No description provided for @adminEcgProlonged.
  ///
  /// In en, this message translates to:
  /// **'Prolonged'**
  String get adminEcgProlonged;

  /// No description provided for @adminEcgShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get adminEcgShort;

  /// No description provided for @adminEcgNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get adminEcgNone;

  /// No description provided for @adminEcgDifficultyBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get adminEcgDifficultyBeginner;

  /// No description provided for @adminEcgDifficultyIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get adminEcgDifficultyIntermediate;

  /// No description provided for @adminEcgDifficultyAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get adminEcgDifficultyAdvanced;

  /// No description provided for @adminExplanationLabel.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get adminExplanationLabel;

  /// No description provided for @adminOptionsSelectCorrect.
  ///
  /// In en, this message translates to:
  /// **'Options (Select all correct ones)'**
  String get adminOptionsSelectCorrect;

  /// No description provided for @adminOptionIndex.
  ///
  /// In en, this message translates to:
  /// **'Option {index}'**
  String adminOptionIndex(Object index);

  /// No description provided for @adminAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get adminAddOption;

  /// No description provided for @adminSetCorrectLogic.
  ///
  /// In en, this message translates to:
  /// **'Set Correct Logic'**
  String get adminSetCorrectLogic;

  /// No description provided for @adminCommonKnowledgeGap.
  ///
  /// In en, this message translates to:
  /// **'Common Knowledge Gap'**
  String get adminCommonKnowledgeGap;

  /// No description provided for @adminHighFailureRateWarning.
  ///
  /// In en, this message translates to:
  /// **'High failure rate detected. Consider reviewing wording.'**
  String get adminHighFailureRateWarning;

  /// No description provided for @adminCommonlyConfusedWith.
  ///
  /// In en, this message translates to:
  /// **'COMMONLY CONFUSED WITH:'**
  String get adminCommonlyConfusedWith;

  /// No description provided for @adminConfirmDeleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete question #{id}? This cannot be undone if students have already answered it.'**
  String adminConfirmDeleteQuestion(Object id);

  /// No description provided for @adminErrorQuestionDeleteLinked.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete: Question has linked responses.'**
  String get adminErrorQuestionDeleteLinked;

  /// No description provided for @adminConfirmDeleteECG.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete ECG #{id}?'**
  String adminConfirmDeleteECG(Object id);

  /// No description provided for @adminErrorDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get adminErrorDeleteFailed;

  /// No description provided for @adminStatement1True.
  ///
  /// In en, this message translates to:
  /// **'Statement 1 is TRUE'**
  String get adminStatement1True;

  /// No description provided for @adminStatement2True.
  ///
  /// In en, this message translates to:
  /// **'Statement 2 is TRUE'**
  String get adminStatement2True;

  /// No description provided for @adminConnectionExists.
  ///
  /// In en, this message translates to:
  /// **'Connection / Link Exists (Because...)'**
  String get adminConnectionExists;

  /// No description provided for @adminMatchingPairs.
  ///
  /// In en, this message translates to:
  /// **'1-to-1 Matching Pairs'**
  String get adminMatchingPairs;

  /// No description provided for @adminAddPair.
  ///
  /// In en, this message translates to:
  /// **'Add Pair'**
  String get adminAddPair;

  /// No description provided for @adminLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'Left {index}'**
  String adminLeftLabel(Object index);

  /// No description provided for @adminRightLabel.
  ///
  /// In en, this message translates to:
  /// **'Right {index}'**
  String adminRightLabel(Object index);

  /// No description provided for @adminRenameSection.
  ///
  /// In en, this message translates to:
  /// **'Rename Section'**
  String get adminRenameSection;

  /// No description provided for @adminTrue.
  ///
  /// In en, this message translates to:
  /// **'TRUE'**
  String get adminTrue;

  /// No description provided for @adminFalse.
  ///
  /// In en, this message translates to:
  /// **'FALSE'**
  String get adminFalse;

  /// No description provided for @adminTranslationFailed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed: {error}'**
  String adminTranslationFailed(Object error);

  /// No description provided for @adminSourceFieldEmpty.
  ///
  /// In en, this message translates to:
  /// **'Source field is empty!'**
  String get adminSourceFieldEmpty;

  /// No description provided for @adminSaveQuestion.
  ///
  /// In en, this message translates to:
  /// **'Save Question'**
  String get adminSaveQuestion;

  /// No description provided for @adminErrorQuestionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save question'**
  String get adminErrorQuestionSaveFailed;

  /// No description provided for @adminSearchCommandsHint.
  ///
  /// In en, this message translates to:
  /// **'Search commands (@user, #question)...'**
  String get adminSearchCommandsHint;

  /// No description provided for @adminKeyboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get adminKeyboardShortcuts;

  /// No description provided for @adminNavigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get adminNavigate;

  /// No description provided for @adminSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get adminSelect;

  /// No description provided for @adminClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get adminClose;

  /// No description provided for @adminPowerCenter.
  ///
  /// In en, this message translates to:
  /// **'Admin Power Center'**
  String get adminPowerCenter;

  /// No description provided for @adminNoMatchingCommands.
  ///
  /// In en, this message translates to:
  /// **'No matching commands or data found'**
  String get adminNoMatchingCommands;

  /// No description provided for @adminCommandGoToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get adminCommandGoToDashboard;

  /// No description provided for @adminCommandGoToQuestions.
  ///
  /// In en, this message translates to:
  /// **'Go to Questions'**
  String get adminCommandGoToQuestions;

  /// No description provided for @adminCommandGoToUsers.
  ///
  /// In en, this message translates to:
  /// **'Go to Users'**
  String get adminCommandGoToUsers;

  /// No description provided for @adminCommandGoToQuotes.
  ///
  /// In en, this message translates to:
  /// **'Go to Quotes'**
  String get adminCommandGoToQuotes;

  /// No description provided for @adminCommandExitAdmin.
  ///
  /// In en, this message translates to:
  /// **'Exit Admin'**
  String get adminCommandExitAdmin;

  /// No description provided for @adminJumpToUser.
  ///
  /// In en, this message translates to:
  /// **'JUMP TO USER'**
  String get adminJumpToUser;

  /// No description provided for @adminJumpToQuestion.
  ///
  /// In en, this message translates to:
  /// **'JUMP TO Q'**
  String get adminJumpToQuestion;

  /// No description provided for @adminF10Help.
  ///
  /// In en, this message translates to:
  /// **'F10 for help'**
  String get adminF10Help;

  /// No description provided for @adminBackToCommands.
  ///
  /// In en, this message translates to:
  /// **'Back to commands'**
  String get adminBackToCommands;

  /// No description provided for @adminShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing'**
  String get adminShowing;

  /// No description provided for @adminVersion.
  ///
  /// In en, this message translates to:
  /// **'version'**
  String get adminVersion;

  /// No description provided for @adminQuestionType.
  ///
  /// In en, this message translates to:
  /// **'Question Type'**
  String get adminQuestionType;

  /// No description provided for @adminBloomCriteria.
  ///
  /// In en, this message translates to:
  /// **'Bloom Criteria'**
  String get adminBloomCriteria;

  /// No description provided for @adminSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get adminSubject;

  /// No description provided for @adminSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get adminSection;

  /// No description provided for @adminErrorSelectSubject.
  ///
  /// In en, this message translates to:
  /// **'Please select a Subject'**
  String get adminErrorSelectSubject;

  /// No description provided for @adminErrorSelectSection.
  ///
  /// In en, this message translates to:
  /// **'Please select a Section'**
  String get adminErrorSelectSection;

  /// No description provided for @adminAutoFill.
  ///
  /// In en, this message translates to:
  /// **'Auto Fill'**
  String get adminAutoFill;

  /// No description provided for @adminEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get adminEnglish;

  /// No description provided for @adminHungarian.
  ///
  /// In en, this message translates to:
  /// **'Hungarian'**
  String get adminHungarian;

  /// No description provided for @adminSelectQuestion.
  ///
  /// In en, this message translates to:
  /// **'Select question'**
  String get adminSelectQuestion;

  /// No description provided for @adminDifficultyShort.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get adminDifficultyShort;

  /// No description provided for @adminAddQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get adminAddQuestion;

  /// No description provided for @adminEditQuestion.
  ///
  /// In en, this message translates to:
  /// **'Edit Question'**
  String get adminEditQuestion;

  /// No description provided for @adminQuestionBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Question Bank Management'**
  String get adminQuestionBankTitle;

  /// No description provided for @adminQuestionsSmall.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get adminQuestionsSmall;

  /// No description provided for @adminManageSectionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage Sections'**
  String get adminManageSectionsTooltip;

  /// No description provided for @adminBatchUploadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Batch Upload'**
  String get adminBatchUploadTooltip;

  /// No description provided for @adminNewECG.
  ///
  /// In en, this message translates to:
  /// **'New ECG'**
  String get adminNewECG;

  /// No description provided for @adminNotificationBroadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Broadcast Notification'**
  String get adminNotificationBroadcastTitle;

  /// No description provided for @adminNotificationBroadcastDesc.
  ///
  /// In en, this message translates to:
  /// **'This will send a push notification and in-app message to all students.'**
  String get adminNotificationBroadcastDesc;

  /// No description provided for @adminNotificationLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Title'**
  String get adminNotificationLabelTitle;

  /// No description provided for @adminNotificationLabelMessage.
  ///
  /// In en, this message translates to:
  /// **'Message Body'**
  String get adminNotificationLabelMessage;

  /// No description provided for @adminNotificationHintTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. New pathology quiz live!'**
  String get adminNotificationHintTitle;

  /// No description provided for @adminNotificationHintMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the notification content here...'**
  String get adminNotificationHintMessage;

  /// No description provided for @adminNoEcgCasesFound.
  ///
  /// In en, this message translates to:
  /// **'No ECG cases found.'**
  String get adminNoEcgCasesFound;

  /// No description provided for @adminNoDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available.'**
  String get adminNoDataAvailable;

  /// No description provided for @adminItems.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get adminItems;

  /// No description provided for @adminSuccessQuestionsMoved.
  ///
  /// In en, this message translates to:
  /// **'Questions moved successfully'**
  String get adminSuccessQuestionsMoved;

  /// No description provided for @adminErrorMoveQuestions.
  ///
  /// In en, this message translates to:
  /// **'Failed to move questions'**
  String get adminErrorMoveQuestions;

  /// No description provided for @adminYesDeleteEverything.
  ///
  /// In en, this message translates to:
  /// **'YES, DELETE EVERYTHING'**
  String get adminYesDeleteEverything;

  /// No description provided for @adminNoAnalyticsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No analytics available'**
  String get adminNoAnalyticsAvailable;

  /// No description provided for @adminNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention:'**
  String get adminNeedsAttention;

  /// No description provided for @adminLivePreview.
  ///
  /// In en, this message translates to:
  /// **'LIVE PREVIEW'**
  String get adminLivePreview;

  /// No description provided for @adminSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send Now'**
  String get adminSendNow;

  /// No description provided for @adminErrorFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get adminErrorFillAllFields;

  /// No description provided for @adminSuccessNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent successfully!'**
  String get adminSuccessNotificationSent;

  /// No description provided for @adminSelectAnItem.
  ///
  /// In en, this message translates to:
  /// **'Select an item'**
  String get adminSelectAnItem;

  /// No description provided for @adminTableType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminTableType;

  /// No description provided for @adminTableSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get adminTableSection;

  /// No description provided for @adminBatchUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch Upload Questions'**
  String get adminBatchUploadTitle;

  /// No description provided for @adminBatchUploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload an Excel (.xlsx) or CSV file to add multiple questions at once.'**
  String get adminBatchUploadSubtitle;

  /// No description provided for @adminPreparationLabel.
  ///
  /// In en, this message translates to:
  /// **'Preparation:'**
  String get adminPreparationLabel;

  /// No description provided for @adminPreparationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use our template to ensure correct formatting and dropdowns.'**
  String get adminPreparationSubtitle;

  /// No description provided for @adminDownloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download Excel Template'**
  String get adminDownloadTemplate;

  /// No description provided for @adminChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File & Upload'**
  String get adminChooseFile;

  /// No description provided for @adminErrorReadBytes.
  ///
  /// In en, this message translates to:
  /// **'Could not read file bytes.'**
  String get adminErrorReadBytes;

  /// No description provided for @adminProcessingUpload.
  ///
  /// In en, this message translates to:
  /// **'Processing Upload'**
  String get adminProcessingUpload;

  /// No description provided for @adminUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload Failed'**
  String get adminUploadFailed;

  /// No description provided for @adminUploadComplete.
  ///
  /// In en, this message translates to:
  /// **'Upload Complete'**
  String get adminUploadComplete;

  /// No description provided for @adminParsing.
  ///
  /// In en, this message translates to:
  /// **'Parsing'**
  String get adminParsing;

  /// No description provided for @adminUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully uploaded {count} questions.'**
  String adminUploadSuccess(Object count);

  /// No description provided for @adminItemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} items selected'**
  String adminItemsSelected(Object count);

  /// No description provided for @adminClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get adminClearSelection;

  /// No description provided for @adminMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move To'**
  String get adminMoveTo;

  /// No description provided for @adminDeleteBatch.
  ///
  /// In en, this message translates to:
  /// **'Delete Batch'**
  String get adminDeleteBatch;

  /// No description provided for @adminConfirmBatchDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Batch Delete'**
  String get adminConfirmBatchDelete;

  /// No description provided for @adminConfirmBatchDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} questions? This cannot be undone if they have no responses.'**
  String adminConfirmBatchDeleteSubtitle(Object count);

  /// No description provided for @adminDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get adminDeleteAll;

  /// No description provided for @adminSuccessDeletedCount.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} questions'**
  String adminSuccessDeletedCount(Object count);

  /// No description provided for @adminErrorDeleteBulk.
  ///
  /// In en, this message translates to:
  /// **'Delete failed (some questions might have responses)'**
  String get adminErrorDeleteBulk;

  /// No description provided for @adminMoveQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Move Questions to Topic'**
  String get adminMoveQuestionsTitle;

  /// No description provided for @adminMoveQuestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select target topic for {count} questions:'**
  String adminMoveQuestionsSubtitle(Object count);

  /// No description provided for @adminTargetTopic.
  ///
  /// In en, this message translates to:
  /// **'Target Topic'**
  String get adminTargetTopic;

  /// No description provided for @adminMoveNow.
  ///
  /// In en, this message translates to:
  /// **'Move Now'**
  String get adminMoveNow;

  /// No description provided for @adminErrorSectionNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'English Section name cannot be empty'**
  String get adminErrorSectionNameEmpty;

  /// No description provided for @adminSuccessSectionCreated.
  ///
  /// In en, this message translates to:
  /// **'Section created successfully'**
  String get adminSuccessSectionCreated;

  /// No description provided for @adminErrorSectionCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create section'**
  String get adminErrorSectionCreateFailed;

  /// No description provided for @adminDeleteSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Section'**
  String get adminDeleteSectionTitle;

  /// No description provided for @adminConfirmDeleteSection.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \'{name}\'?'**
  String adminConfirmDeleteSection(Object name);

  /// No description provided for @adminConfirmDataLossTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Data Loss'**
  String get adminConfirmDataLossTitle;

  /// No description provided for @adminDeleteSectionWarning.
  ///
  /// In en, this message translates to:
  /// **'Deleting this section will PERMANENTLY delete all questions within it. This action cannot be undone.'**
  String get adminDeleteSectionWarning;

  /// No description provided for @adminConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure?'**
  String get adminConfirmAction;

  /// No description provided for @adminSuccessSectionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Section deleted successfully'**
  String get adminSuccessSectionDeleted;

  /// No description provided for @adminManageSectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Sections'**
  String get adminManageSectionsTitle;

  /// No description provided for @adminSectionNameEnLabel.
  ///
  /// In en, this message translates to:
  /// **'Section Name (EN)'**
  String get adminSectionNameEnLabel;

  /// No description provided for @adminSectionNameHuLabel.
  ///
  /// In en, this message translates to:
  /// **'Section Name (HU)'**
  String get adminSectionNameHuLabel;

  /// No description provided for @adminAddSection.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get adminAddSection;

  /// No description provided for @adminExistingSections.
  ///
  /// In en, this message translates to:
  /// **'Existing Sections'**
  String get adminExistingSections;

  /// No description provided for @adminNoSectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sections yet. Create one above!'**
  String get adminNoSectionsYet;

  /// No description provided for @adminRenameSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Rename Section ({lang})'**
  String adminRenameSectionLabel(Object lang);

  /// No description provided for @adminQuotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage motivational quotes and gallery images'**
  String get adminQuotesSubtitle;

  /// No description provided for @adminManageIcons.
  ///
  /// In en, this message translates to:
  /// **'Manage Icons'**
  String get adminManageIcons;

  /// No description provided for @adminEcgSelectDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Please select a primary diagnosis'**
  String get adminEcgSelectDiagnosis;

  /// No description provided for @adminEcgUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Please upload an ECG strip'**
  String get adminEcgUploadImage;

  /// No description provided for @adminEcgUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed'**
  String get adminEcgUploadFailed;

  /// No description provided for @adminEcgNewCase.
  ///
  /// In en, this message translates to:
  /// **'New 7+2 ECG Case'**
  String get adminEcgNewCase;

  /// No description provided for @adminEcgEditCase.
  ///
  /// In en, this message translates to:
  /// **'Edit 7+2 Case'**
  String get adminEcgEditCase;

  /// No description provided for @adminRequired.
  ///
  /// In en, this message translates to:
  /// **'Field is required'**
  String get adminRequired;

  /// No description provided for @quizTypeSingleChoice.
  ///
  /// In en, this message translates to:
  /// **'Single Choice'**
  String get quizTypeSingleChoice;

  /// No description provided for @quizTypeMultipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple Choice'**
  String get quizTypeMultipleChoice;

  /// No description provided for @quizTypeTrueFalse.
  ///
  /// In en, this message translates to:
  /// **'True/False'**
  String get quizTypeTrueFalse;

  /// No description provided for @quizTypeMatching.
  ///
  /// In en, this message translates to:
  /// **'Matching'**
  String get quizTypeMatching;

  /// No description provided for @quizTypeRelational.
  ///
  /// In en, this message translates to:
  /// **'Relational Analysis'**
  String get quizTypeRelational;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;
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
