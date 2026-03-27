import 'package:flutter/foundation.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:feature_quiz/feature_quiz.dart';
import 'package:feature_auth/feature_auth.dart';
import '../domain/models/readiness.dart';

// Re-export models so existing importers don't break
export '../domain/models/readiness.dart';
export '../domain/models/report.dart';
export 'package:arbormed_core/arbormed_core.dart';
export 'package:feature_quiz/feature_quiz.dart';

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
      final data =
          await authProvider.apiService.get(ApiEndpoints.statsSmartReview);
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
      final data =
          await authProvider.apiService.get(ApiEndpoints.statsReadiness);
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
      final data = await authProvider.apiService
          .get('${ApiEndpoints.statsSubject}/$slug');
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
      final data =
          await authProvider.apiService.get(ApiEndpoints.quizSingleQuote);
      _currentQuote = Quote.fromJson(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching current quote: $e');
    }
  }


  // ===================================================================
  // Resets all student-specific statistics.
  // ===================================================================
  void resetState() {
    _subjectMastery = [];
    _activity = [];
    _isLoading = false;
    _currentQuote = null;
    _smartReview = [];
    _readiness = null;
    _sectionMastery.clear();
    _sectionStates.clear();
    notifyListeners();
  }
}
