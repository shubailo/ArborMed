import 'package:flutter/foundation.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'api_service.dart';
import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/features/analytics/models/performance.dart';
import 'package:arbor_med/features/analytics/models/user_history_entry.dart';
import 'package:arbor_med/features/analytics/models/question_stats.dart';

/// Manages admin user-related operations: user lists, performance,
/// history, role changes, and admin summary stats.
class AdminUserProvider with ChangeNotifier {
  final AuthProvider authProvider;

  AdminUserProvider(this.authProvider);

  ApiService get apiService => authProvider.apiService;

  // --- State ---
  bool _isLoading = false;
  bool get isLoading => _isLoading || dashboardLoading || directoryLoading || historyLoading;
  int _summaryRequest = 0;
  int _questionStatsRequest = 0;
  bool _summaryLoading = false;
  bool _questionStatsLoading = false;
  bool _summaryFailed = false;
  bool _questionStatsFailed = false;
  bool get dashboardLoading => _summaryLoading || _questionStatsLoading;
  bool get dashboardFailed => _summaryFailed || _questionStatsFailed;
  int _directoryRequest = 0;
  String? _directoryEndpoint;
  Future<void> Function()? _reloadDirectory;
  int _directoryPage = 1;
  int get directoryPage => _directoryPage;
  bool _directoryLoading = false;
  bool get directoryLoading => _directoryLoading;
  bool _directoryFailed = false;
  bool get directoryFailed => _directoryFailed;
  int _historyRequest = 0;
  int? _historyUserId;
  int? get historyUserId => _historyUserId;
  bool _historyLoading = false;
  bool get historyLoading => _historyLoading;
  bool _historyFailed = false;
  bool get historyFailed => _historyFailed;

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

  Future<({List<UserPerformance> users, int total})> _readPage(String endpoint) async {
    final data = await apiService.get(endpoint);
    final rows = data is List ? data : data['users'] as List;
    final users = rows.map((item) => UserPerformance.fromJson(item)).toList();
    return (users: users, total: data is List ? users.length : data['total'] as int);
  }

  /// The command palette has its own result list and never changes the directory.
  Future<List<UserPerformance>> searchStudents(String search) async {
    final page = await _readPage('${ApiEndpoints.statsAdminUsersPerformance}?page=1&limit=50&search=${Uri.encodeComponent(search)}');
    return page.users;
  }

  Future<void> fetchUsersPerformance({int page = 1, int limit = 50, String search = '',
      String sort = 'activity', bool ascending = false}) =>
      _fetchDirectory(true, page, limit, search, sort, ascending);

  Future<void> fetchAdminsPerformance({int page = 1, int limit = 50, String search = '',
      String sort = 'activity', bool ascending = false}) =>
      _fetchDirectory(false, page, limit, search, sort, ascending);

