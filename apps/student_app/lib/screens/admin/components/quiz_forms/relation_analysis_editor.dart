import 'package:flutter/material.dart';

import '../../../../core/models/relation_answer.dart';
import '../../../../generated/l10n/app_localizations.dart';

class RelationAnalysisEditor extends StatelessWidget {
  final int? correctIndex;
  final ValueChanged<int> onIndexChanged;

  const RelationAnalysisEditor({
    super.key,
    required this.correctIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final labels = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labels.adminSetCorrectLogic,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        for (final answer in RelationAnswer.values)
          ChoiceChip(
            label: Text('${answer.code}. ${answer.label(labels)}'),
            selected: correctIndex == answer.index,
            onSelected: (selected) {
              if (selected) onIndexChanged(answer.index);
            },
          ),
      ],
    );
  }
}
