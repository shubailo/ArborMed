import 'package:flutter/material.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../../theme/cozy_theme.dart';
import '../../../../core/models/admin_question.dart';
import '../../../../features/analytics/providers/stats_provider.dart';

class QuestionsDataTable extends StatelessWidget {
  final StatsProvider stats;
  final Set<int> selectedIds;
  final Function(Set<int>) onSelectionChanged;
  final String sortBy;
  final bool isAscending;
  final Function(String, bool) onSort;
  final AdminQuestion? selectedPreviewQuestion;
  final Function(AdminQuestion) onPreviewSelected;
  final String Function(String) getReadableType;
  final Function(AdminQuestion) onEditQuestion;
  final Function(AdminQuestion) onDeleteQuestion;

  const QuestionsDataTable({
    super.key,
    required this.stats,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.sortBy,
    required this.isAscending,
    required this.onSort,
    required this.selectedPreviewQuestion,
    required this.onPreviewSelected,
    required this.getReadableType,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const int textFlex = 3;
        const int typeFlex = 1;
        const int sectionFlex = 2;
        const int bloomFlex = 1;
        const int attemptsFlex = 1;
        const int accuracyFlex = 1;

        return Column(
          children: [
            // 1. STICKY HEADER
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: CozyTheme.of(
                  context,
                ).textPrimary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Checkbox(
                      value: stats.adminQuestions.isNotEmpty &&
                          selectedIds.length == stats.adminQuestions.length,
                      onChanged: (val) {
                        if (val == true) {
                          onSelectionChanged(
                            stats.adminQuestions.map((q) => q.id).toSet(),
                          );
                        } else {
                          onSelectionChanged({});
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.adminTableId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  _buildFlexHeaderCell(
                    context,
                    AppLocalizations.of(context)!.adminTableQuestionText,
                    textFlex,
                  ),
                  _buildFlexHeaderCell(
                    context,
                    AppLocalizations.of(context)!.adminTableType,
                    typeFlex,
                    sortKey: 'type',
                    center: true,
                  ),
                  _buildFlexHeaderCell(
                    context,
                    AppLocalizations.of(context)!.adminTableSection,
                    sectionFlex,
                    sortKey: 'topic_name',
                    center: true,
                  ),
                  _buildFlexHeaderCell(
                    context,
                    AppLocalizations.of(context)!.adminTableBloom,
                    bloomFlex,
                    sortKey: 'bloom_level',
                    center: true,
                  ),
                  _buildFlexHeaderCell(
                    context,
                    AppLocalizations.of(context)!.adminTableAttempts,
                    attemptsFlex,
                    sortKey: 'attempts',
                    center: true,
                  ),
                  _buildFlexHeaderCell(
                    context,
                    AppLocalizations.of(context)!.adminTableAccuracy,
                    accuracyFlex,
                    sortKey: 'success_rate',
                    center: true,
                  ),
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.adminTableActions,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RepaintBoundary(
                child: ListView.builder(
                  itemCount: stats.adminQuestions.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final q = stats.adminQuestions[index];
                    return _buildQuestionRowItem(
                      context,
                      q,
                      textFlex,
                      typeFlex,
                      sectionFlex,
                      bloomFlex,
                      attemptsFlex,
                      accuracyFlex,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8), // Reduced bottom padding
          ],
        );
      },
    );
  }

  Widget _buildQuestionRowItem(
    BuildContext context,
    AdminQuestion q,
    int textFlex,
    int typeFlex,
    int sectionFlex,
    int bloomFlex,
    int attemptsFlex,
    int accuracyFlex,
  ) {
    final accuracy = q.successRate;
    Color accuracyColor = Colors.grey;
    if (q.attempts > 0) {
      if (accuracy < 40) {
        accuracyColor = Colors.red;
      } else if (accuracy < 70) {
        accuracyColor = Colors.orange;
      } else {
        accuracyColor = Colors.green;
      }
    }

    return InkWell(
      onTap: () {
        onPreviewSelected(q);
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CozyTheme.of(context).textSecondary.withValues(alpha: 0.1),
            ),
          ),
          color: selectedPreviewQuestion?.id == q.id
              ? CozyTheme.of(context).primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                value: selectedIds.contains(q.id),
                onChanged: (val) {
                  final newSet = Set<int>.from(selectedIds);
                  if (val == true) {
                    newSet.add(q.id);
                  } else {
                    newSet.remove(q.id);
                  }
                  onSelectionChanged(newSet);
                },
              ),
            ),
            SizedBox(
              width: 50,
              child: Center(
                child: Text(
                  q.id.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            Expanded(
              flex: textFlex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  q.text ?? '(No text)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            _buildFlexCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CozyTheme.of(context).background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  getReadableType(q.type ?? 'unknown'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              typeFlex,
              center: true,
            ),
            _buildFlexCell(
              Text(
                q.topicNameEn ?? q.topicNameHu ?? '-',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              sectionFlex,
              center: true,
            ),
            _buildFlexCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "L${q.bloomLevel}",
                  style: TextStyle(
                    color: CozyTheme.of(context).primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              bloomFlex,
              center: true,
            ),
            _buildFlexCell(
              Text(q.attempts.toString(), style: const TextStyle(fontSize: 12)),
              attemptsFlex,
              center: true,
            ),
            _buildFlexCell(
              Text(
                "${accuracy.toStringAsFixed(1)}%",
                style: TextStyle(
                  color: accuracyColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              accuracyFlex,
              center: true,
            ),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                    onPressed: () => onEditQuestion(q),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: AppLocalizations.of(context)!.adminEditQuestion,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () => onDeleteQuestion(q),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: AppLocalizations.of(context)!.deleteQuestion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlexHeaderCell(
    BuildContext context,
    String label,
    int flex, {
    String? sortKey,
    bool center = false,
  }) {
    final bool isSorted = sortBy == sortKey;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: sortKey != null
            ? () => onSort(sortKey, !isSorted || !isAscending)
            : null,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: center ? Alignment.center : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: center
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: center ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSorted
                        ? CozyTheme.of(context, listen: false).primary
                        : CozyTheme.of(context, listen: false).textSecondary,
                  ),
                ),
              ),
              if (sortKey != null) ...[
                const SizedBox(width: 2),
                Icon(
                  isSorted
                      ? (isAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: 12,
                  color: isSorted
                      ? CozyTheme.of(context, listen: false).primary
                      : Colors.grey[300],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlexCell(Widget child, int flex, {bool center = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: child,
      ),
    );
  }
}
