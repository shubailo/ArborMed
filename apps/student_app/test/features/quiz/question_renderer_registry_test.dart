import 'package:arbor_med/features/quiz/widgets/questions/question_renderer_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('case studies and historical relation questions retain their renderers', () {
    for (final alias in {'case_study': 'single_choice', 'relational_analysis': 'relation_analysis'}.entries) {
      expect(QuestionRendererRegistry.hasRenderer(alias.key), isTrue);
      expect(QuestionRendererRegistry.getRenderer(alias.key),
          same(QuestionRendererRegistry.getRenderer(alias.value)));
    }
  });
}
