import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'auth_provider.dart';
import 'api_service.dart';

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
      totalAnswered: int.tryParse(json['total_answered']?.toString() ?? '0') ?? 0,
      correctAnswered: int.tryParse(json['correct_answered']?.toString() ?? '0') ?? 0,
      masteryPercent: int.tryParse(json['mastery_percent']?.toString() ?? '0') ?? 0,
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
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}

class ActivityData {
  final DateTime date;
  final int count;
  final int correctCount;

  ActivityData({required this.date, required this.count, required this.correctCount});

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      date: DateTime.parse(json['date']),
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
      lastActivity: json['last_activity'] != null ? DateTime.parse(json['last_activity']) : null,
      pathophysiology: parseSubject('pathophysiology'),
      pathology: parseSubject('pathology'),
      microbiology: parseSubject('microbiology'),
      pharmacology: parseSubject('pharmacology'),
      ecg: parseSubject('ecg'),
      cases: parseSubject('cases'),
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

class StatsProvider with ChangeNotifier {
  final AuthProvider authProvider;
  List<SubjectMastery> _subjectMastery = [];
  List<ActivityData> _activity = [];
  bool _isLoading = false;
  List<UserPerformance> _usersPerformance = [];
  List<UserHistoryEntry> _userHistory = [];

  StatsProvider(this.authProvider);

  List<SubjectMastery> get subjectMastery => _subjectMastery;
  List<ActivityData> get activity => _activity;
  bool get isLoading => _isLoading;
  List<UserPerformance> get usersPerformance => _usersPerformance;
  List<UserHistoryEntry> get userHistory => _userHistory;

  List<String> _uploadedIcons = [];
  List<String> get uploadedIcons => _uploadedIcons;

  List<Quote> _adminQuotes = [];
  List<Quote> get adminQuotes => _adminQuotes;

  Quote? _currentQuote;
  Quote? get currentQuote => _currentQuote;

  final Map<String, List<Map<String, dynamic>>> _sectionMastery = {};
  Map<String, List<Map<String, dynamic>>> get sectionMastery => _sectionMastery;

  String get _baseUrl => '${ApiService.baseUrl}/stats';

  Future<void> fetchSummary() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/summary'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _subjectMastery = data.map((item) => SubjectMastery.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActivity({String timeframe = 'week', DateTime? anchorDate}) async {
    try {
      String url = '$_baseUrl/activity?timeframe=$timeframe';
      if (anchorDate != null) {
        // Format YYYY-MM-DD
        String dateStr = anchorDate.toIso8601String().split('T')[0];
        url += '&anchorDate=$dateStr';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _activity = data.map((item) => ActivityData.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching activity: $e');
    }
  }

  Future<void> fetchSubjectDetail(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/subject/$slug'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _sectionMastery[slug] = data.cast<Map<String, dynamic>>();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching subject detail: $e');
    }
  }

  // --- ADMIN METHODS ---

