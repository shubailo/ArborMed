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
            onTap: () => showZoomedImage(context, imageUrl!.startsWith('http') ? imageUrl : '${ApiService.baseUrl}$imageUrl'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl.startsWith('http') ? imageUrl : '${ApiService.baseUrl}$imageUrl',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  Container(
                    height: 150, 
                    color: Colors.grey[200], 
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))
                  ),
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
            color: CozyTheme.textPrimary,
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

        Color backgroundColor = CozyTheme.paperCream;
        Color borderColor = CozyTheme.textPrimary.withValues(alpha: 0.1);
        Color textColor = CozyTheme.textPrimary;
        Color iconColor = CozyTheme.textPrimary.withValues(alpha: 0.4);
        double borderWidth = 1.0;
        List<BoxShadow> shadows = [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
        ];

        if (isChecked) {
          if (isCorrect) {
            backgroundColor = CozyTheme.success.withValues(alpha: 0.08);
            borderColor = CozyTheme.success.withValues(alpha: 0.5);
            textColor = const Color(0xFF1B5E20);
            iconColor = CozyTheme.success;
            borderWidth = 1.5;
            shadows = [];
          } else if (isWrong) {
            backgroundColor = CozyTheme.error.withValues(alpha: 0.08);
            borderColor = CozyTheme.error.withValues(alpha: 0.5);
            textColor = const Color(0xFFB71C1C);
            iconColor = CozyTheme.error;
            borderWidth = 1.5;
            shadows = [];
          }
        } else if (isSelected) {
          backgroundColor = CozyTheme.primary.withValues(alpha: 0.08);
          borderColor = CozyTheme.primary;
          textColor = CozyTheme.primary;
          iconColor = CozyTheme.primary;
          borderWidth = 2.0;
          shadows = [
            BoxShadow(color: CozyTheme.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                        color: iconColor,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: isSelected || isCorrect ? FontWeight.w600 : FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (isChecked && isCorrect)
                        const Icon(Icons.check_circle_rounded, color: CozyTheme.success, size: 22),
                      if (isChecked && isWrong)
                        const Icon(Icons.cancel_rounded, color: CozyTheme.error, size: 22),
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
  dynamic getAnswerForIndex(BuildContext context, Map<String, dynamic> question, int index, dynamic currentAnswer) {
    final options = getLocalizedOptions(context, question);
    if (index >= 0 && index < options.length) {
      return options[index];
    }
    return currentAnswer;
  }
}
