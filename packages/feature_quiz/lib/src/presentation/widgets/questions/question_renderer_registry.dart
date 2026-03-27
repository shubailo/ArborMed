import 'package:flutter/material.dart';
import 'renderers/question_renderer.dart';
import 'renderers/single_choice_renderer.dart';
import 'renderers/multiple_choice_renderer.dart';
import 'renderers/true_false_renderer.dart';

class QuestionRendererRegistry {
  static QuestionRenderer getRenderer(String? type) {
    switch (type) {
      case 'multiple_choice':
        return const MultipleChoiceRenderer();
      case 'true_false':
        return const TrueFalseRenderer();
      case 'single_choice':
      default:
        return const SingleChoiceRenderer();
    }
  }
}
