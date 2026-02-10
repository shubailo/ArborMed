import 'dart:convert';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'download/download_helper.dart'; // Added for file download logic
import 'package:image_picker/image_picker.dart';
import 'auth_provider.dart';
import 'api_service.dart';
import '../constants/api_endpoints.dart';

enum SubjectQuizState { initial, loading, loaded, empty, error }

class SubjectMastery {
  final String subjectEn;
  final String? subjectHu;
  final String slug;
  final int totalAnswered;
  final int correctAnswered;
  final int masteryPercent;

  SubjectMastery({
    required this.subjectEn,
    this.subjectHu,
    required this.slug,
    required this.totalAnswered,
    required this.correctAnswered,
    required this.masteryPercent,
  });

  factory SubjectMastery.fromJson(Map<String, dynamic> json) {
    return SubjectMastery(
      subjectEn: json['name_en'] ?? json['subject'] ?? 'Unknown',
      subjectHu: json['name_hu'],
      slug: json['slug'] ?? '',
      totalAnswered:
          int.tryParse(json['total_answered']?.toString() ?? '0') ?? 0,
      correctAnswered:
          int.tryParse(json['correct_answered']?.toString() ?? '0') ?? 0,
      masteryPercent:
          int.tryParse(json['mastery_percent']?.toString() ?? '0') ?? 0,
    );
  }
}

class Quote {
  final int id;
  final String textEn;
  final String textHu;
  final String author;
  final String titleEn;
  final String titleHu;
  final String iconName;
  final String? customIconUrl;
  final DateTime? createdAt;

