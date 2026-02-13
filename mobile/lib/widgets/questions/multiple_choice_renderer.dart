import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/audio_provider.dart';
import 'question_renderer.dart';
import '../../theme/cozy_theme.dart';
import '../../services/api_service.dart';
import '../cozy/pressable_answer_button.dart';

/// Renderer for Multiple Choice (Multi-Select) questions
class MultipleChoiceRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final palette = CozyTheme.of(context);
    final questionText = getLocalizedText(context, question);

    String? imageUrl;
    if (question['content'] != null && question['content'] is Map) {
      imageUrl = question['content']['image_url'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          GestureDetector(
            onTap: () {
              Provider.of<AudioProvider>(context, listen: false)
                  .playSfx('click');
              showZoomedImage(
                  context,
                  imageUrl!.startsWith('http')
                      ? imageUrl
                      : '${ApiService.baseUrl}$imageUrl');
            },
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
        const SizedBox(height: 8),
        Text(
          "(Válassz ki minden helyes választ!)",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: palette.textSecondary,
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
    final palette = CozyTheme.of(context);
    final options = getLocalizedOptions(context, question);
    final List<String> selectedOptions =
        (currentAnswer is List) ? List<String>.from(currentAnswer) : [];

    if (options.isEmpty) {
      return const Text("No options available");
    }

    return Column(
      children: options.asMap().entries.map<Widget>((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = selectedOptions.contains(option);
        final List<String> corrects = (correctAnswer is List)
            ? correctAnswer.map((e) => e.toString()).toList()
            : [];
        final bool isOptionCorrect = corrects.contains(option);

        Color backgroundColor = palette.paperCream;
        Color borderColor = palette.textPrimary.withValues(alpha: 0.1);
        Color textColor = palette.textPrimary;

        if (isSelected) {
          backgroundColor = palette.primary.withValues(alpha: 0.15);
          borderColor = palette.primary;
          textColor = palette.primary;
        }

        if (isChecked) {
          if (isOptionCorrect) {
            backgroundColor = palette.primary; // Same green as Continue button
            borderColor = palette.primary;
            textColor = palette.textInverse;
          } else if (isSelected && !isOptionCorrect) {
            backgroundColor = palette.error;
            borderColor = palette.error;
            textColor = palette.textInverse;
          }
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
              key: ValueKey("multi_${question['id']}_$index"),
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              isSelected: isSelected,
              isWrong: isChecked && isSelected && !isOptionCorrect,
              isDisabled: isChecked,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () {
                final newSelected = List<String>.from(selectedOptions);
                if (isSelected) {
                  newSelected.remove(option);
                } else {
                  newSelected.add(option);
                }
                onAnswerChanged(newSelected);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: isSelected || (isChecked && isOptionCorrect)
                            ? FontWeight.w600
                            : FontWeight.w400,
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
    return answer != null && (answer is List) && answer.isNotEmpty;
  }

  @override
  dynamic formatAnswer(dynamic answer) {
    return answer;
  }

  @override
  bool validateAnswer(dynamic userAnswer, dynamic correctAnswer) {
    if (userAnswer == null || correctAnswer == null) return false;
    if (userAnswer is! List) return false;

    final List<String> uList =
        userAnswer.map((e) => e.toString().trim().toLowerCase()).toList();
    List<String> cList = [];

    if (correctAnswer is String) {
      final trimmed = correctAnswer.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = json.decode(trimmed);
          if (decoded is List) {
            cList = decoded.map((e) => e.toString().trim().toLowerCase()).toList();
          } else {
            cList = [trimmed.toLowerCase()];
          }
        } catch (_) {
          cList = [trimmed.toLowerCase()];
        }
      } else if (trimmed.contains(',')) {
        // Handle comma-separated strings: "Option A, Option B"
        cList = trimmed.split(',').map((e) => e.trim().toLowerCase()).toList();
      } else {
        cList = [trimmed.toLowerCase()];
      }
    } else if (correctAnswer is List) {
      cList =
          correctAnswer.map((e) => e.toString().trim().toLowerCase()).toList();
    }

    if (uList.length != cList.length) return false;
    return uList.every((u) => cList.contains(u));
  }

  @override
  dynamic getAnswerForIndex(BuildContext context, Map<String, dynamic> question,
      int index, dynamic currentAnswer) {
    final options = getLocalizedOptions(context, question);
    if (index >= 0 && index < options.length) {
      final option = options[index];
      final List<String> selectedOptions =
          (currentAnswer is List) ? List<String>.from(currentAnswer) : [];
      if (selectedOptions.contains(option)) {
        selectedOptions.remove(option);
      } else {
        selectedOptions.add(option);
      }
      return selectedOptions;
    }
    return currentAnswer;
  }
}
