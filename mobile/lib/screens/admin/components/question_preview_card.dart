import 'package:flutter/material.dart';
import '../../../services/stats_provider.dart'; // For AdminQuestion
import '../../../widgets/questions/question_renderer_registry.dart';

class QuestionPreviewCard extends StatelessWidget {
  final AdminQuestion? question;
  final String language; // 'en' or 'hu'

  const QuestionPreviewCard({super.key, this.question, this.language = 'en'});

  @override
  Widget build(BuildContext context) {
    if (question == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 40, color: Colors.grey),
            SizedBox(height: 12),
            Text("Select question",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    // Get question type (default to single_choice for backward compatibility)
    final questionType = question!.type ?? 'single_choice';

    // Get the appropriate renderer
    final renderer = QuestionRendererRegistry.getRenderer(questionType);

    // Extract localized options for the renderer
    dynamic localizedOptions = question!.options;
    if (question!.options is Map) {
      localizedOptions = question!.options[language] ??
          (language == 'hu' ? question!.options['en'] : []);
    }

    // Special handling for True/False options format required by TrueFalseRenderer
    if (questionType == 'true_false') {
      localizedOptions = [
        {'value': 'true', 'label': language == 'hu' ? 'Igaz' : 'True'},
        {'value': 'false', 'label': language == 'hu' ? 'Hamis' : 'False'},
      ];
    }

    // Extract matching data if present
    final matchingData =
        question!.content != null && question!.content['pairs'] != null
            ? {
                'left': (question!.content['pairs'] as List).map((p) {
                  final val = p['left'];
                  if (val is Map) return val[language] ?? val['en'];
                  return val;
                }).toList(),
                'right': (question!.content['pairs'] as List).map((p) {
                  final val = p['right'];
                  if (val is Map) return val[language] ?? val['en'];
                  return val;
                }).toList(),
              }
            : null;

    // Convert AdminQuestion to Map for the renderer
    final questionMap = {
      'text': language == 'hu'
          ? (question!.questionTextHu ?? question!.text)
          : question!.text,
      'question_text_en': question!.text,
      'question_text_hu': question!.questionTextHu,
      'options': localizedOptions,
      'content': question!.content,
      'matching_data': matchingData,
      'bloom_level': question!.bloomLevel,
      'difficulty': 3, // Mock difficulty for preview
    };

    final showSubmitButton = [
      'multiple_choice',
      'relation_analysis',
      'matching',
      'case_study'
    ].contains(questionType);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Header (Chips)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMockChip("Level ${question!.bloomLevel}"),
              _buildMockChip("Diff 3"),
            ],
          ),
          const SizedBox(height: 16),

          // Question Content (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  renderer.buildQuestion(context, questionMap),
                  const SizedBox(height: 24),
                  renderer.buildAnswerInput(
                    context,
                    questionMap,
                    null,
                    (_) {}, // No-op
                  ),
                ],
              ),
            ),
          ),

          if (showSubmitButton) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: null, // Always disabled in admin preview
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child:
                  const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMockChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700),
      ),
    );
  }
}