  Quote({
    required this.id,
    required this.textEn,
    required this.textHu,
    required this.author,
    this.titleEn = 'Study Break',
    this.titleHu = 'Tanul\u00e1s',
    this.iconName = 'menu_book_rounded',
    this.customIconUrl,
    this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] ?? 0,
      textEn: json['text_en'] ?? json['text'] ?? '',
      textHu: json['text_hu'] ?? '',
      author: json['author'] ?? 'Anonymous',
      titleEn: json['title_en'] ?? 'Study Break',
      titleHu: json['title_hu'] ?? 'Tanul\u00e1s',
      iconName: json['icon_name'] ?? 'menu_book_rounded',
      customIconUrl: json['custom_icon_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}

class ActivityData {
  final DateTime date;
  final String? dayLabel;
  final int count;
  final int correctCount;

  ActivityData(
      {required this.date,
      this.dayLabel,
      required this.count,
      required this.correctCount});

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      date: DateTime.parse(json['date']),
      dayLabel: json['day_label'],
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      correctCount: int.tryParse(json['correct_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class SubjectPerformance {
  final int avgScore;
  final int totalQuestions;
  final int correctQuestions;
  final int avgTimeMs;

  SubjectPerformance({
    required this.avgScore,
    required this.totalQuestions,
    required this.correctQuestions,
    required this.avgTimeMs,
  });
}

class UserPerformance {
  final int id;
  final String email;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final SubjectPerformance pathophysiology;
  final SubjectPerformance pathology;
  final SubjectPerformance microbiology;
  final SubjectPerformance pharmacology;
  final SubjectPerformance ecg;
  final SubjectPerformance cases;

  // Admin-specific fields
  final int? assignedSubjectId;
  final String? assignedSubjectName;
  final int? questionsUploaded;

  UserPerformance({
    required this.id,
    required this.email,
    required this.createdAt,
    this.lastActivity,
    required this.pathophysiology,
    required this.pathology,
    required this.microbiology,
    required this.pharmacology,
    required this.ecg,
    required this.cases,
    this.assignedSubjectId,
    this.assignedSubjectName,
    this.questionsUploaded,
  });

  factory UserPerformance.fromJson(Map<String, dynamic> json) {
    SubjectPerformance parseSubject(String prefix) {
      return SubjectPerformance(
        avgScore: json['${prefix}_avg'] ?? 0,
        totalQuestions: json['${prefix}_total'] ?? 0,
        correctQuestions: json['${prefix}_correct'] ?? 0,
        avgTimeMs: json['${prefix}_time'] ?? 0,
      );
    }

    return UserPerformance(
      id: json['id'],
      email: json['email'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
      pathophysiology: parseSubject('pathophysiology'),
      pathology: parseSubject('pathology'),
      microbiology: parseSubject('microbiology'),
      pharmacology: parseSubject('pharmacology'),
      ecg: parseSubject('ecg'),
      cases: parseSubject('cases'),
      assignedSubjectId: json['assigned_subject_id'],
      assignedSubjectName: json['assigned_subject_name'],
      questionsUploaded: json['questions_uploaded'],
    );
  }
}

class UserHistoryEntry {
  final int id;
  final DateTime createdAt;
  final bool isCorrect;
  final int responseTimeMs;
  final String questionText;
  final int bloomLevel;
  final String sectionName;
  final String subjectName;
  final String subjectSlug;

  UserHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.questionText,
    required this.bloomLevel,
    required this.sectionName,
    required this.subjectName,
    required this.subjectSlug,
  });

  factory UserHistoryEntry.fromJson(Map<String, dynamic> json) {
    return UserHistoryEntry(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      isCorrect: json['is_correct'] ?? false,
      responseTimeMs: json['response_time_ms'] ?? 0,
      questionText: json['question_text_en'] ?? '',
      bloomLevel: json['bloom_level'] ?? 1,
      sectionName: json['section_name'] ?? '',
      subjectName: json['subject_name'] ?? '',
      subjectSlug: json['subject_slug'] ?? '',
    );
  }
}

class SmartReviewItem {
  final String topic;
  final String slug;
  final double retention;
  final double daysSince;
  final int mastery;

  SmartReviewItem({
    required this.topic,
    required this.slug,
    required this.retention,
    required this.daysSince,
    required this.mastery,
  });

  factory SmartReviewItem.fromJson(Map<String, dynamic> json) {
    return SmartReviewItem(
      topic: json['topic'] ?? '',
      slug: json['slug'] ?? '',
      retention: (json['retention'] ?? 0).toDouble(),
      daysSince: (json['daysSince'] ?? 0).toDouble(),
      mastery: (json['mastery'] ?? 0).toInt(),
    );
  }
}

class ReadinessScore {
  final int overall;
  final List<ReadinessDetail> breakdown;

  ReadinessScore({required this.overall, required this.breakdown});

  factory ReadinessScore.fromJson(Map<String, dynamic> json) {
    return ReadinessScore(
      overall: (json['overallReadiness'] ?? 0).toInt(),
      breakdown: (json['breakdown'] as List?)
              ?.map((e) => ReadinessDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ReadinessDetail {
  final String topic;
  final String slug;
  final int score;
  final double retention;
  final int mastery;

  ReadinessDetail({
    required this.topic,
    required this.slug,
    required this.score,
    required this.retention,
    required this.mastery, // Fixed typo from 'matery'
  });

  factory ReadinessDetail.fromJson(Map<String, dynamic> json) {
    return ReadinessDetail(
      topic: json['topic'] ?? '',
      slug: json['slug'] ?? '',
      score: (json['score'] ?? 0).toInt(),
      retention: (json['metrics']?['retention'] ?? 0).toDouble(),
      mastery: (json['metrics']?['mastery'] ?? 0).toInt(),
    );
  }
}

class StatsProvider with ChangeNotifier {
  final AuthProvider authProvider;
  List<SubjectMastery> _subjectMastery = [];
  List<ActivityData> _activity = [];
  bool _isLoading = false;
  List<UserPerformance> _usersPerformance = [];
  int _totalStudents = 0; // NEW
  List<UserPerformance> _adminsPerformance = [];
  int _totalAdmins = 0; // NEW
  List<UserHistoryEntry> _userHistory = [];

  StatsProvider(this.authProvider);

  ApiService get apiService => authProvider.apiService;

  List<SubjectMastery> get subjectMastery => _subjectMastery;
  List<ActivityData> get activity => _activity;
  bool get isLoading => _isLoading;
  List<UserPerformance> get usersPerformance => _usersPerformance;
  int get totalStudents => _totalStudents; // NEW
  List<UserPerformance> get adminsPerformance => _adminsPerformance;
  int get totalAdmins => _totalAdmins; // NEW
  List<UserHistoryEntry> get userHistory => _userHistory;

  List<String> _uploadedIcons = [];
  List<String> get uploadedIcons => _uploadedIcons;

  List<Quote> _adminQuotes = [];
  List<Quote> get adminQuotes => _adminQuotes;

  Quote? _currentQuote;

  Quote? get currentQuote => _currentQuote;

  List<SmartReviewItem> _smartReview = [];
  List<SmartReviewItem> get smartReview => _smartReview;

  ReadinessScore? _readiness;
  ReadinessScore? get readiness => _readiness;

  final Map<String, List<Map<String, dynamic>>> _sectionMastery = {};
  Map<String, List<Map<String, dynamic>>> get sectionMastery => _sectionMastery;

  final Map<String, SubjectQuizState> _sectionStates = {};
  Map<String, SubjectQuizState> get sectionStates => _sectionStates;

  SubjectQuizState getSectionState(String slug) =>
      _sectionStates[slug] ?? SubjectQuizState.initial;

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

  // 🚀 Pre-fetch all essential data for snappier UX
  Future<void> preFetchData() async {
    debugPrint("🚀 Snappy Mode: Pre-fetching essential stats...");

    // 1. Fetch critical summary first
    await fetchSummary();

    // 2. Stagger the rest to prevent UI freeze (JSON parsing on main thread)
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
        // Format YYYY-MM-DD
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

  // --- ADMIN METHODS ---

  List<QuestionStats> _questionStats = [];
  Map<String, dynamic> _userStats = {
    'total_users': 0,
    'avg_session_mins': 0,
    'avg_bloom': 1.0
  };
  List<Map<String, dynamic>> _adminSummary = [];

  List<QuestionStats> get questionStats => _questionStats;
  Map<String, dynamic> get userStats => _userStats;
  List<Map<String, dynamic>> get adminSummary => _adminSummary;

  List<dynamic> _inventorySummary = [];
  List<dynamic> get inventorySummary => _inventorySummary;

  Future<void> fetchInventorySummary() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data =
          await authProvider.apiService.get(ApiEndpoints.statsInventorySummary);
      _inventorySummary = data;
    } catch (e) {
      debugPrint('Error fetching inventory summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUsersPerformance(
      {int page = 1, int limit = 50, String search = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final endpoint =
          '${ApiEndpoints.statsAdminUsersPerformance}?page=$page&limit=$limit&search=${Uri.encodeComponent(search)}';
      final data = await authProvider.apiService.get(endpoint);
      if (data is Map<String, dynamic>) {
        _usersPerformance = (data['users'] as List)
            .map((item) => UserPerformance.fromJson(item))
            .toList();
        _totalStudents = data['total'] ?? 0;
      } else if (data is List) {
        // Fallback for old API if not yet updated
        _usersPerformance =
            data.map((item) => UserPerformance.fromJson(item)).toList();
        _totalStudents = _usersPerformance.length;
      }
    } catch (e) {
      debugPrint('Error fetching users performance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserHistory(int userId, {int limit = 100}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await authProvider.apiService
          .get('${ApiEndpoints.statsAdminUserBase}/$userId/history?limit=$limit');
      if (data is List) {
        _userHistory =
            data.map((item) => UserHistoryEntry.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching user history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchAdminUserAnalytics(int userId) async {
    try {
      final data = await authProvider.apiService
          .get('${ApiEndpoints.statsAdminUserBase}/$userId/analytics');
      if (data != null) {
        return data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching admin user analytics: $e');
      return null;
    }
  }

  // --- NEW ADMIN ACTION METHODS ---

  Future<void> fetchAdminsPerformance(
      {int page = 1, int limit = 50, String search = ''}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final endpoint =
          '${ApiEndpoints.adminAdmins}?page=$page&limit=$limit&search=${Uri.encodeComponent(search)}';
      final data = await authProvider.apiService.get(endpoint);
      if (data is Map<String, dynamic>) {
        _adminsPerformance = (data['users'] as List)
            .map((item) => UserPerformance.fromJson(item))
            .toList();
        _totalAdmins = data['total'] ?? 0;
      } else if (data is List) {
        // Fallback for old API if not yet updated
        _adminsPerformance =
            data.map((item) => UserPerformance.fromJson(item)).toList();
        _totalAdmins = _adminsPerformance.length;
      }
    } catch (e) {
      debugPrint('Error fetching admins: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserRole(int userId, String newRole) async {
    try {
      await authProvider.apiService
          .put(ApiEndpoints.adminUserRole, {'userId': userId, 'newRole': newRole});
      await fetchUsersPerformance();
      await fetchAdminsPerformance();
      return true;
    } catch (e) {
      debugPrint('Error updating role: $e');
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      await authProvider.apiService.delete('${ApiEndpoints.adminUserBase}/$userId');
      await fetchUsersPerformance();
      await fetchAdminsPerformance();
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  Future<bool> sendDirectMessage(int userId, String message) async {
    try {
      await authProvider.apiService
          .post(ApiEndpoints.adminNotify, {'userId': userId, 'message': message});
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  Future<void> fetchAdminSummary() async {
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.statsAdminSummary);
      if (data is List) {
        _adminSummary = data.cast<Map<String, dynamic>>();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching admin summary: $e');
    }
  }

  Future<void> fetchQuestionStats({int? topicId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      String endpoint = ApiEndpoints.statsQuestions;
      if (topicId != null) {
        endpoint += '?topicId=$topicId';
      }

      final data = await authProvider.apiService.get(endpoint);
      _questionStats = (data['questionStats'] as List)
          .map((item) => QuestionStats.fromJson(item))
          .toList();
      _userStats =
          data['userStats'] ?? {'total_users': 0, 'avg_session_mins': 0};
    } catch (e) {
      debugPrint('Error fetching question stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CMS METHODS ---

  List<AdminQuestion> _adminQuestions = [];
  int _adminTotalQuestions = 0;
  List<AdminQuestion> get adminQuestions => _adminQuestions;
  int get adminTotalQuestions => _adminTotalQuestions;

  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> get topics => _topics;

  Future<void> fetchTopics() async {
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.quizTopics);
      if (data is List) {
        _topics = data.cast<Map<String, dynamic>>();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching topics: $e');
    }
  }

  Future<bool> createTopic(String nameEn, String nameHu, int? parentId) async {
    try {
      await authProvider.apiService.post(ApiEndpoints.quizAdminTopics, {
        'name_en': nameEn,
        'name_hu': nameHu,
        'parent_id': parentId,
      });

      await fetchTopics();
      return true;
    } catch (e) {
      debugPrint('Error creating topic: $e');
      return false;
    }
  }

  Future<String?> deleteTopic(int topicId, {bool force = false}) async {
    try {
      await authProvider.apiService
          .delete('${ApiEndpoints.quizAdminTopics}/$topicId${force ? '?force=true' : ''}');
      await fetchTopics();
      return null; // Success
    } catch (e) {
      debugPrint('Error deleting topic: $e');
      return e.toString().contains('API Error')
          ? e.toString().split('API Error: ')[1]
          : 'Network error';
    }
  }

  Future<String?> updateTopic(int id, String nameEn, String nameHu) async {
    try {
      await authProvider.apiService.put('${ApiEndpoints.quizAdminTopics}/$id', {
        'name_en': nameEn,
        'name_hu': nameHu,
      });

      // Optimistic update
      final index = _topics.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        _topics[index]['name_en'] = nameEn;
        _topics[index]['name_hu'] = nameHu;
        notifyListeners();
      }

      fetchTopics(); // Background refresh
      return null;
    } catch (e) {
      debugPrint('Error updating topic: $e');
      return e.toString().contains('API Error')
          ? e.toString().split('API Error: ')[1]
          : 'Network error';
    }
  }

  Future<void> fetchAdminQuestions(
      {int page = 1,
      String search = '',
      String type = '',
      int? bloomLevel,
      int? topicId,
      String sortBy = 'created_at',
      String order = 'DESC'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      String endpoint =
          '${ApiEndpoints.quizAdminQuestions}?page=$page&search=$search&sortBy=$sortBy&order=$order';
      if (type.isNotEmpty) endpoint += '&type=$type';
      if (bloomLevel != null) endpoint += '&bloom_level=$bloomLevel';
      if (topicId != null) endpoint += '&topic_id=$topicId';

      final data = await authProvider.apiService.get(endpoint);
      // Map server JSON to AdminQuestion objects
      final fetched = (data['questions'] as List)
          .map((item) => AdminQuestion.fromJson(item))
          .toList();
      // Deduplicate by id while preserving order (keep first occurrence)
      final seen = <int>{};
      _adminQuestions = [];
      for (var q in fetched) {
        if (!seen.contains(q.id)) {
          seen.add(q.id);
          _adminQuestions.add(q);
        }
      }
      _adminTotalQuestions = data['total'];
    } catch (e) {
      debugPrint('Error fetching admin questions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createQuestion(Map<String, dynamic> questionData) async {
    try {
      await authProvider.apiService.post(ApiEndpoints.quizAdminQuestions, questionData);
      return true;
    } catch (e) {
      debugPrint('Error creating question: $e');
      return false;
    }
  }

  Future<bool> updateQuestion(int id, Map<String, dynamic> questionData) async {
    try {
      await authProvider.apiService
          .put('${ApiEndpoints.quizAdminQuestions}/$id', questionData);
      return true;
    } catch (e) {
      debugPrint('Error updating question: $e');
      return false;
    }
  }

  Future<bool> deleteQuestion(int id) async {
    try {
      await authProvider.apiService.delete('${ApiEndpoints.quizAdminQuestions}/$id');
      fetchAdminQuestions(); // Added refresh
      return true;
    } catch (e) {
      debugPrint('Error deleting question: $e');
      return false;
    }
  }

  Future<bool> bulkActionQuestions(
      {required String action,
      required List<int> ids,
      int? targetTopicId}) async {
    try {
      await authProvider.apiService.post(ApiEndpoints.quizAdminBulk, {
        'action': action,
        'ids': ids,
        'targetTopicId': targetTopicId,
      });
      fetchAdminQuestions(); // Refresh after bulk
      return true;
    } catch (e) {
      debugPrint('Error in bulk action: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadQuestionsBatch(
      List<int> bytes, String filename) async {
    try {
      final result = await authProvider.apiService.postMultipart(
          ApiEndpoints.quizAdminBatch,
          bytes: bytes,
          filename: filename);
      fetchAdminQuestions(); // Refresh after batch upload
      return result as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error in batch upload: $e');
      return null;
    }
  }

  Future<void> downloadQuestionsTemplate() async {
    try {
      final bytes = await authProvider.apiService
          .getBytes(ApiEndpoints.quizAdminTemplate);
      
      await downloadHelper.download(
        bytes, 
        'QUESTION_TEMPLATE.xlsx', 
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      );
    } catch (e) {
      debugPrint('Error downloading template: $e');
    }
  }

  Map<String, dynamic> _wallOfPain = {
    'failedQuestions': [],
    'difficultTopics': []
  };
  Map<String, dynamic> get wallOfPain => _wallOfPain;

  Future<void> fetchWallOfPain() async {
    try {
      final data = await authProvider.apiService
          .get(ApiEndpoints.quizAdminWallOfPain);
      _wallOfPain = data;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching Wall of Pain: $e');
    }
  }

  // --- ECG METHODS ---

  List<ECGCase> _ecgCases = [];
  List<ECGCase> get ecgCases => _ecgCases;

  List<ECGDiagnosis> _ecgDiagnoses = [];
  List<ECGDiagnosis> get ecgDiagnoses => _ecgDiagnoses;

  Future<void> fetchECGCases() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.ecgCases);
      if (data is List) {
        _ecgCases = data.map((e) => ECGCase.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching ECG cases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchECGDiagnoses() async {
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.ecgDiagnoses);
      if (data is List) {
        _ecgDiagnoses = data.map((e) => ECGDiagnosis.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching ECG diagnoses: $e');
    }
  }

  Future<bool> createECGCase(Map<String, dynamic> data) async {
    try {
      await authProvider.apiService.post(ApiEndpoints.ecgCases, data);
      return true;
    } catch (e) {
      debugPrint('Error creating ECG case: $e');
      return false;
    }
  }

  Future<bool> updateECGCase(int id, Map<String, dynamic> data) async {
    try {
      await authProvider.apiService.put('${ApiEndpoints.ecgCases}/$id', data);
      return true;
    } catch (e) {
      debugPrint('Error updating ECG case: $e');
      return false;
    }
  }

  Future<bool> deleteECGCase(int id) async {
    try {
      await authProvider.apiService.delete('${ApiEndpoints.ecgCases}/$id');
      return true;
    } catch (e) {
      debugPrint('Error deleting ECG case: $e');
      return false;
    }
  }

  // --- QUOTE METHODS ---

  Future<void> fetchAdminQuotes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.quizAdminQuotes);
      if (data is List) {
        _adminQuotes = data.map((e) => Quote.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching admin quotes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createQuote(String textEn, String textHu, String author,
      {String? titleEn,
      String? titleHu,
      String? iconName,
      String? customIconUrl}) async {
    try {
      await authProvider.apiService.post(ApiEndpoints.quizAdminQuotes, {
        'text_en': textEn,
        'text_hu': textHu,
        'author': author,
        'title_en': titleEn,
        'title_hu': titleHu,
        'icon_name': iconName,
        'custom_icon_url': customIconUrl,
      });
      await fetchAdminQuotes();
      return true;
    } catch (e) {
      debugPrint('Error creating quote: $e');
      return false;
    }
  }

  Future<bool> updateQuote(int id, String textEn, String textHu, String author,
      {String? titleEn,
      String? titleHu,
      String? iconName,
      String? customIconUrl}) async {
    try {
      await authProvider.apiService.put('${ApiEndpoints.quizAdminQuotes}/$id', {
        'text_en': textEn,
        'text_hu': textHu,
        'author': author,
        'title_en': titleEn,
        'title_hu': titleHu,
        'icon_name': iconName,
        'custom_icon_url': customIconUrl,
      });
      await fetchAdminQuotes();
      return true;
    } catch (e) {
      debugPrint('Error updating quote: $e');
      return false;
    }
  }

  Future<String?> uploadImage(XFile file, {String? folder}) async {
    return ApiService().uploadImage(file, folder: folder);
  }

  Future<void> fetchUploadedIcons() async {
    try {
      final data =
          await authProvider.apiService.get('${ApiEndpoints.apiUpload}?folder=icons');
      _uploadedIcons = List<String>.from(data['images']);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching uploaded icons: $e');
    }
  }

  Future<bool> deleteUploadedIcon(String iconUrl) async {
    try {
      final filename = iconUrl.split('/').last;
      await authProvider.apiService.delete('${ApiEndpoints.apiUpload}/$filename');
      _uploadedIcons.removeWhere((url) => url.endsWith(filename));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting icon: $e');
      return false;
    }
  }

  Future<String?> translateText(
      String text, String sourceLang, String targetLang) async {
    try {
      final data = await authProvider.apiService.post(ApiEndpoints.quizTranslate, {
        'text': text,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
      });
      return data['translatedText'];
    } catch (e) {
      debugPrint('Error translating text: $e');
      return null;
    }
  }

  Future<bool> deleteQuote(int id) async {
    try {
      await authProvider.apiService.delete('${ApiEndpoints.quizAdminQuotes}/$id');
      await fetchAdminQuotes();
      return true;
    } catch (e) {
      debugPrint('Error deleting quote: $e');
      return false;
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

  /// 🧹 Resets all user-specific statistics.
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

class QuestionStats {
  final String questionId;
  final String questionText;
  final String topicSlug;
  final int bloomLevel;
  final int totalAttempts;
  final int correctCount;
  final int avgTimeMs;
  final int correctPercentage;

  QuestionStats({
    required this.questionId,
    required this.questionText,
    required this.topicSlug,
    required this.bloomLevel,
    required this.totalAttempts,
    required this.correctCount,
    required this.avgTimeMs,
    required this.correctPercentage,
  });

  factory QuestionStats.fromJson(Map<String, dynamic> json) {
    return QuestionStats(
      questionId: json['question_id']?.toString() ?? '',
      questionText: json['question_text'] ?? '',
      topicSlug: json['topic_slug'] ?? '',
      bloomLevel: int.tryParse(json['bloom_level']?.toString() ?? '1') ?? 1,
      totalAttempts:
          int.tryParse(json['total_attempts']?.toString() ?? '0') ?? 0,
      correctCount: int.tryParse(json['correct_count']?.toString() ?? '0') ?? 0,
      avgTimeMs: int.tryParse(json['avg_time_ms']?.toString() ?? '0') ?? 0,
      correctPercentage:
          int.tryParse(json['correct_percentage']?.toString() ?? '0') ?? 0,
    );
  }
}

class AdminQuestion {
  final int id;
  final String? text; // Default/English text
  final String? questionTextHu; // Hungarian text
  final dynamic options; // String or List or Map ({"en": [], "hu": []})
  final dynamic content;
  final dynamic correctAnswer;
  final String? explanation; // Default/English explanation
  final String? explanationHu; // Hungarian explanation
  final int topicId;
  final String? topicNameEn;
  final String? topicNameHu;
  final int bloomLevel;
  final String? type;
  final int attempts;
  final double successRate;

  AdminQuestion({
    required this.id,
    this.text,
    this.questionTextHu,
    required this.options,
    this.content,
    required this.correctAnswer,
    this.explanation,
    this.explanationHu,
    required this.topicId,
    this.topicNameEn,
    this.topicNameHu,
    required this.bloomLevel,
    this.type,
    this.attempts = 0,
    this.successRate = 0.0,
  });

  factory AdminQuestion.fromJson(Map<String, dynamic> json) {
    try {
      return AdminQuestion(
        id: json['id'],
        text: json['text'] ?? json['question_text_en'] ?? '',
        questionTextHu: json['question_text_hu'],
        options: json['options'],
        content: json['content'],
        correctAnswer: json['correct_answer'],
        explanation: json['explanation'] ?? json['explanation_en'],
        explanationHu: json['explanation_hu'],
        topicId: json['topic_id'],
        topicNameEn: json['topic_name'] ?? json['name_en'],
        topicNameHu: json['topic_name_hu'] ?? json['name_hu'],
        bloomLevel: json['bloom_level'] ?? 1,
        type: json['type'] ?? 'single_choice',
        attempts: json['attempts'] ?? 0,
        successRate: (json['success_rate'] is int)
            ? (json['success_rate'] as int).toDouble()
            : (json['success_rate'] ?? 0.0),
      );
    } catch (e) {
      debugPrint('Error parsing AdminQuestion ID ${json['id']}: $e');
      debugPrint('JSON Content: $json');
      rethrow;
    }
  }

  // Helper to extract options list for a specific language
  List<String>? get optionsHu {
    if (options is Map) {
      final map = options as Map;
      if (map.containsKey('hu')) {
        return (map['hu'] as List).map((e) => e?.toString() ?? '').toList();
      }
    }
    return null;
  }
}

class ECGCase {
  final int id;
  final int diagnosisId;
  final String imageUrl;
  final String difficulty;
  final Map<String, dynamic> findings;
  final String? diagnosisCode;
  final String? diagnosisName;
  final List<int> secondaryDiagnosesIds;

  ECGCase({
    required this.id,
    required this.diagnosisId,
    required this.imageUrl,
    required this.difficulty,
    required this.findings,
    this.diagnosisCode,
    this.diagnosisName,
    this.secondaryDiagnosesIds = const [],
  });

  factory ECGCase.fromJson(Map<String, dynamic> json) {
    return ECGCase(
      id: json['id'],
      diagnosisId: json['diagnosis_id'],
      imageUrl: json['image_url'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
      findings: json['findings_json'] ?? {},
      diagnosisCode: json['diagnosis_code'],
      diagnosisName: json['diagnosis_name'],
      secondaryDiagnosesIds: (json['secondary_diagnoses_ids'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }
}

class ECGDiagnosis {
  final int id;
  final String code;
  final String nameEn;
  final String nameHu;
  final Map<String, dynamic>? standardFindings;

  ECGDiagnosis({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameHu,
    this.standardFindings,
  });

  factory ECGDiagnosis.fromJson(Map<String, dynamic> json) {
    return ECGDiagnosis(
      id: json['id'],
      code: json['code'],
      nameEn: json['name_en'],
      nameHu: json['name_hu'] ?? '',
      standardFindings: json['standard_findings_json'] != null
          ? (json['standard_findings_json'] is String
              ? jsonDecode(json['standard_findings_json'])
              : json['standard_findings_json'])
          : null,
    );
  }
}
