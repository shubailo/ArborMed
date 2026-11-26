import 'package:flutter/foundation.dart';
import 'download/download_helper.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'api_service.dart';
import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/core/api_exceptions.dart';
import '../core/models/admin_question.dart';
import 'package:arbor_med/features/analytics/models/ecg_case.dart';
import 'package:arbor_med/features/analytics/models/ecg_diagnosis.dart';
import 'package:arbor_med/features/analytics/models/report.dart';

/// Manages admin CMS operations: question CRUD, bulk actions,
/// batch uploads, ECG case management, and wall of pain analytics.
class AdminQuestionProvider with ChangeNotifier {
  final AuthProvider authProvider;

  AdminQuestionProvider(this.authProvider);

  ApiService get apiService => authProvider.apiService;

  (int?, String?)? _account;
  int _generation = 0;
  (int, int) get actionSession => (authProvider.sessionRevision, _generation);

  void updateAccount(int? id, String? role) {
    if (_account == (id, role)) return;
    _account = (id, role);
    resetState();
  }

  // --- State ---
  bool _isLoading = false;
  bool get isLoading => _isLoading || _questionsLoading || _ecgCasesLoading;
  bool _questionsLoading = false;
  bool get questionsLoading => _questionsLoading;
  bool _questionsFailed = false;
  bool get questionsFailed => _questionsFailed;
  int _questionRequest = 0;
  Uri? _questionListUri;

  List<AdminQuestion> _adminQuestions = [];
  int _adminTotalQuestions = 0;
  List<AdminQuestion> get adminQuestions => _adminQuestions;
  int get adminTotalQuestions => _adminTotalQuestions;

  Map<String, dynamic> _wallOfPain = {
    'failedQuestions': [],
    'difficultTopics': [],
  };
  Map<String, dynamic> get wallOfPain => _wallOfPain;

  int _ecgCasesRequest = 0;
  int _ecgDiagnosesRequest = 0;
  bool _ecgCasesLoading = false;
  bool _ecgCasesFailed = false;
  bool _ecgDiagnosesFailed = false;
  bool get ecgCasesLoading => _ecgCasesLoading;
  bool get ecgCasesFailed => _ecgCasesFailed;
  bool get ecgDiagnosesFailed => _ecgDiagnosesFailed;

  List<ECGCase> _ecgCases = [];
  List<ECGCase> get ecgCases => _ecgCases;

  List<ECGDiagnosis> _ecgDiagnoses = [];
  List<ECGDiagnosis> get ecgDiagnoses => _ecgDiagnoses;
  List<Report> _questionReports = [];
  List<Report> get questionReports => _questionReports;
  int _reportsRequest = 0;
  int? _reportsQuestionId;
  int? get reportsQuestionId => _reportsQuestionId;
  bool _reportsLoading = false;
  bool get reportsLoading => _reportsLoading;
  bool _reportsLoadFailed = false;
  bool get reportsLoadFailed => _reportsLoadFailed;

  // --- Question CRUD ---

  Future<void> fetchAdminQuestions(
      {int page = 1,
      String search = '',
      String type = '',
      int? bloomLevel,
      int? topicId,
      String sortBy = 'created_at',
      String order = 'DESC'}) {
    final uri = Uri(path: ApiEndpoints.quizAdminQuestions, queryParameters: {
      'page': '$page', 'search': search, 'sortBy': sortBy, 'order': order,
      if (type.isNotEmpty) 'type': type,
      if (bloomLevel != null) 'bloom_level': '$bloomLevel',
      if (topicId != null) 'topic_id': '$topicId',
    });
    return _loadQuestions(uri);
  }

  Future<(List<AdminQuestion>, int)> _readQuestions(Uri uri) async {
    final data = await apiService.get(uri.toString());
    final seen = <int>{};
    final questions = (data['questions'] as List)
        .map((item) => AdminQuestion.fromJson(item))
        .where((q) => seen.add(q.id))
        .toList();
    return (questions, data['total'] as int);
  }

