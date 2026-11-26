import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:provider/provider.dart';
import 'package:arbor_med/core/models/topic_hierarchy.dart';
import 'package:arbor_med/features/quiz/providers/topic_provider.dart';
import '../../../services/admin_question_provider.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'admin_question_action.dart';

class BulkActionHandler {
  static Future<void> handleBulkDelete(
          {required BuildContext context,
          required AdminQuestionProvider questionProvider,
          required Set<int> selectedIds,
          required VoidCallback onSuccess}) =>
      _run(context, questionProvider, selectedIds, onSuccess, move: false);

  static Future<void> handleBulkMove(
          {required BuildContext context,
          required AdminQuestionProvider questionProvider,
          required Set<int> selectedIds,
          required VoidCallback onSuccess}) =>
      _run(context, questionProvider, selectedIds, onSuccess, move: true);

  static Future<void> _run(BuildContext context, AdminQuestionProvider provider,
          Set<int> selectedIds, VoidCallback onSuccess,
          {required bool move}) =>
      runQuestionAction(context, provider, (active) async {
        final ids = List<int>.unmodifiable(selectedIds);
        if (ids.isEmpty) return;
        final l = AppLocalizations.of(context)!;
        final catalog = move ? context.read<TopicProvider>() : null;
        int? target;
        List<int>? selectedPath;
        bool sameTarget(TopicHierarchy h) =>
            target != null && listEquals(h.branch(target!), selectedPath);
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialog) {
              void close(bool result) {
                if (ModalRoute.of(dialog)?.isCurrent == true) {
                  Navigator.pop(dialog, result);
                }
              }

              Widget prompt(TopicHierarchy? hierarchy, StateSetter rebuild) {
                final valid = move && sameTarget(hierarchy!);
                return AlertDialog(
                    scrollable: true,
                    title: Text(move
                        ? l.adminMoveQuestionsTitle
                        : l.adminConfirmBatchDelete),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(move
                          ? l.adminMoveQuestionsSubtitle(ids.length)
                          : l.adminConfirmBatchDeleteSubtitle(ids.length)),
                      if (hierarchy != null)
                        DropdownButtonFormField<int>(
                            key: ValueKey(valid ? target : null),
                            initialValue: valid ? target : null,
                            isExpanded: true,
                            decoration:
                                InputDecoration(labelText: l.adminTargetTopic),
                            items: [
                              for (final id in hierarchy.subjectOf.keys)
                                DropdownMenuItem(
                                    value: id,
                                    child: Text(
                                        hierarchy.label(id, l.localeName,
                                            l.adminUnnamedSection,
                                            includeRoot: true),
                                        overflow: TextOverflow.ellipsis))
                            ],
                            onChanged: (id) => rebuild(() {
                                  target = id;
                                  selectedPath =
                                      id == null ? null : hierarchy.branch(id);
                                })),
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => close(false), child: Text(l.cancel)),
                      TextButton(
                          onPressed:
                              (!move || valid) ? () => close(true) : null,
                          style: move
                              ? null
                              : TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(dialog).colorScheme.error),
                          child: Text(move ? l.adminMoveNow : l.adminDeleteAll))
                    ]);
              }

              return StatefulBuilder(
                  builder: (context, rebuild) => catalog == null
                      ? prompt(null, rebuild)
                      : ListenableBuilder(
                          listenable: catalog,
                          builder: (_, __) =>
                              prompt(TopicHierarchy(catalog.topics), rebuild)));
            });
        if (confirmed != true ||
            !active() ||
            !context.mounted || ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        if (move && !sameTarget(TopicHierarchy(catalog!.topics))) return;
        final success = await provider.bulkActionQuestions(
            action: move ? 'move' : 'delete', ids: ids, targetTopicId: target);
        if (!active() || !context.mounted) return;
        final message = success
            ? (move
                ? l.adminSuccessQuestionsMoved
                : l.adminSuccessDeletedCount(ids.length))
            : (move ? l.adminErrorMoveQuestions : l.adminErrorDeleteBulk);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        if (success) onSuccess();
      });
}
