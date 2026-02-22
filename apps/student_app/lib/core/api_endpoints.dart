class ApiEndpoints {
  // Base prefixes
  static const String shopPrefix = '/shop';
  static const String quizPrefix = '/quiz';
  static const String authPrefix = '/auth';
  static const String statsPrefix = '/stats';
  static const String ecgPrefix = '/ecg';

  // Shop & Inventory (Unified under /shop)
  static const String shopCatalog = '$shopPrefix/items';
  static const String shopInventory = '$shopPrefix/inventory';
  static const String shopBuy = '$shopPrefix/buy';
  static const String shopEquip = '$shopPrefix/equip';
  static const String shopUnequip = '$shopPrefix/unequip';
  static const String shopSyncRoom = '$shopPrefix/sync-room';

  // Quiz
  static const String quizQuestions = '$quizPrefix/questions';
  static const String quizSubmit = '$quizPrefix/submit';
  static const String quizNext = '$quizPrefix/next';
  static const String quizTopics = '$quizPrefix/topics';
  static const String quizAdminTopics = '$quizPrefix/admin/topics';
  static const String quizAdminQuestions = '$quizPrefix/admin/questions';
  static const String quizStart = '$quizPrefix/start';
  static const String quizAnswer = '$quizPrefix/answer';

  // Auth
  static const String authLogin = '$authPrefix/login';
  static const String authRegister = '$authPrefix/register';
  static const String authVerifyRegistration = '$authPrefix/verify-registration';
  static const String authResendRegistrationOtp = '$authPrefix/resend-registration-otp';
  static const String authRefresh = '$authPrefix/refresh';
  static const String authMe = '$authPrefix/me';
  static const String authProfile = '$authPrefix/profile';
  static const String authLogout = '$authPrefix/logout';
  static const String authRequestOtp = '$authPrefix/request-otp';
  static const String authResetPassword = '$authPrefix/reset-password';
  static const String authVerifyEmail = '$authPrefix/verify-email';

  // Social
  static const String socialPrefix = '/social';
  static const String socialNetwork = '$socialPrefix/network';
  static const String socialSearch = '$socialPrefix/search';
  static const String socialRequest = '$socialPrefix/request';
  static const String socialColleague = '$socialPrefix/colleague';
  static const String socialLike = '$socialPrefix/like';
  static const String socialNote = '$socialPrefix/note';

  // Stats
  static const String statsSummary = '$statsPrefix/summary';
  static const String statsActivity = '$statsPrefix/activity';
  static const String statsMistakes = '$statsPrefix/mistakes';
  static const String statsSmartReview = '$statsPrefix/smart-review';
  static const String statsReadiness = '$statsPrefix/readiness';
  static const String statsSubject = '$statsPrefix/subject';
  static const String statsInventorySummary = '$statsPrefix/inventory-summary';
  static const String statsQuestions = '$statsPrefix/questions';

  // Admin Stats
  static const String statsAdminSummary = '$statsPrefix/admin/summary';
  static const String statsAdminUsersPerformance = '$statsPrefix/admin/users-performance';
  static const String statsAdminUserBase = '$statsPrefix/admin/users';

  // Admin General
  static const String adminAdmins = '/admin/admins';
  static const String adminUserRole = '/admin/user-role';
  static const String adminUserBase = '/admin/users';
  static const String adminNotify = '/admin/notify';

  // ECG
  static const String ecgCases = '$ecgPrefix/cases';
  static const String ecgDiagnoses = '$ecgPrefix/diagnoses';

  // Advanced Admin & Quiz Tools
  static const String quizAdminBulk = '$quizPrefix/admin/questions/bulk';
  static const String quizAdminBatch = '$quizPrefix/admin/questions/batch';
  static const String quizAdminTemplate = '$quizPrefix/admin/questions/template';
  static const String quizAdminQuotes = '$quizPrefix/admin/quotes';
  static const String quizAdminWallOfPain = '$quizPrefix/admin/analytics/wall-of-pain';
  static const String quizTranslate = '$quizPrefix/translate';
  static const String quizSingleQuote = '$quizPrefix/quote';

  // System
  static const String apiUpload = '/api/upload';
  static const String apiTranslate = '/api/translate';
  static const String apiTranslateQuestion = '/api/translate/question';
}
