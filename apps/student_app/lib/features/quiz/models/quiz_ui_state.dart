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