  Future<List<AdminQuestion>> searchQuestions(String search) async {
    final generation = _generation;
    final uri = Uri(path: ApiEndpoints.quizAdminQuestions,
        queryParameters: {'search': search, 'limit': '20'});
    final (questions, _) = await _readQuestions(uri);
    return generation == _generation ? questions : [];
  }

  Future<void> _loadQuestions(Uri uri) async {
    final request = ++_questionRequest;
    if (uri != _questionListUri) {
      _adminQuestions = [];
      _adminTotalQuestions = 0;
    }
    _questionListUri = uri;
    _questionsLoading = true;
    _questionsFailed = false;
    notifyListeners();
    try {
      final (questions, total) = await _readQuestions(uri);
      if (request != _questionRequest) return;
      _adminQuestions = questions;
      _adminTotalQuestions = total;
    } catch (e) {
      if (request != _questionRequest) return;
      _adminQuestions = [];
      _adminTotalQuestions = 0;
      _questionsFailed = true;
      debugPrint('Error fetching admin questions: $e');
    } finally {
      if (request == _questionRequest) {
        _questionsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _refreshQuestions(int generation) async {
    if (generation != _generation) return;
    await _loadQuestions(_questionListUri ?? Uri(path: ApiEndpoints.quizAdminQuestions));
  }

  Future<bool> createQuestion(Map<String, dynamic> questionData) async {
    try {
      await apiService.post(ApiEndpoints.quizAdminQuestions, questionData);
      return true;
    } catch (e) {
      debugPrint('Error creating question: $e');
      return false;
    }
  }

  Future<bool> updateQuestion(int id, Map<String, dynamic> questionData) async {
    try {
      await apiService.put(
          '${ApiEndpoints.quizAdminQuestions}/$id', questionData);
      return true;
    } catch (e) {
      debugPrint('Error updating question: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchQuestionAnalytics(int id) async {
    try {
      final data =
          await apiService.get('${ApiEndpoints.quizAdminQuestions}/$id/analytics');
      if (data is Map<String, dynamic>) {
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching question analytics: $e');
      return null;
    }
  }

  Future<bool> deleteQuestion(int id) async {
    final generation = _generation;
    try {
      await apiService.delete('${ApiEndpoints.quizAdminQuestions}/$id');
      await _refreshQuestions(generation);
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
    final generation = _generation;
    try {
      await apiService.post(ApiEndpoints.quizAdminBulk, {
        'action': action,
        'ids': ids,
        'targetTopicId': targetTopicId,
      });
      await _refreshQuestions(generation);
      return true;
    } catch (e) {
      debugPrint('Error in bulk action: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadQuestionsBatch(
      List<int> bytes, String filename) async {
    final generation = _generation;
    try {
      final result = await apiService.postMultipart(ApiEndpoints.quizAdminBatch,
          bytes: bytes, filename: filename);
      await _refreshQuestions(generation);
      return result as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Error in batch upload: $e');
      return null;
    }
  }

  Future<void> downloadQuestionsTemplate() async {
    final session = actionSession;
    final bytes = await apiService.getBytes(ApiEndpoints.quizAdminTemplate);
    if (actionSession != session) return;
    await downloadHelper.download(bytes, 'QUESTION_TEMPLATE.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  }

  Future<void> fetchWallOfPain() async {
    try {
      final data = await apiService.get(ApiEndpoints.quizAdminWallOfPain);
      _wallOfPain = data;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching Wall of Pain: $e');
    }
  }

  // --- ECG CRUD ---

  Future<void> fetchECGCases() async {
    final request = ++_ecgCasesRequest;
    _ecgCasesLoading = true;
    _ecgCasesFailed = false;
    notifyListeners();
    try {
      final data = await apiService.get(ApiEndpoints.ecgCases);
      if (request != _ecgCasesRequest) return;
      _ecgCases = (data as List).map((e) => ECGCase.fromJson(e)).toList();
    } catch (e) {
      if (request != _ecgCasesRequest) return;
      _ecgCases = [];
      _ecgCasesFailed = true;
      debugPrint('Error fetching ECG cases: $e');
    } finally {
      if (request == _ecgCasesRequest) {
        _ecgCasesLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchECGDiagnoses() async {
    final request = ++_ecgDiagnosesRequest;
    _ecgDiagnosesFailed = false;
    notifyListeners();
    try {
      final data = await apiService.get(ApiEndpoints.ecgDiagnoses);
      if (request != _ecgDiagnosesRequest) return;
      _ecgDiagnoses = (data as List).map((e) => ECGDiagnosis.fromJson(e)).toList();
    } catch (e) {
      if (request != _ecgDiagnosesRequest) return;
      _ecgDiagnosesFailed = true;
      debugPrint('Error fetching ECG diagnoses: $e');
    } finally {
      if (request == _ecgDiagnosesRequest) notifyListeners();
    }
  }

  Future<bool> createECGCase(Map<String, dynamic> data) async {
    try {
      await apiService.post(ApiEndpoints.ecgCases, data);
      return true;
    } catch (e) {
      debugPrint('Error creating ECG case: $e');
      return false;
    }
  }

  Future<bool> updateECGCase(int id, Map<String, dynamic> data) async {
    try {
      await apiService.put('${ApiEndpoints.ecgCases}/$id', data);
      return true;
    } catch (e) {
      debugPrint('Error updating ECG case: $e');
      return false;
    }
  }

  Future<bool> deleteECGCase(int id) async {
    try {
      await apiService.delete('${ApiEndpoints.ecgCases}/$id');
      return true;
    } catch (e) {
      debugPrint('Error deleting ECG case: $e');
      return false;
    }
  }

  Future<void> fetchReports(int questionId) async {
    final request = ++_reportsRequest;
    _reportsQuestionId = questionId;
    _questionReports = [];
    _reportsLoading = true;
    _reportsLoadFailed = false;
    notifyListeners();

    try {
      final data = await apiService.get(
        '${ApiEndpoints.reportsQuestion}/$questionId',
      );
      if (request != _reportsRequest) return;
      _questionReports = (data as List)
          .map((item) => Report.fromJson(item))
          .toList();
    } catch (e) {
      if (request != _reportsRequest) return;
      _reportsLoadFailed = true;
      debugPrint('Error fetching reports: $e');
    } finally {
      if (request == _reportsRequest) {
        _reportsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> updateReportStatus(int reportId, String status,
      {String? adminNotes}) async {
    final request = _reportsRequest;
    try {
      final result = await apiService.patch('${ApiEndpoints.reportsBase}/$reportId', {
        'status': status,
        if (adminNotes != null) 'adminNotes': adminNotes,
      });
      if (request != _reportsRequest) return false;
      final updated = Report.fromJson(result);
      if (updated.id != reportId || updated.questionId != _reportsQuestionId) {
        return false;
      }
      _questionReports = [
        for (final report in _questionReports)
          report.id == reportId ? updated : report,
      ];
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating report status: $e');
      return false;
    }
  }

  void resetState() {
    _generation++;
    _questionRequest++;
    _questionListUri = null;
    _questionsLoading = false;
    _questionsFailed = false;
    _isLoading = false;
    _adminQuestions = [];
    _adminTotalQuestions = 0;
    _wallOfPain = {'failedQuestions': [], 'difficultTopics': []};
    _ecgCases = [];
    _ecgDiagnoses = [];
    _ecgCasesRequest++;
    _ecgDiagnosesRequest++;
    _ecgCasesFailed = _ecgCasesLoading = _ecgDiagnosesFailed = false;
    _reportsRequest++;
    _reportsQuestionId = null;
    _reportsLoading = false;
    _reportsLoadFailed = false;
    _questionReports = [];
    notifyListeners();
  }
}
