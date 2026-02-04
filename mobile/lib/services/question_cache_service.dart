import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class QuestionCacheService extends ChangeNotifier {
  final ApiService _apiService;
  final Queue<Map<String, dynamic>> _queue = Queue<Map<String, dynamic>>();
  
  String? _currentTopic;
  bool _isFetching = false;
  int _answeredCount = 0;
  bool _hasError = false;

  QuestionCacheService(this._apiService);

  bool get isEmpty => _queue.isEmpty;
  int get queueSize => _queue.length;
  bool get hasError => _hasError;

  /// 🏁 Initialize the cache for a new topic
  Future<void> init(String topicSlug) async {
    debugPrint("🧠 Cache: Initializing for topic [$topicSlug]");
    _currentTopic = topicSlug;
    _queue.clear();
    _answeredCount = 0;
    _hasError = false;
    
    // Fetch initial 10 questions
    await _fetchMore(10);
  }

  /// 🚀 Get the next question from the queue
  Map<String, dynamic>? next() {
    if (_queue.isEmpty) {
      debugPrint("⚠️ Cache: Queue empty! Direct fetch needed.");
      return null;
    }
    
    final q = _queue.removeFirst();
    debugPrint("📦 Cache: Popped question. Remaining: ${_queue.length}");
    notifyListeners();
    return q;
  }

  /// 📉 Track progress and trigger background fetches
  void notifyAnswered() {
    _answeredCount++;
    debugPrint("✅ Cache: Answered $_answeredCount. Checking for pre-fetch...");
    
    // Every 5 answers, fetch 5 more to maintain the buffer
    if (_answeredCount % 5 == 0) {
      _fetchMore(5);
    }
  }

  /// 🌩️ Recursive/Aggressive fetcher with strict retry
  Future<void> _fetchMore(int count) async {
    if (_isFetching || _currentTopic == null) return;
    _isFetching = true;
    _hasError = false;
    notifyListeners();

    int fetchedInThisBatch = 0;
    
    while (fetchedInThisBatch < count) {
      try {
        debugPrint("📡 Cache: Fetching question ${fetchedInThisBatch + 1}/$count...");
        final q = await _apiService.get('/quiz/next?topic=$_currentTopic');
        
        if (q != null) {
          _queue.add(q);
          fetchedInThisBatch++;
          notifyListeners();
        } else {
          // No more questions available for this topic
          debugPrint("🚫 Cache: Topic exhausted.");
          break; 
        }
      } catch (e) {
        debugPrint("❌ Cache Fetch Error: $e. Retrying in 2s...");
        _hasError = true;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        // We continue the loop because of the 'Strict' rule
      }
    }

    _isFetching = false;
    _hasError = false;
    notifyListeners();
    debugPrint("🏁 Cache Batch Complete. Current Queue: ${_queue.length}");
  }

  void clear() {
    _queue.clear();
    _currentTopic = null;
    _answeredCount = 0;
    notifyListeners();
  }
}
