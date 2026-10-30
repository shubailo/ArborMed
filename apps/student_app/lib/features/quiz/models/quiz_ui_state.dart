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
  final int currentBloomLevel;
  final int? newLevel;
  final String levelDirection; // 'NONE' | 'UP' | 'DOWN'
  final String? error;
  final int questionIndex;
  final bool isReviewComplete;

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
    this.currentBloomLevel = 1,
    this.newLevel,
    this.levelDirection = 'NONE',
    this.error,
    this.questionIndex = 0,
    this.isReviewComplete = false,
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
    int? currentBloomLevel,
    Object? newLevel = _undefined,
    String? levelDirection,
    Object? error = _undefined,
    int? questionIndex,
    bool? isReviewComplete,
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
      currentBloomLevel: currentBloomLevel ?? this.currentBloomLevel,
      newLevel: newLevel == _undefined ? this.newLevel : newLevel as int?,
      levelDirection: levelDirection ?? this.levelDirection,
      error: error == _undefined ? this.error : error as String?,
      questionIndex: questionIndex ?? this.questionIndex,
      isReviewComplete: isReviewComplete ?? this.isReviewComplete,
    );
  }
}
