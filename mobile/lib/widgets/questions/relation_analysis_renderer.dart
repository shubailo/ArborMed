import 'package:flutter/material.dart';
import 'question_renderer.dart';
import '../../theme/cozy_theme.dart';

/// Renderer for Relation Analysis questions
/// Medical exam format: Two statements with relationship analysis
class RelationAnalysisRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final statement1 = getLocalizedContentField(context, question, 'statement1', defaultVal: '');
    final statement2 = getLocalizedContentField(context, question, 'statement2', defaultVal: '');
    final linkWord = getLocalizedContentField(context, question, 'link_word', defaultVal: 'because');

    // If still using old snake_case keys (fallback)
    final s1 = statement1.isNotEmpty ? statement1 : getLocalizedContentField(context, question, 'statement_1');
    final s2 = statement2.isNotEmpty ? statement2 : getLocalizedContentField(context, question, 'statement_2');

    // If legacy split data exists, render it. 
    // Otherwise, assume main question text covers it (Single Text Mode).
    if (statement1.isEmpty && statement2.isEmpty) {
      final questionText = getLocalizedText(context, question);
      return Center(
        child: Text(
          questionText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statement 1
        _buildStatementBox(context, '1', s1, Colors.blue),
        
        // Link word
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                linkWord,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // Statement 2
        _buildStatementBox(context, '2', s2, Colors.green),
      ],
    );
  }

  Widget _buildStatementBox(BuildContext context, String num, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildAnswerInput(
    BuildContext context,
    Map<String, dynamic> question,
    dynamic currentAnswer,
    Function(dynamic) onAnswerChanged,
  ) {
    // Simplified 3-State Logic
    // S1 True/False
    // S2 True/False
    // Link Exists/Not (Only relevant if both are true?) -> Standard format allows all combos but Link usually mostly relevant for A/B.
    
    // Deconstruct standard A-E answer back to booleans for UI state
    // A: T, T, Linked
    // B: T, T, Not Linked
    // C: T, F
    // D: F, T
    // E: F, F

    bool s1 = false;
    bool s2 = false;
    bool link = false;

    if (currentAnswer != null) {
      final ans = currentAnswer.toString().toUpperCase();
      if (['A', 'B', 'C'].contains(ans)) s1 = true;
      if (['A', 'B', 'D'].contains(ans)) s2 = true;
      if (ans == 'A') link = true;
    } else {
      // Default state? Or empty? 
      // If empty, all false.
    }

    // Helper to calculate resulting A-E value based on booleans
    String calculateResult(bool s1, bool s2, bool link) {
      if (s1 && s2) {
        return link ? 'A' : 'B';
      }
      if (s1 && !s2) return 'C';
      if (!s1 && s2) return 'D';
      return 'E'; // !s1 && !s2
    }

    return Column(
      children: [
        _buildToggle(context, 'Statement 1 is True', s1, (val) {
          onAnswerChanged(calculateResult(val, s2, link));
        }),
        const SizedBox(height: 12),
        _buildToggle(context, 'Statement 2 is True', s2, (val) {
          onAnswerChanged(calculateResult(s1, val, link));
        }),
        
        // Link is strictly only valid for A vs B logically, logic-wise it's usually greyed out if not both true?
        // But for simplicity let's keep it visible or maybe only enable if both are true?
        // User asked: "a check box if there connect inbetween the statement"
        const SizedBox(height: 12),
        Opacity(
          opacity: (s1 && s2) ? 1.0 : 0.5,
          child: _buildToggle(context, 'Connection / Link Exists', link, (val) {
             if (s1 && s2) onAnswerChanged(calculateResult(s1, s2, val));
          }, isLink: true),
        ),
      ],
    );
  }

  Widget _buildToggle(BuildContext context, String label, bool value, Function(bool) onChanged, {bool isLink = false}) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value ? (isLink ? Colors.orange.withValues(alpha: 0.1) : CozyTheme.primary.withValues(alpha: 0.1)) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? (isLink ? Colors.orange : CozyTheme.primary) : Colors.grey[300]!,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? (isLink ? Colors.orange : CozyTheme.primary) : Colors.grey[400],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: value ? FontWeight.bold : FontWeight.normal,
                  color: value ? (isLink ? Colors.deepOrange : CozyTheme.primary) : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
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
