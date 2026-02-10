import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'question_renderer.dart';
import '../../theme/cozy_theme.dart';
import '../cozy/pressable_answer_button.dart';

/// Renderer for True/False questions
class TrueFalseRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final palette = CozyTheme.of(context);
    final questionText = getLocalizedText(context, question);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: palette.paperCream,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: palette.textPrimary.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Text(
          questionText,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: palette.textPrimary,
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
    Function(dynamic) onAnswerChanged, {
    bool isChecked = false,
    dynamic correctAnswer,
  }) {
    final palette = CozyTheme.of(context);

    final locale = Localizations.localeOf(context).languageCode;
    final isHu = locale == 'hu';

    // Use locale-based labels regardless of DB content
    final options = [
      {'value': 'true', 'label': isHu ? 'Igaz' : 'True'},
      {'value': 'false', 'label': isHu ? 'Hamis' : 'False'}
    ];

    return Row(
      children: options.map<Widget>((option) {
        final value = option['value'] as String;
        final label = option['label'] as String;
        final isSelected = currentAnswer == value;
        final isCorrect = isChecked && value.toLowerCase() == correctAnswer.toString().toLowerCase();
        final isWrong = isChecked && isSelected && value.toLowerCase() != correctAnswer.toString().toLowerCase();

        final isTrue = value == 'true';

        // Use primary (sage green) for correct like Continue button, error for wrong
        Color backgroundColor = palette.paperCream;
        Color borderColor = palette.textPrimary.withValues(alpha: 0.15);
        Color textColor = palette.textPrimary;

        if (isChecked) {
          if (isCorrect) {
            backgroundColor = palette.primary; // Same green as Continue button
            borderColor = palette.primary;
            textColor = palette.textInverse;
          } else if (isWrong) {
            backgroundColor = palette.error;
            borderColor = palette.error;
            textColor = palette.textInverse;
          }
        } else if (isSelected) {
          backgroundColor = palette.primary.withValues(alpha: 0.15);
          borderColor = palette.primary;
          textColor = palette.primary;
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: isTrue ? 0 : 8,
              right: isTrue ? 8 : 0,
            ),
            child: PressableAnswerButton(
              key: ValueKey("tf_${question['id']}_$value"),
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              isSelected: isSelected,
              isWrong: isWrong,
              isDisabled: isChecked,
              padding: const EdgeInsets.symmetric(vertical: 12),
              onTap: () => onAnswerChanged(value),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    letterSpacing: 0.3,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: textColor,
                  ),
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

  @override
  bool validateAnswer(dynamic userAnswer, dynamic correctAnswer) {
    if (userAnswer == null || correctAnswer == null) return false;
    final u = userAnswer.toString().trim().toLowerCase();
    
    // Correct answer might be "True", "true", or a JSON list ["True"]
    if (correctAnswer is String) {
      final c = correctAnswer.trim().toLowerCase();
      if (c.startsWith('[') && c.endsWith(']')) {
        try {
          final List<dynamic> list = json.decode(c);
          return list.any((e) => e.toString().trim().toLowerCase() == u);
        } catch (_) {}
      }
      return u == c;
    } else if (correctAnswer is List) {
      return correctAnswer.any((e) => e.toString().trim().toLowerCase() == u);
    }
    
    return u == correctAnswer.toString().trim().toLowerCase();
  }

  @override
  dynamic getAnswerForIndex(BuildContext context, Map<String, dynamic> question,
      int index, dynamic currentAnswer) {
    if (index == 0) return 'true';
    if (index == 1) return 'false';
    return currentAnswer;
  }
}
