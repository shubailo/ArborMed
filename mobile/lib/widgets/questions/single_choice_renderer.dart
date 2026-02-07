import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'question_renderer.dart';
import '../../theme/cozy_theme.dart';
import '../../services/api_service.dart';

/// Renderer for Single Choice questions
/// Traditional multiple choice with one correct answer
class SingleChoiceRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final palette = CozyTheme.of(context);

    // getLocalizedText handles checking for question_text_en/hu and falling back to text
    final questionText = getLocalizedText(context, question);

    // Check for image
    String? imageUrl;
    if (question['content'] != null && question['content'] is Map) {
      imageUrl = question['content']['image_url'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          GestureDetector(
            onTap: () => showZoomedImage(
                context,
                imageUrl!.startsWith('http')
                    ? imageUrl
                    : '${ApiService.baseUrl}$imageUrl'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl.startsWith('http')
                    ? imageUrl
                    : '${ApiService.baseUrl}$imageUrl',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: palette.textSecondary.withValues(alpha: 0.1),
                    child: Center(
                        child: Icon(Icons.broken_image,
                            color:
                                palette.textSecondary.withValues(alpha: 0.4)))),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          questionText,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
      ],
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

    // getLocalizedOptions handles parsing JSON and selecting en/hu list
    final options = getLocalizedOptions(context, question);

    if (options.isEmpty) {
      return const Text("No options available");
    }

    return Column(
      children: options.map<Widget>((option) {
        final isSelected = currentAnswer == option;
        final isCorrect = isChecked && option == correctAnswer;
        final isWrong = isChecked && isSelected && option != correctAnswer;

        Color backgroundColor = palette.paperCream;
        Color borderColor = palette.textPrimary.withValues(alpha: 0.1);
        Color textColor = palette.textPrimary;
        Color iconColor = palette.textPrimary.withValues(alpha: 0.4);
        double borderWidth = 1.0;
        List<BoxShadow> shadows = [
          BoxShadow(
              color: palette.textPrimary.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ];

        if (isChecked) {
          if (isCorrect) {
            backgroundColor = palette.success.withValues(alpha: 0.08);
            borderColor = palette.success.withValues(alpha: 0.5);
            textColor = palette.success;
            iconColor = palette.success;
            borderWidth = 1.5;
            shadows = [];
          } else if (isWrong) {
            backgroundColor = palette.error.withValues(alpha: 0.08);
            borderColor = palette.error.withValues(alpha: 0.5);
            textColor = palette.error;
            iconColor = palette.error;
            borderWidth = 1.5;
            shadows = [];
          }
        } else if (isSelected) {
          backgroundColor = palette.primary.withValues(alpha: 0.08);
          borderColor = palette.primary;
          textColor = palette.primary;
          iconColor = palette.primary;
          borderWidth = 2.0;
          shadows = [
            BoxShadow(
                color: palette.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ];
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isChecked ? null : () => onAnswerChanged(option),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                    boxShadow: shadows,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: iconColor,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: isSelected || isCorrect
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (isChecked && isCorrect)
                        Icon(Icons.check_circle_rounded,
                            color: palette.success, size: 22),
                      if (isChecked && isWrong)
                        Icon(Icons.cancel_rounded,
                            color: palette.error, size: 22),
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
    return answer != null && answer.toString().isNotEmpty;
  }

  @override
  dynamic formatAnswer(dynamic answer) {
    return answer;
  }

  @override
  dynamic getAnswerForIndex(BuildContext context, Map<String, dynamic> question,
      int index, dynamic currentAnswer) {
    final options = getLocalizedOptions(context, question);
    if (index >= 0 && index < options.length) {
      return options[index];
    }
    return currentAnswer;
  }
}
