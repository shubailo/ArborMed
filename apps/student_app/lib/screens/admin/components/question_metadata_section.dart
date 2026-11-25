import 'package:flutter/material.dart';
import '../../../theme/cozy_theme.dart';
import '../../../generated/l10n/app_localizations.dart';

class QuestionMetadataSection extends StatelessWidget {
  final List<dynamic> topics;
  final Map<int, int> subjectByTopic;
  final List<String> excludedTopicSlugs;
  final String questionType;
  final int bloomLevel;
  final int? selectedSubjectId;
  final int? selectedTopicId;
  final ValueChanged<String> onQuestionTypeChanged;
  final ValueChanged<int> onBloomLevelChanged;
  final ValueChanged<int?> onSubjectChanged;
  final ValueChanged<int?> onTopicChanged;

  const QuestionMetadataSection({
    super.key,
    required this.topics,
    required this.subjectByTopic,
    this.excludedTopicSlugs = const ['ecg'],
    required this.questionType,
    required this.bloomLevel,
    required this.selectedSubjectId,
    required this.selectedTopicId,
    required this.onQuestionTypeChanged,
    required this.onBloomLevelChanged,
    required this.onSubjectChanged,
    required this.onTopicChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subjects = topics
        .where((t) =>
            t['parent_id'] == null &&
            (!excludedTopicSlugs.contains(t['slug']) || t['id'] == selectedSubjectId))
        .toList();

    List<dynamic> sections = [];
    if (selectedSubjectId != null) {
      sections = topics
          .where((t) => subjectByTopic[t['id']] == selectedSubjectId &&
              (t['id'] != selectedSubjectId || t['id'] == selectedTopicId))
          .toList();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                key: ValueKey('type_$questionType'),
                initialValue: questionType,
                isExpanded: true,
                decoration: CozyTheme.inputDecoration(
                  context,
                  AppLocalizations.of(context)!.adminQuestionType,
                ).copyWith(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'single_choice',
                    child: Text(
                      AppLocalizations.of(context)!.quizTypeSingleChoice,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'multiple_choice',
                    child: Text(
                      AppLocalizations.of(context)!.quizTypeMultipleChoice,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'true_false',
                    child: Text(
                      AppLocalizations.of(context)!.quizTypeTrueFalse,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'relation_analysis',
                    child: Text(
                      AppLocalizations.of(context)!.quizTypeRelational,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'matching',
                    child: Text(
                      AppLocalizations.of(context)!.quizTypeMatching,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    onQuestionTypeChanged(val);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                key: ValueKey('bloom_$bloomLevel'),
                initialValue: bloomLevel,
                isExpanded: true,
                decoration: CozyTheme.inputDecoration(
                  context,
                  AppLocalizations.of(context)!.adminBloomCriteria,
                ).copyWith(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [1, 2, 3, 4]
                    .map(
                      (l) => DropdownMenuItem(
                        value: l,
                        child: Text(
                          "${AppLocalizations.of(context)!.adminLevel} $l",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    onBloomLevelChanged(val);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('sub_$selectedSubjectId'),
                initialValue: selectedSubjectId,
                isExpanded: true,
                decoration: CozyTheme.inputDecoration(
                  context,
                  AppLocalizations.of(context)!.adminSubject,
                ).copyWith(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: subjects.map<DropdownMenuItem<int>>((s) {
                  return DropdownMenuItem(
                    value: s['id'] as int,
                    child: Text(
                      s['name']?.toString() ??
                          s['name_en']?.toString() ??
                          'Unnamed Subject',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                validator: (val) => val == null
                    ? AppLocalizations.of(context)!.adminErrorSelectSubject
                    : null,
                onChanged: onSubjectChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('topic_$selectedTopicId'),
                initialValue: selectedTopicId,
                isExpanded: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: CozyTheme.inputDecoration(
                  context,
                  AppLocalizations.of(context)!.adminSection,
                ).copyWith(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (val) {
                  if (selectedSubjectId != null && val == null) {
                    return AppLocalizations.of(context)!.adminErrorSelectSection;
                  }
                  return null;
                },
                items: sections.isEmpty
                    ? []
                    : sections.map<DropdownMenuItem<int>>((s) {
                        return DropdownMenuItem(
                          value: s['id'] as int,
                          child: Text(
                            s['name']?.toString() ??
                                s['name_en']?.toString() ??
                                'Unnamed Topic',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                onChanged: sections.isEmpty ? null : onTopicChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

