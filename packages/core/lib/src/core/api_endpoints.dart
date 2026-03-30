class ApiEndpoints {
  // Auth
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authResendRegistrationOtp = '/auth/resend-otp';
  static const String authVerifyRegistration = '/auth/verify-registration';
  static const String authMe = '/auth/me';
  static const String authProfile = '/auth/profile';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';
  static const String authRequestOtp = '/auth/request-otp';
  static const String authResetPassword = '/auth/reset-password';
  static const String authVerifyEmail = '/auth/verify-email';

  // Stats
  static const String statsSummary = '/stats/summary';
  static const String statsActivity = '/stats/activity';
  static const String statsMistakes = '/stats/mistakes';
  static const String statsSmartReview = '/stats/smart-review';
  static const String statsReadiness = '/stats/readiness';
  static const String statsSubject = '/stats/subject';
  static const String statsQuestions = '/stats/questions';
  static const String statsInventorySummary = '/stats/inventory/summary';

  // Admin Stats
  static const String statsAdminSummary = '/admin/stats/summary';
  static const String statsAdminUsersPerformance = '/admin/stats/users/performance';
  static const String statsAdminUserBase = '/admin/stats/users';

  // Admin
  static const String adminAdmins = '/admin/admins';
  static const String adminUserRole = '/admin/users/role';
  static const String adminUserBase = '/admin/users';
  static const String adminNotify = '/admin/notify';

  // Quiz
  static const String quizTopics = '/quiz/topics';
  static const String quizNext = '/quiz/next';
  static const String quizTranslate = '/quiz/translate';
  static const String quizSingleQuote = '/quiz/quote/random';

  // Admin Quiz
  static const String quizAdminTopics = '/admin/quiz/topics';
  static const String quizAdminQuestions = '/admin/quiz/questions';
  static const String quizAdminBulk = '/admin/quiz/questions/bulk';
  static const String quizAdminBatch = '/admin/quiz/questions/batch';
  static const String quizAdminTemplate = '/admin/quiz/questions/template';
  static const String quizAdminWallOfPain = '/admin/quiz/questions/wall-of-pain';
  static const String quizAdminQuotes = '/admin/quiz/quotes';

  // ECG
  static const String ecgCases = '/ecg/cases';
  static const String ecgDiagnoses = '/ecg/diagnoses';

  // Reports
  static const String reportsBase = '/reports';
  static const String reportsQuestion = '/reports/question';

  // System
  static const String apiUpload = '/upload';
  static const String apiTranslate = '/translate';
  static const String apiTranslateQuestion = '/translate/question';

  // Social
  static const String socialNetwork = '/social/network';
  static const String socialSearch = '/social/search';
  static const String socialRequest = '/social/request';
  static const String socialColleague = '/social/colleague';
  static const String socialLike = '/social/like';
  static const String socialNote = '/social/note';
}

