enum QuestPeriod { daily, weekly }
enum QuestStatus { active, completed, claimed }
enum QuestType { questionsAnswered, correctAnswers, perfectScore, login }

class LearningQuest {
  final String id;
  final QuestPeriod period;
  final QuestType type;
  final String title;
  final String description;
  final int targetCount;
  int currentCount;
  QuestStatus status;
  final int rewardTokens;

  LearningQuest({
    required this.id,
    required this.period,
    required this.type,
    required this.title,
    required this.description,
    required this.targetCount,
    this.currentCount = 0,
    this.status = QuestStatus.active,
    required this.rewardTokens,
  });

  // Factory for JSON if needed (persistence)
  factory LearningQuest.fromJson(Map<String, dynamic> json) {
    return LearningQuest(
      id: json['id'],
      period: QuestPeriod.values.firstWhere((e) => e.toString() == json['period']),
      type: QuestType.values.firstWhere((e) => e.toString() == json['type']),
      title: json['title'],
      description: json['description'],
      targetCount: json['targetCount'],
      currentCount: json['currentCount'],
      status: QuestStatus.values.firstWhere((e) => e.toString() == json['status']),
      rewardTokens: json['rewardTokens'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period': period.toString(),
      'type': type.toString(),
      'title': title,
      'description': description,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'status': status.toString(),
      'rewardTokens': rewardTokens,
    };
  }

  double get progress => (currentCount / targetCount).clamp(0.0, 1.0);
}
