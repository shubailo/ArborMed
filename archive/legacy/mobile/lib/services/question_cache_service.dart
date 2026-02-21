import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../core/api_endpoints.dart';

class QuestionCacheService extends ChangeNotifier {
  final ApiService _apiService;

  // Dual Buffer System
  final Queue<Map<String, dynamic>> _currentLevelQueue =
      Queue<Map<String, dynamic>>();
  final Queue<Map<String, dynamic>> _nextLevelQueue =
      Queue<Map<String, dynamic>>();

  // 🧠 Deep Memory: Track every ID shown in this session to prevent duplicates
  final Set<int> _sessionHistory = <int>{};

  String? _currentTopic;
  int _currentBloomLevel = 1;
  int _currentStreak = 0;
  bool _isFetching = false;
  bool _hasError = false;
  bool _isPredictiveFetchActive = false;

  QuestionCacheService(this._apiService);

  bool get isEmpty => _currentLevelQueue.isEmpty;
  int get queueSize => _currentLevelQueue.length;
  bool get hasError => _hasError;
  Set<int> get sessionHistoryIds => UnmodifiableSetView(_sessionHistory);

  /// 🏁 Initialize the cache for a new topic
  Future<void> init(String topicSlug, {int bloomLevel = 1}) async {
    debugPrint(
        "🧠 Cache: Initializing for topic [$topicSlug] at Bloom Level $bloomLevel");
    _currentTopic = topicSlug;
    _currentBloomLevel = bloomLevel;
    _currentStreak = 0;
    _currentLevelQueue.clear();
    _nextLevelQueue.clear();
    _sessionHistory.clear(); // 🧼 Clear history for new topic
    _hasError = false;
    _isPredictiveFetchActive = false;

    // 🚀 Speed Optimization: Fetch 1st question immediately so user can start
    await _fetchQuestionsForLevel(_currentBloomLevel, 1, _currentLevelQueue);
    notifyListeners(); // Force update so UI sees the 1st question

    // 🕊️ Background: Fill the rest of the buffer (9 more)
    // We do NOT await this, letting it run while user plays Q1
    _fetchQuestionsForLevel(_currentBloomLevel, 9, _currentLevelQueue);
    
    // 🛡️ Safe notify: initialization might happen during build
    Future.microtask(() => notifyListeners());
  }

  /// 🚀 Get the next question from the queue
  Map<String, dynamic>? next() {
    if (_currentLevelQueue.isEmpty) {
      debugPrint("⚠️ Cache: Queue empty! Direct fetch needed.");
      return null;
    }

    final q = _currentLevelQueue.removeFirst();

    // 🧠 Mark as seen IMMEDIATELY to prevent pre-fetcher from re-pulling it
    final id = (q['id'] is num)
        ? (q['id'] as num).toInt()
        : int.tryParse(q['id']?.toString() ?? '');
    if (id != null) {
      _sessionHistory.add(id);
    }

    debugPrint(
        "📦 Cache: Popped question id=$id. History Size: ${_sessionHistory.length}");
    notifyListeners();

    // Maintain buffer: fetch 5 more when we drop to 5 remaining
    if (_currentLevelQueue.length <= 5 && !_isFetching) {
      _fetchQuestionsForLevel(_currentBloomLevel, 5, _currentLevelQueue);
    }

    return q;
  }

  /// 📊 Update streak and trigger predictive fetching
  void updateStreak(int newStreak, bool isCorrect) {
    _currentStreak = newStreak;
    debugPrint("🎯 Cache: Streak updated to $_currentStreak");

    if (isCorrect &&
        _currentStreak == 15 &&
        !_isPredictiveFetchActive &&
        _currentBloomLevel < 4) {
      // 🔮 PREDICTIVE FETCH: User is 5 questions away from level-up
      debugPrint(
          "🔮 Cache: Streak 15! Pre-fetching Level ${_currentBloomLevel + 1} questions...");
      _isPredictiveFetchActive = true;
      _fetchQuestionsForLevel(_currentBloomLevel + 1, 5, _nextLevelQueue);
    }

    if (!isCorrect) {
      // Streak broken - clear next level buffer
      if (_nextLevelQueue.isNotEmpty) {
        debugPrint("💔 Cache: Streak broken. Clearing next level buffer.");
        _nextLevelQueue.clear();
      }
      _isPredictiveFetchActive = false;
    }
  }

