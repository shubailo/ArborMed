import 'package:equatable/equatable.dart';

class Question extends Equatable {
  final String id;
  final String topicId;
  final int bloomLevel;
  final int difficulty;
  final String content;
  final String explanation;
  final String? selectionReason;
  final List<AnswerOption> options;

  const Question({
    required this.id,
    required this.topicId,
    required this.bloomLevel,
    required this.difficulty,
    required this.content,
    required this.explanation,
    this.selectionReason,
    required this.options,
  });

  @override
  List<Object?> get props => [
    id,
    topicId,
    bloomLevel,
    difficulty,
    content,
    selectionReason,
    options,
  ];
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
