import '../../../core/models/relation_answer.dart';
import '../../../core/models/relation_content.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../core/models/admin_question.dart';
import './reports_dialog.dart';

class QuestionPreviewPane extends StatelessWidget {
  final AdminQuestion question;
  final Future<Map<String, dynamic>?>? analyticsFuture;
  final VoidCallback onClose;
  final Function(AdminQuestion) onEditQuestion;
  final VoidCallback? onReportsChanged;

  const QuestionPreviewPane({
    super.key,
    required this.question,
    this.analyticsFuture,
    required this.onClose,
    required this.onEditQuestion,
    this.onReportsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CozyTheme.of(context);
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: palette.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: palette.textSecondary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.adminQuestionDetails,
                        style: GoogleFonts.quicksand(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        "#${question.id} • ${question.type}",
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: palette.textSecondary),
                  tooltip: l.close,
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SavedQuestionDetails(
                      key: ValueKey(question.id), question: question),
                  const SizedBox(height: 24),
                  // ANALYTICS SECTION
                  Text(
                    l.analyticsTab,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: palette.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: palette.textSecondary.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.attempts == 0
                                    ? '—'
                                    : '${question.successRate.toStringAsFixed(1)}%',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: question.attempts == 0
                                      ? palette.textSecondary
                                      : question.successRate < 30
                                          ? palette.error
                                          : (question.successRate > 80
                                              ? Colors.green
                                              : palette.primary),
                                ),
                              ),
                              Text(
                                l.adminSuccessRate,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: palette.textSecondary.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.attempts.toString(),
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                              Text(
                                l.adminTableAttempts,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Reports Section
                  if (question.reportCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flag_rounded, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${l.adminQuestionReports} (${question.reportCount})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => ReportsDialog(
                                  questionId: question.id,
                                  onChanged: () {
                                    if (context.mounted) {
                                      onReportsChanged?.call();
                                    }
                                  },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.orange,
                              elevation: 0,
                            ),
                            child: Text(l.adminQuestionReports),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Common Knowledge Gap (Existing)
                  if (question.attempts > 0 && question.successRate < 50) ...[
                    Text(
                      AppLocalizations.of(context)!.adminCommonKnowledgeGap,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: palette.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: palette.error,
                            size: 20,
                          ),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!
                                  .adminHighFailureRateWarning,
                              style: TextStyle(
                                color: palette.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Analytics: Wrong Answers
                  FutureBuilder<Map<String, dynamic>?>(
                    future: analyticsFuture,
                    builder: (context, snapshot) {
                      if (analyticsFuture == null ||
                          snapshot.connectionState != ConnectionState.done) {
                        return const SizedBox.shrink();
                      }
                      final raw = snapshot.data?['wrongAnswers'];
                      if (snapshot.hasError || raw is! List) {
                        return Text(l.adminNoAnalyticsAvailable);
                      }
                      final wrongAnswers = raw.whereType<Map>().where((row) =>
                          row['answer'] != null && row['count'] is num);
                      if (wrongAnswers.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .adminCommonlyConfusedWith,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: palette.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: wrongAnswers.map<Widget>((item) {
                              final ans = item['answer'];
                              final count = item['count'];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: palette.textSecondary.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ans.toString(),
                                      style: TextStyle(
                                        color: palette.textPrimary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.error.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        count.toString(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: palette.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: question.supportsEditing
                          ? () => onEditQuestion(question)
                          : null,
                      icon: const Icon(Icons.edit),
                      label: Text(
                        AppLocalizations.of(context)!.adminEditQuestion,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: palette.textInverse,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedQuestionDetails extends StatefulWidget {
  const _SavedQuestionDetails({super.key, required this.question});
  final AdminQuestion question;

  @override
  State<_SavedQuestionDetails> createState() => _SavedQuestionDetailsState();
}

class _SavedQuestionDetailsState extends State<_SavedQuestionDetails> {
  String? _language;

  @override
  Widget build(BuildContext context) {
    final ui = AppLocalizations.of(context)!;
    final lang = _language ?? Localizations.localeOf(context).languageCode;
    final q = widget.question;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, children: [
        for (final code in ['en', 'hu'])
          ChoiceChip(
              label: Text(
                  code == 'hu' ? ui.languageHungarian : ui.languageEnglish),
              selected: lang == code,
              onSelected: (_) => setState(() => _language = code)),
      ]),
      const SizedBox(height: 12),
      Text(ui.questionText, style: Theme.of(context).textTheme.labelMedium),
      Text(q.questionLabel(lang) ?? ui.adminUntitled),
      if (q.type == 'relation_analysis' && q.content is Map)
        for (final field in ['statement1', 'link_word', 'statement2'])
          if (relationText(q.content, field, lang, fallback: true) case final value when value.isNotEmpty)
            Text(value),
      if (q.type == 'single_choice' ||
          q.type == 'multiple_choice' ||
          q.type == 'case_study')
        for (final choice in q.choices) Text('• ${choice.label(lang)}'),
      const SizedBox(height: 12),
      Text(ui.correctAnswer, style: Theme.of(context).textTheme.labelMedium),
      for (final answer in _answers(q, lang, ui)) Text(answer),
      if (q.explanationLabel(lang) case final String explanation) ...[
        const SizedBox(height: 12),
        Text(ui.explanation, style: Theme.of(context).textTheme.labelMedium),
        Text(explanation),
      ],
    ]);
  }

  Iterable<String> _answers(
      AdminQuestion q, String lang, AppLocalizations l) sync* {
    final keys = q.answerKeys;
    if (q.type == 'relation_analysis') {
      yield RelationAnswer.fromStored(q.correctAnswer)?.code ?? l.adminAnswerKeyUnresolved;
      return;
    }
    if (q.type == 'true_false') {
      final labels = lookupAppLocalizations(Locale(lang));
      yield switch (q.booleanAnswer) {
        true => labels.adminTrue,
        false => labels.adminFalse,
        null => l.adminAnswerKeyUnresolved,
      };
      return;
    }
    if (q.type == 'matching') {
      final pairs = q.matchingPairs;
      final stored = keys.singleOrNull;
      if (pairs.isEmpty || (keys.isNotEmpty && stored is! Map)) {
        yield l.adminAnswerKeyUnresolved;
        return;
      }
      final left = <String, String>{};
      final right = <String, String>{};
      for (final pair in pairs) {
        for (final (side, labels) in [('left', left), ('right', right)]) {
          final en = pair.text(side, 'en');
          final translated = pair.text(side, lang);
          labels[en] = translated.trim().isEmpty ? en : translated;
        }
      }
      final answers = stored is Map && stored.isNotEmpty
          ? stored
          : {
              for (final pair in pairs)
                pair.text('left', 'en'): pair.text('right', 'en')
            };
      for (final entry in answers.entries) {
        yield '${left[entry.key] ?? entry.key} → ${right[entry.value] ?? entry.value}';
      }
      return;
    }
    if (keys.isEmpty) {
      yield l.adminAnswerKeyUnresolved;
      return;
    }
    for (final key in keys) {
      if (q.type == 'single_choice' ||
          q.type == 'multiple_choice' ||
          q.type == 'case_study') {
        final index = q.choiceIndex(key);
        yield index == null
            ? '${l.adminAnswerKeyUnresolved} ($key)'
            : q.choices[index].label(lang);
      } else {
        yield key.toString();
      }
    }
  }
}
