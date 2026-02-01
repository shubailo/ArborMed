import 'package:flutter/material.dart';
import 'question_renderer.dart';

/// Renderer for True/False questions
class TrueFalseRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final content = question['content'] as Map<String, dynamic>?;
    if (content == null) {
      return const Text('Invalid question format');
    }

    final statement = content['statement'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          statement,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget buildAnswerInput(
    BuildContext context,
    Map<String, dynamic> question,
    dynamic currentAnswer,
    Function(dynamic) onAnswerChanged,
  ) {
    final options = (question['options'] as List<dynamic>?) ?? [
      {'value': 'true', 'label': 'Igaz'},
      {'value': 'false', 'label': 'Hamis'}
    ];

    return Row(
      children: options.map<Widget>((option) {
        final optionMap = option as Map<String, dynamic>;
        final value = optionMap['value'] as String;
        final label = optionMap['label'] as String;
        final isSelected = currentAnswer == value;
        
        final isTrue = value == 'true';

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: isTrue ? 0 : 8,
              right: isTrue ? 8 : 0,
            ),
            child: InkWell(
              onTap: () => onAnswerChanged(value),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? (isTrue ? Colors.green[600] : Colors.red[600])
                    : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                      ? (isTrue ? Colors.green[700]! : Colors.red[700]!)
                      : Colors.grey[300]!,
                    width: 2,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: (isTrue ? Colors.green : Colors.red).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ] : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      isTrue ? Icons.check_circle_outline : Icons.highlight_off,
                      size: 32,
                      color: isSelected ? Colors.white : (isTrue ? Colors.green : Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  bool hasAnswer(dynamic answer) {
    return answer != null;
  }

  @override
  dynamic formatAnswer(dynamic answer) {
    return answer;
  }
}
