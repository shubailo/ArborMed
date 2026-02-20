import '../../domain/entities/question.dart';

class QuestionModel extends Question {
  const QuestionModel({
    required super.id,
    required super.topicId,
    required super.bloomLevel,
    required super.content,
    required super.explanation,
    required super.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'],
      topicId: json['topicId'],
      bloomLevel: json['bloomLevel'],
      content: json['content'],
      explanation: json['explanation'] ?? '',
      options: (json['options'] as List)
          .map((i) => AnswerOptionModel.fromJson(i))
          .toList(),
    );
  }
}

class AnswerOptionModel extends AnswerOption {
  const AnswerOptionModel({
    required super.id,
    required super.text,
    required super.isCorrect,
  });

  factory AnswerOptionModel.fromJson(Map<String, dynamic> json) {
    return AnswerOptionModel(
      id: json['id'] ?? '',
      text: json['text'],
      isCorrect: json['isCorrect'],
    );
  }
}
