abstract class QuizContract {
  void onQuizCompleted({
    required String userId,
    required int xpEarned,
    required int coinsEarned,
    required String subjectId,
  });
}
