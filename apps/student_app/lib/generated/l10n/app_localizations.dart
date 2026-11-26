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

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authLearn.
  ///
  /// In en, this message translates to:
  /// **'Professional Medical Learning'**
  String get authLearn;

  /// No description provided for @authIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get authIdentifier;

  /// No description provided for @authRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get authRequired;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShow;

  /// No description provided for @authHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHide;

  /// No description provided for @authShort.
  ///
  /// In en, this message translates to:
  /// **'Too short'**
  String get authShort;

  /// No description provided for @authForgotLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotLink;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authNoAccount;

  /// No description provided for @authCreateLink.
  ///
  /// In en, this message translates to:
  /// **'Create One'**
  String get authCreateLink;

  /// No description provided for @authForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get authForgot;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetTitle;

  /// No description provided for @authEmailPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get authEmailPrompt;

  /// No description provided for @authCodePrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get authCodePrompt;

  /// No description provided for @authResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful! Please login.'**
  String get authResetSuccess;

  /// No description provided for @authTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get authTryAgain;

  /// No description provided for @authResetHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a 6-digit reset code.'**
  String get authResetHelp;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authOtp.
  ///
  /// In en, this message translates to:
  /// **'6-digit OTP'**
  String get authOtp;

  /// No description provided for @authShowNew.
  ///
  /// In en, this message translates to:
  /// **'Show new password'**
  String get authShowNew;

  /// No description provided for @authHideNew.
  ///
  /// In en, this message translates to:
  /// **'Hide new password'**
  String get authHideNew;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get authSendCode;

  /// No description provided for @authReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get authReset;

  /// No description provided for @authJoin.
  ///
  /// In en, this message translates to:
  /// **'Join ArborMed'**
  String get authJoin;

  /// No description provided for @authJourney.
  ///
  /// In en, this message translates to:
  /// **'Start your medical journey'**
  String get authJourney;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authHandle.
  ///
  /// In en, this message translates to:
  /// **'Medical Handle (@username)'**
  String get authHandle;

  /// No description provided for @authUserRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get authUserRequired;

  /// No description provided for @authDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get authDisplayName;

  /// No description provided for @authDisplayRequired.
  ///
  /// In en, this message translates to:
  /// **'Display name is required'**
  String get authDisplayRequired;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// No description provided for @authMinLength.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters'**
  String get authMinLength;

  /// No description provided for @authUpper.
  ///
  /// In en, this message translates to:
  /// **'Missing uppercase letter'**
  String get authUpper;

  /// No description provided for @authNumber.
  ///
  /// In en, this message translates to:
  /// **'Missing number'**
  String get authNumber;

  /// No description provided for @authSpecial.
  ///
  /// In en, this message translates to:
  /// **'Missing special character'**
  String get authSpecial;

  /// No description provided for @authCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreate;

  /// No description provided for @authExisting.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authExisting;

  /// No description provided for @authCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email}'**
  String authCodeSent(String email);

  /// No description provided for @authRegFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration Failed: {reason}'**
  String authRegFailed(String reason);

  /// No description provided for @quizPreparingSystem.
  ///
  /// In en, this message translates to:
  /// **'Preparing {system}'**
  String quizPreparingSystem(String system);

  /// No description provided for @quizLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the quiz'**
  String get quizLoadFailed;

  /// No description provided for @quizLoadRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Return to the previous screen and try again.'**
  String get quizLoadRetryHint;

  /// No description provided for @quizSelectAllCorrect.
  ///
  /// In en, this message translates to:
  /// **'Select all correct answers.'**
  String get quizSelectAllCorrect;

  /// No description provided for @adminMatchingRepairKey.
  ///
  /// In en, this message translates to:
  /// **'The stored answer disagrees with these pairs. Save the displayed pairs as the new answer key.'**
  String get adminMatchingRepairKey;

  /// No description provided for @adminMatchingMinimum.
  ///
  /// In en, this message translates to:
  /// **'Enter at least two pairs.'**
  String get adminMatchingMinimum;

  /// No description provided for @adminMatchingDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This label must be unique in its column.'**
  String get adminMatchingDuplicate;

  /// No description provided for @quizMatchPairs.
  ///
  /// In en, this message translates to:
  /// **'Match the pairs.'**
  String get quizMatchPairs;

  /// No description provided for @quizPairedWith.
  ///
  /// In en, this message translates to:
  /// **'Paired with {term}'**
  String quizPairedWith(String term);

  /// No description provided for @quizNoOptions.
  ///
  /// In en, this message translates to:
  /// **'No options available'**
  String get quizNoOptions;

  /// No description provided for @quizEnlargeImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to enlarge image'**
  String get quizEnlargeImage;

  /// No description provided for @mistakeReviewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the mistakes for this period. Try again.'**
  String get mistakeReviewLoadFailed;

  /// No description provided for @dailyQuests.
  ///
  /// In en, this message translates to:
  /// **'Daily quests'**
  String get dailyQuests;

  /// No description provided for @subjectMastery.
  ///
  /// In en, this message translates to:
  /// **'Subject mastery'**
  String get subjectMastery;

  /// No description provided for @analyticsTab.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTab;

  /// No description provided for @activityTab.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTab;

  /// No description provided for @questEmpty.
  ///
  /// In en, this message translates to:
  /// **'No daily quests available.'**
  String get questEmpty;

  /// No description provided for @questClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get questClaim;

  /// No description provided for @questAward.
  ///
  /// In en, this message translates to:
  /// **'You earned {count} tokens.'**
  String questAward(int count);

  /// No description provided for @questClaimFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm the reward. Check the refreshed quest list.'**
  String get questClaimFailed;

  /// No description provided for @questRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh daily quests.'**
  String get questRefreshFailed;

  /// No description provided for @activityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load activity for this period.'**
  String get activityLoadFailed;

  /// No description provided for @masteryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load subject mastery.'**
  String get masteryLoadFailed;

  /// No description provided for @masteryNoSections.
  ///
  /// In en, this message translates to:
  /// **'No sections available for this subject.'**
  String get masteryNoSections;

  /// No description provided for @masteryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No subjects available.'**
  String get masteryEmpty;

  /// No description provided for @activityActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Active days'**
  String get activityActiveDays;

  /// No description provided for @activityMonthIntensity.
  ///
  /// In en, this message translates to:
  /// **'Monthly intensity'**
  String get activityMonthIntensity;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity data for this period.'**
  String get activityEmpty;

  /// No description provided for @activityLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get activityLess;

  /// No description provided for @activityMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get activityMore;

  /// No description provided for @activityCorrectCount.
  ///
  /// In en, this message translates to:
  /// **'{count} correct'**
  String activityCorrectCount(int count);

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

  /// No description provided for @duelArena.
  ///
  /// In en, this message translates to:
  /// **'Duel Arena'**
  String get duelArena;

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

  /// No description provided for @adminSearchStudents.
  ///
  /// In en, this message translates to:
  /// **'Search by student ID or email'**
  String get adminSearchStudents;

  /// No description provided for @adminSearchAdmins.
  ///
  /// In en, this message translates to:
  /// **'Search by email'**
  String get adminSearchAdmins;

  /// No description provided for @adminDirectoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the user list.'**
  String get adminDirectoryLoadFailed;

  /// No description provided for @adminHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this student’s study history.'**
  String get adminHistoryLoadFailed;

  /// No description provided for @adminNoStudyHistory.
  ///
  /// In en, this message translates to:
  /// **'No quiz answers recorded yet.'**
  String get adminNoStudyHistory;

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

  /// No description provided for @adminNoRecordedActivity.
  ///
  /// In en, this message translates to:
  /// **'No recorded activity'**
  String get adminNoRecordedActivity;

  /// No description provided for @adminCaseStudies.
  ///
  /// In en, this message translates to:
  /// **'Case studies'**
  String get adminCaseStudies;

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

  /// No description provided for @relationAnswerA.
  ///
  /// In en, this message translates to:
  /// **'Both statements are true, and there is a causal link between them.'**
  String get relationAnswerA;

  /// No description provided for @relationAnswerB.
  ///
  /// In en, this message translates to:
  /// **'Both statements are true, but there is no causal link between them.'**
  String get relationAnswerB;

  /// No description provided for @relationAnswerC.
  ///
  /// In en, this message translates to:
  /// **'Only the first statement is true.'**
  String get relationAnswerC;

  /// No description provided for @relationAnswerD.
  ///
  /// In en, this message translates to:
  /// **'Only the second statement is true.'**
  String get relationAnswerD;

  /// No description provided for @relationAnswerE.
  ///
  /// In en, this message translates to:
  /// **'Both statements are false.'**
  String get relationAnswerE;

  /// No description provided for @quizUnsupportedQuestionType.
  ///
  /// In en, this message translates to:
  /// **'This question type is not supported.'**
  String get quizUnsupportedQuestionType;

  /// No description provided for @quizIncompleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'This question is incomplete.'**
  String get quizIncompleteQuestion;

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

  /// No description provided for @adminAnswerKeyUnresolved.
  ///
  /// In en, this message translates to:
  /// **'Could not identify the correct answer'**
  String get adminAnswerKeyUnresolved;

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

  /// No description provided for @adminFirstStatement.
  ///
  /// In en, this message translates to:
  /// **'First statement'**
  String get adminFirstStatement;

  /// No description provided for @adminSecondStatement.
  ///
  /// In en, this message translates to:
  /// **'Second statement'**
  String get adminSecondStatement;

  /// No description provided for @adminLinkWord.
  ///
  /// In en, this message translates to:
  /// **'Linking word'**
  String get adminLinkWord;

  /// No description provided for @adminTranslationDraftChanged.
  ///
  /// In en, this message translates to:
  /// **'The draft changed during translation. Translate again to apply it.'**
  String get adminTranslationDraftChanged;

  /// No description provided for @adminEcgCaseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ECG case} other{{count} ECG cases}}'**
  String adminEcgCaseCount(int count);

  /// No description provided for @adminQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String adminQuestionCount(int count);

  /// No description provided for @adminEcgLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load ECG cases.'**
  String get adminEcgLoadFailed;

  /// No description provided for @adminEcgSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save ECG case.'**
  String get adminEcgSaveFailed;

  /// No description provided for @adminEcgDiagnosesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load diagnoses.'**
  String get adminEcgDiagnosesLoadFailed;

  /// No description provided for @adminEcgInvalidRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive whole number for heart rate.'**
  String get adminEcgInvalidRate;

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

  /// No description provided for @adminQuotesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load quotes.'**
  String get adminQuotesLoadFailed;

  /// No description provided for @adminQuoteSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the quote.'**
  String get adminQuoteSaveFailed;

  /// No description provided for @adminQuestionReports.
  ///
  /// In en, this message translates to:
  /// **'Question reports'**
  String get adminQuestionReports;

  /// No description provided for @adminReportsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load reports for this question.'**
  String get adminReportsLoadFailed;

  /// No description provided for @adminReportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reports for this question.'**
  String get adminReportsEmpty;

  /// No description provided for @adminIgnoreReport.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get adminIgnoreReport;

  /// No description provided for @adminResolveReport.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get adminResolveReport;

  /// No description provided for @adminReportUpdated.
  ///
  /// In en, this message translates to:
  /// **'Report updated.'**
  String get adminReportUpdated;

  /// No description provided for @adminReportUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the report.'**
  String get adminReportUpdateFailed;

  /// No description provided for @adminBroadcastFailed.
  ///
  /// In en, this message translates to:
  /// **'Delivery could not be confirmed. You can retry this message.'**
  String get adminBroadcastFailed;

  /// No description provided for @adminBroadcastDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered to student inboxes: {count}'**
  String adminBroadcastDelivered(int count);

  /// No description provided for @adminExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the report.'**
  String get adminExportFailed;

  /// No description provided for @adminExportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No question data available to export.'**
  String get adminExportUnavailable;

  /// No description provided for @adminNotificationBroadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Broadcast Notification'**
  String get adminNotificationBroadcastTitle;

  /// No description provided for @adminNotificationBroadcastDesc.
  ///
  /// In en, this message translates to:
  /// **'Send an in-app message to every student’s inbox.'**
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

  /// No description provided for @adminImportFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Select a file of up to 5 MiB.'**
  String get adminImportFileTooLarge;

  /// No description provided for @adminImportWithErrors.
  ///
  /// In en, this message translates to:
  /// **'Import completed with errors'**
  String get adminImportWithErrors;

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

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyEmailTitle;

  /// No description provided for @verificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Verification Required'**
  String get verificationRequired;

  /// No description provided for @verificationSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit verification code to:\n{email}'**
  String verificationSentTo(String email);

  /// No description provided for @verificationEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get verificationEnterCode;

  /// No description provided for @verificationContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verificationContinue;

  /// No description provided for @verificationResend.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get verificationResend;

  /// No description provided for @verificationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get verificationSuccess;

  /// No description provided for @verificationResent.
  ///
  /// In en, this message translates to:
  /// **'Verification code resent!'**
  String get verificationResent;

  /// No description provided for @verificationRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the request. Try again.'**
  String get verificationRetry;

  /// No description provided for @verificationRestart.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get verificationRestart;

  /// No description provided for @verificationWait.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get verificationWait;

  /// No description provided for @verificationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Verification is temporarily unavailable. Try again later.'**
  String get verificationUnavailable;

  /// No description provided for @verificationChanged.
  ///
  /// In en, this message translates to:
  /// **'This verification request has changed. Start again.'**
  String get verificationChanged;

  /// No description provided for @verificationSignOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not finish signing out on this device. Try again.'**
  String get verificationSignOutFailed;

  /// No description provided for @duelSelectWager.
  ///
  /// In en, this message translates to:
  /// **'Select Wager'**
  String get duelSelectWager;

  /// No description provided for @duelChooseWager.
  ///
  /// In en, this message translates to:
  /// **'Choose your bet for the knowledge battle:'**
  String get duelChooseWager;

  /// No description provided for @duelFindMatch.
  ///
  /// In en, this message translates to:
  /// **'Find Match'**
  String get duelFindMatch;

  /// No description provided for @duelSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching for opponent...'**
  String get duelSearching;

  /// No description provided for @duelWagerAmount.
  ///
  /// In en, this message translates to:
  /// **'Wager: {amount} 🩺'**
  String duelWagerAmount(int amount);

  /// No description provided for @duelWalletAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} Stethoscopes'**
  String duelWalletAmount(int amount);

  /// No description provided for @duelLowBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance is too low for this wager.'**
  String get duelLowBalance;

  /// No description provided for @duelRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh your balance. Try again.'**
  String get duelRefreshFailed;

  /// No description provided for @duelLeaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm leaving the queue. Try again.'**
  String get duelLeaveFailed;

  /// No description provided for @profileRefreshRetry.
  ///
  /// In en, this message translates to:
  /// **'Profile refresh failed. Retry'**
  String get profileRefreshRetry;

  /// No description provided for @nicknameLength.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname between 1 and 255 characters.'**
  String get nicknameLength;

  /// No description provided for @nicknameSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your nickname. Try again.'**
  String get nicknameSaveFailed;

  /// No description provided for @profileSessionChanged.
  ///
  /// In en, this message translates to:
  /// **'Your active account has changed. Close this editor.'**
  String get profileSessionChanged;

  /// No description provided for @roundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily clinical rounds'**
  String get roundsTitle;

  /// No description provided for @roundsConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Today’s rounds are complete.'**
  String get roundsConfirmed;

  /// No description provided for @roundsRequirement.
  ///
  /// In en, this message translates to:
  /// **'Give {goal} correct answers during the UTC day to complete your rounds.'**
  String roundsRequirement(int goal);

  /// No description provided for @roundsProgressCount.
  ///
  /// In en, this message translates to:
  /// **'{progress} / {goal} correct answers'**
  String roundsProgressCount(int progress, int goal);

  /// No description provided for @roundsPractice.
  ///
  /// In en, this message translates to:
  /// **'Start practice'**
  String get roundsPractice;

  /// No description provided for @roundsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm daily rounds'**
  String get roundsConfirm;

  /// No description provided for @roundsRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not verify clinical standing. Retry'**
  String get roundsRetry;

  /// No description provided for @roundsStrikes.
  ///
  /// In en, this message translates to:
  /// **'Strikes: {count}'**
  String roundsStrikes(int count);

  /// No description provided for @roundsProbation.
  ///
  /// In en, this message translates to:
  /// **'Clinical probation'**
  String get roundsProbation;

  /// No description provided for @roundsSubjectStats.
  ///
  /// In en, this message translates to:
  /// **'Subject responses: {count} · {percent}% correct'**
  String roundsSubjectStats(int count, int percent);

  /// No description provided for @roundsNoResponses.
  ///
  /// In en, this message translates to:
  /// **'No recorded subject responses yet.'**
  String get roundsNoResponses;

  /// No description provided for @roundsSummaryRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load subject results. Retry'**
  String get roundsSummaryRetry;

  /// No description provided for @roundsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh progress'**
  String get roundsRefresh;

  /// No description provided for @quizFallbackQuote.
  ///
  /// In en, this message translates to:
  /// **'Clear mind, focused goals.'**
  String get quizFallbackQuote;

  /// No description provided for @quizPracticeSubject.
  ///
  /// In en, this message translates to:
  /// **'Practise this subject'**
  String get quizPracticeSubject;

  /// No description provided for @quizSectionsRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load sections. Retry'**
  String get quizSectionsRetry;

  /// No description provided for @quizNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No active questions yet'**
  String get quizNoQuestions;

  /// No description provided for @quizReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart review'**
  String get quizReviewTitle;

  /// No description provided for @quizReadinessRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load readiness. Retry'**
  String get quizReadinessRetry;

  /// No description provided for @quizNoReadiness.
  ///
  /// In en, this message translates to:
  /// **'Complete a quiz to see your readiness.'**
  String get quizNoReadiness;

  /// No description provided for @quizReadyPercent.
  ///
  /// In en, this message translates to:
  /// **'Readiness {score}%'**
  String quizReadyPercent(int score);

  /// No description provided for @quizRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Topics to review'**
  String get quizRecommendations;

  /// No description provided for @quizReviewRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load recommendations. Retry'**
  String get quizReviewRetry;

  /// No description provided for @quizReviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No topics to review right now.'**
  String get quizReviewEmpty;

  /// No description provided for @quizRetention.
  ///
  /// In en, this message translates to:
  /// **'Estimated retention {percent}%'**
  String quizRetention(int percent);

  /// No description provided for @quizDaysSince.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Less than one day ago} =1{One day ago} other{{days} days since practice}}'**
  String quizDaysSince(int days);

  /// No description provided for @quizReviewSessionEnded.
  ///
  /// In en, this message translates to:
  /// **'This review belonged to your previous login.'**
  String get quizReviewSessionEnded;
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
