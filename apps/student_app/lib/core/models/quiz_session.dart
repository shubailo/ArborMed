class QuizSession {
  final int id;
  final int userId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double? score;

  QuizSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.completedAt,
    this.score,
  });

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      id: json['id'],
      userId: json['user_id'],
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      score: (json['score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'score': score,
    };
  }
}
