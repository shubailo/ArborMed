import 'package:flutter/material.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'question_renderer.dart';

class MultipleChoiceRenderer extends QuestionRenderer {
  const MultipleChoiceRenderer();

  @override
  bool hasAnswer(dynamic answer) => answer is List && (answer as List).isNotEmpty;

  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final text = question['text'] ?? question['question_text_en'] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ArborColors.textPrimary,
              height: 1.4,
            ),
      ),
    );
  }

  @override
  Widget buildAnswerInput(
    BuildContext context,
    Map<String, dynamic> question,
    dynamic userAnswer,
    Function(dynamic) onAnswerChanged,
  ) {
    final options = _getOptions(question);
    final List<int> selectedIndices = (userAnswer is List) 
        ? (userAnswer as List).map<int>((e) => e as int).toList() 
        : [];
    
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value.toString();
        final isSelected = selectedIndices.contains(index);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: InkWell(
            onTap: () {
              final next = List<int>.from(selectedIndices);
              if (next.contains(index)) {
                next.remove(index);
              } else {
                next.add(index);
              }
              onAnswerChanged(next);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: isSelected ? ArborColors.primary.withOpacity(0.05) : Colors.white,
                border: Border.all(
                  color: isSelected ? ArborColors.primary : Colors.grey.shade200,
                  width: isSelected ? 2.5 : 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: ArborColors.primary.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ] : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? ArborColors.textPrimary : ArborColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: isSelected ? ArborColors.primary : Colors.grey.shade300,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  dynamic formatAnswer(dynamic answer) => answer;

  List<dynamic> _getOptions(Map<String, dynamic> question) {
    final opts = question['options'];
    if (opts is List) return opts;
    if (opts is Map && opts.containsKey('en')) return opts['en'] as List;
    return [];
  }
}
