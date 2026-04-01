class QuizSession {
  final String id;
  final String topicId;
  final List<int> questionIds;
  final List<int> incorrectQuestionIds;
  final int currentIndex;
  final int correctCount;
  final int totalQuestions;
  final DateTime startTime;
  final bool isFinished;

  const QuizSession({
    required this.id,
    required this.topicId,
    required this.questionIds,
    this.incorrectQuestionIds = const [],
    required this.currentIndex,
    required this.correctCount,
    required this.totalQuestions,
    required this.startTime,
    this.isFinished = false,
  });

  QuizSession copyWith({
    int? currentIndex,
    int? correctCount,
    List<int>? incorrectQuestionIds,
    bool? isFinished,
  }) {
    return QuizSession(
      id: id,
      topicId: topicId,
      questionIds: questionIds,
      incorrectQuestionIds: incorrectQuestionIds ?? this.incorrectQuestionIds,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      totalQuestions: totalQuestions,
      startTime: startTime,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  double get progress => totalQuestions > 0 ? (currentIndex + 1) / totalQuestions : 0.0;
  double get accuracy => totalQuestions > 0 ? (correctCount / totalQuestions) : 0.0;
  int get mistakeCount => incorrectQuestionIds.length;
}
