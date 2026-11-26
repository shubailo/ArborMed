import 'package:flutter/foundation.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import '../../../core/api_endpoints.dart';

// Models
import 'package:arbor_med/features/analytics/models/subject_mastery.dart';
import 'package:arbor_med/features/analytics/models/quote.dart';
import 'package:arbor_med/features/analytics/models/activity_data.dart';
import '../../quiz/models/smart_review_item.dart';
import 'package:arbor_med/features/analytics/models/readiness.dart';

// Re-export student models for convenient consumption
export '../../../core/models/user.dart';
export '../../../core/models/question.dart';
export '../../../core/models/topic.dart';
export '../../../core/models/quiz_session.dart';
export '../models/subject_mastery.dart';
export '../models/quote.dart';
export '../models/activity_data.dart';
export '../../quiz/models/smart_review_item.dart';
export '../models/readiness.dart';

enum SubjectQuizState { initial, loading, loaded, empty, error }

/// Student-facing statistics provider.
/// Admin operations have been moved to:
/// - [AdminUserProvider] for user management
/// - [AdminQuestionProvider] for question/ECG CMS
/// - [TopicProvider] for topic management
/// - [AdminContentProvider] for quotes/images/translation
class StatsProvider with ChangeNotifier {
  final AuthProvider authProvider;

  StatsProvider(this.authProvider) : _owner = authProvider.user?.id {
    authProvider.addListener(_syncOwner);
  }

  int? _owner;
  bool _disposed = false;
  final _requests = <String, Object>{};
  String? _today;
  int _todayCount = 0;

  void _syncOwner() {
    final owner = authProvider.user?.id;
    if (_owner == owner) return;
    _owner = owner;
    resetState();
  }

  Object? _begin(String key) {
    if (_disposed || _owner == null) return null;
    return _requests[key] = Object();
  }

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

  String _date(DateTime date) => date.toIso8601String().split('T').first;

  int get todayCorrectAnswers =>
      _today == _date(DateTime.now()) ? _todayCount : 0;

  Future<void> _read(String key, String endpoint, void Function(dynamic) apply,
      {VoidCallback? start, VoidCallback? failed, VoidCallback? finish}) async {
    final token = _begin(key);
    if (token == null) return;
    if (start != null) {
      start();
      notifyListeners();
    }
    try {
      final data = await apiService.get(endpoint);
      if (_requests[key] == token) apply(data);
    } catch (e) {
      if (_requests[key] == token) {
        failed?.call();
        debugPrint('Stats request failed ($key): ${e.runtimeType}');
      }
    } finally {
      if (_requests[key] == token) {
        _requests.remove(key);
        finish?.call();
        notifyListeners();
      }
    }
  }

  Future<void> fetchSummary() => _read(
      'summary',
      ApiEndpoints.statsSummary,
      (data) => _subjectMastery =
          (data as List).map((item) => SubjectMastery.fromJson(item)).toList(),
      start: () => _isLoading = true,
      finish: () => _isLoading = false);

  Future<void> preFetchData() async {
    await Future.wait([
      fetchSummary(),
      _fetchActivity('week', DateTime.now(), preload: true),
      fetchSmartReview(),
      fetchReadiness()
    ]);
  }

  String _periodUrl(String path, String timeframe, DateTime anchor) =>
      Uri(path: path, queryParameters: {
        'timeframe': timeframe,
        'anchorDate': _date(anchor)
      }).toString();

  Future<void> fetchActivity(
          {String timeframe = 'week', DateTime? anchorDate}) =>
      _fetchActivity(timeframe, anchorDate ?? DateTime.now());

  Future<void> _fetchActivity(String timeframe, DateTime anchor,
      {bool preload = false}) async {
    if (_disposed || _owner == null) return;
    final chart =
        preload && (_activity.isNotEmpty || _requests.containsKey('chart'))
            ? null
            : _begin('chart');
    final today = _date(DateTime.now());
    final daily = _date(anchor) == today ? _begin('today') : null;
    try {
      final data = await apiService
          .get(_periodUrl(ApiEndpoints.statsActivity, timeframe, anchor));
      if ((chart == null || _requests['chart'] != chart) &&
          (daily == null || _requests['today'] != daily)) {
        return;
      }
      final rows =
          (data as List).map((item) => ActivityData.fromJson(item)).toList();
      if (daily != null && _requests['today'] == daily) {
        _today = today;
        _todayCount = rows
            .where((row) =>
                (row.calendarDate ?? _date(row.date.toLocal())) == today)
            .fold(0, (sum, row) => sum + row.correctCount);
      }
      if (chart != null && _requests['chart'] == chart) _activity = rows;
      notifyListeners();
    } catch (e) {
      if (chart != null && _requests['chart'] == chart) {
        debugPrint('Activity request failed: ${e.runtimeType}');
      }
    } finally {
      if (chart != null && _requests['chart'] == chart) {
        _requests.remove('chart');
      }
      if (daily != null && _requests['today'] == daily) {
        _requests.remove('today');
      }
    }
  }

  /// Null indicates a superseded request. An empty list is a successful result.
  Future<List<int>?> fetchMistakeIds(
      {String timeframe = 'week', DateTime? anchorDate}) async {
    final token = _begin('mistakes');
    if (token == null) return null;
    try {
      final data = await apiService.get(_periodUrl(
          ApiEndpoints.statsMistakes, timeframe, anchorDate ?? DateTime.now()));
      if (_requests['mistakes'] != token) return null;
      if (data is! List) throw const FormatException('Expected mistake IDs');
      return data.map((value) {
        final id = int.tryParse(value.toString());
        if (id == null || id <= 0) {
          throw const FormatException('Invalid mistake ID');
        }
        return id;
      }).toList();
    } catch (_) {
      if (_requests['mistakes'] != token) return null;
      rethrow;
    } finally {
      if (_requests['mistakes'] == token) _requests.remove('mistakes');
    }
  }

  Future<void> fetchSmartReview() => _read(
      'review',
      ApiEndpoints.statsSmartReview,
      (data) => _smartReview = (data['recommendations'] as List)
          .map((item) => SmartReviewItem.fromJson(item))
          .toList());

  Future<void> fetchReadiness() => _read(
      'readiness',
      ApiEndpoints.statsReadiness,
      (data) => _readiness = ReadinessScore.fromJson(data));

  Future<void> fetchSubjectDetail(String slug) => _read('section:$slug',
          '${ApiEndpoints.statsSubject}/${Uri.encodeComponent(slug)}', (data) {
        final systems = List<Map<String, dynamic>>.from(data as List);
        _sectionMastery[slug] = systems;
        _sectionStates[slug] =
            systems.isEmpty ? SubjectQuizState.empty : SubjectQuizState.loaded;
      },
          start: () => _sectionStates[slug] = SubjectQuizState.loading,
          failed: () => _sectionStates[slug] = SubjectQuizState.error);

  Future<void> fetchCurrentQuote() => _read(
      'quote',
      ApiEndpoints.quizSingleQuote,
      (data) => _currentQuote = Quote.fromJson(data));

  @override
  void dispose() {
    _disposed = true;
    _requests.clear();
    authProvider.removeListener(_syncOwner);
    super.dispose();
  }

  /// Resets all user-specific statistics.
  void resetState() {
    _requests.clear();
    _today = null;
    _todayCount = 0;
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
