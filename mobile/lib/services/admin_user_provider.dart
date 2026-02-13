import 'package:flutter/foundation.dart';
import 'auth_provider.dart';
import 'api_service.dart';
import '../core/api_endpoints.dart';
import '../models/performance.dart';
import '../models/user_history_entry.dart';
import '../models/question_stats.dart';

/// Manages admin user-related operations: user lists, performance,
/// history, role changes, and admin summary stats.
class AdminUserProvider with ChangeNotifier {
  final AuthProvider authProvider;

  AdminUserProvider(this.authProvider);

  ApiService get apiService => authProvider.apiService;

  // --- State ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

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

  List<QuestionStats> _questionStats = [];
  Map<String, dynamic> _userStats = {
    'total_users': 0,
    'avg_session_mins': 0,
    'avg_bloom': 1.0,
  };
  List<Map<String, dynamic>> _adminSummary = [];
  List<dynamic> _inventorySummary = [];

  List<QuestionStats> get questionStats => _questionStats;
  Map<String, dynamic> get userStats => _userStats;
  List<Map<String, dynamic>> get adminSummary => _adminSummary;
  List<dynamic> get inventorySummary => _inventorySummary;

  // --- Fetchers ---

  Future<void> fetchUsersPerformance(
      {int page = 1, int limit = 50, String search = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final endpoint =
          '${ApiEndpoints.statsAdminUsersPerformance}?page=$page&limit=$limit&search=${Uri.encodeComponent(search)}';
      final data = await apiService.get(endpoint);
      if (data is Map<String, dynamic>) {
        _usersPerformance = (data['users'] as List)
            .map((item) => UserPerformance.fromJson(item))
            .toList();
        _totalStudents = data['total'] ?? 0;
      } else if (data is List) {
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
      final data = await apiService
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
      final data = await apiService
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

  Future<void> fetchAdminsPerformance(
      {int page = 1, int limit = 50, String search = ''}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final endpoint =
          '${ApiEndpoints.adminAdmins}?page=$page&limit=$limit&search=${Uri.encodeComponent(search)}';
      final data = await apiService.get(endpoint);
      if (data is Map<String, dynamic>) {
        _adminsPerformance = (data['users'] as List)
            .map((item) => UserPerformance.fromJson(item))
            .toList();
        _totalAdmins = data['total'] ?? 0;
      } else if (data is List) {
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
      await apiService
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
      await apiService.delete('${ApiEndpoints.adminUserBase}/$userId');
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
      await apiService
          .post(ApiEndpoints.adminNotify, {'userId': userId, 'message': message});
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  Future<void> fetchAdminSummary() async {
    try {
      final data = await apiService.get(ApiEndpoints.statsAdminSummary);
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

      final data = await apiService.get(endpoint);
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

  Future<void> fetchInventorySummary() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await apiService.get(ApiEndpoints.statsInventorySummary);
      _inventorySummary = data;
    } catch (e) {
      debugPrint('Error fetching inventory summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetState() {
    _isLoading = false;
    _usersPerformance = [];
    _totalStudents = 0;
    _adminsPerformance = [];
    _totalAdmins = 0;
    _userHistory = [];
    _questionStats = [];
    _userStats = {'total_users': 0, 'avg_session_mins': 0, 'avg_bloom': 1.0};
    _adminSummary = [];
    _inventorySummary = [];
    notifyListeners();
  }
}
