import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'download/download_helper.dart';
import 'auth_provider.dart';
import 'api_service.dart';
import '../core/api_endpoints.dart';

// Models
import '../models/subject_mastery.dart';
import '../models/quote.dart';
import '../models/activity_data.dart';
import '../models/performance.dart';
import '../models/user_history_entry.dart';
import '../models/smart_review_item.dart';
import '../models/readiness.dart';
import '../models/question_stats.dart';
import '../models/admin_question.dart';
import '../models/ecg_case.dart';
import '../models/ecg_diagnosis.dart';

// Re-export models so existing importers don't break
export '../models/subject_mastery.dart';
export '../models/quote.dart';
export '../models/activity_data.dart';
export '../models/performance.dart';
export '../models/user_history_entry.dart';
export '../models/smart_review_item.dart';
export '../models/readiness.dart';
export '../models/question_stats.dart';
export '../models/admin_question.dart';
export '../models/ecg_case.dart';
export '../models/ecg_diagnosis.dart';

// Re-export new providers so existing code using StatsProvider import still works
export 'admin_user_provider.dart';
export 'admin_question_provider.dart';
export 'topic_provider.dart';
export 'admin_content_provider.dart';

enum SubjectQuizState { initial, loading, loaded, empty, error }

/// Student-facing statistics provider.
/// Admin operations have been moved to:
/// - [AdminUserProvider] for user management
/// - [AdminQuestionProvider] for question/ECG CMS
/// - [TopicProvider] for topic management
/// - [AdminContentProvider] for quotes/images/translation
class StatsProvider with ChangeNotifier {
  final AuthProvider authProvider;

  StatsProvider(this.authProvider);

  ApiService get apiService => authProvider.apiService;

  // --- Student State ---
  List<SubjectMastery> _subjectMastery = [];
  List<ActivityData> _activity = [];
  bool _isLoading = false;
  List<SmartReviewItem> _smartReview = [];
  ReadinessScore? _readiness;
  Quote? _currentQuote;

  final Map<String, List<Map<String, dynamic>>> _sectionMastery = {};
  final Map<String, SubjectQuizState> _sectionStates = {};

  List<SubjectMastery> get subjectMastery => _subjectMastery;
  List<ActivityData> get activity => _activity;
  bool get isLoading => _isLoading;
  List<SmartReviewItem> get smartReview => _smartReview;
  ReadinessScore? get readiness => _readiness;
  Quote? get currentQuote => _currentQuote;
  Map<String, List<Map<String, dynamic>>> get sectionMastery => _sectionMastery;
  Map<String, SubjectQuizState> get sectionStates => _sectionStates;

  SubjectQuizState getSectionState(String slug) =>
      _sectionStates[slug] ?? SubjectQuizState.initial;

  // --- Student Methods ---

