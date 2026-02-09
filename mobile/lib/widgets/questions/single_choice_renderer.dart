import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final options = getLocalizedOptions(context, question);

    if (options.isEmpty) {
      return const Text("No options available");
    }

    return Column(
      children: options.asMap().entries.map<Widget>((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = currentAnswer == option;
        final optionStr = option.toString().trim().toLowerCase();
        final correctStr = (correctAnswer?.toString() ?? "").trim().toLowerCase();
        
        final isCorrect = isChecked && optionStr == correctStr;
        final isWrong = isChecked && isSelected && optionStr != correctStr;

        Color backgroundColor = palette.paperCream;
        Color borderColor = palette.textPrimary.withValues(alpha: 0.1);
        Color textColor = palette.textPrimary;

        if (isChecked) {
          if (isCorrect) {
            backgroundColor = palette.success.withValues(alpha: 0.08);
            borderColor = palette.success.withValues(alpha: 0.5);
            textColor = palette.success;
          } else if (isWrong) {
            backgroundColor = palette.error.withValues(alpha: 0.08);
            borderColor = palette.error.withValues(alpha: 0.5);
            textColor = palette.error;
          }
        } else if (isSelected) {
          backgroundColor = palette.primary.withValues(alpha: 0.08);
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isChecked
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        await Future.delayed(const Duration(milliseconds: 50));
                        HapticFeedback.lightImpact();
                        onAnswerChanged(option);
                      },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedScale(
                  scale: isSelected ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? borderColor : borderColor.withValues(alpha: 0.1),
                        width: isSelected ? 2.0 : 1.0,
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
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            option,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
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
  bool validateAnswer(dynamic userAnswer, dynamic correctAnswer) {
    if (userAnswer == null || correctAnswer == null) return false;
    final u = userAnswer.toString().trim().toLowerCase();
    
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
    final options = getLocalizedOptions(context, question);
    if (index >= 0 && index < options.length) {
      return options[index];
    }
    return currentAnswer;
  }
}
