import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'question_cache_service.dart';
import '../database/database.dart';
import 'package:drift/drift.dart' as drift;
import '../widgets/questions/question_renderer_registry.dart';

enum QuizEffectType { confetti, coins, hapticSuccess, hapticError }

class QuizEffect {
  final QuizEffectType type;
  final dynamic data;
  QuizEffect(this.type, [this.data]);
}

// Represents the UI State (Dumb Data for the View)
class QuizState {
  final Map<String, dynamic>? currentQuestion;
  final bool isLoading;
  final bool isSubmitting;
  final dynamic userAnswer;
  final bool isAnswerChecked;
  final bool isCorrect;
  final dynamic correctAnswer;
  final String explanation;
  final double levelProgress;
  final int? newLevel;
  final String? error;

  static const _undefined = Object();

  const QuizState({
    this.currentQuestion,
    this.isLoading = true,
    this.isSubmitting = false,
    this.userAnswer,
    this.isAnswerChecked = false,
    this.isCorrect = false,
    this.correctAnswer,
    this.explanation = '',
    this.levelProgress = 0.0,
    this.newLevel,
    this.error,
  });

  QuizState copyWith({
    Map<String, dynamic>? currentQuestion,
    bool? isLoading,
    bool? isSubmitting,
    Object? userAnswer = _undefined,
    bool? isAnswerChecked,
    bool? isCorrect,
    Object? correctAnswer = _undefined,
    String? explanation,
    double? levelProgress,
    Object? newLevel = _undefined,
    Object? error = _undefined,
  }) {
    return QuizState(
      currentQuestion: currentQuestion ?? this.currentQuestion,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      userAnswer: userAnswer == _undefined ? this.userAnswer : userAnswer,
      isAnswerChecked: isAnswerChecked ?? this.isAnswerChecked,
      isCorrect: isCorrect ?? this.isCorrect,
      correctAnswer: correctAnswer == _undefined ? this.correctAnswer : correctAnswer,
      explanation: explanation ?? this.explanation,
      levelProgress: levelProgress ?? this.levelProgress,
      newLevel: newLevel == _undefined ? this.newLevel : newLevel as int?,
      error: error == _undefined ? this.error : error as String?,
    );
  }
}

class QuizController extends ChangeNotifier {
  final ApiService _apiService;
  final QuestionCacheService _cacheService;
  final AppDatabase _db;
  final String systemSlug;
  final String systemName;
  final int _userId; 

  // Session State
  String? _sessionId;
  final Stopwatch _stopwatch = Stopwatch();
  QuizState _state = const QuizState();
  QuizState get state => _state;

  // Effects Stream
  final _effectController = StreamController<QuizEffect>.broadcast();
  Stream<QuizEffect> get effects => _effectController.stream;

  final List<int>? _mistakeIds;
  final bool _isReviewMode;

  QuizController({
    required ApiService apiService,
    required QuestionCacheService cacheService,
    required AppDatabase db,
    required this.systemSlug,
    required this.systemName,
    required int userId,
    Map<String, dynamic>? initialQuestion,
    String? initialSessionId,
    List<int>? questionIds,
  })  : _apiService = apiService,
        _cacheService = cacheService,
        _db = db,
        _userId = userId,
        _mistakeIds = questionIds != null ? List.from(questionIds) : null,
        _isReviewMode = questionIds != null && questionIds.isNotEmpty {
    if (initialQuestion != null) {
      _sessionId = initialSessionId;
      _state = _state.copyWith(
        isLoading: false,
        currentQuestion: initialQuestion,
        levelProgress: (initialQuestion['streakProgress'] as num?)?.toDouble() ?? 0.0,
      );
    } else {
      _initSession();
    }
  }

  @override
  void dispose() {
    _effectController.close();
    super.dispose();
  }

  void _initSession() async {
    if (!_isReviewMode) {
      _cacheService.init(systemSlug);
      await _loadLocalProgress();
    }
    _startSession();
  }

