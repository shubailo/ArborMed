
import 'package:arbor_med/core/models/boolean_answer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'question_renderer.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/widgets/cozy/pressable_answer_button.dart';

/// Renderer for True/False questions
class TrueFalseRenderer extends QuestionRenderer {
  @override
  String getLocalizedText(BuildContext context, Map<String, dynamic> question,
      {String? defaultText}) {
    final content = question['content'];
    final statement = content is Map ? content['statement'] : null;
    final language = Localizations.localeOf(context).languageCode;
    final localized = statement is Map ? statement[language] : statement;
    if (localized is String && localized.trim().isNotEmpty) return localized;

    final prompt = super.getLocalizedText(context, question, defaultText: defaultText);
    if (prompt.isNotEmpty) return prompt;
    if (statement is Map) {
      for (final fallback in [statement['en'], statement['hu']]) {
        if (fallback is String && fallback.trim().isNotEmpty) return fallback;
      }
    }
    return '';
  }

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

    final selected = parseBooleanAnswer(currentAnswer);
    final expected = isChecked ? parseStoredBooleanAnswer(correctAnswer) : null;

    return Row(
      children: options.map<Widget>((option) {
        final value = option['value'] as String;
        final label = option['label'] as String;
        final isTrue = value == 'true';
        final isSelected = selected == isTrue;
        final isCorrect = expected == isTrue;
        final isWrong = expected != null && isSelected && !isCorrect;

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
    return parseBooleanAnswer(answer) != null;
  }

  @override
  dynamic formatAnswer(dynamic answer) {
    return parseBooleanAnswer(answer)?.toString();
  }

  @override
  bool validateAnswer(dynamic userAnswer, dynamic correctAnswer, Map<String, dynamic> question) {
    final selected = parseBooleanAnswer(userAnswer);
    return selected != null && selected == parseStoredBooleanAnswer(correctAnswer);
  }

  @override
  dynamic getAnswerForIndex(BuildContext context, Map<String, dynamic> question,
      int index, dynamic currentAnswer) {
    if (index == 0) return 'true';
    if (index == 1) return 'false';
    return currentAnswer;
  }
}
