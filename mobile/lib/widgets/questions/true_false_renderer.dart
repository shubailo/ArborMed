import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'question_renderer.dart';
import '../../theme/cozy_theme.dart';

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

    List<Map<String, dynamic>> options = [];
    final localizedOptions = getLocalizedOptions(context, question);

    if (localizedOptions.isNotEmpty && localizedOptions.length >= 2) {
      // Smart mapping: check if the label semantically means True or False
      // This is resilient to shuffling if it ever happens again or if source data is weird.
      final op1 = localizedOptions[0].toLowerCase();
      
      // If first option looks like "Hamis" or "False", map it to 'false' value
      if (op1 == 'hamis' || op1 == 'false') {
        options = [
          {'value': 'false', 'label': localizedOptions[0]},
          {'value': 'true', 'label': localizedOptions[1]}
        ];
      } else {
        options = [
          {'value': 'true', 'label': localizedOptions[0]},
          {'value': 'false', 'label': localizedOptions[1]}
        ];
      }
    } else {
      options = [
        {'value': 'true', 'label': isHu ? 'Igaz' : 'True'},
        {'value': 'false', 'label': isHu ? 'Hamis' : 'False'}
      ];
    }

    return Row(
      children: options.map<Widget>((option) {
        final optionMap = option;
        final value = optionMap['value'] as String;
        final label = optionMap['label'] as String;
        final isSelected = currentAnswer == value;
        final isCorrect = isChecked && value.toString().toLowerCase() == correctAnswer.toString().toLowerCase();
        final isWrong = isChecked && isSelected && value.toString().toLowerCase() != correctAnswer.toString().toLowerCase();

        final isTrue = value == 'true';

        Color backgroundColor = palette.paperCream;
        Color borderColor = palette.textPrimary.withValues(alpha: 0.1);
        Color textColor = palette.textPrimary;
        double borderWidth = 1.5;

        if (isChecked) {
          if (isCorrect) {
            backgroundColor = palette.success;
            borderColor = palette.success;
            textColor = palette.textInverse;
          } else if (isWrong) {
            backgroundColor = palette.error;
            borderColor = palette.error;
            textColor = palette.textInverse;
          }
        } else if (isSelected) {
          backgroundColor = palette.primary;
          borderColor = palette.primary;
          textColor = palette.textInverse;
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
                child: AnimatedScale(
                  scale: isSelected ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected ? 3.0 : borderWidth,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (isChecked
                                        ? (isCorrect ? palette.success : palette.error)
                                        : palette.primary)
                                    .withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ]
                          : [
                              BoxShadow(
                                color: palette.textPrimary.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
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
