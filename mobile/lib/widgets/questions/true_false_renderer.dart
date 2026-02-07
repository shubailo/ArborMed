import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'question_renderer.dart';
import '../../theme/cozy_theme.dart';

/// Renderer for True/False questions
class TrueFalseRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final palette = CozyTheme.of(context);
    final statement = getLocalizedContentField(context, question, 'statement',
        defaultVal: '');

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
          statement,
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

    final options = (question['options'] as List<dynamic>?) ??
        [
          {'value': 'true', 'label': 'Igaz'},
          {'value': 'false', 'label': 'Hamis'}
        ];

    return Row(
      children: options.map<Widget>((option) {
        final optionMap = option as Map<String, dynamic>;
        final value = optionMap['value'] as String;
        final label = optionMap['label'] as String;
        final isSelected = currentAnswer == value;
        final isCorrect = isChecked && value == correctAnswer;
        final isWrong = isChecked && isSelected && value != correctAnswer;

        final isTrue = value == 'true';

        Color backgroundColor = palette.paperCream;
        Color borderColor = palette.textPrimary.withValues(alpha: 0.1);
        Color textColor = palette.textPrimary;
        Color iconColor = isTrue ? palette.success : palette.secondary;
        double borderWidth = 1.5;

        if (isChecked) {
          if (isCorrect) {
            backgroundColor = palette.success;
            borderColor = palette.success;
            textColor = palette.textInverse;
            iconColor = palette.textInverse;
          } else if (isWrong) {
            backgroundColor = palette.error;
            borderColor = palette.error;
            textColor = palette.textInverse;
            iconColor = palette.textInverse;
          }
        } else if (isSelected) {
          backgroundColor = isTrue ? palette.success : palette.error;
          borderColor = isTrue ? palette.success : palette.error;
          textColor = palette.textInverse;
          iconColor = palette.textInverse;
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: isTrue ? 0 : 8,
              right: isTrue ? 8 : 0,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isChecked ? null : () => onAnswerChanged(value),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                    boxShadow: isSelected && !isChecked
                        ? [
                            BoxShadow(
                              color: (isTrue ? palette.success : palette.error)
                                  .withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isTrue
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 32,
                        color: iconColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
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
  dynamic getAnswerForIndex(BuildContext context, Map<String, dynamic> question,
      int index, dynamic currentAnswer) {
    if (index == 0) return 'true';
    if (index == 1) return 'false';
    return currentAnswer;
  }
}
