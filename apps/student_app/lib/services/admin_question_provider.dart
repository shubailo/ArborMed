import 'package:flutter/foundation.dart';
import 'download/download_helper.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'api_service.dart';
import 'package:arbor_med/core/api_endpoints.dart';
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

  void updateAccount(int? id, String? role) {
    if (_account == (id, role)) return;
    _account = (id, role);
    resetState();
  }

  // --- State ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AdminQuestion> _adminQuestions = [];
  int _adminTotalQuestions = 0;
  List<AdminQuestion> get adminQuestions => _adminQuestions;
  int get adminTotalQuestions => _adminTotalQuestions;

  Map<String, dynamic> _wallOfPain = {
    'failedQuestions': [],
    'difficultTopics': [],
  };
  Map<String, dynamic> get wallOfPain => _wallOfPain;

  List<ECGCase> _ecgCases = [];
  List<ECGCase> get ecgCases => _ecgCases;

  List<ECGDiagnosis> _ecgDiagnoses = [];
  List<ECGDiagnosis> get ecgDiagnoses => _ecgDiagnoses;
  List<Report> _questionReports = [];
  List<Report> get questionReports => _questionReports;

  // --- Question CRUD ---

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

      final data = await apiService.get(endpoint);
      final fetched = (data['questions'] as List)
          .map((item) => AdminQuestion.fromJson(item))
          .toList();
      // Deduplicate by id while preserving order
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
    try {
      await apiService.delete('${ApiEndpoints.quizAdminQuestions}/$id');
      fetchAdminQuestions();
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
      await apiService.post(ApiEndpoints.quizAdminBulk, {
        'action': action,
        'ids': ids,
        'targetTopicId': targetTopicId,
      });
      fetchAdminQuestions();
      return true;
    } catch (e) {
      debugPrint('Error in bulk action: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadQuestionsBatch(
      List<int> bytes, String filename) async {
    try {
      final result = await apiService.postMultipart(ApiEndpoints.quizAdminBatch,
          bytes: bytes, filename: filename);
      fetchAdminQuestions();
      return result as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error in batch upload: $e');
      return null;
    }
  }

  Future<void> downloadQuestionsTemplate() async {
    try {
      final bytes = await apiService.getBytes(ApiEndpoints.quizAdminTemplate);

      await downloadHelper.download(
        bytes,
        'QUESTION_TEMPLATE.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      debugPrint('Error downloading template: $e');
    }
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
    final generation = _generation;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await apiService.get(ApiEndpoints.ecgCases);
      if (generation != _generation) return;
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
    final generation = _generation;
    try {
      final data = await apiService.get(ApiEndpoints.ecgDiagnoses);
      if (generation != _generation) return;
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
    _isLoading = true;
    notifyListeners();

    try {
      final data = await apiService
          .get('${ApiEndpoints.quizAdminQuestions}/$questionId/reports');
      if (data is List) {
        _questionReports = data.map((item) => Report.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateReportStatus(int reportId, String status,
      {String? adminNotes}) async {
    try {
      await apiService.patch(
          '${ApiEndpoints.reportsBase}/$reportId',
          {'status': status, 'adminNotes': adminNotes});
      final index = _questionReports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        final report = _questionReports[index];
        await fetchReports(report.questionId);
      }
      return true;
    } catch (e) {
      debugPrint('Error updating report status: $e');
      return false;
    }
  }

  void resetState() {
    _generation++;
    _isLoading = false;
    _adminQuestions = [];
    _adminTotalQuestions = 0;
    _wallOfPain = {'failedQuestions': [], 'difficultTopics': []};
    _ecgCases = [];
    _ecgDiagnoses = [];
    _questionReports = [];
    notifyListeners();
  }
}
