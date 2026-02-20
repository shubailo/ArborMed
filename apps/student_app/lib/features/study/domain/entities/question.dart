import 'package:equatable/equatable.dart';

class Question extends Equatable {
  final String id;
  final String topicId;
  final int bloomLevel;
  final String content;
  final String explanation;
  final List<AnswerOption> options;

  const Question({
    required this.id,
    required this.topicId,
    required this.bloomLevel,
    required this.content,
    required this.explanation,
    required this.options,
  });

  @override
  List<Object?> get props => [id, topicId, bloomLevel, content, options];
}

class AnswerOption extends Equatable {
  final String id;
  final String text;
  final bool isCorrect;

  const AnswerOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [id, text, isCorrect];
}
