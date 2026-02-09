import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

        Color backgroundColor = palette.paperCream;
        Color borderColor = palette.textPrimary.withValues(alpha: 0.1);
        Color textColor = palette.textPrimary;

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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isChecked
                    ? null
                    : () async {
                        // Enhanced haptic: medium + light pulse
                        HapticFeedback.mediumImpact();
                        await Future.delayed(const Duration(milliseconds: 50));
                        HapticFeedback.lightImpact();
                        onAnswerChanged(value);
                      },
                borderRadius: BorderRadius.circular(24),
                child: AnimatedScale(
                  scale: isSelected ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? borderColor : borderColor.withValues(alpha: 0.1),
                        width: isSelected ? 2.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? borderColor.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: isSelected ? 20 : 12,
                          offset: isSelected ? const Offset(0, 10) : const Offset(0, 4),
                          spreadRadius: isSelected ? 0 : -2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          label,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            letterSpacing: 0.5,
                            fontWeight: isSelected || isCorrect
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
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
