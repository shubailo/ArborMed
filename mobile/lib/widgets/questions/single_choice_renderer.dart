import 'package:flutter/material.dart';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          GestureDetector(
            onTap: () => showZoomedImage(context, imageUrl!.startsWith('http') ? imageUrl : '${ApiService.baseUrl}$imageUrl'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!.startsWith('http') ? imageUrl : '${ApiService.baseUrl}$imageUrl',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  Container(
                    height: 150, 
                    color: Colors.grey[200], 
                    child: Center(child: Icon(Icons.broken_image, color: Colors.grey))
                  ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          questionText,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget buildAnswerInput(
    BuildContext context,
    Map<String, dynamic> question,
    dynamic currentAnswer,
    Function(dynamic) onAnswerChanged,
  ) {
    // getLocalizedOptions handles parsing JSON and selecting en/hu list
    final options = getLocalizedOptions(context, question);

    if (options.isEmpty) {
      return const Text("No options available");
    }

    return Column(
      children: options.map<Widget>((option) {
        final isSelected = currentAnswer == option;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onAnswerChanged(option),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? CozyTheme.primary.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? CozyTheme.primary : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? CozyTheme.primary : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? CozyTheme.primary : Colors.black87,
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
}
