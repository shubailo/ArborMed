import 'package:flutter/material.dart';

/// Abstract base class for all question renderers
/// Each question type must implement this interface
abstract class QuestionRenderer {
  /// Build the question display widget
  /// This shows the question content (text, statements, images, etc.)
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question);

  /// Build the answer input widget
  /// This shows the interactive elements for answering (radio buttons, checkboxes, etc.)
  Widget buildAnswerInput(
    BuildContext context,
    Map<String, dynamic> question,
    dynamic currentAnswer,
    Function(dynamic) onAnswerChanged,
  );

  /// Validate if the user has provided an answer
  bool hasAnswer(dynamic answer);

  /// Get the user's answer in the format expected by the backend
  dynamic formatAnswer(dynamic answer);
}
