import 'package:flutter/foundation.dart';

class AdminQuestion {
  final int id;
  final String? text; // Default/English text
  final String? questionTextHu; // Hungarian text
  final dynamic options; // String or List or Map ({"en": [], "hu": []})
  final dynamic content;
  final dynamic correctAnswer;
  final String? explanation; // Default/English explanation
  final String? explanationHu; // Hungarian explanation
  final int topicId;
  final String? topicNameEn;
  final String? topicNameHu;
  final int bloomLevel;
  final String? type;
  final int attempts;
  final double successRate;
  final int reportCount;

  AdminQuestion({
    required this.id,
    this.text,
    this.questionTextHu,
    required this.options,
    this.content,
    required this.correctAnswer,
    this.explanation,
    this.explanationHu,
    required this.topicId,
    this.topicNameEn,
    this.topicNameHu,
    required this.bloomLevel,
    this.type,
    this.attempts = 0,
    this.successRate = 0.0,
    this.reportCount = 0,
  });

  factory AdminQuestion.fromJson(Map<String, dynamic> json) {
    try {
      return AdminQuestion(
        id: json['id'],
        text: json['text'] ?? json['question_text_en'] ?? '',
        questionTextHu: json['question_text_hu'],
        options: json['options'],
        content: json['content'],
        correctAnswer: json['correct_answer'],
        explanation: json['explanation'] ?? json['explanation_en'],
        explanationHu: json['explanation_hu'],
        topicId: json['topic_id'],
        topicNameEn: json['topic_name'] ?? json['name_en'],
        topicNameHu: json['topic_name_hu'] ?? json['name_hu'],
        bloomLevel: json['bloom_level'] ?? 1,
        type: json['type'] ?? 'single_choice',
        attempts: json['attempts'] ?? 0,
        successRate: (json['success_rate'] is int)
            ? (json['success_rate'] as int).toDouble()
            : (json['success_rate'] ?? 0.0),
        reportCount: json['report_count'] ?? 0,
      );
    } catch (e) {
      debugPrint('Error parsing AdminQuestion ID ${json['id']}: $e');
      debugPrint('JSON Content: $json');
      rethrow;
    }
  }

  // Helper to extract options list for a specific language
  List<String>? get optionsHu {
    if (options is Map) {
      final map = options as Map;
      if (map.containsKey('hu')) {
        return (map['hu'] as List).map((e) => e?.toString() ?? '').toList();
      }
    }
    return null;
  }
}
