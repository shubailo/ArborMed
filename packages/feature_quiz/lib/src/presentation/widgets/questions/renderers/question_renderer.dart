import 'package:flutter/material.dart';

abstract class QuestionRenderer {
  const QuestionRenderer();

  bool hasAnswer(dynamic answer);

  Widget buildQuestion(BuildContext context, Map<String, dynamic> question);

  Widget buildAnswerInput(
    BuildContext context,
    Map<String, dynamic> question,
    dynamic userAnswer,
    Function(dynamic) onAnswerChanged,
  );

  dynamic formatAnswer(dynamic answer);
}
