import 'package:flutter/material.dart';
import 'question_renderer.dart';
import '../../theme/cozy_theme.dart';

/// Renderer for Single Choice questions
/// Traditional multiple choice with one correct answer
class SingleChoiceRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final content = question['content'] as Map<String, dynamic>?;
    if (content == null) {
      // Fallback for old format
      final text = question['text'] as String? ?? '';
      return Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      );
    }

    final questionText = content['question_text'] as String? ?? '';
    return Text(
      questionText,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    );
  }

  @override
  Widget buildAnswerInput(
    BuildContext context,
    Map<String, dynamic> question,
    dynamic currentAnswer,
    Function(dynamic) onAnswerChanged,
  ) {
    List<String> options = [];
    
    // Try new format first
    final content = question['content'] as Map<String, dynamic>?;
    if (content != null && content['options'] != null) {
      options = List<String>.from(content['options'] as List);
    } else {
      // Fallback to old format
      final optionsData = question['options'];
      if (optionsData is List) {
        options = List<String>.from(optionsData);
      } else if (optionsData is String) {
        try {
          final decoded = optionsData;
          options = List<String>.from(decoded as List);
        } catch (e) {
          options = [optionsData];
        }
      }
    }

    return Column(
      children: options.map<Widget>((option) {
        final isSelected = currentAnswer == option;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onAnswerChanged(option),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? CozyTheme.primary.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? CozyTheme.primary : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? CozyTheme.primary : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? CozyTheme.primary : Colors.black87,
                      ),
                    ),
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
  bool hasAnswer(dynamic answer) {
    return answer != null && answer.toString().isNotEmpty;
  }

  @override
  dynamic formatAnswer(dynamic answer) {
    return answer;
  }
}