  List<QuestionStats> _questionStats = [];
  Map<String, dynamic> _userStats = {'total_users': 0, 'avg_session_mins': 0, 'avg_bloom': 1.0};
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
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/stats/inventory-summary'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        _inventorySummary = json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching inventory summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUsersPerformance() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/users-performance'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _usersPerformance = data.map((item) => UserPerformance.fromJson(item)).toList();
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
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/users/$userId/history?limit=$limit'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _userHistory = data.map((item) => UserHistoryEntry.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching user history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdminSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/summary'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
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
      String url = '$_baseUrl/questions';
      if (topicId != null) {
        url += '?topicId=$topicId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _questionStats = (data['questionStats'] as List).map((item) => QuestionStats.fromJson(item)).toList();
        _userStats = data['userStats'] ?? {'total_users': 0, 'avg_session_mins': 0};
      } else {
        debugPrint('Error fetching question stats: ${response.statusCode}');
      }
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
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/quiz/topics'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _topics = data.cast<Map<String, dynamic>>();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching topics: $e');
    }
  }

  Future<bool> createTopic(String nameEn, String nameHu, int? parentId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/quiz/admin/topics'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name_en': nameEn,
          'name_hu': nameHu,
          'parent_id': parentId,
        }),
      );

      if (response.statusCode == 201) {
        // Refresh topics list
        await fetchTopics();
        return true;
      } else {
        final error = json.decode(response.body);
        debugPrint('Error creating topic: ${error['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating topic: $e');
      return false;
    }
  }

  Future<String?> deleteTopic(int topicId, {bool force = false}) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/quiz/admin/topics/$topicId${force ? '?force=true' : ''}'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        // Refresh topics list
        await fetchTopics();
        return null; // Success
      } else {
        final error = json.decode(response.body);
        return error['message'] ?? 'Failed to delete topic';
      }
    } catch (e) {
      debugPrint('Error deleting topic: $e');
      return 'Network error';
    }
  }


  Future<String?> updateTopic(int id, String nameEn, String nameHu) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/quiz/admin/topics/$id'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name_en': nameEn,
          'name_hu': nameHu,
        }),
      );

      if (response.statusCode == 200) {
        // Optimistic update
        final index = _topics.indexWhere((t) => t['id'] == id);
        if (index != -1) {
          _topics[index]['name_en'] = nameEn;
          _topics[index]['name_hu'] = nameHu;
          notifyListeners();
        }
        
        fetchTopics(); // Background refresh
        return null;
      } else {
        final error = json.decode(response.body);
        return error['message'] ?? 'Failed to update topic';
      }
    } catch (e) {
      debugPrint('Error updating topic: $e');
      return 'Network error';
    }
  }


  Future<void> fetchAdminQuestions({
    int page = 1, 
    String search = '', 
    String type = '', 
    int? bloomLevel, 
    int? topicId,
    String sortBy = 'created_at',
    String order = 'DESC'
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String url = '${ApiService.baseUrl}/quiz/admin/questions?page=$page&search=$search&sortBy=$sortBy&order=$order';
      if (type.isNotEmpty) url += '&type=$type';
      if (bloomLevel != null) url += '&bloom_level=$bloomLevel';
      if (topicId != null) url += '&topic_id=$topicId';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _adminQuestions = (data['questions'] as List)
            .map((item) => AdminQuestion.fromJson(item))
            .toList();
        _adminTotalQuestions = data['total'];
      }
    } catch (e) {
      debugPrint('Error fetching admin questions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createQuestion(Map<String, dynamic> questionData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/quiz/admin/questions'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(questionData),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating question: $e');
      return false;
    }
  }

  Future<bool> updateQuestion(int id, Map<String, dynamic> questionData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/quiz/admin/questions/$id'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(questionData),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating question: $e');
      return false;
    }
  }

  Future<bool> deleteQuestion(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/quiz/admin/questions/$id'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting question: $e');
      return false;
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
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/ecg/cases'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
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
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/ecg/diagnoses'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _ecgDiagnoses = data.map((e) => ECGDiagnosis.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching ECG diagnoses: $e');
    }
  }

  Future<bool> createECGCase(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/ecg/cases'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode(data),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating ECG case: $e');
      return false;
    }
  }

  Future<bool> updateECGCase(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/ecg/cases/$id'),
         headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating ECG case: $e');
      return false;
    }
  }

  Future<bool> deleteECGCase(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/ecg/cases/$id'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );
      return response.statusCode == 200;
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
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/quiz/admin/quotes'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _adminQuotes = data.map((e) => Quote.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching admin quotes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createQuote(String textEn, String textHu, String author, {String? titleEn, String? titleHu, String? iconName, String? customIconUrl}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/quiz/admin/quotes'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'text_en': textEn, 
          'text_hu': textHu, 
          'author': author,
          'title_en': titleEn,
          'title_hu': titleHu,
          'icon_name': iconName,
          'custom_icon_url': customIconUrl,
        }),
      );
      if (response.statusCode == 201) {
        await fetchAdminQuotes();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating quote: $e');
      return false;
    }
  }

  Future<bool> updateQuote(int id, String textEn, String textHu, String author, {String? titleEn, String? titleHu, String? iconName, String? customIconUrl}) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/quiz/admin/quotes/$id'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'text_en': textEn, 
          'text_hu': textHu, 
          'author': author,
          'title_en': titleEn,
          'title_hu': titleHu,
          'icon_name': iconName,
          'custom_icon_url': customIconUrl,
        }),
      );
      if (response.statusCode == 200) {
        await fetchAdminQuotes();
        return true;
      }
      return false;
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
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/upload?folder=icons'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _uploadedIcons = List<String>.from(data['images']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching uploaded icons: $e');
    }
  }

  Future<bool> deleteUploadedIcon(String iconUrl) async {
    try {
      final filename = iconUrl.split('/').last;
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/api/upload/$filename'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );

      if (response.statusCode == 200) {
        _uploadedIcons.removeWhere((url) => url.endsWith(filename));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting icon: $e');
      return false;
    }
  }

  Future<String?> translateText(String text, String sourceLang, String targetLang) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/quiz/translate'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'text': text,
          'sourceLang': sourceLang,
          'targetLang': targetLang,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['translatedText'];
      }
      return null;
    } catch (e) {
      debugPrint('Error translating text: $e');
      return null;
    }
  }

  Future<bool> deleteQuote(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/quiz/admin/quotes/$id'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );
      if (response.statusCode == 200) {
        await fetchAdminQuotes();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting quote: $e');
      return false;
    }
  }

  Future<void> fetchCurrentQuote() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/quiz/quote'),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );
      if (response.statusCode == 200) {
        _currentQuote = Quote.fromJson(json.decode(response.body));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching current quote: $e');
    }
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
      totalAttempts: int.tryParse(json['total_attempts']?.toString() ?? '0') ?? 0,
      correctCount: int.tryParse(json['correct_count']?.toString() ?? '0') ?? 0,
      avgTimeMs: int.tryParse(json['avg_time_ms']?.toString() ?? '0') ?? 0,
      correctPercentage: int.tryParse(json['correct_percentage']?.toString() ?? '0') ?? 0,
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
      secondaryDiagnosesIds: (json['secondary_diagnoses_ids'] as List?)?.map((e) => e as int).toList() ?? [],
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
