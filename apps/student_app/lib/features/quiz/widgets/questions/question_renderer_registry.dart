import 'question_renderer.dart';
import 'relation_analysis_renderer.dart';
import 'single_choice_renderer.dart';
import 'true_false_renderer.dart';
import 'matching_renderer.dart';
import 'multiple_choice_renderer.dart';

/// Registry for all question renderers
/// Maps question types to their corresponding renderer implementations
class QuestionRendererRegistry {
  static final Map<String, QuestionRenderer> _renderers = {
    'single_choice': SingleChoiceRenderer(),
    'relation_analysis': RelationAnalysisRenderer(),
    'true_false': TrueFalseRenderer(),
    'matching': MatchingRenderer(),
    'multiple_choice': MultipleChoiceRenderer(),
    // Add more renderers here as they're implemented
  };

  /// Get the appropriate renderer for a question type
  /// Falls back to SingleChoiceRenderer if type is unknown
  static QuestionRenderer getRenderer(String questionType) {
    return _renderers[questionType] ?? SingleChoiceRenderer();
  }

  /// Check if a question type has a registered renderer
  static bool hasRenderer(String questionType) {
    return _renderers.containsKey(questionType);
  }

  /// Get all registered question types
  static List<String> getRegisteredTypes() {
    return _renderers.keys.toList();
  }
}