  Future<void> _loadLocalProgress() async {
    try {
      final existing = await (_db.select(_db.topicProgress)
            ..where((t) =>
                t.userId.equals(_userId) &
                t.topicSlug.equals(systemSlug)))
          .getSingleOrNull();

      if (existing != null) {
        final progress = (existing.currentStreak / 20.0).clamp(0.0, 1.0);
        _state = _state.copyWith(levelProgress: progress);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Persistence Load Error: $e");
    }
  }

  Future<void> _startSession() async {
     try {
      // Optimistic Session ID (Offline support)
      _sessionId = "local_${DateTime.now().millisecondsSinceEpoch}";
      
      // Async Sync (Fire & Forget)
      try {
        final session = await _apiService.post('/quiz/start', {});
        _sessionId = session['id'].toString();
      } catch (e) {
        debugPrint("Offline Session: Using local ID");
      }

      loadNextQuestion();
    } catch (e) {
      debugPrint("Error starting session: $e");
    }
  }

  Future<void> loadNextQuestion() async {
    _state = _state.copyWith(
      isLoading: _state.currentQuestion == null, // Only show spinner if no question
      userAnswer: null, // CLEAR ANSWER
      isAnswerChecked: false, // RESET CHECK
      isCorrect: false,
      isSubmitting: false,
      error: null,
      newLevel: null, // Clear level up state
    );
    notifyListeners();

    try {
      if (_isReviewMode) {
        if (_mistakeIds?.isEmpty ?? true) {
           // Review Complete
           _state = _state.copyWith(isLoading: false, currentQuestion: null);
           notifyListeners();
           return;
        }
        
        final nextId = _mistakeIds!.removeAt(0);
        final q = await _apiService.get('/quiz/questions/$nextId');
        
        if (q != null) {
          _setQuestion(q);
        } else {
           // Skip if failed to load
           loadNextQuestion();
        }
        return;
      }

      // Standard Mode Logic
      // 1. Try Cache
      Map<String, dynamic>? q = _cacheService.next();

      if (q != null) {
        _setQuestion(q);
      } else {
        // 2. Fallback to API
        final qRemote = await _apiService.get('/quiz/next?topic=$systemSlug');
        if (qRemote != null) {
          _setQuestion(qRemote);
           // Update cache stats in background
           _updateCache(qRemote);
        } else {
           // Handle Empty/End of Quiz
           _state = _state.copyWith(isLoading: false, currentQuestion: null);
           notifyListeners();
        }
      }
    } catch (e) {
       _state = _state.copyWith(isLoading: false, error: e.toString());
       notifyListeners();
    }
  }

  void _setQuestion(Map<String, dynamic> q) {
    _state = _state.copyWith(
      currentQuestion: q,
      isLoading: false,
      userAnswer: null, 
    );
    _stopwatch.reset();
    _stopwatch.start();
    notifyListeners();
  }

  void selectAnswer(dynamic answer) {
    if (_state.isAnswerChecked) return;
    _state = _state.copyWith(userAnswer: answer);
    notifyListeners();
  }

  // HYBRID ANSWER SUBMISSION
  Future<void> submitAnswer() async {
    if (_state.isAnswerChecked || _state.isSubmitting || _state.currentQuestion == null) return;
    
    final q = _state.currentQuestion!;
    _stopwatch.stop(); // Stop recording time
    final formattedAnswer = _formatAnswer(q, _state.userAnswer);
    if (formattedAnswer == null) return; // Invalid answer

    // 1. INSTANT LOCAL VALIDATION
    bool localIsCorrect = false;
    dynamic correctAnswer;
    String explanation = "";

    if (q.containsKey('correct_answer')) {
      final qType = q['question_type'] ?? 'single_choice';
      final renderer = QuestionRendererRegistry.getRenderer(qType);
      
      localIsCorrect = renderer.validateAnswer(_state.userAnswer, q['correct_answer'], q);
      correctAnswer = q['correct_answer'];
      explanation = _getExplanation(q);
    }

    // Update UI IMMEDIATELY
    _state = _state.copyWith(
      isAnswerChecked: true, // Lock UI
      isSubmitting: true, // Background sync indicator
      isCorrect: localIsCorrect,
      correctAnswer: correctAnswer,
      explanation: explanation,
    );
    notifyListeners();

    // Trigger Immediate Effects
    if (localIsCorrect) {
       _effectController.add(QuizEffect(QuizEffectType.hapticSuccess));
    } else {
       _effectController.add(QuizEffect(QuizEffectType.hapticError));
    }

    // 2. BACKGROUND SYNC (The "Truth")
    try {
       final response = await _apiService.post('/quiz/answer', {
        'sessionId': _sessionId,
        'questionId': q['id'],
        'userAnswer': formattedAnswer,
        'responseTimeMs': _stopwatch.elapsedMilliseconds
      });

      if (response != null && _state.currentQuestion?['id'] == q['id']) {
          // Sync Server Truth back to UI (State Reconciliation)
          _state = _state.copyWith(
            isSubmitting: false, // Done syncing
            levelProgress: (response['streakProgress'] as num).toDouble(),
            newLevel: (response['newLevel'] as num?)?.toInt(),
            explanation: _getExplanation(response), 
          );
          
          // Emit Server-Triggered Effects
          final coins = (response['coinsEarned'] as num?)?.toInt() ?? 0;
          if (coins > 0) {
             _effectController.add(QuizEffect(QuizEffectType.coins, coins));
          }

          if (response['event'] == 'PROMOTION' || response['event'] == 'LEVEL_UNLOCKED') {
              _effectController.add(QuizEffect(QuizEffectType.confetti));
          }
          
          // Fire & Forget Cache Update
          _updateCache(response);
          notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Background Sync Failed: $e");
      // Graceful degradation
       _state = _state.copyWith(isSubmitting: false); 
       notifyListeners();
    }
  }

  dynamic _formatAnswer(Map<String, dynamic> q, dynamic answer) {
     final qType = q['question_type'] ?? 'single_choice';
     final renderer = QuestionRendererRegistry.getRenderer(qType);
     return renderer.formatAnswer(answer);
  }

  String _getExplanation(Map<String, dynamic> data) {
    return data['explanation'] ?? data['explanation_en'] ?? "";
  }
  
  Future<void> _updateCache(Map<String, dynamic> data) async {
     await _syncTopicProgress(
        (data['streak'] as num?)?.toInt() ?? 0,
        (data['mastery'] as num?)?.toInt() ?? (data['coverage'] as num?)?.toInt() ?? 0,
      );
  }

  Future<void> _syncTopicProgress(int streak, dynamic masteryValue) async {
     final mastery = (masteryValue as num?)?.toInt() ?? 0;
     try {
      final existing = await (_db.select(_db.topicProgress)
            ..where((t) =>
                t.userId.equals(_userId) &
                t.topicSlug.equals(systemSlug)))
          .getSingleOrNull();

      if (existing != null) {
        await (_db.update(_db.topicProgress)..where((t) => t.id.equals(existing.id)))
            .write(
          TopicProgressCompanion(
            currentStreak: drift.Value(streak),
            masteryScore: drift.Value(mastery),
            lastStudiedAt: drift.Value(DateTime.now()),
          ),
        );
      } else {
        await _db.into(_db.topicProgress).insert(
              TopicProgressCompanion.insert(
                userId: drift.Value(_userId),
                topicSlug: drift.Value(systemSlug),
                currentStreak: drift.Value(streak),
                masteryScore: drift.Value(mastery),
                lastStudiedAt: drift.Value(DateTime.now()),
              ),
            );
      }
    } catch (e) {
      debugPrint("❌ Database Sync Error: $e");
    }
  }

  void pauseTimer() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      debugPrint("⏱️ Quiz Timer Paused: ${_stopwatch.elapsedMilliseconds}ms");
    }
  }

  void resumeTimer() {
    if (!_stopwatch.isRunning && _state.currentQuestion != null && !_state.isAnswerChecked) {
      _stopwatch.start();
      debugPrint("⏱️ Quiz Timer Resumed");
    }
  }
}
