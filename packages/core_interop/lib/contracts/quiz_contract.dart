import '../src/models/question.dart';
import '../src/models/quiz_session.dart';

abstract class QuizContract {
  List<Question> get questions;
  QuizSession? get currentSession;
  bool get isLoading;

  Future<void> startSession(String topicId, {int count = 10, List<int>? questionIds});
  Future<bool> submitAnswer(String choiceId); // Returns true if correct
  Future<void> endSession();
  
  void nextQuestion();
  Question? get currentQuestion;
}
