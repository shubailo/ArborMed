import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:get_it/get_it.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:core_interop/core_interop.dart';

class QuizService extends ChangeNotifier {
  final Isar _isar;
  final StudentContract _studentContract = GetIt.I<StudentContract>();

  List<QuestionCollection> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isFinished = false;

  QuizService(this._isar);

  List<QuestionCollection> get questions => _questions;
  int get currentIndex => _currentIndex;
  int get score => _score;
  bool get isFinished => _isFinished;
  
  double get progress => _questions.isEmpty ? 0 : (_currentIndex + 1) / _questions.length;

  Future<void> loadQuestions(String topicSlug) async {
    _questions = await _isar.questionCollections
        .filter()
        .topicSlugEqualTo(topicSlug)
        .findAll();
    
    _currentIndex = 0;
    _score = 0;
    _isFinished = false;
    notifyListeners();
  }

  void answerQuestion(int selectedIndex) {
    if (_currentIndex >= _questions.length) return;

    if (selectedIndex == _questions[_currentIndex].correctAnswerIndex) {
      _score++;
    }

    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
    } else {
      _isFinished = true;
      _finalizeQuiz();
    }
    notifyListeners();
  }

  Future<void> _finalizeQuiz() async {
    // Reward logic per interop contracts
    final xpEarned = _score * 10;
    final coinsEarned = _score * 5;

    await _studentContract.addXP(xpEarned);
    await _studentContract.addCoins(coinsEarned);
  }
}
