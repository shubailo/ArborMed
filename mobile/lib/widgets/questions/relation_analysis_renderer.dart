import 'package:flutter/material.dart';
import 'question_renderer.dart';
import '../../theme/cozy_theme.dart';

/// Renderer for Relation Analysis questions
/// Medical exam format: Two statements with relationship analysis
class RelationAnalysisRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final content = question['content'] as Map<String, dynamic>?;
    if (content == null) {
      return const Text('Invalid question format');
    }

    final statement1 = content['statement_1'] as String? ?? '';
    final statement2 = content['statement_2'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statement 1
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statement1,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Relationship icon
        Center(
          child: Icon(
            Icons.compare_arrows,
            size: 32,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 16),

        // Statement 2
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statement2,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ],
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
    Function(dynamic) onAnswerChanged,
  ) {
    List<dynamic> options = [];

    // 1. Try options from top-level (prepared by backend registry)
    if (question['options'] != null && 
        question['options'] is List && 
        (question['options'] as List).isNotEmpty) {
      options = question['options'] as List<dynamic>;
    } 
    // 2. Try options from content (for old or unprepared questions)
    else if (question['content'] != null && 
             question['content']['options'] != null && 
             (question['content']['options'] as List).isNotEmpty) {
      options = question['content']['options'] as List<dynamic>;
    }
    // 3. Fallback: Hardcoded standard Hungarian medical options
    else {
      options = [
        { 'value': 'both_true_related', 'label': 'Mindkét állítás igaz, és van köztük ok-okozati összefüggés' },
        { 'value': 'both_true_unrelated', 'label': 'Mindkét állítás igaz, de nincs köztük összefüggés' },
        { 'value': 'only_first_true', 'label': 'Csak az 1. állítás igaz' },
        { 'value': 'only_second_true', 'label': 'Csak a 2. állítás igaz' },
        { 'value': 'neither_true', 'label': 'Egyik állítás sem igaz' }
      ];
    }

    return Column(
      children: options.map<Widget>((option) {
        final optionMap = Map<String, dynamic>.from(option as Map);
        final value = optionMap['value'] as String;
        final label = optionMap['label'] as String;
        final isSelected = currentAnswer == value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onAnswerChanged(value),
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
                      label,
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
