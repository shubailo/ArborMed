enum QuestPeriod { daily, weekly }

enum QuestStatus { active, completed, claimed }

enum QuestType { questionsAnswered, correctAnswers, perfectScore, login }

class LearningQuest {
  final String id;
  final QuestPeriod period;
  final QuestType type;
  final String title;
  final String description;
  final String? titleHu;
  final String? descriptionHu;
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
    this.titleHu,
    this.descriptionHu,
    required this.targetCount,
    this.currentCount = 0,
    this.status = QuestStatus.active,
    required this.rewardTokens,
  });

  // Older local snapshots used qualified enum names; the API uses short names.
  factory LearningQuest.fromJson(Map<String, dynamic> json) {
    T readEnum<T extends Enum>(List<T> choices, dynamic value) =>
        choices.firstWhere(
            (item) => value == item.name || value == item.toString(),
            orElse: () => throw const FormatException('Invalid quest enum'));
    final target = json['targetCount'];
    final current = json['currentCount'];
    final reward = json['rewardTokens'];
    if (target is! int ||
        target <= 0 ||
        current is! int ||
        current < 0 ||
        current > target ||
        reward is! int ||
        reward < 0) {
      throw const FormatException('Invalid quest counts');
    }
    return LearningQuest(
      id: json['id'] as String,
      period: readEnum(QuestPeriod.values, json['period'] ?? 'daily'),
      type: readEnum(QuestType.values, json['type']),
      title: json['title'] as String,
      titleHu: json['titleHu'] as String?,
      descriptionHu: json['descriptionHu'] as String?,
      description: json['description'] as String,
      targetCount: target,
      currentCount: current,
      status: readEnum(QuestStatus.values, json['status']),
      rewardTokens: reward,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period': period.toString(),
      'type': type.toString(),
      'title': title,
      if (titleHu != null) 'titleHu': titleHu,
      if (descriptionHu != null) 'descriptionHu': descriptionHu,
      'description': description,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'status': status.toString(),
      'rewardTokens': rewardTokens,
    };
  }

  double get progress => (currentCount / targetCount).clamp(0.0, 1.0);
}
