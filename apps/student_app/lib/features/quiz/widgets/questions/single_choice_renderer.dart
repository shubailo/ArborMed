import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'question_renderer.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/widgets/cozy/pressable_answer_button.dart';

/// Renderer for Single Choice questions
/// Traditional multiple choice with one correct answer
class SingleChoiceRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final palette = CozyTheme.of(context);
    final questionText = getLocalizedText(context, question);

    final content = question['content'];
    final raw = content is Map ? content['image_url'] : null;
    Uri? image;
    if (raw is String && raw.trim().isNotEmpty) {
      final reference = Uri.tryParse(raw.trim());
      if (reference != null) {
        final uri = Uri.parse(ApiService.baseUrl).resolveUri(reference);
        if ((uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty) image = uri;
      }
    }
    final imageUrl = image?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (imageUrl != null) ...[
          Tooltip(
            message: 'Tap to enlarge image',
            child: GestureDetector(
              onTap: () {
                Provider.of<AudioProvider>(context, listen: false)
                    .playSfx('click');
                showZoomedImage(context, imageUrl);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: palette.textSecondary.withValues(alpha: 0.1),
                      child: Center(
                          child: Icon(Icons.broken_image,
                              color: palette.textSecondary
                                  .withValues(alpha: 0.4)))),
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
    final options = getLocalizedOptions(context, question);

    if (options.isEmpty) {
      return const Text("No options available");
    }

    return Column(
      children: options.asMap().entries.map<Widget>((entry) {
        final index = entry.key;
        final option = entry.value;
        final optionId = choiceValue(question, index, option);
        final isSelected = currentAnswer == optionId;
        final isCorrect = isChecked &&
            commonValidateAnswer(optionId, correctAnswer, question, false);
        final isWrong = isChecked && isSelected && !isCorrect;

        Color backgroundColor = palette.paperCream;
        Color borderColor = palette.textPrimary.withValues(alpha: 0.1);
        Color textColor = palette.textPrimary;

        if (isChecked) {
          if (isCorrect) {
            backgroundColor = palette.primary;
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

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: PressableAnswerButton(
              key: ValueKey("single_${question['id']}_$index"),
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              isSelected: isSelected,
              isWrong: isWrong,
              isDisabled: isChecked,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              onTap: () => onAnswerChanged(optionId),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        letterSpacing: 0.2,
                        fontWeight: isSelected || isCorrect
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: textColor,
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

  @override
  bool validateAnswer(dynamic userAnswer, dynamic correctAnswer,
      Map<String, dynamic> question) {
    return commonValidateAnswer(userAnswer, correctAnswer, question);
  }

  @override
  dynamic getAnswerForIndex(BuildContext context, Map<String, dynamic> question,
      int index, dynamic currentAnswer) {
    final options = getLocalizedOptions(context, question);
    if (index >= 0 && index < options.length) {
      return choiceValue(question, index, options[index]);
    }
    return currentAnswer;
  }
}
