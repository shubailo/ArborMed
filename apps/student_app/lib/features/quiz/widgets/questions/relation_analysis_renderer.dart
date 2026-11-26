import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'package:arbor_med/core/models/relation_answer.dart';
import 'package:arbor_med/core/models/relation_content.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'question_renderer.dart';
import 'package:arbor_med/theme/cozy_theme.dart';

/// Renderer for Relation Analysis questions
/// Medical exam format: Two statements with relationship analysis
class RelationAnalysisRenderer extends QuestionRenderer {
  bool _hasContent(Map<String, dynamic> question) {
    final raw = question['content'];
    if (raw != null && raw is! Map) return false;
    final content = raw is Map ? raw : const {};
    final prompt = content['question_text'];
    final hasPrompt = [
      question['question_text_en'],
      question['question_text_hu'],
      question['text'],
      if (prompt is Map) ...[prompt['en'], prompt['hu']] else prompt,
    ].whereType<String>().any((value) => value.trim().isNotEmpty);
    return relationContentValid(content, hasPrompt: hasPrompt);
  }

  @override
  bool isPlayable(Map<String, dynamic> question) =>
      _hasContent(question) &&
      RelationAnswer.fromStored(question['correct_answer']) != null;

  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    if (!_hasContent(question)) {
      return Text(AppLocalizations.of(context)!.quizIncompleteQuestion);
    }
    final palette = CozyTheme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final raw = question['content'];
    final content = raw is Map ? raw : const {};
    final s1 = relationText(content, 'statement1', lang, fallback: true);
    final s2 = relationText(content, 'statement2', lang, fallback: true);
    final connector = relationText(content, 'link_word', lang, fallback: true);
    final linkWord =
        connector.isNotEmpty ? connector : (lang == 'hu' ? 'mert' : 'because');

    final questionText = getLocalizedText(context, question);
    if (s1.isEmpty && s2.isEmpty) {
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
        if (questionText.trim().isNotEmpty &&
            questionText.trim() != s1.trim() &&
            questionText.trim() != s2.trim())
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(questionText,
                style: Theme.of(context).textTheme.titleMedium),
          ),
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
                border: Border.all(
                    color: palette.textPrimary.withValues(alpha: 0.1)),
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

  Widget _buildStatementBox(
      BuildContext context, String num, String text, Color color) {
    final palette = CozyTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.paperCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: palette.textPrimary.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: palette.textPrimary.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.outfit(
                    color: palette.textInverse, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                  fontSize: 17,
                  height: 1.5,
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w500),
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
    if (!_hasContent(question)) return const SizedBox.shrink();
    final labels = AppLocalizations.of(context)!;
    final selected = RelationAnswer.fromInput(currentAnswer);
    final expected =
        isChecked ? RelationAnswer.fromStored(correctAnswer) : null;
    final palette = CozyTheme.of(context);
    return RadioGroup<RelationAnswer>(
      groupValue: selected,
      onChanged: (choice) {
        if (isChecked || choice == null) return;
        context.read<AudioProvider>().playSfx('click');
        onAnswerChanged(choice.code);
      },
      child: Column(children: [
        for (final choice in RelationAnswer.values)
          RadioListTile<RelationAnswer>(
            key: ValueKey('relation-${choice.code}'),
            value: choice,
            enabled: !isChecked,
            selected: selected == choice,
            activeColor: palette.primary,
            title: Text('${choice.code} · ${choice.label(labels)}'),
            subtitle: expected == choice ? Text(labels.correctAnswer) : null,
          ),
      ]),
    );
  }

  @override
  bool hasAnswer(dynamic answer) => RelationAnswer.fromInput(answer) != null;

  @override
  String? formatAnswer(dynamic answer) =>
      RelationAnswer.fromInput(answer)?.code;

  @override
  bool validateAnswer(dynamic userAnswer, dynamic correctAnswer,
      Map<String, dynamic> question) {
    final actual = RelationAnswer.fromInput(userAnswer);
    return actual != null && actual == RelationAnswer.fromStored(correctAnswer);
  }

  @override
  dynamic getAnswerForIndex(BuildContext context, Map<String, dynamic> question,
          int index, dynamic currentAnswer) =>
      index >= 0 && index < RelationAnswer.values.length
          ? RelationAnswer.values[index].code
          : currentAnswer;
}
