import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'question_renderer.dart';
import '../../theme/cozy_theme.dart';

/// Renderer for Relation Analysis questions
/// Medical exam format: Two statements with relationship analysis
class RelationAnalysisRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final palette = CozyTheme.of(context);
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
          style: GoogleFonts.outfit(
            fontSize: 20, 
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statement 1
        _buildStatementBox(context, '1', s1, palette.secondary),
        
        // Link word
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: palette.textPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.textPrimary.withValues(alpha: 0.1)),
              ),
              child: Text(
                linkWord.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: palette.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),

        // Statement 2
        _buildStatementBox(context, '2', s2, palette.primary),
      ],
    );
  }

  Widget _buildStatementBox(BuildContext context, String num, String text, Color color) {
    final palette = CozyTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.paperCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.textPrimary.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(color: palette.textPrimary.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.outfit(color: palette.textInverse, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(fontSize: 17, height: 1.5, color: palette.textPrimary, fontWeight: FontWeight.w500),
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
    Function(dynamic) onAnswerChanged, {
    bool isChecked = false,
    dynamic correctAnswer,
  }) {
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
        _buildToggle(context, 'Statement 1 is True', s1, 
          isChecked ? (_) {} : (val) {
            onAnswerChanged(calculateResult(val, s2, link));
          }, isChecked: isChecked),
        const SizedBox(height: 12),
        _buildToggle(context, 'Statement 2 is True', s2, 
          isChecked ? (_) {} : (val) {
            onAnswerChanged(calculateResult(s1, val, link));
          }, isChecked: isChecked),
        
        // Link is strictly only valid for A vs B logically, logic-wise it's usually greyed out if not both true?
        // But for simplicity let's keep it visible or maybe only enable if both are true?
        // User asked: "a check box if there connect inbetween the statement"
        const SizedBox(height: 12),
        Opacity(
          opacity: (s1 && s2) ? 1.0 : 0.5,
          child: _buildToggle(context, 'Connection / Link Exists', link, 
            isChecked ? (_) {} : (val) {
              if (s1 && s2) onAnswerChanged(calculateResult(s1, s2, val));
            }, isLink: true, isChecked: isChecked),
        ),
      ],
    );
  }

  Widget _buildToggle(BuildContext context, String label, bool value, Function(bool) onChanged, {bool isLink = false, bool isChecked = false}) {
    final palette = CozyTheme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isChecked ? null : () => onChanged(!value),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: value ? (isLink ? palette.secondary.withValues(alpha: 0.1) : palette.success.withValues(alpha: 0.1)) : palette.paperCream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: value ? (isLink ? palette.secondary : palette.success) : palette.textPrimary.withValues(alpha: 0.1),
              width: value ? 2 : 1.5,
            ),
            boxShadow: value ? [
              BoxShadow(
                color: (isLink ? palette.secondary : palette.success).withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Row(
            children: [
              Icon(
                value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: value ? (isLink ? palette.secondary : palette.success) : palette.textPrimary.withValues(alpha: 0.3),
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                    color: value ? (isLink ? palette.secondary : palette.success) : palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
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

  @override
  dynamic getAnswerForIndex(BuildContext context, Map<String, dynamic> question, int index, dynamic currentAnswer) {
    if (index < 0 || index > 2) return currentAnswer;

    bool s1 = false;
    bool s2 = false;
    bool link = false;

    if (currentAnswer != null) {
      final ans = currentAnswer.toString().toUpperCase();
      if (['A', 'B', 'C'].contains(ans)) s1 = true;
      if (['A', 'B', 'D'].contains(ans)) s2 = true;
      if (ans == 'A') link = true;
    }

    if (index == 0) s1 = !s1;
    if (index == 1) s2 = !s2;
    if (index == 2 && s1 && s2) link = !link;

    // Local result calculation helper (reused logic)
    if (s1 && s2) {
      return link ? 'A' : 'B';
    }
    if (s1 && !s2) return 'C';
    if (!s1 && s2) return 'D';
    return 'E'; // !s1 && !s2
  }
}
