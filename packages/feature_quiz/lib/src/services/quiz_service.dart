import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:arbormed_core/arbormed_core.dart' hide Question, QuestType;
import 'package:core_interop/core_interop.dart';

enum QuizEffectType { confetti, coins, hapticSuccess, hapticError }

class QuizEffect {
  final QuizEffectType type;
  final dynamic data;
  const QuizEffect(this.type, [this.data]);
}

class QuizService extends ChangeNotifier implements QuizContract {
  final StudentContract _studentContract;
  final QuestContract _questContract;
  final ApiService _api = ApiService();
  
  List<Question> _questions = [];
  QuizSession? _currentSession;
  bool _isLoading = false;
  
  final _effectController = StreamController<QuizEffect>.broadcast();
  Stream<QuizEffect> get effects => _effectController.stream;

  // Timer logic
  int _accumulatedTimeMs = 0;
  DateTime? _timerStartTime;

  QuizService(this._studentContract, this._questContract);

  @override
  List<Question> get questions => _questions;

  @override
  QuizSession? get currentSession => _currentSession;

  @override
  bool get isLoading => _isLoading;

  @override
  Question? get currentQuestion {
    if (_currentSession == null || _questions.isEmpty) return null;
    if (_currentSession!.currentIndex >= _questions.length) return null;
    return _questions[_currentSession!.currentIndex];
  }

  @override
  Future<void> startSession(String topicId, {int count = 10, List<int>? questionIds}) async {
    _isLoading = true;
    _questions = [];
    _currentSession = null;
    notifyListeners();

    try {
      // If we have specific question IDs (Mistake Review mode), fetch them directly
      if (questionIds != null && questionIds.isNotEmpty) {
         final response = await _api.post('${ApiEndpoints.statsSummary}/questions/batch', {
           'ids': questionIds,
         });
         if (response is List) {
           _questions = response.map((e) => Question.fromJson(e)).toList();
         }
      } else {
        // Normal topic-based session
        final response = await _api.get('${ApiEndpoints.statsSummary}/questions?topic=$topicId&limit=$count');
        if (response is List) {
          _questions = response.map((e) => Question.fromJson(e)).toList();
        }
      }
      
      if (_questions.isNotEmpty) {
        _currentSession = QuizSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          topicId: topicId,
          questionIds: _questions.map((q) => q.id).toList(),
          incorrectQuestionIds: [],
          currentIndex: 0,
          correctCount: 0,
          totalQuestions: _questions.length,
          startTime: DateTime.now(),
        );
        resumeTimer();
      }
    } catch (e) {
      debugPrint('Error starting quiz session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<bool> submitAnswer(String choiceId) async {
    if (_currentSession == null || currentQuestion == null) return false;
    
    pauseTimer();
    final responseTime = _accumulatedTimeMs > 0 ? _accumulatedTimeMs : 1000;
    
    final isCorrect = currentQuestion!.correctAnswer == choiceId;
    
    // Update Quest Progress
    _questContract.updateProgress(QuestType.questionsAnswered, 1);
    
    if (isCorrect) {
      _currentSession = _currentSession!.copyWith(
        correctCount: _currentSession!.correctCount + 1,
      );
      
      _questContract.updateProgress(QuestType.correctAnswers, 1);
      
      await _studentContract.addXP(10);
      await _studentContract.addCoins(5);
      
      _effectController.add(const QuizEffect(QuizEffectType.hapticSuccess));
      _effectController.add(const QuizEffect(QuizEffectType.coins, 5));
    } else {
      final updatedIncorrect = List<int>.from(_currentSession!.incorrectQuestionIds)
        ..add(currentQuestion!.id);
      _currentSession = _currentSession!.copyWith(
        incorrectQuestionIds: updatedIncorrect,
      );
      _effectController.add(const QuizEffect(QuizEffectType.hapticError));
    }

    // Sync with backend analytics (Legacy Parity)
    try {
      await _api.post('/quiz/answer', {
        'sessionId': _currentSession!.id,
        'questionId': currentQuestion!.id,
        'isCorrect': isCorrect,
        'responseTimeMs': responseTime,
      });
    } catch (e) {
      debugPrint('Failed to sync answer analytics: $e');
    }

    notifyListeners();
    return isCorrect;
  }

  @override
  void nextQuestion() {
    if (_currentSession == null) return;
    
    if (_currentSession!.currentIndex < _questions.length - 1) {
      _currentSession = _currentSession!.copyWith(
        currentIndex: _currentSession!.currentIndex + 1,
      );
      _accumulatedTimeMs = 0;
      resumeTimer();
      notifyListeners();
    } else {
      endSession();
    }
  }

  @override
  Future<void> endSession() async {
    if (_currentSession == null) return;
    
    pauseTimer();
    _currentSession = _currentSession!.copyWith(isFinished: true);
    
    if (_currentSession!.accuracy > 0.8) {
      _effectController.add(const QuizEffect(QuizEffectType.confetti));
      _questContract.updateProgress(QuestType.accuracyMaster, 1);
    }
    
    notifyListeners();
  }

  void pauseTimer() {
    if (_timerStartTime != null) {
      _accumulatedTimeMs += DateTime.now().difference(_timerStartTime!).inMilliseconds;
      _timerStartTime = null;
    }
  }

  void resumeTimer() {
    if (_timerStartTime == null && !(_currentSession?.isFinished ?? false)) {
      _timerStartTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    pauseTimer();
    _effectController.close();
    super.dispose();
  }
}
