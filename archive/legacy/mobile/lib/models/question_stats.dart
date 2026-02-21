class QuestionStats {
  final String questionId;
  final String questionText;
  final String topicSlug;
  final int bloomLevel;
  final int totalAttempts;
  final int correctCount;
  final int avgTimeMs;
  final int correctPercentage;

  QuestionStats({
    required this.questionId,
    required this.questionText,
    required this.topicSlug,
    required this.bloomLevel,
    required this.totalAttempts,
    required this.correctCount,
    required this.avgTimeMs,
    required this.correctPercentage,
  });

  factory QuestionStats.fromJson(Map<String, dynamic> json) {
    return QuestionStats(
      questionId: json['question_id']?.toString() ?? '',
      questionText: json['question_text'] ?? '',
      topicSlug: json['topic_slug'] ?? '',
      bloomLevel: int.tryParse(json['bloom_level']?.toString() ?? '1') ?? 1,
      totalAttempts:
          int.tryParse(json['total_attempts']?.toString() ?? '0') ?? 0,
      correctCount: int.tryParse(json['correct_count']?.toString() ?? '0') ?? 0,
      avgTimeMs: int.tryParse(json['avg_time_ms']?.toString() ?? '0') ?? 0,
      correctPercentage:
          int.tryParse(json['correct_percentage']?.toString() ?? '0') ?? 0,
    );
  }
}