  Future<void> fetchSummary() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await authProvider.apiService.get(ApiEndpoints.statsSummary);
      if (data is List) {
        _subjectMastery =
            data.map((item) => SubjectMastery.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> preFetchData() async {
    debugPrint("🚀 Snappy Mode: Pre-fetching essential stats...");
    await fetchSummary();
    Future.delayed(const Duration(milliseconds: 500),
        () => fetchActivity(timeframe: 'week'));
    Future.delayed(const Duration(milliseconds: 1000),
        () => fetchActivity(timeframe: 'day'));
    Future.delayed(
        const Duration(milliseconds: 1500), () => fetchSmartReview());
    Future.delayed(const Duration(milliseconds: 2000), () => fetchReadiness());
    debugPrint("✅ Snappy Mode: Stats scheduled.");
  }

  Future<void> fetchActivity(
      {String timeframe = 'week', DateTime? anchorDate}) async {
    try {
      String endpoint = '${ApiEndpoints.statsActivity}?timeframe=$timeframe';
      if (anchorDate != null) {
        String dateStr = anchorDate.toIso8601String().split('T')[0];
        endpoint += '&anchorDate=$dateStr';
      }

      final data = await authProvider.apiService.get(endpoint);
      if (data is List) {
        _activity = data.map((item) => ActivityData.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching activity: $e');
    }
  }

  Future<List<int>> fetchMistakeIds(
      {String timeframe = 'week', DateTime? anchorDate}) async {
    try {
      String endpoint = '${ApiEndpoints.statsMistakes}?timeframe=$timeframe';
      if (anchorDate != null) {
        String dateStr = anchorDate.toIso8601String().split('T')[0];
        endpoint += '&anchorDate=$dateStr';
      }

      final data = await authProvider.apiService.get(endpoint);
      if (data is List) {
        return data.map((id) => int.parse(id.toString())).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching mistakes: $e');
      return [];
    }
  }

  Future<void> fetchSmartReview() async {
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.statsSmartReview);
      if (data != null && data['recommendations'] is List) {
        _smartReview = (data['recommendations'] as List)
            .map((e) => SmartReviewItem.fromJson(e))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching smart review: $e');
    }
  }

  Future<void> fetchReadiness() async {
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.statsReadiness);
      if (data != null) {
        _readiness = ReadinessScore.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching readiness: $e');
    }
  }

  Future<void> fetchSubjectDetail(String slug) async {
    _sectionStates[slug] = SubjectQuizState.loading;
    notifyListeners();

    try {
      final data = await authProvider.apiService.get('${ApiEndpoints.statsSubject}/$slug');
      if (data is List) {
        final List<Map<String, dynamic>> systems =
            data.cast<Map<String, dynamic>>();
        _sectionMastery[slug] = systems;
        _sectionStates[slug] =
            systems.isEmpty ? SubjectQuizState.empty : SubjectQuizState.loaded;
      } else {
        _sectionStates[slug] = SubjectQuizState.error;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching subject detail for $slug: $e');
      _sectionStates[slug] = SubjectQuizState.error;
      notifyListeners();
    }
  }

  Future<void> fetchCurrentQuote() async {
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.quizSingleQuote);
      _currentQuote = Quote.fromJson(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching current quote: $e');
    }
  }

  // ===================================================================
  // DEPRECATED DELEGATION METHODS
  // These exist only for backward compatibility. New code should use the
  // dedicated providers (AdminUserProvider, AdminQuestionProvider, etc.)
  // directly. These will be removed in a future cleanup pass.
  // ===================================================================

  // --- Admin User delegation (via AdminUserProvider) ---
  List<UserPerformance> _usersPerformance = [];
  int _totalStudents = 0;
  List<UserPerformance> _adminsPerformance = [];
  int _totalAdmins = 0;
  List<UserHistoryEntry> _userHistory = [];
  List<QuestionStats> _questionStats = [];
  Map<String, dynamic> _userStats = {'total_users': 0, 'avg_session_mins': 0, 'avg_bloom': 1.0};
  List<Map<String, dynamic>> _adminSummary = [];
  List<dynamic> _inventorySummary = [];
  List<String> _uploadedIcons = [];
  List<Quote> _adminQuotes = [];
  List<Map<String, dynamic>> _topics = [];
  List<AdminQuestion> _adminQuestions = [];
  int _adminTotalQuestions = 0;
  Map<String, dynamic> _wallOfPain = {'failedQuestions': [], 'difficultTopics': []};
  List<ECGCase> _ecgCases = [];
  List<ECGDiagnosis> _ecgDiagnoses = [];

  List<UserPerformance> get usersPerformance => _usersPerformance;
  int get totalStudents => _totalStudents;
  List<UserPerformance> get adminsPerformance => _adminsPerformance;
  int get totalAdmins => _totalAdmins;
  List<UserHistoryEntry> get userHistory => _userHistory;
  List<QuestionStats> get questionStats => _questionStats;
  Map<String, dynamic> get userStats => _userStats;
  List<Map<String, dynamic>> get adminSummary => _adminSummary;
  List<dynamic> get inventorySummary => _inventorySummary;
  List<String> get uploadedIcons => _uploadedIcons;
  List<Quote> get adminQuotes => _adminQuotes;
  List<Map<String, dynamic>> get topics => _topics;
  List<AdminQuestion> get adminQuestions => _adminQuestions;
  int get adminTotalQuestions => _adminTotalQuestions;
  Map<String, dynamic> get wallOfPain => _wallOfPain;
  List<ECGCase> get ecgCases => _ecgCases;
  List<ECGDiagnosis> get ecgDiagnoses => _ecgDiagnoses;

  // Admin User Methods (delegated)
  Future<void> fetchUsersPerformance({int page = 1, int limit = 50, String search = ''}) async {
    _isLoading = true; notifyListeners();
    try {
      final endpoint = '${ApiEndpoints.statsAdminUsersPerformance}?page=$page&limit=$limit&search=${Uri.encodeComponent(search)}';
      final data = await authProvider.apiService.get(endpoint);
      if (data is Map<String, dynamic>) {
        _usersPerformance = (data['users'] as List).map((item) => UserPerformance.fromJson(item)).toList();
        _totalStudents = data['total'] ?? 0;
      } else if (data is List) {
        _usersPerformance = data.map((item) => UserPerformance.fromJson(item)).toList();
        _totalStudents = _usersPerformance.length;
      }
    } catch (e) { debugPrint('Error fetching users performance: $e'); }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> fetchUserHistory(int userId, {int limit = 100}) async {
    _isLoading = true; notifyListeners();
    try {
      final data = await authProvider.apiService.get('${ApiEndpoints.statsAdminUserBase}/$userId/history?limit=$limit');
      if (data is List) { _userHistory = data.map((item) => UserHistoryEntry.fromJson(item)).toList(); }
    } catch (e) { debugPrint('Error fetching user history: $e'); }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<Map<String, dynamic>?> fetchAdminUserAnalytics(int userId) async {
    try {
      final data = await authProvider.apiService.get('${ApiEndpoints.statsAdminUserBase}/$userId/analytics');
      return data != null ? data as Map<String, dynamic> : null;
    } catch (e) { debugPrint('Error fetching admin user analytics: $e'); return null; }
  }

  Future<void> fetchAdminsPerformance({int page = 1, int limit = 50, String search = ''}) async {
    _isLoading = true; notifyListeners();
    try {
      final endpoint = '${ApiEndpoints.adminAdmins}?page=$page&limit=$limit&search=${Uri.encodeComponent(search)}';
      final data = await authProvider.apiService.get(endpoint);
      if (data is Map<String, dynamic>) {
        _adminsPerformance = (data['users'] as List).map((item) => UserPerformance.fromJson(item)).toList();
        _totalAdmins = data['total'] ?? 0;
      } else if (data is List) {
        _adminsPerformance = data.map((item) => UserPerformance.fromJson(item)).toList();
        _totalAdmins = _adminsPerformance.length;
      }
    } catch (e) { debugPrint('Error fetching admins: $e'); }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> updateUserRole(int userId, String newRole) async {
    try {
      await authProvider.apiService.put(ApiEndpoints.adminUserRole, {'userId': userId, 'newRole': newRole});
      await fetchUsersPerformance(); await fetchAdminsPerformance(); return true;
    } catch (e) { debugPrint('Error updating role: $e'); return false; }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      await authProvider.apiService.delete('${ApiEndpoints.adminUserBase}/$userId');
      await fetchUsersPerformance(); await fetchAdminsPerformance(); return true;
    } catch (e) { debugPrint('Error deleting user: $e'); return false; }
  }

  Future<bool> sendDirectMessage(int userId, String message) async {
    try {
      await authProvider.apiService.post(ApiEndpoints.adminNotify, {'userId': userId, 'message': message});
      return true;
    } catch (e) { debugPrint('Error sending message: $e'); return false; }
  }

  Future<void> fetchAdminSummary() async {
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.statsAdminSummary);
      if (data is List) { _adminSummary = data.cast<Map<String, dynamic>>(); notifyListeners(); }
    } catch (e) { debugPrint('Error fetching admin summary: $e'); }
  }

  Future<void> fetchQuestionStats({int? topicId}) async {
    _isLoading = true; notifyListeners();
    try {
      String endpoint = ApiEndpoints.statsQuestions;
      if (topicId != null) endpoint += '?topicId=$topicId';
      final data = await authProvider.apiService.get(endpoint);
      _questionStats = (data['questionStats'] as List).map((item) => QuestionStats.fromJson(item)).toList();
      _userStats = data['userStats'] ?? {'total_users': 0, 'avg_session_mins': 0};
    } catch (e) { debugPrint('Error fetching question stats: $e'); }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> fetchInventorySummary() async {
    _isLoading = true; notifyListeners();
    try { final data = await authProvider.apiService.get(ApiEndpoints.statsInventorySummary); _inventorySummary = data; }
    catch (e) { debugPrint('Error fetching inventory summary: $e'); }
    finally { _isLoading = false; notifyListeners(); }
  }

  // Admin Question/CMS Methods (delegated)
  Future<void> fetchTopics() async {
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.quizTopics);
      if (data is List) { _topics = data.cast<Map<String, dynamic>>(); notifyListeners(); }
    } catch (e) { debugPrint('Error fetching topics: $e'); }
  }

  Future<bool> createTopic(String nameEn, String nameHu, int? parentId) async {
    try {
      await authProvider.apiService.post(ApiEndpoints.quizAdminTopics, {'name_en': nameEn, 'name_hu': nameHu, 'parent_id': parentId});
      await fetchTopics(); return true;
    } catch (e) { debugPrint('Error creating topic: $e'); return false; }
  }

  Future<String?> deleteTopic(int topicId, {bool force = false}) async {
    try {
      await authProvider.apiService.delete('${ApiEndpoints.quizAdminTopics}/$topicId${force ? '?force=true' : ''}');
      await fetchTopics(); return null;
    } catch (e) {
      debugPrint('Error deleting topic: $e');
      return e.toString().contains('API Error') ? e.toString().split('API Error: ')[1] : 'Network error';
    }
  }

  Future<String?> updateTopic(int id, String nameEn, String nameHu) async {
    try {
      await authProvider.apiService.put('${ApiEndpoints.quizAdminTopics}/$id', {'name_en': nameEn, 'name_hu': nameHu});
      final index = _topics.indexWhere((t) => t['id'] == id);
      if (index != -1) { _topics[index]['name_en'] = nameEn; _topics[index]['name_hu'] = nameHu; notifyListeners(); }
      fetchTopics(); return null;
    } catch (e) {
      debugPrint('Error updating topic: $e');
      return e.toString().contains('API Error') ? e.toString().split('API Error: ')[1] : 'Network error';
    }
  }

  Future<void> fetchAdminQuestions({int page = 1, String search = '', String type = '', int? bloomLevel, int? topicId, String sortBy = 'created_at', String order = 'DESC'}) async {
    _isLoading = true; notifyListeners();
    try {
      String endpoint = '${ApiEndpoints.quizAdminQuestions}?page=$page&search=$search&sortBy=$sortBy&order=$order';
      if (type.isNotEmpty) endpoint += '&type=$type';
      if (bloomLevel != null) endpoint += '&bloom_level=$bloomLevel';
      if (topicId != null) endpoint += '&topic_id=$topicId';
      final data = await authProvider.apiService.get(endpoint);
      final fetched = (data['questions'] as List).map((item) => AdminQuestion.fromJson(item)).toList();
      final seen = <int>{}; _adminQuestions = [];
      for (var q in fetched) { if (!seen.contains(q.id)) { seen.add(q.id); _adminQuestions.add(q); } }
      _adminTotalQuestions = data['total'];
    } catch (e) { debugPrint('Error fetching admin questions: $e'); }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> createQuestion(Map<String, dynamic> questionData) async {
    try { await authProvider.apiService.post(ApiEndpoints.quizAdminQuestions, questionData); return true; }
    catch (e) { debugPrint('Error creating question: $e'); return false; }
  }

  Future<bool> updateQuestion(int id, Map<String, dynamic> questionData) async {
    try { await authProvider.apiService.put('${ApiEndpoints.quizAdminQuestions}/$id', questionData); return true; }
    catch (e) { debugPrint('Error updating question: $e'); return false; }
  }

  Future<bool> deleteQuestion(int id) async {
    try { await authProvider.apiService.delete('${ApiEndpoints.quizAdminQuestions}/$id'); fetchAdminQuestions(); return true; }
    catch (e) { debugPrint('Error deleting question: $e'); return false; }
  }

  Future<bool> bulkActionQuestions({required String action, required List<int> ids, int? targetTopicId}) async {
    try {
      await authProvider.apiService.post(ApiEndpoints.quizAdminBulk, {'action': action, 'ids': ids, 'targetTopicId': targetTopicId});
      fetchAdminQuestions(); return true;
    } catch (e) { debugPrint('Error in bulk action: $e'); return false; }
  }

  Future<Map<String, dynamic>?> uploadQuestionsBatch(List<int> bytes, String filename) async {
    try {
      final result = await authProvider.apiService.postMultipart(ApiEndpoints.quizAdminBatch, bytes: bytes, filename: filename);
      fetchAdminQuestions(); return result as Map<String, dynamic>;
    } catch (e) { debugPrint('Error in batch upload: $e'); return null; }
  }

  Future<void> downloadQuestionsTemplate() async {
    try {
      final bytes = await authProvider.apiService.getBytes(ApiEndpoints.quizAdminTemplate);
      await downloadHelper.download(bytes, 'QUESTION_TEMPLATE.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    } catch (e) { debugPrint('Error downloading template: $e'); }
  }

  Future<void> fetchWallOfPain() async {
    try { final data = await authProvider.apiService.get(ApiEndpoints.quizAdminWallOfPain); _wallOfPain = data; notifyListeners(); }
    catch (e) { debugPrint('Error fetching Wall of Pain: $e'); }
  }

  // ECG Methods (delegated)
  Future<void> fetchECGCases() async {
    _isLoading = true; notifyListeners();
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.ecgCases);
      if (data is List) { _ecgCases = data.map((e) => ECGCase.fromJson(e)).toList(); }
    } catch (e) { debugPrint('Error fetching ECG cases: $e'); }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> fetchECGDiagnoses() async {
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.ecgDiagnoses);
      if (data is List) { _ecgDiagnoses = data.map((e) => ECGDiagnosis.fromJson(e)).toList(); notifyListeners(); }
    } catch (e) { debugPrint('Error fetching ECG diagnoses: $e'); }
  }

  Future<bool> createECGCase(Map<String, dynamic> data) async {
    try { await authProvider.apiService.post(ApiEndpoints.ecgCases, data); return true; }
    catch (e) { debugPrint('Error creating ECG case: $e'); return false; }
  }

  Future<bool> updateECGCase(int id, Map<String, dynamic> data) async {
    try { await authProvider.apiService.put('${ApiEndpoints.ecgCases}/$id', data); return true; }
    catch (e) { debugPrint('Error updating ECG case: $e'); return false; }
  }

  Future<bool> deleteECGCase(int id) async {
    try { await authProvider.apiService.delete('${ApiEndpoints.ecgCases}/$id'); return true; }
    catch (e) { debugPrint('Error deleting ECG case: $e'); return false; }
  }

  // Quote/Content Methods (delegated)
  Future<void> fetchAdminQuotes() async {
    _isLoading = true; notifyListeners();
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.quizAdminQuotes);
      if (data is List) { _adminQuotes = data.map((e) => Quote.fromJson(e)).toList(); }
    } catch (e) { debugPrint('Error fetching admin quotes: $e'); }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> createQuote(String textEn, String textHu, String author, {String? titleEn, String? titleHu, String? iconName, String? customIconUrl}) async {
    try {
      await authProvider.apiService.post(ApiEndpoints.quizAdminQuotes, {'text_en': textEn, 'text_hu': textHu, 'author': author, 'title_en': titleEn, 'title_hu': titleHu, 'icon_name': iconName, 'custom_icon_url': customIconUrl});
      await fetchAdminQuotes(); return true;
    } catch (e) { debugPrint('Error creating quote: $e'); return false; }
  }

  Future<bool> updateQuote(int id, String textEn, String textHu, String author, {String? titleEn, String? titleHu, String? iconName, String? customIconUrl}) async {
    try {
      await authProvider.apiService.put('${ApiEndpoints.quizAdminQuotes}/$id', {'text_en': textEn, 'text_hu': textHu, 'author': author, 'title_en': titleEn, 'title_hu': titleHu, 'icon_name': iconName, 'custom_icon_url': customIconUrl});
      await fetchAdminQuotes(); return true;
    } catch (e) { debugPrint('Error updating quote: $e'); return false; }
  }

  Future<bool> deleteQuote(int id) async {
    try { await authProvider.apiService.delete('${ApiEndpoints.quizAdminQuotes}/$id'); await fetchAdminQuotes(); return true; }
    catch (e) { debugPrint('Error deleting quote: $e'); return false; }
  }

  Future<String?> uploadImage(XFile file, {String? folder}) async {
    return ApiService().uploadImage(file, folder: folder);
  }

  Future<void> fetchUploadedIcons() async {
    try {
      final data = await authProvider.apiService.get('${ApiEndpoints.apiUpload}?folder=icons');
      _uploadedIcons = List<String>.from(data['images']); notifyListeners();
    } catch (e) { debugPrint('Error fetching uploaded icons: $e'); }
  }

  Future<bool> deleteUploadedIcon(String iconUrl) async {
    try {
      final filename = iconUrl.split('/').last;
      await authProvider.apiService.delete('${ApiEndpoints.apiUpload}/$filename');
      _uploadedIcons.removeWhere((url) => url.endsWith(filename)); notifyListeners(); return true;
    } catch (e) { debugPrint('Error deleting icon: $e'); return false; }
  }

  Future<String?> translateText(String text, String sourceLang, String targetLang) async {
    try {
      final data = await authProvider.apiService.post(ApiEndpoints.quizTranslate, {'text': text, 'sourceLang': sourceLang, 'targetLang': targetLang});
      return data['translatedText'];
    } catch (e) { debugPrint('Error translating text: $e'); return null; }
  }

  /// Resets all user-specific statistics.
  void resetState() {
    _subjectMastery = [];
    _activity = [];
    _isLoading = false;
    _usersPerformance = [];
    _totalStudents = 0;
    _adminsPerformance = [];
    _totalAdmins = 0;
    _userHistory = [];
    _uploadedIcons = [];
    _adminQuotes = [];
    _currentQuote = null;
    _smartReview = [];
    _readiness = null;
    _sectionMastery.clear();
    _sectionStates.clear();
    _questionStats = [];
    _userStats = {'total_users': 0, 'avg_session_mins': 0, 'avg_bloom': 1.0};
    _adminSummary = [];
    _inventorySummary = [];
    _ecgCases = [];
    _ecgDiagnoses = [];
    notifyListeners();
  }
}
