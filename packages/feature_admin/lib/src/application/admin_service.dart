import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:arbormed_core/arbormed_core.dart' hide AdminQuestion, UserPerformance, UserHistoryEntry;
import 'package:core_interop/core_interop.dart';

class AdminService extends ChangeNotifier {
  final Logger _logger;
  final DatabaseService _dbService;
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- Questions ---
  List<AdminQuestion> _adminQuestions = [];
  int _adminTotalQuestions = 0;
  List<AdminQuestion> get adminQuestions => _adminQuestions;
  int get adminTotalQuestions => _adminTotalQuestions;

  // --- Users ---
  List<UserPerformance> _usersPerformance = [];
  int _totalStudents = 0;
  List<UserPerformance> _adminsPerformance = [];
  int _totalAdmins = 0;
  List<UserHistoryEntry> _userHistory = [];

  List<UserPerformance> get usersPerformance => _usersPerformance;
  int get totalStudents => _totalStudents;
  List<UserPerformance> get adminsPerformance => _adminsPerformance;
  int get totalAdmins => _totalAdmins;
  List<UserHistoryEntry> get userHistory => _userHistory;

  // --- Stats / Analytics ---
  Map<String, dynamic> _wallOfPain = {
    'failedQuestions': [],
    'difficultTopics': [],
  };
  Map<String, dynamic> get wallOfPain => _wallOfPain;

  List<Map<String, dynamic>> _adminSummary = [];
  List<Map<String, dynamic>> get adminSummary => _adminSummary;

  // --- ECG ---
  List<ECGCase> _ecgCases = [];
  List<ECGDiagnosis> _ecgDiagnoses = [];
  List<ECGCase> get ecgCases => _ecgCases;
  List<ECGDiagnosis> get ecgDiagnoses => _ecgDiagnoses;

  AdminService({Logger? logger, required DatabaseService dbService})
      : _logger = logger ?? Logger(),
        _dbService = dbService;

  // --- Question Methods ---

  Future<void> fetchAdminQuestions({
    int page = 1,
    String search = '',
    String type = '',
    int? bloomLevel,
    int? topicId,
    String sortBy = 'created_at',
    String order = 'DESC',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String endpoint =
          '${ApiEndpoints.quizAdminQuestions}?page=$page&search=$search&sortBy=$sortBy&order=$order';
      if (type.isNotEmpty) endpoint += '&type=$type';
      if (bloomLevel != null) endpoint += '&bloom_level=$bloomLevel';
      if (topicId != null) endpoint += '&topic_id=$topicId';

      final data = await _apiService.get(endpoint);
      final fetched = (data['questions'] as List)
          .map((item) => AdminQuestion.fromJson(item))
          .toList();

      final seen = <int>{};
      _adminQuestions = [];
      for (var q in fetched) {
        if (!seen.contains(q.id)) {
          seen.add(q.id);
          _adminQuestions.add(q);
        }
      }
      _adminTotalQuestions = data['total'] ?? 0;
      _logger.i('Fetched ${_adminQuestions.length} admin questions');
    } catch (e) {
      _logger.e('Error fetching admin questions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createQuestion(Map<String, dynamic> questionData) async {
    try {
      await _apiService.post(ApiEndpoints.quizAdminQuestions, questionData);
      return true;
    } catch (e) {
      _logger.e('Error creating question: $e');
      return false;
    }
  }

  Future<bool> updateQuestion(int id, Map<String, dynamic> questionData) async {
    try {
      await _apiService.put(
          '${ApiEndpoints.quizAdminQuestions}/$id', questionData);
      return true;
    } catch (e) {
      _logger.e('Error updating question: $id - $e');
      return false;
    }
  }

  Future<bool> deleteQuestion(int id) async {
    try {
      await _apiService.delete('${ApiEndpoints.quizAdminQuestions}/$id');
      return true;
    } catch (e) {
      _logger.e('Error deleting question: $id - $e');
      return false;
    }
  }

  // --- User Methods ---

  Future<void> fetchUsersPerformance(
      {int page = 1, int limit = 50, String search = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final endpoint =
          '${ApiEndpoints.statsAdminUsersPerformance}?page=$page&limit=$limit&search=${Uri.encodeComponent(search)}';
      final data = await _apiService.get(endpoint);
      if (data is Map<String, dynamic>) {
        _usersPerformance = (data['users'] as List)
            .map((item) => UserPerformance.fromJson(item))
            .toList();
        _totalStudents = data['total'] ?? 0;
      }
      _logger.i('Fetched ${_usersPerformance.length} users performance');
    } catch (e) {
      _logger.e('Error fetching users performance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserHistory(int userId, {int limit = 100}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.get(
          '${ApiEndpoints.statsAdminUserBase}/$userId/history?limit=$limit');
      if (data is List) {
        _userHistory =
            data.map((item) => UserHistoryEntry.fromJson(item)).toList();
      }
    } catch (e) {
      _logger.e('Error fetching user history: $userId - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdminSummary() async {
    try {
      final data = await _apiService.get(ApiEndpoints.statsAdminSummary);
      if (data is List) {
        _adminSummary = data.cast<Map<String, dynamic>>();
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error fetching admin summary: $e');
    }
  }

  Future<void> fetchWallOfPain() async {
    try {
      final data = await _apiService.get(ApiEndpoints.quizAdminWallOfPain);
      _wallOfPain = data;
      notifyListeners();
    } catch (e) {
      _logger.e('Error fetching Wall of Pain: $e');
    }
  }

  // --- ECG Methods ---

  Future<void> fetchECGCases() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.get(ApiEndpoints.ecgCases);
      if (data is List) {
        _ecgCases = data.map((e) => ECGCase.fromJson(e)).toList();
      }
    } catch (e) {
      _logger.e('Error fetching ECG cases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchECGDiagnoses() async {
    try {
      final data = await _apiService.get(ApiEndpoints.ecgDiagnoses);
      if (data is List) {
        _ecgDiagnoses = data.map((e) => ECGDiagnosis.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Error fetching ECG diagnoses: $e');
    }
  }

  void resetState() {
    _isLoading = false;
    _adminQuestions = [];
    _adminTotalQuestions = 0;
    _usersPerformance = [];
    _totalStudents = 0;
    _adminsPerformance = [];
    _totalAdmins = 0;
    _userHistory = [];
    _wallOfPain = {'failedQuestions': [], 'difficultTopics': []};
    _adminSummary = [];
    _ecgCases = [];
    _ecgDiagnoses = [];
    notifyListeners();
  }
}
