import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'question_renderer.dart';
import '../../theme/cozy_theme.dart';
import '../../services/api_service.dart';

/// Renderer for Multiple Choice (Multi-Select) questions
class MultipleChoiceRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final questionText = getLocalizedText(context, question);
    
    // Check for image
    String? imageUrl;
    if (question['content'] != null && question['content'] is Map) {
       imageUrl = question['content']['image_url'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          style: GoogleFonts.outfit(
            fontSize: 18, 
            fontWeight: FontWeight.w600,
            color: CozyTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "(Válassz ki minden helyes választ!)",
          style: GoogleFonts.outfit(
            fontSize: 13, 
            color: CozyTheme.textSecondary, 
            fontStyle: FontStyle.italic,
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
    final options = getLocalizedOptions(context, question);
    final List<String> selectedOptions = (currentAnswer is List) ? List<String>.from(currentAnswer) : [];

    if (options.isEmpty) {
      return const Text("No options available");
    }

    return Column(
      children: options.map<Widget>((option) {
        final isSelected = selectedOptions.contains(option);
        final List<String> corrects = (correctAnswer is List) ? List<String>.from(correctAnswer) : [];
        final bool isOptionCorrect = corrects.contains(option);

        Color backgroundColor = CozyTheme.paperCream;
        Color borderColor = CozyTheme.textPrimary.withValues(alpha: 0.1);
        Color textColor = CozyTheme.textPrimary;
        double borderWidth = 1.5;
        List<BoxShadow> shadows = [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
        ];

        if (isSelected) {
          backgroundColor = CozyTheme.primary.withValues(alpha: 0.08);
          borderColor = CozyTheme.primary;
          textColor = CozyTheme.primary;
          borderWidth = 2.0;
          shadows = [
            BoxShadow(color: CozyTheme.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))
          ];
        }

        if (isChecked) {
          if (isOptionCorrect) {
            backgroundColor = CozyTheme.success.withValues(alpha: 0.08);
            borderColor = CozyTheme.success;
            textColor = const Color(0xFF1B5E20);
            borderWidth = 2.0;
            shadows = [];
          } else if (isSelected && !isOptionCorrect) {
            backgroundColor = CozyTheme.error.withValues(alpha: 0.08);
            borderColor = CozyTheme.error;
            textColor = const Color(0xFFB71C1C);
            borderWidth = 2.0;
            shadows = [];
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isChecked ? null : () {
                final newSelected = List<String>.from(selectedOptions);
                if (isSelected) {
                  newSelected.remove(option);
                } else {
                  newSelected.add(option);
                }
                onAnswerChanged(newSelected);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    Checkbox(
                      value: isSelected,
                      onChanged: isChecked ? null : (val) {
                         final newSelected = List<String>.from(selectedOptions);
                          if (val == true) {
                            newSelected.add(option);
                          } else {
                            newSelected.remove(option);
                          }
                          onAnswerChanged(newSelected);
                      },
                      activeColor: isChecked && !isOptionCorrect ? CozyTheme.error : CozyTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: isSelected || (isChecked && isOptionCorrect) ? FontWeight.w600 : FontWeight.w400,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (isChecked && isOptionCorrect)
                      const Icon(Icons.check_circle_rounded, color: CozyTheme.success, size: 22),
                    if (isChecked && isSelected && !isOptionCorrect)
                      const Icon(Icons.cancel_rounded, color: CozyTheme.error, size: 22),
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
    return answer != null && (answer is List) && answer.isNotEmpty;
  }

  @override
  dynamic formatAnswer(dynamic answer) {
    return answer;
  }
}
