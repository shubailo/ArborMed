import 'dart:async';
import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'submission_queue.dart';
import '../../../core/api_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/features/quiz/providers/question_cache_service.dart';
import 'package:arbor_med/core/api_endpoints.dart';
import '../../../database/database.dart';
import '../../../features/quiz/widgets/questions/question_renderer_registry.dart';
import 'package:arbor_med/features/quiz/models/quiz_ui_state.dart';

class QuizController extends ChangeNotifier {
  final ApiService _apiService;
  late final QuestionSession? _selection;
  bool _loadingQuestion = false;
  final AppDatabase _db;
  final SubmissionQueue _queue;
  late final StreamSubscription<Map<String, dynamic>> _receiptSubscription;
  String? _visibleSubmission;
  double _progressBeforeAnswer = 0;
  String? _progressTopic;
  bool _disposed = false;
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
  final String? languageCode;

  QuizController({
    required ApiService apiService,
    required QuestionCacheService cacheService,
    required AppDatabase db,
    required SubmissionQueue queue,
    required this.systemSlug,
    required this.systemName,
    required int userId,
    Map<String, dynamic>? initialQuestion,
    String? initialSessionId,
    List<int>? questionIds,
    this.languageCode = 'hu',
  })  : _apiService = apiService,
        _db = db,
        _queue = queue,
        _userId = userId,
        _mistakeIds = questionIds != null ? List.from(questionIds) : null,
        _isReviewMode = questionIds != null && questionIds.isNotEmpty {
    final first = initialQuestion == null ? null : normalizePracticeQuestion(initialQuestion);
    _selection = _isReviewMode ? null : cacheService.open(systemSlug, shown: first?['id'] as int?);
    _receiptSubscription = _queue.receipts.listen(_applyReceipt);
    if (first != null) {
      _progressTopic = first['topic_slug']?.toString() ?? systemSlug;
      _sessionId = initialSessionId;
      _stopwatch.start();
      _selection?.prefetch();
      _state = _state.copyWith(
        isLoading: false,
        currentQuestion: first,
        currentBloomLevel: (first['currentBloom'] as num?)?.toInt() ?? 1,
        levelDirection: 'NONE',
        levelProgress: (first['streakProgress'] as num?)?.toDouble() ?? 0.0,
      );
    } else {
      _initSession();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _selection?.close();
    _receiptSubscription.cancel();
    _effectController.close();
    super.dispose();
  }

  void _initSession() async {
    if (!_isReviewMode) {
      await _loadLocalProgress();
    }
    if (!_disposed && _apiService.userId == _userId) await _startSession();
  }

  Future<void> _loadLocalProgress() async {
    try {
      final existing = await (_db.select(_db.topicProgress)
            ..where((t) =>
                t.userId.equals(_userId) &
                t.topicSlug.equals(systemSlug)))
          .getSingleOrNull();

      if (!_disposed && _apiService.userId == _userId && existing != null) {
        final progress = (existing.levelCorrectCount / 20.0).clamp(0.0, 1.0);
        _state = _state.copyWith(levelProgress: progress, currentBloomLevel: existing.currentBloomLevel);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Persistence Load Error: $e");
    }
  }

  Future<void> _startSession() async {
    try {
      // Optimistic Session ID (Offline / Cold-start support)
      _sessionId = "local_${DateTime.now().millisecondsSinceEpoch}";

      // Load first question immediately so user doesn't wait on backend spin-up
      loadNextQuestion();

      // Negotiate session with server asynchronously
      _apiService.post(ApiEndpoints.quizStart, {}).then((session) {
        if (!_disposed && _apiService.userId == _userId && session != null && session['id'] != null) {
          _sessionId = session['id'].toString();
          debugPrint("✅ Session established with server: $_sessionId");
        }
      }).catchError((e) {
        debugPrint("Offline or cold-start session, using local ID: $_sessionId ($e)");
      });
    } catch (e) {
      debugPrint("Error starting session: $e");
    }
  }

  Future<void> loadNextQuestion() async {
    if (_disposed || _loadingQuestion) return;
    _loadingQuestion = true;
    final previousProgress = _visibleSubmission == null ? _state.levelProgress : _progressBeforeAnswer;
    _visibleSubmission = null;
    final nextIndex = _state.currentQuestion != null
        ? _state.questionIndex + 1
        : _state.questionIndex;

    _state = _state.copyWith(
      isLoading: true,
      currentQuestion: null,
      userAnswer: null,
      correctAnswer: null,
      explanation: '',
      submissionRejected: false,
      levelProgress: previousProgress,
      levelDirection: 'NONE',
      isAnswerChecked: false, // RESET CHECK
      isCorrect: false,
      isSubmitting: false,
      error: null,
      newLevel: null, // Clear level up state
      questionIndex: nextIndex,
      isReviewComplete: false,
    );
    notifyListeners();

    try {
      if (_isReviewMode) {
        if (_mistakeIds?.isEmpty ?? true) {
          // Review Complete
          _state = _state.copyWith(
            isLoading: false,
            currentQuestion: null,
            isReviewComplete: true,
          );
          notifyListeners();
          return;
        }

        Map<String, dynamic>? q;
        final mistakeList = _mistakeIds;
        if (mistakeList != null) {
          while (mistakeList.isNotEmpty) {
            final nextId = mistakeList.first;
            try {
              if (_apiService.userId != _userId) throw StateError('The study account changed');
              final result = await _apiService.get('/quiz/questions/$nextId');
              if (_disposed) return;
              if (_apiService.userId != _userId) throw StateError('The study account changed');
              q = normalizePracticeQuestion(result, expectedId: nextId);
              mistakeList.removeAt(0);
              break;
            } on ApiException catch (e) {
              if (e.statusCode != 404 && e.statusCode != 422) rethrow;
              mistakeList.removeAt(0);
            }
          }
        }

        if (_disposed) return;
        if (q != null) {
          _setQuestion(q);
        } else {
          _state = _state.copyWith(
            isLoading: false,
            currentQuestion: null,
            isReviewComplete: true,
          );
          notifyListeners();
        }
        return;
      }

      final question = await _selection!.next();
      if (_disposed) return;
      if (question != null) {
        _setQuestion(question);
      } else {
        _state = _state.copyWith(isLoading: false);
        notifyListeners();
      }
    } catch (e) {
      if (_disposed) return;
      _state = _state.copyWith(isLoading: false, error: e.toString());
      notifyListeners();
    } finally {
      _loadingQuestion = false;
    }
  }

  void _setQuestion(Map<String, dynamic> q) {
    final topic = q['topic_slug']?.toString() ?? systemSlug;
    // Keep cached progress only when it belongs to this section.
    final reported = (q['streakProgress'] as num?)?.toDouble().clamp(0.0, 1.0);
    final cachedTopic = _progressTopic ?? systemSlug;
    final fallbackProgress = cachedTopic == topic ? _state.levelProgress : 0.0;
    final fallbackBloom = cachedTopic == topic ? _state.currentBloomLevel : 1;
    _progressTopic = topic;
    _state = _state.copyWith(
      currentQuestion: q,
      currentBloomLevel: (q['currentBloom'] as num?)?.toInt() ?? fallbackBloom,
      levelDirection: 'NONE',
      isLoading: false,
      userAnswer: null,
      levelProgress: reported ?? fallbackProgress,
    );
    _stopwatch.reset();
    _stopwatch.start();
    notifyListeners();
  }

  void selectAnswer(dynamic answer) {
    if (_state.isAnswerChecked || _state.isSubmitting || _state.submissionRejected) return;
    _state = _state.copyWith(userAnswer: answer);
    notifyListeners();
  }

  Future<void> submitAnswer() async {
    if (_disposed || _apiService.userId != _userId || _state.submissionRejected ||
        _state.isAnswerChecked || _state.isSubmitting || _state.currentQuestion == null) {
      return;
    }
    final question = _state.currentQuestion!;
    final renderer = QuestionRendererRegistry.getRenderer(question['question_type'] ?? 'single_choice');
    if (renderer == null || !renderer.canSubmit(question, _state.userAnswer)) return;
    final answer = renderer.formatAnswer(_state.userAnswer);
    if (answer == null) return;
    _stopwatch.stop();
    _state = _state.copyWith(isSubmitting: true, error: null);
    notifyListeners();
    late final String id;
    try {
      id = await _queue.enqueue(_userId, question['topic_slug']?.toString() ?? systemSlug, {
        'sessionId': _sessionId,
        'questionId': question['id'],
        'userAnswer': answer,
        'responseTimeMs': _stopwatch.elapsedMilliseconds,
        'selectionReason': question['selectionReason'],
      });
    } catch (_) {
      if (_disposed || _apiService.userId != _userId || !identical(question, _state.currentQuestion)) return;
      _stopwatch.start();
      _state = _state.copyWith(isSubmitting: false, error: languageCode == 'hu'
          ? 'A válasz mentése sikertelen. Próbáld újra.' : 'Could not save your answer. Please retry.');
      notifyListeners();
      return;
    }
    if (!_disposed && _apiService.userId == _userId && identical(question, _state.currentQuestion)) {
      _progressBeforeAnswer = _state.levelProgress;
      _visibleSubmission = id;
      final correct = renderer.validateAnswer(answer, question['correct_answer'], question);
      _state = _state.copyWith(
        isAnswerChecked: true, isCorrect: correct,
        correctAnswer: question['correct_answer'], explanation: _getExplanation(question),
        levelProgress: correct ? (_state.levelProgress + 0.05).clamp(0.0, 1.0) : _state.levelProgress,
      );
      _effectController.add(QuizEffect(correct ? QuizEffectType.hapticSuccess : QuizEffectType.hapticError));
      notifyListeners();
    }
    await _queue.flush();
    if (!_disposed && _visibleSubmission == id && _state.isSubmitting) {
      _state = _state.copyWith(isSubmitting: false);
      notifyListeners();
    }
  }

  void _applyReceipt(Map<String, dynamic> receipt) {
    if (_disposed || _apiService.userId != _userId) return;
    if (!receipt.containsKey('error')) _selection?.invalidate();
    if (receipt['submissionId'] != _visibleSubmission) {
      if (_visibleSubmission == null && _progressTopic != null &&
          receipt['topicSlug'] == _progressTopic && !receipt.containsKey('error')) {
        _state = _state.copyWith(
          levelProgress: (receipt['streakProgress'] as num?)?.toDouble(),
          currentBloomLevel: (receipt['currentBloom'] as num?)?.toInt(),
        );
        notifyListeners();
      }
      return;
    }
    _visibleSubmission = null;
    if (receipt.containsKey('error')) {
      _state = _state.copyWith(
        submissionRejected: true,
        isSubmitting: false,
        isAnswerChecked: false,
        isCorrect: false,
        correctAnswer: null,
        explanation: '',
        levelProgress: _progressBeforeAnswer,
      );
      notifyListeners();
      return;
    }
    _state = _state.copyWith(
      isSubmitting: false,
      isCorrect: receipt['isCorrect'] as bool,
      correctAnswer: receipt['correctAnswer'],
      explanation: _getExplanation(receipt),
      levelProgress: (receipt['streakProgress'] as num?)?.toDouble(),
      currentBloomLevel: (receipt['currentBloom'] as num?)?.toInt(),
      newLevel: (receipt['newLevel'] as num?)?.toInt(),
      levelDirection: receipt['levelDirection']?.toString() ?? 'NONE',
    );
    final coins = (receipt['coinsEarned'] as num?)?.toInt() ?? 0;
    if (coins > 0) _effectController.add(QuizEffect(QuizEffectType.coins, coins));
    if (receipt['event'] == 'PROMOTION' || receipt['event'] == 'LEVEL_UNLOCKED') {
      _effectController.add(QuizEffect(QuizEffectType.confetti));
    }
    notifyListeners();
  }

  String _getExplanation(Map<String, dynamic> data) {
    final lang = languageCode ?? 'hu';
    if (lang == 'hu') {
      final hu = data['explanation_hu']?.toString().trim();
      if (hu != null && hu.isNotEmpty && hu != 'null') {
        return hu;
      }
    }
    return data['explanation'] ?? data['explanation_en'] ?? data['explanation_hu'] ?? "";
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
