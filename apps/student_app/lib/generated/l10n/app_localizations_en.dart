// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ArborMed';

  @override
  String get authLogin => 'Login';

  @override
  String get authLearn => 'Professional Medical Learning';

  @override
  String get authIdentifier => 'Email or Username';

  @override
  String get authRequired => 'Required';

  @override
  String get authPassword => 'Password';

  @override
  String get authShow => 'Show password';

  @override
  String get authHide => 'Hide password';

  @override
  String get authShort => 'Too short';

  @override
  String get authForgotLink => 'Forgot Password?';

  @override
  String get authNoAccount => 'Don\'t have an account? ';

  @override
  String get authCreateLink => 'Create One';

  @override
  String get authForgot => 'Forgot Password';

  @override
  String get authResetTitle => 'Reset Password';

  @override
  String get authEmailPrompt => 'Enter your email address.';

  @override
  String get authCodePrompt => 'Enter the 6-digit code.';

  @override
  String get authResetSuccess => 'Password reset successful! Please login.';

  @override
  String get authTryAgain => 'Please try again.';

  @override
  String get authResetHelp =>
      'Enter your email to receive a 6-digit reset code.';

  @override
  String get authEmail => 'Email';

  @override
  String get authOtp => '6-digit OTP';

  @override
  String get authShowNew => 'Show new password';

  @override
  String get authHideNew => 'Hide new password';

  @override
  String get authSendCode => 'Send Code';

  @override
  String get authReset => 'Reset';

  @override
  String get authJoin => 'Join ArborMed';

  @override
  String get authJourney => 'Start your medical journey';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authEmailInvalid => 'Please enter a valid email address';

  @override
  String get authHandle => 'Medical Handle (@username)';

  @override
  String get authUserRequired => 'Username is required';

  @override
  String get authDisplayName => 'Display Name';

  @override
  String get authDisplayRequired => 'Display name is required';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authMinLength => 'Min 8 characters';

  @override
  String get authUpper => 'Missing uppercase letter';

  @override
  String get authNumber => 'Missing number';

  @override
  String get authSpecial => 'Missing special character';

  @override
  String get authCreate => 'Create Account';

  @override
  String get authExisting => 'Already have an account? ';

  @override
  String authCodeSent(String email) {
    return 'Code sent to $email';
  }

  @override
  String authRegFailed(String reason) {
    return 'Registration Failed: $reason';
  }

  @override
  String quizPreparingSystem(String system) {
    return 'Preparing $system';
  }

  @override
  String get quizLoadFailed => 'Could not load the quiz';

  @override
  String get quizLoadRetryHint =>
      'Return to the previous screen and try again.';

  @override
  String get quizSelectAllCorrect => 'Select all correct answers.';

  @override
  String get quizNoOptions => 'No options available';

  @override
  String get quizEnlargeImage => 'Tap to enlarge image';

  @override
  String get mistakeReviewLoadFailed =>
      'Could not load the mistakes for this period. Try again.';

  @override
  String get dailyQuests => 'Daily quests';

  @override
  String get subjectMastery => 'Subject mastery';

  @override
  String get analyticsTab => 'Analytics';

  @override
  String get activityTab => 'Activity';

  @override
  String get questEmpty => 'No daily quests available.';

  @override
  String get questClaim => 'Claim';

  @override
  String questAward(int count) {
    return 'You earned $count tokens.';
  }

  @override
  String get questClaimFailed =>
      'Could not confirm the reward. Check the refreshed quest list.';

  @override
  String get questRefreshFailed => 'Could not refresh daily quests.';

  @override
  String get activityLoadFailed => 'Could not load activity for this period.';

  @override
  String get masteryLoadFailed => 'Could not load subject mastery.';

  @override
  String get masteryNoSections => 'No sections available for this subject.';

  @override
  String get masteryEmpty => 'No subjects available.';

  @override
  String get activityActiveDays => 'Active days';

  @override
  String get activityMonthIntensity => 'Monthly intensity';

  @override
  String get activityEmpty => 'No activity data for this period.';

  @override
  String get activityLess => 'Less';

  @override
  String get activityMore => 'More';

  @override
  String activityCorrectCount(int count) {
    return '$count correct';
  }

  @override
  String get quizStart => 'Start Quiz';

  @override
  String get quizContinue => 'Continue';

  @override
  String get quizSubmit => 'Submit Answer';

  @override
  String get quizNext => 'Next Question';

  @override
  String get quizFinish => 'Finish Quiz';

  @override
  String get quizCorrect => 'Correct!';

  @override
  String get quizIncorrect => 'Incorrect';

  @override
  String get quizScore => 'Score';

  @override
  String get quizResults => 'Quiz Results';

  @override
  String get quizStudyBreak => 'Study Break';

  @override
  String get quizStartSession => 'Start Session';

  @override
  String get quizSelectSubject => 'Select Subject';

  @override
  String get quizComingSoon => 'Coming Soon...';

  @override
  String get quizSubjectPathophysiology => 'Pathophysiology';

  @override
  String get quizSubjectPathology => 'Pathology';

  @override
  String get quizSubjectMicrobiology => 'Microbiology';

  @override
  String get quizSubjectPharmacology => 'Pharmacology';

  @override
  String get quizLastStudied => 'LAST STUDIED';

  @override
  String get quizQuoteTopic => 'Choose your focus for today.';

  @override
  String get quizSubjects => 'Subjects';

  @override
  String get quizECG => 'ECG';

  @override
  String get duelArena => 'Duel Arena';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHungarian => 'Hungarian';

  @override
  String get audio => 'Audio';

  @override
  String get music => 'Music';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get about => 'About';

  @override
  String get shop => 'Shop';

  @override
  String get inventory => 'Inventory';

  @override
  String get profile => 'Profile';

  @override
  String get friends => 'Friends';

  @override
  String get stats => 'Statistics';

  @override
  String get logout => 'Logout';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get coins => 'Coins';

  @override
  String get xp => 'XP';

  @override
  String get level => 'Level';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get retry => 'Retry';

  @override
  String get autoTranslate => 'Auto-translate';

  @override
  String get reviewTranslation => 'Review Translation';

  @override
  String get translating => 'Translating...';

  @override
  String get translationFailed => 'Translation failed';

  @override
  String get questionText => 'Question';

  @override
  String get explanation => 'Explanation';

  @override
  String get options => 'Options';

  @override
  String get correctAnswer => 'Correct Answer';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get topic => 'Topic';

  @override
  String get admin => 'Admin';

  @override
  String get questions => 'Questions';

  @override
  String get createQuestion => 'Create Question';

  @override
  String get editQuestion => 'Edit Question';

  @override
  String get deleteQuestion => 'Delete Question';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get aboutApp => 'ABOUT APP';

  @override
  String get musicVolume => 'Music Volume';

  @override
  String get selectTrack => 'Select Track';

  @override
  String get themeMode => 'Appearance';

  @override
  String get notifications => 'Notifications';

  @override
  String get signOut => 'Sign Out';

  @override
  String get adminPanel => 'Admin';

  @override
  String get appVersion => 'v0.1.0 Beta';

  @override
  String get appDescription =>
      'ArborMed is an educational companion designed for medical students to master theory through gamification.';

  @override
  String get appMission =>
      'By blending evidence-based learning with a cozy, stress-free environment, we help students tackle complex core medical subjects effectively.';

  @override
  String get createdBy => 'CREATED BY';

  @override
  String get vision => 'VISION';

  @override
  String get visionStatement =>
      'Transforming medical education into a delightful, rewarding daily habit.';

  @override
  String get copyright => '© 2026 ArborMed Team';

  @override
  String get accountSettings => 'ACCOUNT SETTINGS';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm New Password';

  @override
  String get update => 'UPDATE';

  @override
  String get passwordsDoNotMatch => 'New passwords do not match';

  @override
  String get passwordChanged => 'Password changed successfully';

  @override
  String get changeNickname => 'Change Nickname';

  @override
  String get nicknameHint =>
      'This name will be visible to other doctors in the Medical Network.';

  @override
  String get enterNickname => 'Enter your nickname...';

  @override
  String get nicknameUpdated => 'Nickname updated!';

  @override
  String get medicalId => 'MEDICAL ID';

  @override
  String get streak => 'STREAK';

  @override
  String get pager => 'PAGER';

  @override
  String get network => 'NETWORK';

  @override
  String get searchColleagues => 'Search colleagues...';

  @override
  String get noDoctorsFound => 'No doctors found';

  @override
  String get consultRequests => 'CONSULT REQUESTS';

  @override
  String get colleagues => 'COLLEAGUES';

  @override
  String get noColleaguesYet => 'No colleagues yet. Search for your peers!';

  @override
  String get removeColleague => 'Remove Colleague?';

  @override
  String areYouSureRemove(Object username) {
    return 'Are you sure you want to remove $username from your network?';
  }

  @override
  String get remove => 'REMOVE';

  @override
  String get sent => 'SENT';

  @override
  String get adminAlert => 'ADMIN ALERT';

  @override
  String get peerNote => 'PEER NOTE';

  @override
  String get from => 'From';

  @override
  String get deleteMessage => 'Delete Message?';

  @override
  String get deleteMessageConfirm =>
      'This record will be permanently removed from your pager.';

  @override
  String get yourPagerIsSilent => 'Your pager is silent.';

  @override
  String get activityTrend => 'ACTIVITY TREND';

  @override
  String get dailyPrescription => 'DAILY PRESCRIPTION';

  @override
  String get goalAchieved => 'GOAL ACHIEVED!';

  @override
  String get dailyDoseComplete => 'Daily dose complete.';

  @override
  String needMoreToday(Object count) {
    return 'Need $count more today.';
  }

  @override
  String get mistakeReview => 'MISTAKE REVIEW';

  @override
  String reviewMistakes(Object count) {
    return 'Review $count failed questions.';
  }

  @override
  String get start => 'START';

  @override
  String get consistency => 'CONSISTENCY';

  @override
  String get day => 'DAY';

  @override
  String get week => 'WEEK';

  @override
  String get month => 'MONTH';

  @override
  String get noMistakes => 'No mistakes found to review in this period!';

  @override
  String get days => 'days';

  @override
  String get logoutOfflineWarningTitle => 'OFFLINE LOGOUT';

  @override
  String get logoutOfflineWarningMessage =>
      'You are offline and have unsynced data. Logging out now will permanently clear these local changes. Continue?';

  @override
  String get confirmLogoutLabel => 'LOGOUT ANYWAY';

  @override
  String get adminDashboard => 'Dashboard';

  @override
  String get adminUsers => 'Users';

  @override
  String get adminQuotes => 'Quotes';

  @override
  String get adminQuestions => 'Questions';

  @override
  String get adminSettings => 'Settings';

  @override
  String get adminSemester => 'Autumn Semester 2026';

  @override
  String get adminTotalUsers => 'TOTAL USERS';

  @override
  String get adminRegisteredStudents => 'Registered students';

  @override
  String get adminClassAvg => 'CLASS AVG';

  @override
  String get adminOverallCorrectness => 'Overall correctness';

  @override
  String get adminAvgBloom => 'AVG BLOOM LEVEL';

  @override
  String get adminPedagogicalDepth => 'Pedagogical depth';

  @override
  String get adminTopicProficiency => 'Topic Proficiency';

  @override
  String get adminDetails => 'DETAILS';

  @override
  String get adminNoDataSubject => 'No data available for this subject';

  @override
  String get adminSuccessRate => 'Success Rate';

  @override
  String get adminAvgTime => 'Avg Time';

  @override
  String get adminSuccessRatePercent => 'Success Rate (%)';

  @override
  String get adminAvgTimeSec => 'Avg Time Spent (sec)';

  @override
  String get adminQuickActions => 'Quick Actions';

  @override
  String get adminImport => 'Import';

  @override
  String get adminReport => 'Report';

  @override
  String get adminNotification => 'Notification';

  @override
  String get adminStudents => 'Students';

  @override
  String get adminAdministrators => 'Administrators';

  @override
  String get adminMedicalRegistry => 'Medical Student Registry & Performance';

  @override
  String get adminQuestionsUploaded => 'Questions Uploaded';

  @override
  String adminByAdmins(Object count) {
    return 'by $count Admins';
  }

  @override
  String get adminActiveUsers => 'Active Users';

  @override
  String get adminNoUsersFound => 'No users found';

  @override
  String get adminSearchById => 'Search by ID';

  @override
  String get adminSearchStudents => 'Search by student ID or email';

  @override
  String get adminSearchAdmins => 'Search by email';

  @override
  String get adminDirectoryLoadFailed => 'Could not load the user list.';

  @override
  String get adminHistoryLoadFailed =>
      'Could not load this student’s study history.';

  @override
  String get adminNoStudyHistory => 'No quiz answers recorded yet.';

  @override
  String get adminStudentAccount => 'Student Account';

  @override
  String get adminNoSubjectAssigned => 'No Subject Assigned';

  @override
  String get adminViewPerformance => 'View Performance History';

  @override
  String get adminTableActivity => 'ACTIVITY';

  @override
  String get adminTableActions => 'Actions';

  @override
  String get adminSendPager => 'Send Pager Message';

  @override
  String get adminPromoteAdmin => 'Promote to Admin';

  @override
  String get adminDemoteStudent => 'Demote to Student';

  @override
  String get adminDeleteUser => 'Delete User';

  @override
  String adminPagerTitle(Object identifier) {
    return 'PAGER: $identifier';
  }

  @override
  String get adminTypePagerMessage => 'Type your message to the student...';

  @override
  String get adminMessageDispatched => 'Message dispatched!';

  @override
  String get adminChangeRole => 'Change Role?';

  @override
  String adminConfirmRoleChange(Object identifier, Object role) {
    return 'Are you sure you want to change $identifier\'s role to $role?';
  }

  @override
  String get adminUserRoleUpdated => 'User role updated!';

  @override
  String get adminDeleteUserTitle => 'Permanently Delete User?';

  @override
  String adminDeleteUserConfirm(Object identifier) {
    return 'This will erase ALL progress for $identifier. This action cannot be undone.';
  }

  @override
  String get adminDoctorRemoved => 'Doctor removed from registry.';

  @override
  String get adminClickHistory => 'Click for history';

  @override
  String get adminNoRecordedActivity => 'No recorded activity';

  @override
  String get adminCaseStudies => 'Case studies';

  @override
  String adminPageOf(Object current, Object total) {
    return 'Page $current of $total';
  }

  @override
  String get adminAddQuote => 'Add New Quote';

  @override
  String get adminEditQuote => 'Edit Quote';

  @override
  String get adminDeleteQuote => 'Delete Quote?';

  @override
  String get adminQuoteGallery => 'Gallery';

  @override
  String get adminQuoteRandom => 'Random';

  @override
  String get adminQuoteTitleLabel => 'Title (e.g. Study Break)';

  @override
  String get adminQuoteTextLabel => 'Quote Text';

  @override
  String get adminAuthorOptional => 'Author (Optional)';

  @override
  String get adminQuoteUpdated => 'Quote updated successfully';

  @override
  String get adminNoQuotesFound =>
      'No quotes found. Add some to start the rotation!';

  @override
  String get adminMotivationalLibrary => 'Motivational Content & Library';

  @override
  String get adminQuestionBank => 'Question Bank Management';

  @override
  String get adminSearchQuestions => 'Search questions or topics...';

  @override
  String get adminAllTypes => 'All Types';

  @override
  String get adminSingleChoice => 'Single choice';

  @override
  String get adminMultipleChoice => 'Multiple choice';

  @override
  String get adminTrueFalse => 'True/False';

  @override
  String get adminMatching => 'Matching';

  @override
  String get adminRelational => 'Relational';

  @override
  String get adminLevel => 'Level';

  @override
  String get adminAllLevels => 'All Levels';

  @override
  String get adminAllSections => 'All Sections';

  @override
  String get adminUnnamedSection => 'Unnamed Section';

  @override
  String get adminManageSections => 'Manage Sections';

  @override
  String get adminBatchUpload => 'Batch Upload';

  @override
  String get adminNewEcg => 'New ECG';

  @override
  String get adminNewQuestion => 'New Question';

  @override
  String get adminTableQuestionText => 'Question Text';

  @override
  String get adminTableBloom => 'Bloom';

  @override
  String get adminTableAttempts => 'Attempts';

  @override
  String get adminTableAccuracy => 'Accuracy';

  @override
  String get adminTableId => 'ID';

  @override
  String get adminTableImage => 'Image';

  @override
  String get adminTableDiagnosis => 'Diagnosis';

  @override
  String get adminTableDifficulty => 'Difficulty';

  @override
  String get adminQuestionDetails => 'Question Details';

  @override
  String get adminUnknown => 'Unknown';

  @override
  String get adminAnswerKeyUnresolved =>
      'Could not identify the correct answer';

  @override
  String get adminUntitled => 'Untitled';

  @override
  String get adminSubjectFallback => 'Subject';

  @override
  String get adminSectionFallback => 'Section';

  @override
  String get adminExit => 'Exit';

  @override
  String get adminGoToGame => 'GO TO GAME';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get adminEcgTemplateApplied =>
      'Template Applied! Autofilled fields are highlighted.';

  @override
  String get adminEcgDifficulty => 'Difficulty';

  @override
  String get adminEcgPrimaryDiagnosis => 'Primary Diagnosis';

  @override
  String get adminEcgSecondaryDiagnoses => 'Secondary Diagnoses';

  @override
  String get adminEcgPatientHistory => '0. Patient History (Optional)';

  @override
  String get adminEcgSignalmentHistory => 'Patient Signalment / History';

  @override
  String get adminEcgHistoryHint => 'e.g. 55M, chest pain for 2 hours...';

  @override
  String get adminEcgRhythm => '1. Rhythm';

  @override
  String get adminEcgRegularity => 'Regularity';

  @override
  String get adminEcgRatio => 'Ratio';

  @override
  String get adminEcgSinusRhythm => 'Sinus Rhythm?';

  @override
  String get adminEcgSinusHint => 'P before QRS, positive in II';

  @override
  String get adminEcgHeartRate => '2. Heart Rate';

  @override
  String get adminFirstStatement => 'First statement';

  @override
  String get adminSecondStatement => 'Second statement';

  @override
  String get adminLinkWord => 'Linking word';

  @override
  String get adminTranslationDraftChanged =>
      'The draft changed during translation. Translate again to apply it.';

  @override
  String adminEcgCaseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ECG cases',
      one: '1 ECG case',
    );
    return '$_temp0';
  }

  @override
  String adminQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String get adminEcgLoadFailed => 'Could not load ECG cases.';

  @override
  String get adminEcgSaveFailed => 'Failed to save ECG case.';

  @override
  String get adminEcgDiagnosesLoadFailed => 'Could not load diagnoses.';

  @override
  String get adminEcgInvalidRate =>
      'Enter a positive whole number for heart rate.';

  @override
  String get adminEcgBpm => 'Heart Rate (BPM)';

  @override
  String get adminEcgRateHint => 'Students get +/- 5 BPM grace zone';

  @override
  String get adminEcgConduction => '3. Conduction';

  @override
  String get adminEcgPrInterval => 'PR Interval';

  @override
  String get adminEcgQrsWidth => 'QRS Width';

  @override
  String get adminEcgQtInterval => 'QT Interval';

  @override
  String get adminEcgAvBlock => 'AV Block';

  @override
  String get adminEcgSaBlock => 'SA Block';

  @override
  String get adminEcgBbb => 'Bundle Branch Block';

  @override
  String get adminEcgAxis => '4. Axis';

  @override
  String get adminEcgHeartAxis => 'Heart Axis';

  @override
  String get adminEcgPwaveMorph => '5. P-Wave Morphology';

  @override
  String get adminEcgMorphology => 'Morphology';

  @override
  String get adminEcgAtrialEnlargement => 'Atrial Enlargement';

  @override
  String get adminEcgQrsMorph => '6. QRS Morphology';

  @override
  String get adminEcgHypertrophy => 'Hypertrophy';

  @override
  String get adminEcgPathQWaves => 'Pathological Q Waves';

  @override
  String get adminEcgStTMorph => '7. ST-T Morphology';

  @override
  String get adminEcgIschemia => 'Ischemia/Infarction';

  @override
  String get adminEcgTWave => 'T-Wave';

  @override
  String get adminEcgIncludeManagement =>
      'Include Step +2: Management & Urgency?';

  @override
  String get adminEcgIntermediateAdvancedOnly =>
      'Only for intermediate/advanced cases';

  @override
  String get adminEcgUrgencyLevel => 'Urgency Level';

  @override
  String get adminEcgNotesNextSteps => 'Notes / Next Steps';

  @override
  String get adminEcgManagementHint =>
      'E.g., Refer to Cardiology, Start Beta Blocker';

  @override
  String get adminEcgClickToUpload => 'Click to upload ECG Strip';

  @override
  String get adminEcgAddSecondaryDiagnosis => 'Add Secondary Diagnosis';

  @override
  String get adminEcgSaveCase => 'Save 7+2 Case';

  @override
  String get adminEcgNoneTapToAdd => 'None (Tap to add)';

  @override
  String get adminEcgRegular => 'Regular';

  @override
  String get adminEcgIrregular => 'Irregular';

  @override
  String get adminEcgIrregularlyIrregular => 'Irregularly Irregular';

  @override
  String get adminEcgNormal => 'Normal';

  @override
  String get adminEcgProlonged => 'Prolonged';

  @override
  String get adminEcgShort => 'Short';

  @override
  String get adminEcgNone => 'None';

  @override
  String get adminEcgDifficultyBeginner => 'Beginner';

  @override
  String get adminEcgDifficultyIntermediate => 'Intermediate';

  @override
  String get adminEcgDifficultyAdvanced => 'Advanced';

  @override
  String get adminExplanationLabel => 'Explanation';

  @override
  String get adminOptionsSelectCorrect => 'Options (Select all correct ones)';

  @override
  String adminOptionIndex(Object index) {
    return 'Option $index';
  }

  @override
  String get adminAddOption => 'Add Option';

  @override
  String get adminSetCorrectLogic => 'Set Correct Logic';

  @override
  String get adminCommonKnowledgeGap => 'Common Knowledge Gap';

  @override
  String get adminHighFailureRateWarning =>
      'High failure rate detected. Consider reviewing wording.';

  @override
  String get adminCommonlyConfusedWith => 'COMMONLY CONFUSED WITH:';

  @override
  String adminConfirmDeleteQuestion(Object id) {
    return 'Are you sure you want to delete question #$id? This cannot be undone if students have already answered it.';
  }

  @override
  String get adminErrorQuestionDeleteLinked =>
      'Cannot delete: Question has linked responses.';

  @override
  String adminConfirmDeleteECG(Object id) {
    return 'Are you sure you want to delete ECG #$id?';
  }

  @override
  String get adminErrorDeleteFailed => 'Delete failed';

  @override
  String get adminStatement1True => 'Statement 1 is TRUE';

  @override
  String get adminStatement2True => 'Statement 2 is TRUE';

  @override
  String get adminConnectionExists => 'Connection / Link Exists (Because...)';

  @override
  String get adminMatchingPairs => '1-to-1 Matching Pairs';

  @override
  String get adminAddPair => 'Add Pair';

  @override
  String adminLeftLabel(Object index) {
    return 'Left $index';
  }

  @override
  String adminRightLabel(Object index) {
    return 'Right $index';
  }

  @override
  String get adminRenameSection => 'Rename Section';

  @override
  String get adminTrue => 'TRUE';

  @override
  String get adminFalse => 'FALSE';

  @override
  String adminTranslationFailed(Object error) {
    return 'Translation failed: $error';
  }

  @override
  String get adminSourceFieldEmpty => 'Source field is empty!';

  @override
  String get adminSaveQuestion => 'Save Question';

  @override
  String get adminErrorQuestionSaveFailed => 'Failed to save question';

  @override
  String get adminSearchCommandsHint => 'Search commands (@user, #question)...';

  @override
  String get adminKeyboardShortcuts => 'Keyboard Shortcuts';

  @override
  String get adminNavigate => 'Navigate';

  @override
  String get adminSelect => 'Select';

  @override
  String get adminClose => 'Close';

  @override
  String get adminPowerCenter => 'Admin Power Center';

  @override
  String get adminNoMatchingCommands => 'No matching commands or data found';

  @override
  String get adminCommandGoToDashboard => 'Go to Dashboard';

  @override
  String get adminCommandGoToQuestions => 'Go to Questions';

  @override
  String get adminCommandGoToUsers => 'Go to Users';

  @override
  String get adminCommandGoToQuotes => 'Go to Quotes';

  @override
  String get adminCommandExitAdmin => 'Exit Admin';

  @override
  String get adminJumpToUser => 'JUMP TO USER';

  @override
  String get adminJumpToQuestion => 'JUMP TO Q';

  @override
  String get adminF10Help => 'F10 for help';

  @override
  String get adminBackToCommands => 'Back to commands';

  @override
  String get adminShowing => 'Showing';

  @override
  String get adminVersion => 'version';

  @override
  String get adminQuestionType => 'Question Type';

  @override
  String get adminBloomCriteria => 'Bloom Criteria';

  @override
  String get adminSubject => 'Subject';

  @override
  String get adminSection => 'Section';

  @override
  String get adminErrorSelectSubject => 'Please select a Subject';

  @override
  String get adminErrorSelectSection => 'Please select a Section';

  @override
  String get adminAutoFill => 'Auto Fill';

  @override
  String get adminEnglish => 'English';

  @override
  String get adminHungarian => 'Hungarian';

  @override
  String get adminSelectQuestion => 'Select question';

  @override
  String get adminDifficultyShort => 'Diff';

  @override
  String get adminAddQuestion => 'Add Question';

  @override
  String get adminEditQuestion => 'Edit Question';

  @override
  String get adminQuestionBankTitle => 'Question Bank Management';

  @override
  String get adminQuestionsSmall => 'Questions';

  @override
  String get adminManageSectionsTooltip => 'Manage Sections';

  @override
  String get adminBatchUploadTooltip => 'Batch Upload';

  @override
  String get adminNewECG => 'New ECG';

  @override
  String get adminQuotesLoadFailed => 'Could not load quotes.';

  @override
  String get adminQuoteSaveFailed => 'Could not save the quote.';

  @override
  String get adminQuestionReports => 'Question reports';

  @override
  String get adminReportsLoadFailed =>
      'Could not load reports for this question.';

  @override
  String get adminReportsEmpty => 'No reports for this question.';

  @override
  String get adminIgnoreReport => 'Ignore';

  @override
  String get adminResolveReport => 'Resolve';

  @override
  String get adminReportUpdated => 'Report updated.';

  @override
  String get adminReportUpdateFailed => 'Could not update the report.';

  @override
  String get adminBroadcastFailed =>
      'Delivery could not be confirmed. You can retry this message.';

  @override
  String adminBroadcastDelivered(int count) {
    return 'Delivered to student inboxes: $count';
  }

  @override
  String get adminExportFailed => 'Could not save the report.';

  @override
  String get adminExportUnavailable => 'No question data available to export.';

  @override
  String get adminNotificationBroadcastTitle => 'Send Broadcast Notification';

  @override
  String get adminNotificationBroadcastDesc =>
      'Send an in-app message to every student’s inbox.';

  @override
  String get adminNotificationLabelTitle => 'Notification Title';

  @override
  String get adminNotificationLabelMessage => 'Message Body';

  @override
  String get adminNotificationHintTitle => 'e.g. New pathology quiz live!';

  @override
  String get adminNotificationHintMessage =>
      'Enter the notification content here...';

  @override
  String get adminNoEcgCasesFound => 'No ECG cases found.';

  @override
  String get adminNoDataAvailable => 'No data available.';

  @override
  String get adminItems => 'items';

  @override
  String get adminSuccessQuestionsMoved => 'Questions moved successfully';

  @override
  String get adminErrorMoveQuestions => 'Failed to move questions';

  @override
  String get adminYesDeleteEverything => 'YES, DELETE EVERYTHING';

  @override
  String get adminNoAnalyticsAvailable => 'No analytics available';

  @override
  String get adminNeedsAttention => 'Needs Attention:';

  @override
  String get adminLivePreview => 'LIVE PREVIEW';

  @override
  String get adminSendNow => 'Send Now';

  @override
  String get adminErrorFillAllFields => 'Please fill all fields';

  @override
  String get adminSuccessNotificationSent => 'Notification sent successfully!';

  @override
  String get adminSelectAnItem => 'Select an item';

  @override
  String get adminTableType => 'Type';

  @override
  String get adminTableSection => 'Section';

  @override
  String get adminBatchUploadTitle => 'Batch Upload Questions';

  @override
  String get adminBatchUploadSubtitle =>
      'Upload an Excel (.xlsx) or CSV file to add multiple questions at once.';

  @override
  String get adminPreparationLabel => 'Preparation:';

  @override
  String get adminPreparationSubtitle =>
      'Use our template to ensure correct formatting and dropdowns.';

  @override
  String get adminDownloadTemplate => 'Download Excel Template';

  @override
  String get adminChooseFile => 'Choose File & Upload';

  @override
  String get adminErrorReadBytes => 'Could not read file bytes.';

  @override
  String get adminProcessingUpload => 'Processing Upload';

  @override
  String get adminUploadFailed => 'Upload Failed';

  @override
  String get adminImportFileTooLarge => 'Select a file of up to 5 MiB.';

  @override
  String get adminImportWithErrors => 'Import completed with errors';

  @override
  String get adminUploadComplete => 'Upload Complete';

  @override
  String get adminParsing => 'Parsing';

  @override
  String adminUploadSuccess(Object count) {
    return 'Successfully uploaded $count questions.';
  }

  @override
  String adminItemsSelected(Object count) {
    return '$count items selected';
  }

  @override
  String get adminClearSelection => 'Clear Selection';

  @override
  String get adminMoveTo => 'Move To';

  @override
  String get adminDeleteBatch => 'Delete Batch';

  @override
  String get adminConfirmBatchDelete => 'Confirm Batch Delete';

  @override
  String adminConfirmBatchDeleteSubtitle(Object count) {
    return 'Are you sure you want to delete $count questions? This cannot be undone if they have no responses.';
  }

  @override
  String get adminDeleteAll => 'Delete All';

  @override
  String adminSuccessDeletedCount(Object count) {
    return 'Deleted $count questions';
  }

  @override
  String get adminErrorDeleteBulk =>
      'Delete failed (some questions might have responses)';

  @override
  String get adminMoveQuestionsTitle => 'Move Questions to Topic';

  @override
  String adminMoveQuestionsSubtitle(Object count) {
    return 'Select target topic for $count questions:';
  }

  @override
  String get adminTargetTopic => 'Target Topic';

  @override
  String get adminMoveNow => 'Move Now';

  @override
  String get adminErrorSectionNameEmpty =>
      'English Section name cannot be empty';

  @override
  String get adminSuccessSectionCreated => 'Section created successfully';

  @override
  String get adminErrorSectionCreateFailed => 'Failed to create section';

  @override
  String get adminDeleteSectionTitle => 'Delete Section';

  @override
  String adminConfirmDeleteSection(Object name) {
    return 'Are you sure you want to delete \'$name\'?';
  }

  @override
  String get adminConfirmDataLossTitle => 'Confirm Data Loss';

  @override
  String get adminDeleteSectionWarning =>
      'Deleting this section will PERMANENTLY delete all questions within it. This action cannot be undone.';

  @override
  String get adminConfirmAction => 'Are you absolutely sure?';

  @override
  String get adminSuccessSectionDeleted => 'Section deleted successfully';

  @override
  String get adminManageSectionsTitle => 'Manage Sections';

  @override
  String get adminSectionNameEnLabel => 'Section Name (EN)';

  @override
  String get adminSectionNameHuLabel => 'Section Name (HU)';

  @override
  String get adminAddSection => 'Add Section';

  @override
  String get adminExistingSections => 'Existing Sections';

  @override
  String get adminNoSectionsYet => 'No sections yet. Create one above!';

  @override
  String adminRenameSectionLabel(Object lang) {
    return 'Rename Section ($lang)';
  }

  @override
  String get adminQuotesSubtitle =>
      'Manage motivational quotes and gallery images';

  @override
  String get adminManageIcons => 'Manage Icons';

  @override
  String get adminEcgSelectDiagnosis => 'Please select a primary diagnosis';

  @override
  String get adminEcgUploadImage => 'Please upload an ECG strip';

  @override
  String get adminEcgUploadFailed => 'Image upload failed';

  @override
  String get adminEcgNewCase => 'New 7+2 ECG Case';

  @override
  String get adminEcgEditCase => 'Edit 7+2 Case';

  @override
  String get adminRequired => 'Field is required';

  @override
  String get quizTypeSingleChoice => 'Single Choice';

  @override
  String get quizTypeMultipleChoice => 'Multiple Choice';

  @override
  String get quizTypeTrueFalse => 'True/False';

  @override
  String get quizTypeMatching => 'Matching';

  @override
  String get quizTypeRelational => 'Relational Analysis';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get verifyEmailTitle => 'Verify Your Email';

  @override
  String get verificationRequired => 'Verification Required';

  @override
  String verificationSentTo(String email) {
    return 'We sent a 6-digit verification code to:\n$email';
  }

  @override
  String get verificationEnterCode => 'Enter 6-digit code';

  @override
  String get verificationContinue => 'Verify & Continue';

  @override
  String get verificationResend => 'Resend Code';

  @override
  String get verificationSuccess => 'Email verified successfully!';

  @override
  String get verificationResent => 'Verification code resent!';

  @override
  String get verificationRetry => 'Could not complete the request. Try again.';

  @override
  String get verificationRestart => 'Start again';

  @override
  String get verificationWait => 'Too many requests. Please try again later.';

  @override
  String get verificationUnavailable =>
      'Verification is temporarily unavailable. Try again later.';

  @override
  String get verificationChanged =>
      'This verification request has changed. Start again.';

  @override
  String get verificationSignOutFailed =>
      'Could not finish signing out on this device. Try again.';

  @override
  String get duelSelectWager => 'Select Wager';

  @override
  String get duelChooseWager => 'Choose your bet for the knowledge battle:';

  @override
  String get duelFindMatch => 'Find Match';

  @override
  String get duelSearching => 'Searching for opponent...';

  @override
  String duelWagerAmount(int amount) {
    return 'Wager: $amount 🩺';
  }

  @override
  String duelWalletAmount(int amount) {
    return '$amount Stethoscopes';
  }

  @override
  String get duelLowBalance => 'Your balance is too low for this wager.';

  @override
  String get duelRefreshFailed => 'Could not refresh your balance. Try again.';

  @override
  String get duelLeaveFailed =>
      'Could not confirm leaving the queue. Try again.';

  @override
  String get profileRefreshRetry => 'Profile refresh failed. Retry';

  @override
  String get nicknameLength => 'Enter a nickname between 1 and 255 characters.';

  @override
  String get nicknameSaveFailed => 'Could not save your nickname. Try again.';

  @override
  String get profileSessionChanged =>
      'Your active account has changed. Close this editor.';

  @override
  String get roundsTitle => 'Daily clinical rounds';

  @override
  String get roundsConfirmed => 'Today’s rounds are complete.';

  @override
  String roundsRequirement(int goal) {
    return 'Give $goal correct answers during the UTC day to complete your rounds.';
  }

  @override
  String roundsProgressCount(int progress, int goal) {
    return '$progress / $goal correct answers';
  }

  @override
  String get roundsPractice => 'Start practice';

  @override
  String get roundsConfirm => 'Confirm daily rounds';

  @override
  String get roundsRetry => 'Could not verify clinical standing. Retry';

  @override
  String roundsStrikes(int count) {
    return 'Strikes: $count';
  }

  @override
  String get roundsProbation => 'Clinical probation';

  @override
  String roundsSubjectStats(int count, int percent) {
    return 'Subject responses: $count · $percent% correct';
  }

  @override
  String get roundsNoResponses => 'No recorded subject responses yet.';

  @override
  String get roundsSummaryRetry => 'Could not load subject results. Retry';

  @override
  String get roundsRefresh => 'Refresh progress';

  @override
  String get quizFallbackQuote => 'Clear mind, focused goals.';

  @override
  String get quizPracticeSubject => 'Practise this subject';

  @override
  String get quizSectionsRetry => 'Could not load sections. Retry';

  @override
  String get quizNoQuestions => 'No active questions yet';

  @override
  String get quizReviewTitle => 'Smart review';

  @override
  String get quizReadinessRetry => 'Could not load readiness. Retry';

  @override
  String get quizNoReadiness => 'Complete a quiz to see your readiness.';

  @override
  String quizReadyPercent(int score) {
    return 'Readiness $score%';
  }

  @override
  String get quizRecommendations => 'Topics to review';

  @override
  String get quizReviewRetry => 'Could not load recommendations. Retry';

  @override
  String get quizReviewEmpty => 'No topics to review right now.';

  @override
  String quizRetention(int percent) {
    return 'Estimated retention $percent%';
  }

  @override
  String quizDaysSince(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days since practice',
      one: 'One day ago',
      zero: 'Less than one day ago',
    );
    return '$_temp0';
  }

  @override
  String get quizReviewSessionEnded =>
      'This review belonged to your previous login.';
}
