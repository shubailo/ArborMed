import 'package:flutter/foundation.dart';
import 'question.dart';

class AdminQuestion extends CoreQuestion {
  final String? topicNameEn;
  final String? topicNameHu;
  final int attempts;
  final double successRate;
  final int reportCount;

  AdminQuestion({
    required super.id,
    super.text,
    super.questionTextHu,
    required super.options,
    super.content,
    required super.correctAnswer,
    super.explanation,
    super.explanationHu,
    required super.topicId,
    required super.bloomLevel,
    super.type,
    this.topicNameEn,
    this.topicNameHu,
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
        successRate: (json['success_rate'] as num?)?.toDouble() ?? 0.0,
        reportCount: json['report_count'] ?? 0,
      );
    } catch (e) {
      debugPrint('Error parsing AdminQuestion ID ${json['id']}: $e');
      debugPrint('JSON Content: $json');
      rethrow;
    }
  }
}
