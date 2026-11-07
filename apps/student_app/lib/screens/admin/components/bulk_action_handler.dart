import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/admin_question_provider.dart';
import 'package:arbor_med/features/quiz/providers/topic_provider.dart';
import '../../../generated/l10n/app_localizations.dart';

class BulkActionHandler {
  static Future<void> handleBulkDelete({
    required BuildContext context,
    required AdminQuestionProvider questionProvider,
    required Set<int> selectedIds,
    required VoidCallback onSuccess,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminConfirmBatchDelete),
        content: Text(
          l10n.adminConfirmBatchDeleteSubtitle(selectedIds.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.adminDeleteAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await questionProvider.bulkActionQuestions(
        action: 'delete',
        ids: selectedIds.toList(),
      );
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminSuccessDeletedCount(selectedIds.length)),
          ),
        );
        onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.adminErrorDeleteBulk),
          ),
        );
      }
    }
  }

  static Future<void> handleBulkMove({
    required BuildContext context,
    required AdminQuestionProvider questionProvider,
    required Set<int> selectedIds,
    required VoidCallback onSuccess,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    int? targetId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.adminMoveQuestionsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.adminMoveQuestionsSubtitle(selectedIds.length)),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: targetId,
                items: Provider.of<TopicProvider>(context, listen: false)
                    .topics
                    .map<DropdownMenuItem<int>>(
                      (topic) => DropdownMenuItem(
                        value: topic['id'],
                        child: Text(
                          topic['name_en'] ?? topic['name'] ?? 'Untitled',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setDialogState(() => targetId = val),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.adminTargetTopic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: targetId == null
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text(l10n.adminMoveNow),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && targetId != null) {
      final success = await questionProvider.bulkActionQuestions(
        action: 'move',
        ids: selectedIds.toList(),
        targetTopicId: targetId,
      );
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.adminSuccessQuestionsMoved,
            ),
          ),
        );
        onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.adminErrorMoveQuestions,
            ),
          ),
        );
      }
    }
  }
}