  Future<void> _fetchDirectory(bool students, int page, int limit, String search,
      String sort, bool ascending) async {
    final endpoint = Uri(path: students ? ApiEndpoints.statsAdminUsersPerformance : ApiEndpoints.adminAdmins,
        queryParameters: {'page': '$page', 'limit': '$limit', 'search': search,
          'sort': sort, 'direction': ascending ? 'asc' : 'desc'}).toString();
    final request = ++_directoryRequest;
    if (_directoryEndpoint != endpoint) {
      if (students) {
        _usersPerformance = [];
        _totalStudents = 0;
      } else {
        _adminsPerformance = [];
        _totalAdmins = 0;
      }
    }
    _directoryEndpoint = endpoint;
    _directoryPage = page;
    _reloadDirectory = () => _fetchDirectory(students, page, limit, search, sort, ascending);
    _directoryLoading = true;
    _directoryFailed = false;
    notifyListeners();
    try {
      final result = await _readPage(endpoint);
      if (_directoryRequest != request) return;
      final lastPage = result.total == 0 ? 1 : (result.total / limit).ceil();
      if (page > lastPage) {
        await _fetchDirectory(students, lastPage, limit, search, sort, ascending);
        return;
      }
      if (students) {
        _usersPerformance = result.users;
        _totalStudents = result.total;
      } else {
        _adminsPerformance = result.users;
        _totalAdmins = result.total;
      }
    } catch (e) {
      if (_directoryRequest == request) _directoryFailed = true;
      debugPrint('Error fetching the user directory: $e');
    } finally {
      if (_directoryRequest == request) {
        _directoryLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchUserHistory(int userId, {int limit = 100}) async {
    final request = ++_historyRequest;
    _historyUserId = userId;
    _userHistory = [];
    _historyLoading = true;
    _historyFailed = false;
    notifyListeners();

    try {
      final data = await apiService
          .get('${ApiEndpoints.statsAdminUserBase}/$userId/history?limit=$limit');
      if (_historyRequest != request) return;
      _userHistory = (data as List).map((item) => UserHistoryEntry.fromJson(item)).toList();
    } catch (e) {
      if (_historyRequest == request) _historyFailed = true;
      debugPrint('Error fetching user history: $e');
    } finally {
      if (_historyRequest == request) {
        _historyLoading = false;
        notifyListeners();
      }
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

  Future<bool> updateUserRole(int userId, String newRole) async {
    try {
      await apiService
          .put(ApiEndpoints.adminUserRole, {'userId': userId, 'newRole': newRole});
      await _reloadDirectory?.call();
      return true;
    } catch (e) {
      debugPrint('Error updating role: $e');
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      await apiService.delete('${ApiEndpoints.adminUserBase}/$userId');
      await _reloadDirectory?.call();
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

  Future<int> sendBroadcast(String title, String message, String requestId) async {
    final result = await apiService.post(ApiEndpoints.adminBroadcast, {
      'title': title, 'message': message, 'requestId': requestId,
    });
    return result['delivered'] as int;
  }

  Future<void> fetchAdminSummary({int? topicId}) async {
    final request = ++_summaryRequest;
    _adminSummary = [];
    _summaryFailed = false;
    _summaryLoading = true;
    notifyListeners();
    try {
      final endpoint = ApiEndpoints.statsAdminSummary;
      final data = await apiService.get(topicId == null ? endpoint : '$endpoint?topicId=$topicId');
      if (request != _summaryRequest) return;
      _adminSummary = (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (request == _summaryRequest) _summaryFailed = true;
      debugPrint('Error fetching admin summary: $e');
    } finally {
      if (request == _summaryRequest) {
        _summaryLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchQuestionStats({int? topicId}) async {
    final request = ++_questionStatsRequest;
    _questionStats = [];
    _userStats = {'total_users': 0, 'avg_session_mins': 0, 'avg_bloom': 1.0};
    _questionStatsFailed = false;
    _questionStatsLoading = true;
    notifyListeners();

    try {
      String endpoint = ApiEndpoints.statsQuestions;
      if (topicId != null) {
        endpoint += '?topicId=$topicId';
      }

      final data = await apiService.get(endpoint);
      if (request != _questionStatsRequest) return;
      _questionStats = (data['questionStats'] as List)
          .map((item) => QuestionStats.fromJson(item))
          .toList();
      _userStats =
          data['userStats'] ?? {'total_users': 0, 'avg_session_mins': 0};
    } catch (e) {
      if (request == _questionStatsRequest) _questionStatsFailed = true;
      debugPrint('Error fetching question stats: $e');
    } finally {
      if (request == _questionStatsRequest) {
        _questionStatsLoading = false;
        notifyListeners();
      }
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
    _directoryRequest++;
    _historyRequest++;
    _reloadDirectory = null;
    _directoryEndpoint = null;
    _directoryPage = 1;
    _directoryLoading = _directoryFailed = false;
    _historyUserId = null;
    _historyLoading = _historyFailed = false;
    _isLoading = false;
    _usersPerformance = [];
    _totalStudents = 0;
    _adminsPerformance = [];
    _totalAdmins = 0;
    _userHistory = [];
    _questionStats = [];
    _userStats = {'total_users': 0, 'avg_session_mins': 0, 'avg_bloom': 1.0};
    _adminSummary = [];
    _summaryRequest++;
    _questionStatsRequest++;
    _summaryLoading = _questionStatsLoading = false;
    _summaryFailed = _questionStatsFailed = false;
    _inventorySummary = [];
    notifyListeners();
  }
}