  /// 🎉 Handle level promotion
  void onLevelUp(int newLevel) {
    debugPrint("🎉 Cache: Level UP! $newLevel");
    _currentBloomLevel = newLevel;
    _currentStreak = 0;
    _isPredictiveFetchActive = false;

    // Swap buffers: next level becomes current level
    _currentLevelQueue.clear();
    _currentLevelQueue.addAll(_nextLevelQueue);
    _nextLevelQueue.clear();

    debugPrint(
        "🔄 Cache: Swapped buffers. Current queue now has ${_currentLevelQueue.length} questions");

    // Fetch 5 more at new level to fill buffer
    if (_currentLevelQueue.length < 10) {
      _fetchQuestionsForLevel(_currentBloomLevel,
          10 - _currentLevelQueue.length, _currentLevelQueue);
    }

    notifyListeners();
  }

  /// 📉 Handle level demotion
  void onLevelDown(int newLevel) {
    debugPrint("📉 Cache: Level DOWN to $newLevel");
    _currentBloomLevel = newLevel;
    _currentStreak = 0;
    _isPredictiveFetchActive = false;

    // Clear both buffers and re-fetch at new (lower) level
    _currentLevelQueue.clear();
    _nextLevelQueue.clear();

    _fetchQuestionsForLevel(_currentBloomLevel, 10, _currentLevelQueue);
    notifyListeners();
  }

  /// 🌩️ Fetch questions for a specific Bloom level
  Future<void> _fetchQuestionsForLevel(int bloomLevel, int count,
      Queue<Map<String, dynamic>> targetQueue) async {
    if (_isFetching || _currentTopic == null) return;
    _isFetching = true;
    _hasError = false;
    // Notify starting fetch
    Future.microtask(() => notifyListeners());

    int fetchedInThisBatch = 0;

    // 🛡️ Robust Exclusion: Exclude EVERYTHING seen + EVERYTHING currently in buffers
    final allExcludedIds = <int>{
      ..._sessionHistory,
      ..._currentLevelQueue
          .map((q) => (q['id'] as num?)?.toInt() ?? -1)
          .where((id) => id != -1),
      ..._nextLevelQueue
          .map((q) => (q['id'] as num?)?.toInt() ?? -1)
          .where((id) => id != -1),
    };

    while (fetchedInThisBatch < count) {
      try {
        // Build exclude parameter
        final excludeParam = allExcludedIds.isNotEmpty
            ? '&exclude=${allExcludedIds.join(',')}'
            : '';
        final url =
            '${ApiEndpoints.quizNext}?topic=$_currentTopic&bloomLevel=$bloomLevel$excludeParam';

        debugPrint(
            "📡 Cache: Fetching L$bloomLevel question ${fetchedInThisBatch + 1}/$count...");
        final q = await _apiService.get(url);

        if (q != null) {
          final id = (q['id'] is num)
              ? (q['id'] as num).toInt()
              : int.tryParse(q['id']?.toString() ?? '');

          // Check for duplicates
          if (id != null && allExcludedIds.contains(id)) {
            debugPrint(
                "⚠️ Cache: Received duplicate question id=$id despite exclude param, skipping...");
            continue;
          }

          if (id != null) {
            allExcludedIds.add(id);
          }

          targetQueue.add(q);
          fetchedInThisBatch++;
          // Removed notifyListeners() mid-loop to prevent UI thrashing/assertion errors
        } else {
          debugPrint("🚫 Cache: No more L$bloomLevel questions available.");
          break;
        }
      } catch (e) {
        debugPrint("❌ Cache Fetch Error: $e");

        // 🛡️ STOP RETRYING on 404 (Empty Level)
        if (e.toString().contains("404")) {
          debugPrint(
              "🚫 Cache: Level $bloomLevel is confirmed empty (404). Stopping fetch.");
          break;
        }

        debugPrint("⏳ Retrying in 2s...");
        _hasError = true;
        Future.microtask(() => notifyListeners());
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    _isFetching = false;
    _hasError = false;
    notifyListeners();
    debugPrint(
        "🏁 Cache Batch Complete. L$bloomLevel: ${targetQueue.length} questions");
  }

  void clear() {
    _currentLevelQueue.clear();
    _nextLevelQueue.clear();
    _currentTopic = null;
    _currentStreak = 0;
    _isPredictiveFetchActive = false;
    notifyListeners();
  }
}
