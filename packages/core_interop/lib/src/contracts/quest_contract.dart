enum QuestType {
  questionsAnswered,
  correctAnswers,
  accuracyMaster,
  dailyStreak,
  topicMastery,
}

abstract class QuestContract {
  Future<void> updateProgress(QuestType type, int amount);
  Future<void> fetchQuests();
  List<dynamic> get activeQuests;
}
